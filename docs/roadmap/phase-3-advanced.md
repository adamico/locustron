# Phase 3: BSP Tree & BVH Implementation (3 weeks)

## Overview
Phase 3 implements advanced spatial partitioning strategies: Binary Space Partitioning (BSP) Trees for complex geometric scenarios and Bounding Volume Hierarchies (BVH) for ray-casting and complex queries. These strategies target specialized use cases requiring sophisticated spatial organization.

---

## Phase 3.1: BSP Tree Strategy (12 days)

### Objectives
- Implement Binary Space Partitioning for complex spatial divisions
- Support arbitrary splitting planes and orientations
- Optimize for irregular spatial distributions
- Enable advanced spatial queries (ray casting, complex shapes)

### Key Features
- **Arbitrary Splitting Planes**: Not limited to axis-aligned divisions
- **Adaptive Partitioning**: Choose optimal split based on object distribution
- **Complex Queries**: Support for ray casting and arbitrary shape queries
- **Geometric Flexibility**: Handle non-rectangular spatial divisions

### BSP Tree Theory
```
BSP Tree divides space using arbitrary planes rather than fixed grid cells:

         |
    A    |    B
         |
---------|--------
         |
    C    |    D
         |

Each node represents a splitting plane that divides space into "in front" and "behind" regions.
Objects are classified based on their relationship to the splitting plane.
```

### Implementation Details
```lua
local BSPTreeStrategy = {}
BSPTreeStrategy.__index = BSPTreeStrategy

function BSPTreeStrategy.new(config)
  local self = setmetatable({}, BSPTreeStrategy)
  
  self.max_objects = config.max_objects or 8
  self.max_depth = config.max_depth or 10
  self.split_method = config.split_method or "longest_axis"
  self.root = create_bsp_node(config.bounds or {0, 0, 1024, 1024}, 0)
  self.objects = {}
  
  return self
end

-- BSP node structure
function create_bsp_node(bounds, depth)
  return {
    bounds = bounds,  -- {x, y, w, h}
    depth = depth,
    objects = {},
    
    -- Splitting plane (ax + by + c = 0)
    split_plane = nil,  -- {a, b, c}
    split_axis = nil,   -- "x" or "y" for axis-aligned splits
    split_pos = nil,    -- Position along axis
    
    front_child = nil,  -- Objects in front of plane
    back_child = nil,   -- Objects behind plane
    is_leaf = true
  }
end

function BSPTreeStrategy:add_object(obj, x, y, w, h)
  local obj_node = create_object_node(obj, x, y, w, h)
  self.objects[obj] = obj_node
  
  self:insert_into_bsp(self.root, obj_node)
  return obj
end

function BSPTreeStrategy:insert_into_bsp(node, obj_node)
  if node.is_leaf then
    table.insert(node.objects, obj_node)
    obj_node.container_node = node
    
    -- Check if subdivision is needed
    if #node.objects > self.max_objects and node.depth < self.max_depth then
      self:subdivide_bsp(node)
    end
  else
    -- Classify object against splitting plane
    local classification = self:classify_object_against_plane(obj_node, node.split_plane)
    
    if classification >= 0 then  -- In front or straddling
      self:insert_into_bsp(node.front_child, obj_node)
    end
    if classification <= 0 then  -- Behind or straddling
      self:insert_into_bsp(node.back_child, obj_node)
    end
  end
end

function BSPTreeStrategy:subdivide_bsp(node)
  -- Choose optimal splitting plane
  local split_info = self:choose_split_plane(node)
  
  node.split_plane = split_info.plane
  node.split_axis = split_info.axis
  node.split_pos = split_info.pos
  node.is_leaf = false
  
  -- Create child nodes
  local front_bounds, back_bounds = self:compute_child_bounds(node, split_info)
  node.front_child = create_bsp_node(front_bounds, node.depth + 1)
  node.back_child = create_bsp_node(back_bounds, node.depth + 1)
  
  -- Redistribute objects
  local objects_to_redistribute = node.objects
  node.objects = {}
  
  for _, obj_node in ipairs(objects_to_redistribute) do
    local classification = self:classify_object_against_plane(obj_node, node.split_plane)
    
    if classification >= 0 then
      self:insert_into_bsp(node.front_child, obj_node)
    end
    if classification <= 0 then
      self:insert_into_bsp(node.back_child, obj_node)
    end
  end
end

function BSPTreeStrategy:choose_split_plane(node)
  if self.split_method == "longest_axis" then
    -- Split along longest axis
    if node.bounds[3] > node.bounds[4] then  -- width > height
      local split_x = node.bounds[1] + node.bounds[3] / 2
      return {
        plane = {1, 0, -split_x},  -- x - split_x = 0
        axis = "x",
        pos = split_x
      }
    else
      local split_y = node.bounds[2] + node.bounds[4] / 2
      return {
        plane = {0, 1, -split_y},  -- y - split_y = 0
        axis = "y", 
        pos = split_y
      }
    end
  elseif self.split_method == "balanced" then
    -- Choose split that balances object distribution
    return self:find_balanced_split(node)
  end
end

function BSPTreeStrategy:classify_object_against_plane(obj_node, plane)
  local a, b, c = plane[1], plane[2], plane[3]
  
  -- Test object corners against plane
  local corners = {
    {obj_node.x, obj_node.y},
    {obj_node.x + obj_node.w, obj_node.y},
    {obj_node.x, obj_node.y + obj_node.h},
    {obj_node.x + obj_node.w, obj_node.y + obj_node.h}
  }
  
  local min_dist, max_dist = math.huge, -math.huge
  for _, corner in ipairs(corners) do
    local dist = a * corner[1] + b * corner[2] + c
    min_dist = math.min(min_dist, dist)
    max_dist = math.max(max_dist, dist)
  end
  
  local epsilon = 1e-6
  if min_dist > epsilon then
    return 1   -- In front
  elseif max_dist < -epsilon then
    return -1  -- Behind
  else
    return 0   -- Straddling
  end
end
```

