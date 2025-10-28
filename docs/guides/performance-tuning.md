# Performance Tuning Guide

This guide provides comprehensive strategies for optimizing Locustron's spatial partitioning performance in your games.

## Understanding Performance Metrics

Before tuning, understand what to measure:

### Key Metrics

- **Query Time**: Time spent finding objects in regions
- **Update Time**: Time spent moving objects between cells
- **Memory Usage**: RAM consumed by spatial structures
- **False Positives**: Objects returned by queries that don't actually collide

### Profiling Setup

```lua
-- Simple profiling utility for Picotron
local profiler = {}

function profiler.start()
  profiler.start_time = time()  -- Picotron's high-resolution timer
  profiler.frames = 0
end

function profiler.update()
  profiler.frames = profiler.frames + 1
  if profiler.frames % 60 == 0 then  -- Every second at 60 FPS
    local elapsed = time() - profiler.start_time
    print(string.format("FPS: %.1f", 60 / elapsed))
    profiler.start_time = time()
  end
end

-- Usage in game loop
function _init()
  profiler.start()
end

function _update()
  -- Your game logic here
  profiler.update()
end
```

## Strategy Selection Optimization

### Quick Reference

| Scenario | Recommended Strategy | Cell Size | Expected Performance |
|----------|---------------------|-----------|---------------------|
| Platformer (bounded, uniform) | Fixed Grid | 32-64 | 95-99% query efficiency |
| Survival (clustered, dynamic) | Quadtree | 16-32 | 85-95% query efficiency |
| Space Game (large, sparse) | Hash Grid | 64-128 | 90-98% query efficiency |

### Benchmark Your Game

```lua
-- Run this in Picotron console to benchmark strategies
include("benchmarks/picotron/benchmark_grid_tuning.lua")

-- Or create custom benchmark
local benchmark = {}

function benchmark.spatial_performance(strategy_config, object_count)
  local loc = locustron(strategy_config)

  -- Create test objects
  local objects = {}
  for i = 1, object_count do
    local obj = {
      x = math.random(0, 1024),
      y = math.random(0, 1024),
      w = 16, h = 16
    }
    loc.add(obj, obj.x, obj.y, obj.w, obj.h)
    table.insert(objects, obj)
  end

  -- Benchmark queries
  local query_time = 0
  local queries = 100

  for i = 1, queries do
    local start = time()  -- Picotron's high-resolution timer
    local results = loc.query(
      math.random(0, 1024), math.random(0, 1024),
      64, 64
    )
    query_time = query_time + (time() - start)
  end

  return {
    avg_query_time = query_time / queries,
    objects_per_query = #objects / queries,
    strategy = strategy_config.strategy or "fixed_grid"
  }
end
```

## Cell Size Optimization

### Finding Optimal Cell Size

Cell size dramatically affects performance. Use this systematic approach:

```lua
function find_optimal_cell_size()
  local results = {}

  for cell_size = 8, 128, 8 do
    local config = {strategy = "fixed_grid", config = {cell_size = cell_size}}
    local perf = benchmark.spatial_performance(config, 500)

    table.insert(results, {
      cell_size = cell_size,
      query_time = perf.avg_query_time,
      efficiency = calculate_efficiency(perf)
    })
  end

  -- Find best balance
  table.sort(results, function(a, b) return a.efficiency > b.efficiency end)
  return results[1]
end

function calculate_efficiency(perf)
  -- Balance query speed with memory efficiency
  local speed_score = 1 / perf.avg_query_time
  local memory_score = 1 / perf.objects_per_query
  return (speed_score + memory_score) / 2
end
```

### Cell Size Guidelines

| Object Size | Recommended Cell Size | Rationale |
|-------------|----------------------|-----------|
| 8x8 pixels | 16-32 | Small objects need smaller cells for precision |
| 16x16 pixels | 32-64 | Standard game objects |
| 32x32 pixels | 64-128 | Large objects can use bigger cells |
| Mixed sizes | 32-48 | Compromise for varied object sizes |

## Memory Optimization

### Pool Management

Locustron automatically manages object pools, but you can monitor usage:

```lua
-- Monitor memory usage (Picotron specific)
function monitor_memory()
  -- Use Picotron's stat() function for memory info
  local memory_kb = stat(3)  -- Memory usage in KB
  local cpu_percent = stat(1) * 100  -- CPU usage percentage

  print(string.format(
    "CPU: %.1f%%, Memory: %dKB",
    cpu_percent, memory_kb
  ))

  return {
    cpu_percent = cpu_percent,
    memory_kb = memory_kb
  }
end
```

### Sparse Allocation Benefits

Different strategies handle memory differently:

- **Fixed Grid**: Allocates cells for entire grid (predictable memory)
- **Quadtree**: Only allocates nodes with objects (memory efficient)
- **Hash Grid**: Only allocates occupied cells (most memory efficient)

## Query Optimization

### Query Size Matters

