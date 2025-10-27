# Phase 2: Quadtree & Hash Grid Implementation (3 weeks)

## Overview
Phase 2 introduces two additional spatial partitioning strategies: Quadtree for hierarchical spatial division and Hash Grid for infinite-world scenarios. Both strategies implement the established interface while providing optimizations for specific use cases.

---

## Phase 2.1: Quadtree Strategy (10 days)

### Objectives
- Implement adaptive Quadtree spatial partitioning
- Optimize for clustered object distributions
- Support dynamic subdivision and merging
- Maintain performance for sparse distributions

### Key Features
- **Adaptive Subdivision**: Cells split when object density exceeds threshold
- **Dynamic Merging**: Empty cells merge back to parent when appropriate
- **Memory Efficiency**: Only allocate nodes when needed
- **Query Optimization**: Early termination for non-overlapping regions

### Implementation Details
```lua
local QuadtreeStrategy = {}
QuadtreeStrategy.__index = QuadtreeStrategy

function QuadtreeStrategy.new(config)
  local self = setmetatable({}, QuadtreeStrategy)
  
  self.max_objects = config.max_objects or 10
  self.max_depth = config.max_depth or 6
  self.root = create_quadtree_node(config.bounds or {0, 0, 1024, 1024}, 0)
  self.objects = {}
  
  return self
end

-- Quadtree node structure
function create_quadtree_node(bounds, depth)
  return {
    x = bounds[1], y = bounds[2],
    w = bounds[3], h = bounds[4],
    depth = depth,
    objects = {},
    children = nil,  -- Will be created on subdivision
    is_leaf = true
  }
end

function QuadtreeStrategy:add_object(obj, x, y, w, h)
  local obj_node = create_object_node(obj, x, y, w, h)
  self.objects[obj] = obj_node
  
  self:insert_into_tree(self.root, obj_node)
  return obj
end

function QuadtreeStrategy:insert_into_tree(node, obj_node)
  -- If this is a leaf and has room, add object here
  if node.is_leaf then
    table.insert(node.objects, obj_node)
    obj_node.container_node = node
    
    -- Check if subdivision is needed
    if #node.objects > self.max_objects and node.depth < self.max_depth then
      self:subdivide(node)
    end
  else
    -- Find appropriate child quadrant(s)
    for _, child in ipairs(node.children) do
      if self:object_intersects_node(obj_node, child) then
        self:insert_into_tree(child, obj_node)
      end
    end
  end
end

function QuadtreeStrategy:subdivide(node)
  local half_w, half_h = node.w / 2, node.h / 2
  
  node.children = {
    create_quadtree_node({node.x, node.y, half_w, half_h}, node.depth + 1),  -- NW
    create_quadtree_node({node.x + half_w, node.y, half_w, half_h}, node.depth + 1),  -- NE
    create_quadtree_node({node.x, node.y + half_h, half_w, half_h}, node.depth + 1),  -- SW
    create_quadtree_node({node.x + half_w, node.y + half_h, half_w, half_h}, node.depth + 1)  -- SE
  }
  
  node.is_leaf = false
  
  -- Redistribute objects to children
  local objects_to_redistribute = node.objects
  node.objects = {}
  
  for _, obj_node in ipairs(objects_to_redistribute) do
    for _, child in ipairs(node.children) do
      if self:object_intersects_node(obj_node, child) then
        self:insert_into_tree(child, obj_node)
      end
    end
  end
end
```

### Performance Characteristics
- **Best Case**: O(log n) for clustered distributions
- **Worst Case**: O(n) for uniform distributions (degrades to linear search)
- **Memory**: Dynamic allocation scales with object clustering
- **Optimal For**: Games with clustered objects (cities, forests, etc.)

---

## Phase 2.2: Hash Grid Strategy (8 days)

### Objectives
- Implement Hash Grid for infinite-world scenarios
- Support negative coordinates and unlimited bounds
- Optimize for uniform object distributions
- Minimize memory overhead for sparse worlds

### Key Features
- **Infinite Bounds**: No world size limitations
- **Hash-based Indexing**: Efficient sparse cell storage
- **Negative Coordinates**: Full coordinate space support
- **Memory Efficiency**: Only store occupied cells

