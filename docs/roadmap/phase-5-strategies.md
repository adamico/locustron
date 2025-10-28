# Phase 5: Additional Strategy Implementation (4 weeks)

## Overview
Phase 5 implements the additional spatial partitioning strategies (Quadtree, Hash Grid, BSP Tree, and BVH) using the foundation established in Phase 1 and the benchmarking tools from Phase 2. This phase focuses on implementing proven algorithms with user-controlled strategy selection.

---

## Phase 5.1: Quadtree Implementation (1 week)

### Objectives
- Implement hierarchical Quadtree spatial partitioning strategy
- Create comprehensive test suite for Quadtree operations
- Integrate with existing strategy interface and factory
- Benchmark against Fixed Grid for comparison

### Key Features
- **Adaptive Subdivision**: Splits cells based on object count thresholds
- **Hierarchical Queries**: Efficient querying through tree traversal
- **Bounded Regions**: Optimized for known world boundaries
- **Dynamic Balancing**: Maintains tree balance through insertion/removal

### Implementation Approach
```lua
--- @class QuadtreeStrategy : SpatialStrategy
--- @field private root QuadtreeNode
--- @field private bounds table World boundaries {x, y, width, height}
--- @field private max_objects number Objects per node before subdivision
--- @field private max_depth number Maximum tree depth
local QuadtreeStrategy = {}
QuadtreeStrategy.__index = QuadtreeStrategy
setmetatable(QuadtreeStrategy, {__index = SpatialStrategy})

--- @class QuadtreeNode
--- @field private bounds table Node boundaries
--- @field private objects table Objects in this node
--- @field private children table Child nodes (nil for leaves)
--- @field private parent QuadtreeNode Parent node
local QuadtreeNode = {}
QuadtreeNode.__index = QuadtreeNode

function QuadtreeNode:new(bounds, parent, max_objects, current_depth)
  local self = setmetatable({}, QuadtreeNode)
  
  self.bounds = bounds  -- {x, y, width, height}
  self.objects = {}
  self.children = nil   -- nil indicates leaf node
  self.parent = parent
  self.max_objects = max_objects
  self.current_depth = current_depth or 0
  
  return self
end

function QuadtreeNode:insert(obj, x, y, w, h, max_depth)
  -- Check if object fits in this node
  if not self:contains_object(x, y, w, h) then
    return false
  end
  
  -- If leaf node and under capacity, add object
  if not self.children and #self.objects < self.max_objects then
    table.insert(self.objects, {obj = obj, x = x, y = y, w = w, h = h})
    return true
  end
  
  -- If leaf node and over capacity, subdivide
  if not self.children and self.current_depth < max_depth then
    self:subdivide()
  end
  
  -- If has children, try to insert in appropriate child
  if self.children then
    local inserted = false
    for _, child in ipairs(self.children) do
      if child:insert(obj, x, y, w, h, max_depth) then
        inserted = true
      end
    end
    
    -- If object couldn't fit in any child, store in this node
    if not inserted then
      table.insert(self.objects, {obj = obj, x = x, y = y, w = w, h = h})
    end
    
    return true
  end
  
  -- Fallback: add to this node
  table.insert(self.objects, {obj = obj, x = x, y = y, w = w, h = h})
  return true
end

function QuadtreeNode:subdivide()
  local half_width = self.bounds.width / 2
  local half_height = self.bounds.height / 2
  local x, y = self.bounds.x, self.bounds.y
  
  self.children = {
    -- Top-left
    QuadtreeNode:new({
      x = x, y = y, 
      width = half_width, height = half_height
    }, self, self.max_objects, self.current_depth + 1),
    
    -- Top-right
    QuadtreeNode:new({
      x = x + half_width, y = y,
      width = half_width, height = half_height
    }, self, self.max_objects, self.current_depth + 1),
    
    -- Bottom-left
    QuadtreeNode:new({
      x = x, y = y + half_height,
      width = half_width, height = half_height
    }, self, self.max_objects, self.current_depth + 1),
    
    -- Bottom-right
    QuadtreeNode:new({
      x = x + half_width, y = y + half_height,
      width = half_width, height = half_height
    }, self, self.max_objects, self.current_depth + 1)
  }
  
  -- Redistribute existing objects to children
  local objects_to_redistribute = self.objects
  self.objects = {}
  
  for _, obj_data in ipairs(objects_to_redistribute) do
    self:insert(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h, 10)
  end
end

function QuadtreeNode:query(x, y, w, h, results)
  -- Check if query region intersects with this node
  if not self:intersects_region(x, y, w, h) then
    return
  end
  
  -- Add objects from this node that intersect with query
  for _, obj_data in ipairs(self.objects) do
    if self:rectangles_intersect(x, y, w, h, obj_data.x, obj_data.y, obj_data.w, obj_data.h) then
      results[obj_data.obj] = true
    end
  end
  
  -- Recursively query children
  if self.children then
    for _, child in ipairs(self.children) do
      child:query(x, y, w, h, results)
    end
  end
end

function QuadtreeStrategy.new(config)
  local self = setmetatable({}, QuadtreeStrategy)
  
  self.bounds = config.bounds or {0, 0, 1000, 1000}
  self.max_objects = config.max_objects or 8
  self.max_depth = config.max_depth or 10
  self.object_count = 0
  self.config = config or {}
  
  -- Strategy identification
  self.strategy_name = "quadtree"
  self.strategy_name = "hierarchical"
  
  self.root = QuadtreeNode:new({
    x = self.bounds[1],
    y = self.bounds[2], 
    width = self.bounds[3],
    height = self.bounds[4]
  }, nil, self.max_objects, 0)
  
  self.objects = {}  -- Object lookup for removal
  
  return self
end

function QuadtreeStrategy:add_object(obj, x, y, w, h)
  if self.objects[obj] then
    error("object already in spatial hash")
  end
  
  self.root:insert(obj, x, y, w, h, self.max_depth)
  self.objects[obj] = {x = x, y = y, w = w, h = h}
  self.object_count = self.object_count + 1
  
  return obj
end

function QuadtreeStrategy:query_region(x, y, w, h, filter_fn)
  local results = {}
  self.root:query(x, y, w, h, results)
  
  if filter_fn then
    local filtered_results = {}
    for obj in pairs(results) do
      if filter_fn(obj) then
        filtered_results[obj] = true
      end
    end
    return filtered_results
  end
  
  return results
end
```

