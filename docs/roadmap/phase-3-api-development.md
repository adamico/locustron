# Phase 3: Main Locustron Game Engine API Development (2 weeks)

## Overview

Phase 3 develops the main Locustron game engine API that provides a clean, unified interface for spatial partitioning operations. Building on the strategy pattern foundation from Phase 1 and benchmarking tools from Phase 2, this phase creates the primary developer-facing API that integrates all spatial strategies into a cohesive game engine component.

---

## Phase 3.1: Core API Design and Implementation (1 week)

### Objectives

- Design unified spatial partitioning API for game development
- Implement strategy factory and configuration system
- Create object lifecycle management (add/update/remove)
- Develop query interfaces for collision detection and culling
- Integrate with existing Picotron runtime environment

### Key Features

- **Strategy Factory**: Clean creation and configuration of spatial strategies
- **Object Management**: Unified add/update/remove operations across strategies
- **Query Operations**: Efficient spatial queries with optional filtering
- **Memory Management**: Automatic object pooling and cleanup
- **Error Handling**: Robust error handling with meaningful messages

### Core API Implementation

```lua
--- @class Locustron
--- Main spatial partitioning API for game development
--- @field private _strategy SpatialStrategy The active spatial strategy
--- @field private _pool table Object pool for memory management
--- @field private _obj_count number Current object count
local Locustron = {}
Locustron.__index = Locustron

--- Create a new Locustron spatial partitioning instance
--- @param config table|string Configuration object or strategy name
--- @return Locustron New spatial partitioning instance
function Locustron.create(config)
  local self = setmetatable({}, Locustron)

  -- Handle legacy string parameter (backward compatibility)
  if type(config) == "number" then
    config = {
      strategy = "fixed_grid",
      config = {cell_size = config}
    }
  elseif type(config) == "string" then
    config = {strategy = config}
  end

  -- Default configuration
  config = config or {}
  config.strategy = config.strategy or "fixed_grid"
  config.config = config.config or {}

  -- Create strategy instance
  self._strategy = Locustron._create_strategy(config.strategy, config.config)

  -- Initialize memory management
  self._pool = {}  -- Object pool for reuse
  self._obj_count = 0

  return self
end

--- Add an object to the spatial partitioning system
--- @param obj any The object to add
--- @param x number Object x-coordinate
--- @param y number Object y-coordinate
--- @param w number Object width
--- @param h number Object height
--- @return any The added object
function Locustron:add(obj, x, y, w, h)
  if not obj then
    error("cannot add nil object")
  end

  if self._strategy:contains(obj) then
    error("object already exists in spatial partitioning")
  end

  -- Add to strategy
  self._strategy:add_object(obj, x, y, w, h)
  self._obj_count = self._obj_count + 1

  return obj
end

--- Update an object's position and/or size in the spatial system
--- @param obj any The object to update
--- @param x number New x-coordinate
--- @param y number New y-coordinate
--- @param w number New width (optional)
--- @param h number New height (optional)
--- @return any The updated object
function Locustron:update(obj, x, y, w, h)
  if not obj then
    error("cannot update nil object")
  end

  if not self._strategy:contains(obj) then
    error("object not found in spatial partitioning")
  end

  -- Get current bounding box if dimensions not provided
  if not w or not h then
    local cx, cy, cw, ch = self._strategy:get_bbox(obj)
    w = w or cw
    h = h or ch
  end

  -- Update in strategy
  self._strategy:update_object(obj, x, y, w, h)

  return obj
end

--- Remove an object from the spatial partitioning system
--- @param obj any The object to remove
--- @return any The removed object
function Locustron:remove(obj)
  if not obj then
    error("cannot remove nil object")
  end

  if not self._strategy:contains(obj) then
    error("object not found in spatial partitioning")
  end

  -- Remove from strategy
  self._strategy:remove_object(obj)
  self._obj_count = self._obj_count - 1

  -- Return to pool for reuse
  self:_pool_object(obj)

  return obj
end

--- Query objects within a rectangular region
--- @param x number Query region x-coordinate
--- @param y number Query region y-coordinate
--- @param w number Query region width
--- @param h number Query region height
--- @param filter_fn function Optional filter function
--- @return table Hash table of objects {obj = true}
function Locustron:query(x, y, w, h, filter_fn)
  if not x or not y or not w or not h then
    error("query requires x, y, w, h parameters")
  end

  -- Validate parameters
  if w <= 0 or h <= 0 then
    error("query region must have positive width and height")
  end

  -- Query strategy
  local results = self._strategy:query_region(x, y, w, h, filter_fn)

  return results
end

--- Get the bounding box of an object
--- @param obj any The object
--- @return number, number, number, number x, y, w, h
function Locustron:get_bbox(obj)
  if not obj then
    error("cannot get bbox of nil object")
  end

  if not self._strategy:contains(obj) then
    error("object not found in spatial partitioning")
  end

  return self._strategy:get_bbox(obj)
end

--- Clear all objects from the spatial partitioning system
function Locustron:clear()
  self._strategy:clear()
  self._obj_count = 0
  self._pool = {}
end

--- Get current object count
--- @return number Number of objects in the system
function Locustron:count()
  return self._obj_count
end

--- Get strategy information
--- @return table Strategy metadata
function Locustron:get_strategy_info()
  return {
    name = self._strategy.strategy_name,
    description = self._strategy.strategy_description,
    object_count = self._obj_count,
    statistics = self._strategy:get_statistics and self._strategy:get_statistics() or {}
  }
end
```