### Implementation Details
```lua
local HashGridStrategy = {}
HashGridStrategy.__index = HashGridStrategy

function HashGridStrategy.new(config)
  local self = setmetatable({}, HashGridStrategy)
  
  self.cell_size = config.cell_size or 32
  self.hash_size = config.hash_size or 4096
  self.cells = {}  -- Hash table of cells
  self.objects = {}
  
  return self
end

function HashGridStrategy:hash_coords(gx, gy)
  -- Simple hash function for grid coordinates
  local hash = (gx * 73856093) ~ (gy * 19349663)
  return (hash % self.hash_size) + 1
end

function HashGridStrategy:get_cell(gx, gy)
  local hash = self:hash_coords(gx, gy)
  local bucket = self.cells[hash]
  
  if not bucket then
    bucket = {}
    self.cells[hash] = bucket
  end
  
  -- Handle hash collisions with chaining
  for _, cell in ipairs(bucket) do
    if cell.gx == gx and cell.gy == gy then
      return cell
    end
  end
  
  -- Create new cell
  local cell = create_cell()
  cell.gx, cell.gy = gx, gy
  table.insert(bucket, cell)
  
  return cell
end

function HashGridStrategy:add_object(obj, x, y, w, h)
  local obj_node = create_object_node(obj, x, y, w, h)
  self.objects[obj] = obj_node
  
  -- Calculate grid bounds (supporting negative coordinates)
  local gx0 = math.floor(x / self.cell_size)
  local gy0 = math.floor(y / self.cell_size)
  local gx1 = math.floor((x + w - 1) / self.cell_size)
  local gy1 = math.floor((y + h - 1) / self.cell_size)
  
  obj_node.grid_cells = {}
  
  -- Add to all overlapping cells
  for gy = gy0, gy1 do
    for gx = gx0, gx1 do
      local cell = self:get_cell(gx, gy)
      insert_object_into_cell(cell, obj_node)
      table.insert(obj_node.grid_cells, {gx = gx, gy = gy})
    end
  end
  
  return obj
end

function HashGridStrategy:query_region(x, y, w, h, filter_fn)
  local results = {}
  local visited = {}
  
  local gx0 = math.floor(x / self.cell_size)
  local gy0 = math.floor(y / self.cell_size)
  local gx1 = math.floor((x + w - 1) / self.cell_size)
  local gy1 = math.floor((y + h - 1) / self.cell_size)
  
  for gy = gy0, gy1 do
    for gx = gx0, gx1 do
      local cell = self:get_existing_cell(gx, gy)
      if cell then
        local node = cell.objects
        while node do
          if not visited[node.obj] then
            visited[node.obj] = true
            if not filter_fn or filter_fn(node.obj) then
              results[node.obj] = true
            end
          end
          node = node.next
        end
      end
    end
  end
  
  return results
end
```

### Performance Characteristics
- **Operations**: O(1) average case for all operations
- **Memory**: Sparse storage, only occupied cells allocated
- **Optimal For**: Large/infinite worlds with uniform object distribution
- **Hash Collisions**: Mitigated with chaining and appropriate hash table size

---

## Phase 2.3: Integration & Benchmarking (4 days)

### Objectives
- Integrate both new strategies into factory system
- Comprehensive performance benchmarking
- Strategy selection guidelines
- Documentation and examples

### Strategy Comparison Matrix

| Strategy | Best Use Case | Time Complexity | Memory Usage | World Size |
|----------|---------------|-----------------|--------------|------------|
| Fixed Grid | Small, bounded worlds | O(1) | Fixed grid allocation | Limited |
| Quadtree | Clustered objects | O(log n) | Dynamic allocation | Bounded |
| Hash Grid | Large/infinite worlds | O(1) average | Sparse allocation | Unlimited |

### Performance Benchmarks
```lua
-- Comprehensive benchmarking suite
local function benchmark_strategies()
  local scenarios = {
    {name = "Clustered Objects", objects = generate_clustered_objects(1000)},
    {name = "Uniform Distribution", objects = generate_uniform_objects(1000)},
    {name = "Sparse World", objects = generate_sparse_objects(1000)},
    {name = "Moving Objects", objects = generate_moving_objects(1000)}
  }
  
  local strategies = {"fixed_grid", "quadtree", "hash_grid"}
  
  for _, scenario in ipairs(scenarios) do
    print(string.format("Scenario: %s", scenario.name))
    
    for _, strategy_name in ipairs(strategies) do
      local loc = locustron({strategy = strategy_name})
      
      -- Add all objects
      local start_time = os.clock()
      for _, obj in ipairs(scenario.objects) do
        loc.add(obj, obj.x, obj.y, obj.w, obj.h)
      end
      local add_time = os.clock() - start_time
      
      -- Query performance
      start_time = os.clock()
      for i = 1, 100 do
        loc.query(math.random(0, 1000), math.random(0, 1000), 64, 64)
      end
      local query_time = os.clock() - start_time
      
      print(string.format("  %s: Add=%.3fms, Query=%.3fms", 
        strategy_name, add_time * 1000, query_time * 10))
    end
    print()
  end
end
```

### Success Criteria
- ✅ Quadtree strategy optimizes clustered object scenarios
- ✅ Hash Grid strategy handles infinite worlds efficiently
- ✅ Both strategies integrate seamlessly with existing API
- ✅ Performance benchmarks guide strategy selection
- ✅ Comprehensive test coverage for all strategies

## Phase 2 Summary

**Duration**: 3 weeks (21 days)
**Key Achievement**: Multiple spatial partitioning strategies available
**New Strategies**: Quadtree (hierarchical), Hash Grid (infinite worlds)
**Performance**: Each strategy optimized for specific use cases
**Compatibility**: Full backward compatibility maintained

**Ready for Phase 3**: Advanced spatial structures (BSP Tree, BVH) with established patterns.