```lua
-- Bad: Large queries
local visible = loc.query(0, 0, 1000, 1000)  -- Checks many cells

-- Good: Focused queries
local visible = loc.query(camera.x, camera.y, screen_width, screen_height)

-- Better: Slightly larger than viewport for buffer
local buffer = 32
local visible = loc.query(
  camera.x - buffer, camera.y - buffer,
  screen_width + buffer * 2, screen_height + buffer * 2
)
```

### Filter Functions

Use filters to reduce processing:

```lua
-- Without filter - check all objects
local enemies = loc.query(x, y, w, h)

-- With filter - only process enemies
local enemies = loc.query(x, y, w, h, function(obj)
  return obj.type == "enemy" and obj.health > 0
end)

-- Complex filter example
local nearby_threats = loc.query(x, y, w, h, function(obj)
  return obj.type == "enemy" and
         obj.aggressive and
         distance(obj.x, obj.y, player.x, player.y) < 100
end)
```

## Update Optimization

### Batch Updates

Group object updates to reduce overhead:

```lua
-- Bad: Update each object individually
for _, enemy in ipairs(enemies) do
  enemy.x = enemy.x + enemy.vx
  enemy.y = enemy.y + enemy.vy
  loc.update(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
end

-- Good: Batch position calculations, then update spatial structure
for _, enemy in ipairs(enemies) do
  enemy.x = enemy.x + enemy.vx
  enemy.y = enemy.y + enemy.vy
end

for _, enemy in ipairs(enemies) do
  loc.update(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
end
```

### Movement Prediction

For fast-moving objects, predict movement to reduce cell crossings:

```lua
function update_fast_moving_object(loc, obj, dt)
  local old_cell_x = math.floor(obj.x / loc.cell_size)
  local old_cell_y = math.floor(obj.y / loc.cell_size)

  -- Calculate new position
  obj.x = obj.x + obj.vx * dt
  obj.y = obj.y + obj.vy * dt

  local new_cell_x = math.floor(obj.x / loc.cell_size)
  local new_cell_y = math.floor(obj.y / loc.cell_size)

  -- Only update spatial structure if cell changed
  if old_cell_x ~= new_cell_x or old_cell_y ~= new_cell_y then
    loc.update(obj, obj.x, obj.y, obj.w, obj.h)
  end
end
```

## Collision Detection Optimization

### Broad Phase + Narrow Phase

Always combine spatial queries with precise collision detection:

```lua
function optimized_collision_detection(player, loc)
  -- Broad phase: spatial query
  local candidates = loc.query(
    player.x - player.w, player.y - player.h,
    player.w * 3, player.h * 3
  )

  -- Narrow phase: precise collision
  local collisions = {}
  for obj in pairs(candidates) do
    if obj ~= player and precise_collision(player, obj) then
      table.insert(collisions, obj)
    end
  end

  return collisions
end

function precise_collision(a, b)
  -- Use more expensive collision detection only for candidates
  return pixel_perfect_collision(a, b)  -- Or SAT, GJK, etc.
end
```

### Collision Matrix

Different collision types have different performance characteristics:

| Collision Type | Performance | Use Case |
|----------------|-------------|----------|
| AABB | Fastest | Simple games, prototypes |
| Circle | Fast | Top-down games, particles |
| Pixel Perfect | Slowest | Precise collision needed |

## Rendering Optimization

### Viewport Culling

Only render visible objects:

```lua
function render_scene(camera, loc)
  -- Query only visible area
  local visible = loc.query(
    camera.x, camera.y,
    camera.width, camera.height
  )

  -- Add small buffer for smooth scrolling
  local buffer = 16
  visible = loc.query(
    camera.x - buffer, camera.y - buffer,
    camera.width + buffer * 2, camera.height + buffer * 2
  )

  -- Render visible objects
  for obj in pairs(visible) do
    if should_render(obj, camera) then
      draw_object(obj)
    end
  end
end

function should_render(obj, camera)
  -- Additional culling logic (frustum, occlusion, etc.)
  return obj.visible and distance(obj, camera) < camera.far_plane
end
```

### LOD (Level of Detail)

Use distance-based detail reduction:

```lua
function render_with_lod(obj, camera)
  local dist = distance(obj.x, obj.y, camera.x, camera.y)

  if dist < 50 then
    -- High detail
    draw_detailed_sprite(obj)
  elseif dist < 150 then
    -- Medium detail
    draw_simple_sprite(obj)
  else
    -- Low detail or cull
    draw_distant_sprite(obj)
  end
end
```

## Advanced Techniques

### Spatial Partitioning for AI

Use spatial queries for efficient AI calculations:

```lua
function find_nearest_enemy(player, loc, max_distance)
  local nearby = loc.query(
    player.x - max_distance, player.y - max_distance,
    max_distance * 2, max_distance * 2,
    function(obj) return obj.type == "enemy" end
  )

  local nearest = nil
  local min_dist = max_distance

  for enemy in pairs(nearby) do
    local dist = distance(player.x, player.y, enemy.x, enemy.y)
    if dist < min_dist then
      min_dist = dist
      nearest = enemy
    end
  end

  return nearest
end
```