### Strategy Factory Implementation

```lua
--- @class StrategyFactory
--- Factory for creating spatial partitioning strategies
local StrategyFactory = {}

--- Create a strategy instance by name
--- @param strategy_name string Name of the strategy
--- @param config table Strategy configuration
--- @return SpatialStrategy The strategy instance
function Locustron._create_strategy(strategy_name, config)
  config = config or {}

  if strategy_name == "fixed_grid" then
    return FixedGridStrategy.new(config)
  elseif strategy_name == "quadtree" then
    return QuadtreeStrategy.new(config)
  elseif strategy_name == "hash_grid" then
    return HashGridStrategy.new(config)
  elseif strategy_name == "bsp_tree" then
    return BSPTreeStrategy.new(config)
  elseif strategy_name == "bvh" then
    return BVHStrategy.new(config)
  else
    error("unknown strategy: " .. tostring(strategy_name))
  end
end

--- Get list of available strategies
--- @return table List of strategy names
function Locustron.get_available_strategies()
  return {
    "fixed_grid",
    "quadtree",
    "hash_grid",
    "bsp_tree",
    "bvh"
  }
end

--- Get strategy metadata
--- @param strategy_name string Name of the strategy
--- @return table Strategy metadata or nil if not found
function Locustron.get_strategy_metadata(strategy_name)
  local metadata = {
    fixed_grid = {
      name = "Fixed Grid",
      description = "Simple grid-based spatial partitioning",
      optimal_for = {"uniform_distribution", "bounded_worlds", "simple_queries"},
      memory_usage = "low",
      performance = "excellent_uniform",
      supports_unbounded = false
    },
    quadtree = {
      name = "Quadtree",
      description = "Hierarchical spatial partitioning with adaptive subdivision",
      optimal_for = {"clustered_objects", "bounded_worlds", "hierarchical_queries"},
      memory_usage = "adaptive",
      performance = "good_clustered",
      supports_unbounded = false
    },
    hash_grid = {
      name = "Hash Grid",
      description = "Hash-based spatial grid for unbounded worlds",
      optimal_for = {"sparse_distribution", "infinite_worlds", "negative_coordinates"},
      memory_usage = "very_sparse",
      performance = "excellent_sparse",
      supports_unbounded = true
    },
    bsp_tree = {
      name = "BSP Tree",
      description = "Binary space partitioning for geometric operations",
      optimal_for = {"ray_casting", "line_intersection", "geometric_queries"},
      memory_usage = "moderate",
      performance = "excellent_geometric",
      supports_unbounded = false
    },
    bvh = {
      name = "Bounding Volume Hierarchy",
      description = "Hierarchical bounding volumes for complex shapes",
      optimal_for = {"mixed_sizes", "nearest_neighbor", "dynamic_objects"},
      memory_usage = "moderate",
      performance = "good_dynamic",
      supports_unbounded = true
    }
  }

  return metadata[strategy_name]
end
```

### Memory Management and Object Pooling