### Advanced Query Support
```lua
function BSPTreeStrategy:ray_cast(start_x, start_y, end_x, end_y, filter_fn)
  local results = {}
  local ray_dir = {end_x - start_x, end_y - start_y}
  
  self:ray_cast_recursive(self.root, start_x, start_y, ray_dir, results, filter_fn)
  return results
end

function BSPTreeStrategy:ray_cast_recursive(node, ray_x, ray_y, ray_dir, results, filter_fn)
  if node.is_leaf then
    -- Test ray against objects in leaf
    for _, obj_node in ipairs(node.objects) do
      if self:ray_intersects_object(ray_x, ray_y, ray_dir, obj_node) then
        if not filter_fn or filter_fn(obj_node.obj) then
          table.insert(results, obj_node.obj)
        end
      end
    end
  else
    -- Determine ray traversal order
    local start_side = self:classify_point_against_plane(ray_x, ray_y, node.split_plane)
    
    if start_side >= 0 then
      self:ray_cast_recursive(node.front_child, ray_x, ray_y, ray_dir, results, filter_fn)
      if self:ray_crosses_plane(ray_x, ray_y, ray_dir, node.split_plane) then
        self:ray_cast_recursive(node.back_child, ray_x, ray_y, ray_dir, results, filter_fn)
      end
    else
      self:ray_cast_recursive(node.back_child, ray_x, ray_y, ray_dir, results, filter_fn)
      if self:ray_crosses_plane(ray_x, ray_y, ray_dir, node.split_plane) then
        self:ray_cast_recursive(node.front_child, ray_x, ray_y, ray_dir, results, filter_fn)
      end
    end
  end
end
```

---

## Phase 3.2: BVH Strategy (9 days)

### Objectives
- Implement Bounding Volume Hierarchy for complex object shapes
- Optimize for ray casting and intersection queries
- Support dynamic object updates with tree restructuring
- Enable efficient nearest-neighbor searches

### Key Features
- **Hierarchical Bounding Volumes**: Tree of nested bounding boxes
- **Surface Area Heuristic (SAH)**: Optimal tree construction
- **Dynamic Updates**: Efficient tree restructuring for moving objects
- **Complex Queries**: Ray casting, k-nearest neighbor, range queries