### Dynamic Strategy Switching

Change strategies based on game state:

```lua
local strategies = {
  exploration = {strategy = "hash_grid", config = {cell_size = 64}},
  combat = {strategy = "quadtree", config = {max_objects = 8, max_depth = 6}},
  menu = {strategy = "fixed_grid", config = {cell_size = 32}}
}

function switch_strategy(game_state)
  local config = strategies[game_state]
  if config then
    -- Migrate objects to new strategy
    local old_loc = current_loc
    current_loc = locustron(config)

    -- Re-add all objects (could be optimized)
    for obj in pairs(old_loc._objects or {}) do
      current_loc.add(obj, obj.x, obj.y, obj.w, obj.h)
    end
  end
end
```

## Performance Monitoring

### Real-time Metrics

```lua
local performance_monitor = {
  query_times = {},
  update_times = {},
  frame_count = 0
}

function performance_monitor.update()
  self.frame_count = self.frame_count + 1

  if self.frame_count % 60 == 0 then  -- Every second
    self:report_metrics()
    self:reset()
  end
end

function performance_monitor.record_query_time(time)
  table.insert(self.query_times, time)
end

function performance_monitor.record_update_time(time)
  table.insert(self.update_times, time)
end

function performance_monitor.report_metrics()
  local avg_query = average(self.query_times)
  local avg_update = average(self.update_times)

  print(string.format(
    "Avg Query: %.3fms, Avg Update: %.3fms, Memory: %dKB",
    avg_query * 1000, avg_update * 1000,
    stat(3)  -- Picotron memory usage in KB
  ))
end

function performance_monitor.reset()
  self.query_times = {}
  self.update_times = {}
end

function average(t)
  if #t == 0 then return 0 end
  local sum = 0
  for _, v in ipairs(t) do sum = sum + v end
  return sum / #t
end
```

## Common Performance Issues

### Problem: Slow Queries

**Symptoms**: Game stutters during area queries

**Solutions**:

- Reduce query region size
- Use filters to limit results
- Consider larger cell sizes
- Switch to more appropriate strategy

### Problem: High Memory Usage

**Symptoms**: Game runs out of memory with many objects

**Solutions**:

- Use Hash Grid for sparse worlds
- Increase cell sizes
- Implement object pooling
- Remove unused objects promptly

### Problem: Poor Update Performance

**Symptoms**: Game slows down with moving objects

**Solutions**:

- Batch updates
- Only update when objects cross cell boundaries
- Use simpler collision shapes
- Profile and optimize movement calculations

### Problem: Too Many False Positives

**Symptoms**: Collision detection checks many non-colliding objects

**Solutions**:

- Adjust cell/query sizes
- Use more precise broad-phase shapes
- Implement better narrow-phase filtering

## Profiling Tools

### Built-in Benchmarks

Locustron includes several benchmarking tools:

```lua
-- Grid size tuning benchmark
include("benchmarks/picotron/benchmark_grid_tuning.lua")

-- Performance comparison
include("benchmarks/benchmark_suite.lua")

-- Memory usage analysis
include("benchmarks/picotron/benchmark_userdata_performance.lua")
```

### Custom Profiling

```lua
local profiler = {}

function profiler.time_function(fn, ...)
  local start = time()  -- Picotron's high-resolution timer
  local results = {fn(...)}
  local elapsed = time() - start
  return elapsed, unpack(results)
end

-- Usage
local query_time, results = profiler.time_function(
  loc.query, loc, x, y, w, h
)

if query_time > 0.016 then  -- Over 16ms (60 FPS)
  print("Slow query detected: " .. query_time .. "s")
end
```

## Strategy-Specific Tuning

### Fixed Grid Tuning

```lua
-- Best for uniform distributions
local config = {
  strategy = "fixed_grid",
  config = {
    cell_size = 32,  -- Match object size
    world_width = 1024,  -- Pre-allocate if known
    world_height = 1024
  }
}
```

### Quadtree Tuning

```lua
-- Best for clustered objects
local config = {
  strategy = "quadtree",
  config = {
    max_objects = 8,    -- Objects per node before split
    max_depth = 6,      -- Maximum tree depth
    looseness = 1.25    -- Node size multiplier
  }
}
```

### Hash Grid Tuning

```lua
-- Best for large/sparse worlds
local config = {
  strategy = "hash_grid",
  config = {
    cell_size = 64,     -- Larger for sparse worlds
    initial_capacity = 1000  -- Pre-allocate hash table
  }
}
```

## Final Optimization Checklist

- [ ] Profile your specific use case
- [ ] Choose appropriate strategy for your game
- [ ] Tune cell/query sizes for optimal performance
- [ ] Implement efficient update patterns
- [ ] Use filters to reduce processing
- [ ] Monitor memory usage
- [ ] Batch operations where possible
- [ ] Test on target hardware

Remember: **Always measure performance** - what works for one game may not work for another. Use the benchmarks and profiling tools to guide your optimization decisions.
