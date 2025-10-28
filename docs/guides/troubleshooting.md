# Troubleshooting Guide

This guide helps you diagnose and resolve common issues when using Locustron in your games.

## Common Error Messages

### "unknown object"

**Symptoms**: Error when trying to update or remove an object

**Causes**:

- Object was never added to the spatial structure
- Object was already removed
- Object reference changed (table was recreated)

**Solutions**:

```lua
-- Check if object exists before operations
if loc:get_bbox(obj) then
  loc.update(obj, new_x, new_y, w, h)
else
  print("Object not found in spatial structure")
  -- Re-add the object
  loc.add(obj, new_x, new_y, w, h)
end

-- Always add objects before using them
local enemy = create_enemy()
loc.add(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
```

### "Strategy not found"

**Symptoms**: Error when creating a spatial structure with an invalid strategy

**Causes**:

- Typo in strategy name
- Strategy not yet implemented
- Using old API format

**Solutions**:

```lua
-- Check available strategies
local available_strategies = {"fixed_grid", "quadtree", "hash_grid"}

-- Use correct strategy names
local loc = locustron({
  strategy = "fixed_grid",  -- ✅ Correct
  config = {cell_size = 32}
})

-- Not this (old API)
-- local loc = locustron("fixed_grid")  -- ❌ Old format
```

### "Config validation failed"

**Symptoms**: Error when strategy configuration is invalid

**Causes**:

- Invalid configuration parameters
- Missing required config fields
- Wrong data types

**Solutions**:

```lua
-- Check strategy-specific requirements
local strategy_configs = {
  fixed_grid = {
    required = {"cell_size"},
    optional = {"world_width", "world_height"}
  },
  quadtree = {
    required = {"max_objects", "max_depth"},
    optional = {"looseness"}
  },
  hash_grid = {
    required = {"cell_size"},
    optional = {"initial_capacity"}
  }
}

-- Validate config before creating
function validate_config(strategy, config)
  local requirements = strategy_configs[strategy]
  if not requirements then
    error("Unknown strategy: " .. strategy)
  end

  for _, field in ipairs(requirements.required) do
    if config[field] == nil then
      error("Missing required config field: " .. field)
    end
  end
end

-- Usage
local config = {cell_size = 32, max_objects = 8}
validate_config("quadtree", config)
local loc = locustron({strategy = "quadtree", config = config})
```

## Performance Issues

### Slow Queries

**Symptoms**: Game stutters when querying large areas

**Debug Steps**:

```lua
-- Add timing to queries
local start_time = time()  -- Picotron's high-resolution timer
local results = loc.query(x, y, w, h)
local query_time = time() - start_time

if query_time > 0.016 then  -- Over 16ms (60 FPS)
  print(string.format("Slow query: %.3fms for %d objects",
    query_time * 1000, #results))

  -- Debug query region
  print(string.format("Query region: (%d,%d) %dx%d", x, y, w, h))
end
```

**Common Causes & Solutions**:

1. **Large Query Regions**

   ```lua
   -- Bad: Query entire world
   local all = loc.query(0, 0, 10000, 10000)

   -- Good: Query only needed area
   local nearby = loc.query(camera.x, camera.y, screen_w, screen_h)
   ```

2. **Small Cell Sizes**

   ```lua
   -- Too many cells to check
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 8}})

   -- Better: Larger cells
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 32}})
   ```

3. **Wrong Strategy for Use Case**

   ```lua
   -- Using Fixed Grid for sparse world
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 32}})

   -- Better: Hash Grid for sparse worlds
   local loc = locustron({strategy = "hash_grid", config = {cell_size = 64}})
   ```

### High Memory Usage

**Symptoms**: Game runs out of memory or slows down

**Debug Steps**:

```lua
-- Monitor memory usage
function debug_memory()
  local memory_kb = stat(3)  -- Picotron memory usage in KB
  local cpu_percent = stat(1) * 100  -- CPU usage percentage

  print(string.format("Memory: %dKB, CPU: %.1f%%", memory_kb, cpu_percent))

  -- Locustron-specific stats (if available)
  if loc._pool then
    print(string.format("Pool size: %d", loc._pool()))
  end
  if loc._obj_count then
    print(string.format("Object count: %d", loc._obj_count()))
  end
end
```