### Test Suite for Quadtree
```lua
-- spec/quadtree_strategy_spec.lua
describe("QuadtreeStrategy", function()
  local strategy
  
  before_each(function()
    strategy = QuadtreeStrategy.new({
      bounds = {0, 0, 1000, 1000},
      max_objects = 4,
      max_depth = 6
    })
  end)
  
  describe("initialization", function()
    it("should create with specified bounds", function()
      assert.equals("quadtree", strategy.strategy_name)
      assert.equals("hierarchical", strategy.strategy_name)
      assert.equals(4, strategy.max_objects)
      assert.equals(6, strategy.max_depth)
    end)
  end)
  
  describe("object management", function()
    it("should add objects within bounds", function()
      local obj = {id = 1}
      strategy:add_object(obj, 100, 100, 32, 32)
      
      assert.equals(1, strategy.object_count)
      local x, y, w, h = strategy:get_bbox(obj)
      assert.equals(100, x)
      assert.equals(100, y)
    end)
    
    it("should handle subdivision when threshold exceeded", function()
      -- Add enough objects to trigger subdivision
      for i = 1, 6 do
        local obj = {id = i}
        strategy:add_object(obj, i * 10, i * 10, 16, 16)
      end
      
      assert.equals(6, strategy.object_count)
      
      -- Verify objects can still be queried
      local results = strategy:query_region(0, 0, 200, 200)
      local count = 0
      for _ in pairs(results) do count = count + 1 end
      assert.equals(6, count)
    end)
  end)
  
  describe("hierarchical queries", function() 
    it("should efficiently query large sparse regions", function()
      -- Add objects in corners
      local obj1 = {id = 1}
      local obj2 = {id = 2}
      strategy:add_object(obj1, 10, 10, 16, 16)     -- Top-left
      strategy:add_object(obj2, 900, 900, 16, 16)   -- Bottom-right
      
      -- Query only top-left quadrant
      local results = strategy:query_region(0, 0, 500, 500)
      assert.equals(true, results[obj1])
      assert.is_nil(results[obj2])
    end)
  end)
end)
```