### BVH Theory
```
BVH organizes objects in a tree of bounding volumes:

         [Root AABB]
        /            \
   [Left AABB]   [Right AABB]
   /        \     /         \
[Obj A]  [Obj B] [Obj C]  [Obj D]

Each internal node contains the AABB that bounds all its children.
Leaf nodes contain actual objects.
Tree construction uses SAH to minimize expected traversal cost.
```

### Implementation Details
```lua
local BVHStrategy = {}
BVHStrategy.__index = BVHStrategy

function BVHStrategy.new(config)
  local self = setmetatable({}, BVHStrategy)
  
  self.max_leaf_objects = config.max_leaf_objects or 4
  self.root = nil
  self.objects = {}
  self.all_objects = {}  -- For rebuild operations
  
  return self
end

-- BVH node structure
function create_bvh_node()
  return {
    aabb = {math.huge, math.huge, -math.huge, -math.huge},  -- {min_x, min_y, max_x, max_y}
    left_child = nil,
    right_child = nil,
    objects = {},  -- Only for leaf nodes
    is_leaf = true
  }
end

function BVHStrategy:add_object(obj, x, y, w, h)
  local obj_node = create_object_node(obj, x, y, w, h)
  self.objects[obj] = obj_node
  table.insert(self.all_objects, obj_node)
  
  -- Mark tree for rebuild (or use incremental insertion)
  self.needs_rebuild = true
  return obj
end

function BVHStrategy:rebuild_tree()
  if not self.needs_rebuild then return end
  
  if #self.all_objects == 0 then
    self.root = nil
  else
    self.root = self:build_bvh_recursive(self.all_objects)
  end
  
  self.needs_rebuild = false
end

function BVHStrategy:build_bvh_recursive(object_list)
  local node = create_bvh_node()
  
  -- Calculate bounding box for all objects
  for _, obj_node in ipairs(object_list) do
    node.aabb[1] = math.min(node.aabb[1], obj_node.x)
    node.aabb[2] = math.min(node.aabb[2], obj_node.y)
    node.aabb[3] = math.max(node.aabb[3], obj_node.x + obj_node.w)
    node.aabb[4] = math.max(node.aabb[4], obj_node.y + obj_node.h)
  end
  
  -- Base case: create leaf node
  if #object_list <= self.max_leaf_objects then
    node.objects = object_list
    node.is_leaf = true
    return node
  end
  
  -- Find best split using Surface Area Heuristic
  local best_split = self:find_best_split_sah(object_list, node.aabb)
  
  if not best_split then
    -- No good split found, create leaf
    node.objects = object_list
    node.is_leaf = true
    return node
  end
  
  -- Split objects into left and right groups
  local left_objects, right_objects = self:partition_objects(object_list, best_split)
  
  node.is_leaf = false
  node.left_child = self:build_bvh_recursive(left_objects)
  node.right_child = self:build_bvh_recursive(right_objects)
  
  return node
end

function BVHStrategy:find_best_split_sah(object_list, parent_aabb)
  local best_cost = math.huge
  local best_split = nil
  
  local parent_area = self:aabb_surface_area(parent_aabb)
  
  -- Try splits along both axes
  for _, axis in ipairs({"x", "y"}) do
    -- Sort objects along axis
    table.sort(object_list, function(a, b)
      local a_center = axis == "x" and (a.x + a.w/2) or (a.y + a.h/2)
      local b_center = axis == "x" and (b.x + b.w/2) or (b.y + b.h/2)
      return a_center < b_center
    end)
    
    -- Try each possible split position
    for i = 1, #object_list - 1 do
      local left_objects = {table.unpack(object_list, 1, i)}
      local right_objects = {table.unpack(object_list, i + 1)}
      
      local left_aabb = self:calculate_aabb(left_objects)
      local right_aabb = self:calculate_aabb(right_objects)
      
      -- Calculate SAH cost
      local left_area = self:aabb_surface_area(left_aabb)
      local right_area = self:aabb_surface_area(right_aabb)
      
      local cost = (left_area / parent_area) * #left_objects + 
                   (right_area / parent_area) * #right_objects
      
      if cost < best_cost then
        best_cost = cost
        best_split = {
          axis = axis,
          split_index = i,
          left_aabb = left_aabb,
          right_aabb = right_aabb
        }
      end
    end
  end
  
  -- Only split if it reduces cost
  if best_cost < #object_list then
    return best_split
  else
    return nil  -- No beneficial split
  end
end

function BVHStrategy:aabb_surface_area(aabb)
  local w = aabb[3] - aabb[1]
  local h = aabb[4] - aabb[2]
  return 2 * (w + h)  -- Perimeter for 2D
end
```