**Common Causes & Solutions**:

1. **Fixed Grid in Large Worlds**

   ```lua
   -- Allocates cells for entire grid
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 32}})

   -- Better for large worlds
   local loc = locustron({strategy = "hash_grid", config = {cell_size = 64}})
   ```

2. **Not Removing Objects**

   ```lua
   -- Objects stay in memory forever
   local bullet = create_bullet()
   loc.add(bullet, bullet.x, bullet.y, bullet.w, bullet.h)

   -- When bullet hits something or goes off-screen
   loc.remove(bullet)  -- Don't forget this!
   bullet = nil  -- Allow garbage collection
   ```

3. **Too Many Objects**

   ```lua
   -- Check object limits
   if object_count > 10000 then
    print("Warning: Approaching object limit")
    -- Consider object pooling or culling
   end
   ```### Poor Update Performance

**Symptoms**: Game slows down when many objects move

**Debug Steps**:

```lua
-- Profile updates
local update_times = {}
local update_count = 0

function profile_update(obj, x, y, w, h)
  local start = time()  -- Picotron's high-resolution timer
  loc.update(obj, x, y, w, h)
  local elapsed = time() - start

  update_count = update_count + 1
  table.insert(update_times, elapsed)

  if update_count % 100 == 0 then
    local avg_time = average(update_times)
    print(string.format("Avg update time: %.6fms", avg_time * 1000))
    update_times = {}
  end
end
```

**Common Causes & Solutions**:

1. **Updating Every Frame**

   ```lua
   -- Bad: Update even when not moving
   function _update()
     for _, obj in ipairs(objects) do
       loc.update(obj, obj.x, obj.y, obj.w, obj.h)
     end
   end

   -- Good: Only update when position changes
   function _update()
     for _, obj in ipairs(objects) do
       if obj.x ~= obj.prev_x or obj.y ~= obj.prev_y then
         loc.update(obj, obj.x, obj.y, obj.w, obj.h)
         obj.prev_x, obj.prev_y = obj.x, obj.y
       end
     end
   end
   ```

2. **Crossing Cell Boundaries Frequently**

   ```lua
   -- Small cells + fast movement = frequent updates
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 16}})
   local fast_obj = {x = 0, y = 0, vx = 10, vy = 10}  -- Moves 10 pixels/frame

   -- Solution: Larger cells or slower movement
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 64}})
   ```

## Collision Detection Issues

### Too Many False Positives

**Symptoms**: Collision detection is slow due to checking many non-colliding objects

**Debug Steps**:

```lua
function debug_collision_candidates(player, loc)
  local candidates = loc.query(
    player.x - player.w, player.y - player.h,
    player.w * 3, player.h * 3
  )

  local actual_collisions = 0
  local total_candidates = 0

  for obj in pairs(candidates) do
    total_candidates = total_candidates + 1
    if obj ~= player and collides(player, obj) then
      actual_collisions = actual_collisions + 1
    end
  end

  local efficiency = actual_collisions / total_candidates
  print(string.format("Collision efficiency: %.1f%% (%d/%d)",
    efficiency * 100, actual_collisions, total_candidates))
end
```

**Common Causes & Solutions**:

1. **Wrong Cell Size**

   ```lua
   -- Cells too large: too many objects per cell
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 128}})

   -- Better: Match cell size to object size
   local loc = locustron({strategy = "fixed_grid", config = {cell_size = 32}})
   ```

2. **No Narrow-Phase Collision**

   ```lua
   -- Bad: Assume all candidates collide
   local nearby = loc.query(x, y, w, h)
   for obj in pairs(nearby) do
     handle_collision(obj)  -- Wrong!
   end

   -- Good: Check precise collision
   local nearby = loc.query(x, y, w, h)
   for obj in pairs(nearby) do
     if precise_collision(player, obj) then
       handle_collision(obj)
     end
   end
   ```