---

## Phase 5.2: Hash Grid Implementation (1 week)

### Objectives
- Implement Hash Grid for unbounded worlds and negative coordinates
- Optimize for sparse object distributions and large worlds
- Create hash collision handling and dynamic resizing
- Benchmark memory efficiency versus Fixed Grid

### Key Features
- **Unbounded Worlds**: Supports infinite coordinate spaces
- **Negative Coordinates**: Handles any coordinate values
- **Memory Efficient**: Only allocates storage for used cells
- **Hash Collision Handling**: Robust collision resolution

### Implementation Approach
```lua
--- @class HashGridStrategy : SpatialStrategy
--- @field private cells table Hash table of cells
--- @field private cell_size number Grid cell size
--- @field private hash_size number Hash table size
local HashGridStrategy = {}
HashGridStrategy.__index = HashGridStrategy
setmetatable(HashGridStrategy, {__index = SpatialStrategy})

function HashGridStrategy.new(config)
  local self = setmetatable({}, HashGridStrategy)
  
  self.cell_size = config.cell_size or 64
  self.hash_size = config.hash_size or 1024
  self.cells = {}  -- Hash table: {[hash] = SpatialCell}
  self.objects = {}
  self.object_count = 0
  self.config = config or {}
  
  -- Strategy identification
  self.strategy_name = "hash_grid"
  self.strategy_name = "spatial_hash"
  
  return self
end

function HashGridStrategy:_hash_coordinates(gx, gy)
  -- Use a prime number hash function for better distribution
  local h1 = gx * 73856093
  local h2 = gy * 19349663
  return ((h1 ~ h2) % self.hash_size) + 1  -- Lua tables are 1-indexed
end

function HashGridStrategy:_world_to_grid(x, y)
  return x // self.cell_size, y // self.cell_size
end

function HashGridStrategy:add_object(obj, x, y, w, h)
  if self.objects[obj] then
    error("object already in spatial hash")
  end
  
  local nodes = self:_add_to_cells(obj, x, y, w, h)
  self.objects[obj] = {
    nodes = nodes,
    bbox = {x = x, y = y, w = w, h = h}
  }
  
  self.object_count = self.object_count + 1
  return obj
end

function HashGridStrategy:_add_to_cells(obj, x, y, w, h)
  local gx0, gy0 = self:_world_to_grid(x, y)
  local gx1, gy1 = self:_world_to_grid(x + w - 1, y + h - 1)
  local nodes = {}
  
  for gy = gy0, gy1 do
    for gx = gx0, gx1 do
      local hash = self:_hash_coordinates(gx, gy)
      
      if not self.cells[hash] then
        self.cells[hash] = dll.createCell()
      end
      
      local node = self.cells[hash]:insertEnd(obj, x, y, w, h)
      table.insert(nodes, {hash = hash, node = node})
    end
  end
  
  return nodes
end
```

---

## Phase 5.3: BSP Tree Implementation (1 week)

### Objectives
- Implement Binary Space Partitioning for ray casting optimization
- Create geometric partitioning with adjustable split strategies
- Optimize for line intersection and visibility queries
- Integrate with existing query interface

### Key Features
- **Geometric Partitioning**: Splits space along geometric planes
- **Ray Casting Optimization**: Efficient line intersection queries
- **Balanced Splitting**: Multiple split strategies for tree balance
- **2D Line Queries**: Specialized support for line-based operations

---

## Phase 5.4: BVH Implementation (1 week)

### Objectives
- Implement Bounding Volume Hierarchy for mixed object sizes
- Create hierarchical bounding volume management
- Optimize for nearest neighbor and complex shape queries
- Handle dynamic rebalancing for changing object distributions

### Key Features
- **Hierarchical Volumes**: Tree of bounding volumes for efficient culling
- **Mixed Object Sizes**: Optimized for objects with varying dimensions
- **Nearest Neighbor**: Efficient k-nearest neighbor queries
- **Dynamic Rebalancing**: Maintains tree quality over time

## Integration and Testing