```lua
--- @class ObjectPool
--- Memory-efficient object pooling for spatial partitioning
local ObjectPool = {}

function ObjectPool.new()
  local self = setmetatable({}, {__index = ObjectPool})

  self.pool = {}  -- Available objects
  self.active = {}  -- Active object tracking
  self.max_pool_size = 1000

  return self
end

function ObjectPool:acquire()
  local obj = table.remove(self.pool)
  if not obj then
    obj = {}  -- Create new object
  end

  self.active[obj] = true
  return obj
end

function ObjectPool:release(obj)
  if not obj then return end

  -- Clear object state
  for k in pairs(obj) do
    obj[k] = nil
  end

  self.active[obj] = nil

  -- Return to pool if not full
  if #self.pool < self.max_pool_size then
    table.insert(self.pool, obj)
  end
end

function ObjectPool:get_stats()
  return {
    pooled = #self.pool,
    active = self:count_active(),
    total_created = #self.pool + self:count_active()
  }
end

function ObjectPool:count_active()
  local count = 0
  for _ in pairs(self.active) do
    count = count + 1
  end
  return count
end

-- Integrate with Locustron
function Locustron:_pool_object(obj)
  if not self._pool then
    self._pool = ObjectPool.new()
  end

  self._pool:release(obj)
end

function Locustron:get_memory_stats()
  local pool_stats = self._pool and self._pool:get_stats() or {pooled = 0, active = 0, total_created = 0}

  return {
    objects_active = self._obj_count,
    pool_available = pool_stats.pooled,
    pool_active = pool_stats.active,
    total_memory_objects = pool_stats.total_created,
    strategy_memory = self._strategy:get_memory_usage and self._strategy:get_memory_usage() or 0
  }
end
```

---

## Phase 3.2: Game Engine Integration Patterns (1 week)

### Integration Objectives

- Create integration patterns for common game engine scenarios
- Implement collision detection helpers
- Develop viewport culling utilities
- Build performance monitoring and optimization tools
- Provide migration guides from legacy APIs

### Collision Detection Integration

```lua
--- @class CollisionSystem
--- Collision detection integration with spatial partitioning
local CollisionSystem = {}

function CollisionSystem.new(locustron_instance)
  local self = setmetatable({}, CollisionSystem)

  self.spatial = locustron_instance
  self.collision_checks = 0
  self.broad_phase_candidates = 0
  self.narrow_phase_collisions = 0

  return self
end

function CollisionSystem:check_collisions(entity, filter_fn)
  local x, y, w, h = self.spatial:get_bbox(entity)

  -- Broad phase: get potential collision candidates
  local candidates = self.spatial:query(x, y, w, h, filter_fn)
  self.broad_phase_candidates = self.broad_phase_candidates + self:count_table(candidates)

  -- Narrow phase: check actual collisions
  local collisions = {}
  for candidate in pairs(candidates) do
    if candidate ~= entity then
      self.collision_checks = self.collision_checks + 1

      if self:rectangles_collide(entity, candidate) then
        table.insert(collisions, candidate)
        self.narrow_phase_collisions = self.narrow_phase_collisions + 1
      end
    end
  end

  return collisions
end

function CollisionSystem:rectangles_collide(obj1, obj2)
  local x1, y1, w1, h1 = self.spatial:get_bbox(obj1)
  local x2, y2, w2, h2 = self.spatial:get_bbox(obj2)

  return x1 < x2 + w2 and x2 < x1 + w1 and
         y1 < y2 + h2 and y2 < y1 + h1
end

function CollisionSystem:get_stats()
  return {
    collision_checks = self.collision_checks,
    broad_phase_candidates = self.broad_phase_candidates,
    narrow_phase_collisions = self.narrow_phase_collisions,
    efficiency_ratio = self.collision_checks > 0 and
                      (self.broad_phase_candidates / self.collision_checks) or 0
  }
end

function CollisionSystem:count_table(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end
```

### Viewport Culling System