### Advanced BVH Queries
```lua
function BVHStrategy:query_region(x, y, w, h, filter_fn)
  self:rebuild_tree()
  if not self.root then return {} end
  
  local query_aabb = {x, y, x + w, y + h}
  local results = {}
  local visited = {}
  
  self:query_bvh_recursive(self.root, query_aabb, results, visited, filter_fn)
  return results
end

function BVHStrategy:query_bvh_recursive(node, query_aabb, results, visited, filter_fn)
  -- Early termination if no intersection
  if not self:aabb_intersects(node.aabb, query_aabb) then
    return
  end
  
  if node.is_leaf then
    for _, obj_node in ipairs(node.objects) do
      if not visited[obj_node.obj] then
        visited[obj_node.obj] = true
        if not filter_fn or filter_fn(obj_node.obj) then
          results[obj_node.obj] = true
        end
      end
    end
  else
    self:query_bvh_recursive(node.left_child, query_aabb, results, visited, filter_fn)
    self:query_bvh_recursive(node.right_child, query_aabb, results, visited, filter_fn)
  end
end

function BVHStrategy:find_nearest(x, y, count, filter_fn)
  self:rebuild_tree()
  if not self.root then return {} end
  
  local candidates = {}
  self:collect_nearest_candidates(self.root, x, y, candidates, filter_fn)
  
  -- Sort by distance and return top 'count'
  table.sort(candidates, function(a, b) return a.distance < b.distance end)
  
  local results = {}
  for i = 1, math.min(count, #candidates) do
    table.insert(results, candidates[i].obj)
  end
  
  return results
end
```

---

## Phase 3.3: Integration & Advanced Features (5 days)

### Objectives
- Integrate BSP Tree and BVH strategies
- Implement strategy auto-selection for complex scenarios
- Advanced query interfaces
- Performance optimization and benchmarking

### Strategy Selection Guidelines
```lua
-- Advanced strategy selection based on usage patterns
local function auto_select_strategy(objects, query_patterns)
  local analysis = analyze_spatial_distribution(objects)
  
  if analysis.has_complex_geometry or analysis.needs_ray_casting then
    return "bsp_tree"
  elseif analysis.needs_nearest_neighbor or analysis.has_irregular_shapes then
    return "bvh"
  elseif analysis.is_clustered then
    return "quadtree"
  elseif analysis.world_size == "infinite" then
    return "hash_grid"
  else
    return "fixed_grid"
  end
end
```

### Advanced Query Interface
```lua
-- Enhanced query capabilities
local loc = locustron({strategy = "auto"})

-- Standard queries
local nearby = loc.query(x, y, w, h)

-- Ray casting (BSP Tree)
local hit_objects = loc.ray_cast(start_x, start_y, end_x, end_y)

-- Nearest neighbor (BVH)
local closest = loc.find_nearest(x, y, 5)

-- Complex shape queries (BSP Tree)
local polygon_hits = loc.query_polygon({{x1,y1}, {x2,y2}, {x3,y3}})

-- Range queries with distance (BVH)
local within_range = loc.query_radius(x, y, radius)
```

## Phase 3 Summary

**Duration**: 3 weeks (21 days)
**Key Achievement**: Advanced spatial partitioning strategies for specialized scenarios
**New Strategies**: BSP Tree (complex geometry), BVH (ray casting, nearest neighbor)
**Advanced Features**: Ray casting, nearest neighbor, complex shape queries
**Auto-Selection**: Intelligent strategy choice based on usage patterns

**Ready for Phase 4**: Intelligent optimization and comprehensive benchmarking.