### Missing Collisions

**Symptoms**: Objects pass through each other

**Debug Steps**:

```lua
function debug_collision(obj1, obj2)
  -- Check bounding boxes
  local bbox1 = {loc:get_bbox(obj1)}
  local bbox2 = {loc:get_bbox(obj2)}

  print(string.format("Obj1 bbox: (%d,%d) %dx%d",
    bbox1[1], bbox1[2], bbox1[3], bbox1[4]))
  print(string.format("Obj2 bbox: (%d,%d) %dx%d",
    bbox2[1], bbox2[2], bbox2[3], bbox2[4]))

  -- Check if they should collide
  if rects_intersect(bbox1, bbox2) then
    print("Bounding boxes intersect - collision expected")
  else
    print("Bounding boxes don't intersect - no collision expected")
  end
end
```

**Common Causes & Solutions**:

1. **Not Updating Positions**

   ```lua
   -- Move object but forget to update spatial structure
   player.x = player.x + player.vx
   player.y = player.y + player.vy
   -- Missing: loc.update(player, player.x, player.y, player.w, player.h)
   ```

2. **Wrong Query Region**

   ```lua
   -- Query too small for movement
   local nearby = loc.query(player.x, player.y, player.w, player.h)

   -- Better: Include movement
   local nearby = loc.query(
     player.x - player.vx, player.y - player.vy,
     player.w + math.abs(player.vx), player.h + math.abs(player.vy)
   )
   ```

## Strategy-Specific Issues

### Fixed Grid Problems

**Issue**: Poor performance in sparse worlds

```lua
-- Symptoms: High memory usage, slow queries
local loc = locustron({strategy = "fixed_grid", config = {cell_size = 32}})

-- Solution: Use Hash Grid for sparse worlds
local loc = locustron({strategy = "hash_grid", config = {cell_size = 64}})
```

**Issue**: Too many objects per cell

```lua
-- Debug: Check cell occupancy
function debug_cell_occupancy(loc)
  local cells = loc._cells or {}
  local total_objects = 0
  local occupied_cells = 0

  for cell_key, cell_objects in pairs(cells) do
    occupied_cells = occupied_cells + 1
    total_objects = total_objects + #cell_objects
  end

  local avg_objects_per_cell = total_objects / occupied_cells
  print(string.format("Avg objects/cell: %.1f", avg_objects_per_cell))

  if avg_objects_per_cell > 10 then
    print("Warning: Consider larger cell size")
  end
end
```

### Quadtree Problems

**Issue**: Poor performance with uniform distributions

```lua
-- Quadtree overkill for uniform object placement
local loc = locustron({
  strategy = "quadtree",
  config = {max_objects = 8, max_depth = 6}
})

-- Solution: Use Fixed Grid for uniform distributions
local loc = locustron({strategy = "fixed_grid", config = {cell_size = 32}})
```

**Issue**: Excessive tree depth

```lua
-- Debug tree depth
function debug_tree_depth(node, depth)
  depth = depth or 0
  if depth > 10 then
    print("Warning: Very deep tree (depth " .. depth .. ")")
  end

  if node.children then
    for _, child in ipairs(node.children) do
      debug_tree_depth(child, depth + 1)
    end
  end
end
```

### Hash Grid Problems

**Issue**: Poor hash function performance

```lua
-- Hash collisions reduce performance
function debug_hash_collisions(loc)
  local hash_table = loc._hash_table or {}
  local collisions = 0
  local total_entries = 0

  for hash_key, bucket in pairs(hash_table) do
    total_entries = total_entries + 1
    if #bucket > 1 then
      collisions = collisions + (#bucket - 1)
    end
  end

  print(string.format("Hash collisions: %d/%d", collisions, total_entries))
end
```

## Debugging Tools

### Visual Debugging