```lua
--- @class ViewportCulling
--- Efficient rendering optimization using spatial queries
local ViewportCulling = {}

function ViewportCulling.new(locustron_instance, viewport_config)
  local self = setmetatable({}, ViewportCulling)

  self.spatial = locustron_instance
  self.viewport = viewport_config or {x = 0, y = 0, w = 400, h = 300}
  self.cull_margin = viewport_config.cull_margin or 32  -- Extra margin for safety
  self.stats = {
    total_objects = 0,
    visible_objects = 0,
    culled_objects = 0,
    cull_ratio = 0
  }

  return self
end

function ViewportCulling:get_visible_objects(filter_fn)
  local vx, vy, vw, vh = self.viewport.x, self.viewport.y, self.viewport.w, self.viewport.h

  -- Add margin to viewport for smoother scrolling
  local query_x = vx - self.cull_margin
  local query_y = vy - self.cull_margin
  local query_w = vw + self.cull_margin * 2
  local query_h = vh + self.cull_margin * 2

  -- Query spatial system
  local visible = self.spatial:query(query_x, query_y, query_w, query_h, filter_fn)

  -- Update statistics
  self.stats.total_objects = self.spatial:count()
  self.stats.visible_objects = self:count_table(visible)
  self.stats.culled_objects = self.stats.total_objects - self.stats.visible_objects
  self.stats.cull_ratio = self.stats.total_objects > 0 and
                         (self.stats.visible_objects / self.stats.total_objects) or 0

  return visible
end

function ViewportCulling:update_viewport(x, y, w, h)
  self.viewport.x = x
  self.viewport.y = y
  self.viewport.w = w or self.viewport.w
  self.viewport.h = h or self.viewport.h
end

function ViewportCulling:get_stats()
  return self.stats
end

function ViewportCulling:count_table(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end
```

### Performance Monitoring

```lua
--- @class PerformanceMonitor
--- Real-time performance monitoring for spatial operations
local PerformanceMonitor = {}

function PerformanceMonitor.new(locustron_instance)
  local self = setmetatable({}, PerformanceMonitor)

  self.spatial = locustron_instance
  self.enabled = true
  self.samples = {}
  self.max_samples = 1000

  self.operation_times = {
    add = {},
    update = {},
    remove = {},
    query = {}
  }

  return self
end

function PerformanceMonitor:time_operation(operation_name, fn, ...)
  if not self.enabled then
    return fn(...)
  end

  local start_time = os.clock()
  local results = {fn(...)}
  local end_time = os.clock()

  local duration = end_time - start_time
  self:record_sample(operation_name, duration)

  return table.unpack(results)
end

function PerformanceMonitor:record_sample(operation_name, duration)
  local samples = self.operation_times[operation_name]
  if not samples then return end

  table.insert(samples, duration)

  -- Maintain sample limit
  if #samples > self.max_samples then
    table.remove(samples, 1)
  end
end

function PerformanceMonitor:get_stats()
  local stats = {}

  for operation, samples in pairs(self.operation_times) do
    if #samples > 0 then
      stats[operation] = {
        count = #samples,
        avg_time = self:calculate_average(samples),
        min_time = math.min(table.unpack(samples)),
        max_time = math.max(table.unpack(samples)),
        p95_time = self:calculate_percentile(samples, 0.95)
      }
    end
  end

  return stats
end

function PerformanceMonitor:calculate_average(samples)
  local sum = 0
  for _, sample in ipairs(samples) do
    sum = sum + sample
  end
  return sum / #samples
end

function PerformanceMonitor:calculate_percentile(samples, percentile)
  if #samples == 0 then return 0 end

  table.sort(samples)
  local index = math.ceil(#samples * percentile)
  return samples[index]
end
```

### Migration and Compatibility

```lua
--- Legacy API compatibility layer
local function create_legacy_api(cell_size)
  local loc = Locustron.create({
    strategy = "fixed_grid",
    config = {cell_size = cell_size}
  })

  -- Legacy method names
  loc.add_object = loc.add
  loc.remove_object = loc.remove
  loc.update_object = loc.update
  loc.query_region = loc.query

  return loc
end

-- Global locustron function for backward compatibility
function locustron(config)
  -- Handle legacy usage: locustron(cell_size)
  if type(config) == "number" then
    return create_legacy_api(config)
  end

  return Locustron.create(config)
end
```

## Phase 3 Summary

**Duration**: 2 weeks (14 days)
**Key Achievement**: Complete game engine API for spatial partitioning
**Core API**: Unified interface across all spatial strategies
**Integration**: Collision detection, viewport culling, and performance monitoring
**Compatibility**: Backward compatibility with legacy APIs

**Ready for Phase 4**: Advanced debugging and visualization tools.