### Strategy Registration
```lua
-- Register all new strategies in builtin_strategies.lua
strategy_interface.register_strategy("quadtree", QuadtreeStrategy, {
  description = "Hierarchical spatial partitioning with adaptive subdivision",
  optimal_for = {"clustered_objects", "bounded_worlds", "hierarchical_queries"},
  memory_characteristics = "adaptive",
  supports_unbounded = false,
  supports_hierarchical = true,
  supports_dynamic_resize = true
})

strategy_interface.register_strategy("hash_grid", HashGridStrategy, {
  description = "Hash-based spatial grid for unbounded worlds",
  optimal_for = {"sparse_distribution", "infinite_worlds", "negative_coordinates"},
  memory_characteristics = "very_sparse",
  supports_unbounded = true,
  supports_hierarchical = false,
  supports_dynamic_resize = false
})

-- Similar registrations for BSP Tree and BVH...
```

### Comprehensive Testing
```lua
-- Run all strategy tests
busted spec/quadtree_strategy_spec.lua
busted spec/hash_grid_strategy_spec.lua
busted spec/bsp_tree_strategy_spec.lua
busted spec/bvh_strategy_spec.lua

-- Cross-strategy compatibility tests
busted spec/strategy_compatibility_spec.lua

-- Performance comparison
lua benchmark_all_strategies.lua
```

## Deliverables

### 5.1 Quadtree Strategy
- [x] **QuadtreeStrategy Class**: Complete hierarchical implementation
- [x] **Adaptive Subdivision**: Object count-based tree splitting
- [x] **Hierarchical Queries**: Efficient tree traversal queries
- [x] **Test Suite**: 20+ comprehensive test cases

### 5.2 Hash Grid Strategy  
- [x] **HashGridStrategy Class**: Unbounded world implementation
- [x] **Hash Functions**: Robust coordinate hashing
- [x] **Collision Handling**: Multiple hash collision strategies
- [x] **Test Suite**: Sparse world and negative coordinate tests

### 5.3 BSP Tree Strategy
- [x] **BSPTreeStrategy Class**: Geometric partitioning implementation
- [x] **Ray Casting Support**: Optimized line intersection queries
- [x] **Split Strategies**: Balanced and geometric splitting options
- [x] **Test Suite**: Ray casting and geometric query tests

### 5.4 BVH Strategy
- [x] **BVHStrategy Class**: Bounding volume hierarchy implementation  
- [x] **Mixed Object Support**: Optimized for varying object sizes
- [x] **Nearest Neighbor**: Efficient k-NN query implementation
- [x] **Test Suite**: Complex shape and rebalancing tests

## Success Criteria

- **Complete Strategy Set**: All 5 strategies (Fixed Grid + 4 new) implemented and tested
- **API Compatibility**: All strategies follow the same interface contract
- **Performance Validation**: Benchmarking confirms expected performance characteristics
- **Educational Value**: Clear examples of different spatial partitioning approaches
- **Production Ready**: Comprehensive testing and documentation for real-world use

## Benchmarking Integration

Phase 5 leverages the benchmarking framework from Phase 2 to validate strategy performance:

```lua
-- Comprehensive strategy comparison
local benchmark_suite = BenchmarkSuite.new({iterations = 1000})
benchmark_suite.strategies = {
  "fixed_grid", "quadtree", "hash_grid", "bsp_tree", "bvh"
}

local results = benchmark_suite:run_complete_benchmark()
local report = benchmark_suite:generate_report(results)
print(report)
```

The benchmarking will provide concrete data for the [Strategy Selection Guide](./strategy-selection-guide.md), enabling developers to make informed decisions based on real performance measurements.

## Phase 5 Summary

**Duration**: 4 weeks (28 days)
**Key Achievement**: Complete multi-strategy spatial partitioning library
**Strategies**: Fixed Grid + Quadtree + Hash Grid + BSP Tree + BVH
**Testing**: Comprehensive test coverage across all strategies
**Performance**: Validated performance characteristics for informed strategy selection

With Phase 5 complete, Locustron becomes a comprehensive spatial partitioning library with user-controlled strategy selection, extensive benchmarking capabilities, and educational value for understanding different spatial data structures.