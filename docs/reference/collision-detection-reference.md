# Collision Detection Reference: Hit.p8 Port for Picotron

## Project Overview

This document serves as a reference for a future **high-performance collision detection library** for Picotron, inspired by [hit.p8](https://github.com/kikito/hit.p8) and optimized for survivor games with hundreds of entities in tight clusters.

**Status**: Reference specification for future development  
**Relationship to Locustron**: Designed to integrate with Locustron's spatial partitioning for optimal performance  
**Target Use Case**: Survivor games, bullet hell games, and other high-entity-count scenarios

---

## Design Philosophy

### Separation of Concerns

- **Spatial Partitioning** (Locustron): Efficiently organize objects in space for fast queries
- **Collision Detection** (This project): Determine precise intersections and collision responses
- **Integration Pattern**: Use Locustron to get collision candidates, then apply precise collision detection

### Performance Goals

- **200+ entities** at **60fps** for survivor games
- **<10ms** collision detection for tight entity clusters
- **Callback-based architecture** for flexible collision response
- **Memory efficiency** with minimal garbage collection

---

## Core Architecture

### Collision Resolution System

**Inspired by locus.p8 patterns and optimized for survivor games**:

```lua
local class = require("lib.middleclass")

-- Core collision resolution system with callback support
local CollisionResolver = class("CollisionResolver")

function CollisionResolver:initialize(spatial_partitioner)
  self.spatial = spatial_partitioner  -- Locustron instance
  self.collision_callbacks = {}
  self.collision_filters = {}
  self.batch_size = 100  -- Process collisions in batches for performance
end

-- Enhanced collision detection with callback-based resolution
function CollisionResolver:detect_collisions(query_region, options)
  options = options or {}
  local collision_type = options.type or "immediate"
  local filter_fn = options.filter or nil
  local callback = options.on_collision or nil
  
  if collision_type == "immediate" then
    return self:detect_immediate_collisions(query_region, filter_fn, callback)
  elseif collision_type == "continuous" then
    return self:detect_continuous_collisions(query_region, filter_fn, callback)
  elseif collision_type == "survivor_swarm" then
    return self:detect_survivor_swarm_collisions(query_region, filter_fn, callback)
  end
end

-- Immediate collision detection (based on locus.p8 pattern)
function CollisionResolver:detect_immediate_collisions(region, filter_fn, callback)
  local x, y, w, h = region.x, region.y, region.w, region.h
  local candidates = self.spatial:query_region(x, y, w, h, filter_fn)
  local collisions = {}
  
  for obj in pairs(candidates) do
    local ox, oy, ow, oh = self.spatial:get_bbox(obj)
    
    -- Rectangle intersection check (following locus.p8 pattern)
    if self:rectangle_intersect(x, y, w, h, ox, oy, ow, oh) then
      local collision_data = {
        object = obj,
        intersection = self:calculate_intersection(x, y, w, h, ox, oy, ow, oh),
        type = "immediate"
      }
      
      table.insert(collisions, collision_data)
      
      -- Execute callback immediately for real-time response
      if callback then
        callback(collision_data)
      end
    end
  end
  
  return collisions
end

-- Survivor game swarm collision detection - optimized for hundreds of entities
function CollisionResolver:detect_survivor_swarm_collisions(region, filter_fn, callback)
  local x, y, w, h = region.x, region.y, region.w, region.h
  local candidates = self.spatial:query_region(x, y, w, h, filter_fn)
  local collisions = {}
  local collision_count = 0
  
  -- Batch processing for performance with large entity counts
  local batch = {}
  local batch_count = 0
  
  for obj in pairs(candidates) do
    local ox, oy, ow, oh = self.spatial:get_bbox(obj)
    
    if self:rectangle_intersect(x, y, w, h, ox, oy, ow, oh) then
      collision_count = collision_count + 1
      batch_count = batch_count + 1
      
      local collision_data = {
        object = obj,
        intersection = self:calculate_intersection(x, y, w, h, ox, oy, ow, oh),
        type = "survivor_swarm",
        batch_id = math.floor(collision_count / self.batch_size)
      }
      
      batch[batch_count] = collision_data
      
      -- Process in batches to maintain frame rate
      if batch_count >= self.batch_size then
        if callback then
          callback({
            type = "batch",
            collisions = batch,
            count = batch_count
          })
        end
        
        -- Add to main collision list
        for i = 1, batch_count do
          table.insert(collisions, batch[i])
        end
        
        -- Reset batch
        batch = {}
        batch_count = 0
      end
    end
  end
  
  -- Process remaining collisions in final batch
  if batch_count > 0 then
    if callback then
      callback({
        type = "batch",
        collisions = batch,
        count = batch_count
      })
    end
    
    for i = 1, batch_count do
      table.insert(collisions, batch[i])
    end
  end
  
  return collisions
end

-- Continuous collision detection (hit.p8 integration pattern)
function CollisionResolver:detect_continuous_collisions(movement_data, filter_fn, callback)
  local obj = movement_data.object
  local start_x, start_y = movement_data.start_x, movement_data.start_y
  local end_x, end_y = movement_data.end_x, movement_data.end_y
  local w, h = movement_data.w, movement_data.h
  
  -- Calculate movement bounding box (locus.p8 pattern)
  local query_x = math.min(start_x, end_x)
  local query_y = math.min(start_y, end_y)
  local query_w = math.abs(end_x - start_x) + w
  local query_h = math.abs(end_y - start_y) + h
  
  local candidates = self.spatial:query_region(query_x, query_y, query_w, query_h, filter_fn)
  local collisions = {}
  local earliest_time = math.huge
  local earliest_collision = nil
  
  for candidate in pairs(candidates) do
    if candidate ~= obj then
      local cx, cy, cw, ch = self.spatial:get_bbox(candidate)
      local collision_time = self:calculate_collision_time(
        start_x, start_y, w, h,
        end_x, end_y,
        cx, cy, cw, ch
      )
      
      if collision_time and collision_time < earliest_time then
        earliest_time = collision_time
        earliest_collision = {
          object = candidate,
          time = collision_time,
          position = {
            x = start_x + (end_x - start_x) * collision_time,
            y = start_y + (end_y - start_y) * collision_time
          },
          type = "continuous"
        }
      end
    end
  end
  
  if earliest_collision then
    table.insert(collisions, earliest_collision)
    if callback then
      callback(earliest_collision)
    end
  end
  
  return collisions
end

-- Rectangle intersection (locus.p8 rectintersect pattern)
function CollisionResolver:rectangle_intersect(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 + w1 >= x2 and x2 + w2 >= x1 and y1 + h1 >= y2 and y2 + h2 >= y1
end

-- Calculate intersection rectangle for collision response
function CollisionResolver:calculate_intersection(x1, y1, w1, h1, x2, y2, w2, h2)
  local left = math.max(x1, x2)
  local top = math.max(y1, y2)
  local right = math.min(x1 + w1, x2 + w2)
  local bottom = math.min(y1 + h1, y2 + h2)
  
  return {
    x = left,
    y = top,
    w = right - left,
    h = bottom - top,
    area = (right - left) * (bottom - top)
  }
end

-- Continuous collision time calculation (simplified hit.p8 pattern)
function CollisionResolver:calculate_collision_time(x1, y1, w1, h1, x2, y2, cx, cy, cw, ch)
  -- This is a simplified version - full implementation would use proper swept AABB
  local dx = x2 - x1
  local dy = y2 - y1
  
  if dx == 0 and dy == 0 then return nil end
  
  -- Calculate time to collision (simplified for demonstration)
  local time_x = math.huge
  local time_y = math.huge
  
  if dx ~= 0 then
    local t1 = (cx - (x1 + w1)) / dx
    local t2 = ((cx + cw) - x1) / dx
    time_x = math.max(0, math.min(math.max(t1, t2), 1))
  end
  
  if dy ~= 0 then
    local t1 = (cy - (y1 + h1)) / dy
    local t2 = ((cy + ch) - y1) / dy
    time_y = math.max(0, math.min(math.max(t1, t2), 1))
  end
  
  local collision_time = math.max(time_x, time_y)
  return collision_time < 1 and collision_time or nil
end
```

---

## Survivor Game Optimization Patterns

### Entity Filter Functions for Performance

```lua
-- Optimized filter functions for survivor games
local SurvivorFilters = {}

-- Filter by entity type with caching for performance
function SurvivorFilters.create_type_filter(entity_type)
  return function(obj)
    return obj.type == entity_type
  end
end

-- Multi-type filter for complex queries (enemies, powerups, projectiles)
function SurvivorFilters.create_multi_type_filter(types)
  local type_lookup = {}
  for _, type_name in ipairs(types) do
    type_lookup[type_name] = true
  end
  
  return function(obj)
    return type_lookup[obj.type] ~= nil
  end
end

-- Distance-based filter for performance (only check nearby entities)
function SurvivorFilters.create_distance_filter(center_x, center_y, max_distance)
  local max_dist_sq = max_distance * max_distance
  
  return function(obj)
    local dx = obj.x - center_x
    local dy = obj.y - center_y
    return (dx * dx + dy * dy) <= max_dist_sq
  end
end

-- Composite filter combining multiple criteria
function SurvivorFilters.create_composite_filter(filters)
  return function(obj)
    for _, filter in ipairs(filters) do
      if not filter(obj) then
        return false
      end
    end
    return true
  end
end
```

### Usage Examples for Survivor Games

```lua
-- Player bullet collision with enemies (typical survivor game pattern)
function update_player_bullets(player_bullets, spatial)
  local resolver = CollisionResolver:new(spatial)
  local enemy_filter = SurvivorFilters.create_type_filter("enemy")
  
  for _, bullet in ipairs(player_bullets) do
    resolver:detect_collisions({
      x = bullet.x, y = bullet.y, w = bullet.w, h = bullet.h
    }, {
      type = "immediate",
      filter = enemy_filter,
      on_collision = function(collision)
        -- Handle bullet-enemy collision
        damage_enemy(collision.object, bullet.damage)
        mark_bullet_for_removal(bullet)
        spawn_hit_effect(collision.intersection.x, collision.intersection.y)
      end
    })
  end
end

-- Enemy swarm collision with player (optimized for hundreds of enemies)
function check_player_enemy_collisions(player, spatial)
  local resolver = CollisionResolver:new(spatial)
  local enemy_filter = SurvivorFilters.create_type_filter("enemy")
  
  -- Use survivor_swarm mode for high-performance batch processing
  local collisions = resolver:detect_collisions({
    x = player.x, y = player.y, w = player.w, h = player.h
  }, {
    type = "survivor_swarm",
    filter = enemy_filter,
    on_collision = function(batch_data)
      if batch_data.type == "batch" then
        -- Process entire batch of enemy collisions at once
        for _, collision in ipairs(batch_data.collisions) do
          apply_enemy_damage(player, collision.object)
        end
        
        -- Update UI once per batch for performance
        update_health_display(player.health)
        
        -- Apply screen shake based on collision count
        if batch_data.count > 5 then
          trigger_screen_shake(batch_data.count / 10)
        end
      end
    end
  })
  
  return #collisions
end

-- Pickup collection with distance optimization
function check_pickup_collection(player, spatial)
  local resolver = CollisionResolver:new(spatial)
  
  -- Combined filter: only pickups within collection range
  local pickup_filter = SurvivorFilters.create_composite_filter({
    SurvivorFilters.create_type_filter("pickup"),
    SurvivorFilters.create_distance_filter(player.x + player.w/2, player.y + player.h/2, 32)
  })
  
  resolver:detect_collisions({
    x = player.x - 16, y = player.y - 16, w = player.w + 32, h = player.h + 32
  }, {
    type = "immediate",
    filter = pickup_filter,
    on_collision = function(collision)
      collect_pickup(player, collision.object)
      spatial:remove_object(collision.object)
      spawn_pickup_effect(collision.object)
    end
  })
end
```

---

## Hit.p8 Port Specifications

### Core Features to Port

1. **Swept AABB collision detection** for continuous collision
2. **Multiple collision shape support** (rectangles, circles, polygons)
3. **Collision response calculations** (penetration depth, normal vectors)
4. **Integration with spatial partitioning** for performance optimization

### Picotron-Specific Optimizations

1. **Userdata integration** for high-performance collision data storage
2. **Token optimization** using closure-based APIs instead of OOP syntax
3. **Memory pooling** for collision result objects
4. **Frame-rate limiting** for collision batch processing

### Performance Optimization Features

1. **Batch Processing**: Handle multiple collisions in batches to maintain frame rate
2. **Filter Caching**: Reuse filter functions to avoid repeated allocations
3. **Early Termination**: Stop processing when frame time budget exceeded
4. **Spatial Culling**: Use distance filters to reduce collision candidates
5. **Callback-Based Architecture**: Avoid returning large collision arrays

---

## Integration with Locustron

### Two-Phase Collision Detection

```lua
-- Phase 1: Spatial partitioning (Locustron)
local candidates = locustron:query(player.x, player.y, player.w, player.h, enemy_filter)

-- Phase 2: Precise collision detection (This project)
local resolver = CollisionResolver:new(locustron)
local collisions = resolver:detect_collisions({
  x = player.x, y = player.y, w = player.w, h = player.h
}, {
  type = "immediate",
  filter = enemy_filter,
  on_collision = handle_collision
})
```

### Performance Benefits

- **Spatial Partitioning**: Reduces collision candidates by 90%+
- **Precise Detection**: Eliminates false positives from spatial queries
- **Optimal Performance**: Best of both worlds - fast broad phase + accurate narrow phase

---

## Testing Framework

### Performance Validation

```lua
-- Test collision detection performance with 200+ entities
describe("Collision Detection Performance", function()
  it("should handle survivor swarm collisions efficiently", function()
    local spatial = locustron({strategy = "fixed_grid"})
    local resolver = CollisionResolver:new(spatial)
    
    -- Set up player
    local player = {type = "player", x = 100, y = 100, w = 16, h = 16}
    spatial:add(player, player.x, player.y, player.w, player.h)
    
    -- Set up 200 enemies in tight cluster (survivor game scenario)
    local enemies = {}
    for i = 1, 200 do
      local enemy = {
        type = "enemy",
        x = 90 + (i % 20) * 2,  -- Tight 20x10 grid
        y = 90 + math.floor(i / 20) * 2,
        w = 4, h = 4,
        id = i
      }
      enemies[i] = enemy
      spatial:add(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
    end
    
    -- Test swarm collision detection
    local batch_count = 0
    local total_collisions = 0
    local start_time = time()  -- Picotron's high-resolution timer
    
    resolver:detect_collisions({
      x = player.x, y = player.y, w = player.w, h = player.h
    }, {
      type = "survivor_swarm",
      filter = function(obj) return obj.type == "enemy" end,
      on_collision = function(batch_data)
        if batch_data.type == "batch" then
          batch_count = batch_count + 1
          total_collisions = total_collisions + batch_data.count
        end
      end
    })
    
    local duration = time() - start_time
    
    -- Verify performance and correctness
    assert.truthy(total_collisions > 0)
    assert.truthy(batch_count > 0)
    assert.truthy(duration < 0.01)  -- Should complete in <10ms
    
    print(string.format("Processed %d collisions in %d batches in %.3fms", 
      total_collisions, batch_count, duration * 1000))
  end)
end)
```

---

## Future Development Roadmap

### Phase 1: Core Implementation (2 weeks)

- Basic rectangle intersection collision detection
- Callback-based architecture
- Integration with Locustron spatial partitioning

### Phase 2: Advanced Features (2 weeks)

- Continuous collision detection (hit.p8 swept AABB)
- Multiple collision shapes (circles, polygons)
- Collision response calculations

### Phase 3: Performance Optimization (1 week)

- Survivor game batch processing
- Memory pooling and userdata optimization
- Frame-rate limiting and early termination

### Phase 4: Documentation & Testing (1 week)

- Comprehensive test suite
- Performance benchmarks
- Integration examples and best practices

---

## Conclusion

This collision detection project would complement Locustron perfectly by providing the precise collision detection capabilities that spatial partitioning enables. By keeping the concerns separate, we maintain clean architecture while achieving optimal performance for demanding game scenarios like survivor games with hundreds of entities.

**Key Benefits:**

- **Separation of Concerns**: Spatial partitioning vs collision detection
- **Performance**: Optimized for 200+ entities at 60fps
- **Flexibility**: Callback-based architecture for any collision response
- **Battle-Tested Patterns**: Based on proven locus.p8 and hit.p8 designs
- **Picotron Optimized**: Userdata, token efficiency, memory pooling