```lua
-- Draw spatial grid overlay
function draw_debug_overlay(loc, camera)
  cls(0)

  -- Draw grid cells
  if loc.strategy == "fixed_grid" then
    local cell_size = loc.cell_size
    for x = 0, screen_width, cell_size do
      for y = 0, screen_height, cell_size do
        rect(x - camera.x, y - camera.y, cell_size, cell_size, 1)
      end
    end
  end

  -- Draw objects
  for obj in pairs(loc._objects or {}) do
    local x, y, w, h = loc:get_bbox(obj)
    rect(x - camera.x, y - camera.y, w, h, 7)
  end

  -- Draw query regions
  if debug_query then
    rect(debug_query.x - camera.x, debug_query.y - camera.y,
         debug_query.w, debug_query.h, 8)
  end
end
```

### Performance Profiling

```lua
local profiler = {
  queries = {},
  updates = {},
  frame_time = 0
}

function profiler.start_query()
  profiler.query_start = time()  -- Picotron's high-resolution timer
end

function profiler.end_query(result_count)
  local elapsed = time() - profiler.query_start
  table.insert(profiler.queries, {
    time = elapsed,
    results = result_count
  })
end

function profiler.start_update()
  profiler.update_start = time()  -- Picotron's high-resolution timer
end

function profiler.end_update()
  local elapsed = time() - profiler.update_start
  table.insert(profiler.updates, elapsed)
end

function profiler.report()
  if #profiler.queries > 0 then
    local avg_query = average(profiler.queries, "time")
    local avg_results = average(profiler.queries, "results")
    print(string.format("Avg query: %.3fms (%d results)",
      avg_query * 1000, avg_results))
  end

  if #profiler.updates > 0 then
    local avg_update = average(profiler.updates)
    print(string.format("Avg update: %.3fms", avg_update * 1000))
  end

  -- Reset for next frame
  profiler.queries = {}
  profiler.updates = {}
end

function average(data, field)
  if #data == 0 then return 0 end
  local sum = 0
  for _, item in ipairs(data) do
    sum = sum + (field and item[field] or item)
  end
  return sum / #data
end
```

### Memory Leak Detection

```lua
local memory_tracker = {
  snapshots = {},
  object_counts = {}
}

function memory_tracker.take_snapshot(label)
  local snapshot = {
    label = label,
    time = time(),  -- Picotron's high-resolution timer
    memory = stat(3),  -- Memory usage in KB
    objects = loc._obj_count and loc._obj_count() or 0
  }

  table.insert(memory_tracker.snapshots, snapshot)
  print(string.format("%s: %dKB, %d objects",
    label, snapshot.memory, snapshot.objects))
end

function memory_tracker.check_leaks()
  if #memory_tracker.snapshots < 2 then return end

  local first = memory_tracker.snapshots[1]
  local last = memory_tracker.snapshots[#memory_tracker.snapshots]

  local memory_diff = last.memory - first.memory
  local object_diff = last.objects - first.objects

  if memory_diff > 1000 then  -- 1000KB (1MB) increase
    print(string.format("Warning: Memory leak detected (+%dKB)",
      memory_diff))
  end

  if object_diff > 0 then
    print(string.format("Warning: Object leak detected (+%d objects)",
      object_diff))
  end
end
```

## Getting Help

### When to Ask for Help

- Error messages you can't resolve
- Performance issues that persist after tuning
- Unexpected behavior not covered here
- Strategy selection confusion

### Information to Provide

When asking for help, include:

1. **Error Messages**: Full error text and stack trace
2. **Code Sample**: Minimal code that reproduces the issue
3. **Environment**: Picotron version, cartridge size, object counts
4. **Expected vs Actual**: What you expected vs what happened
5. **Performance Data**: FPS, memory usage, profiler output

### Quick Fixes

Try these first before asking for help:

1. **Restart Picotron**: Clears any corrupted state
2. **Check Object References**: Ensure objects aren't being recreated
3. **Validate Coordinates**: Check for NaN or infinite values
4. **Test with Simple Case**: Reduce complexity to isolate issues
5. **Check Benchmarks**: Run included benchmarks to verify performance

Remember: Most issues have simple solutions once you know where to look. Use the debugging tools and methodical approach to identify and resolve problems.
