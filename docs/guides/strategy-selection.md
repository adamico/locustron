# Strategy Selection Guide

## Overview

This guide provides practical advice for choosing the optimal spatial partitioning strategy based on your game's characteristics. Each strategy has specific strengths and is optimized for different scenarios.

## Quick Decision Matrix

| Scenario | Primary Strategy | Alternative | Reason |
|----------|------------------|-------------|--------|
| Small worlds, uniform objects | Fixed Grid | Hash Grid | Simple, predictable performance |
| Large sparse worlds | Hash Grid | Fixed Grid | Memory efficient for sparse data |
| Clustered objects | Quadtree | BVH | Adaptive subdivision for clusters |
| Many moving objects | Fixed Grid | Hash Grid | Fast updates, minimal reorganization |
| Ray casting queries | BSP Tree | BVH | Optimized for line intersection |
| Mixed object sizes | BVH | Quadtree | Handles size variation well |
| High object density | Hash Grid | Fixed Grid | Scales well with object count |

## Strategy Details

### Fixed Grid

**Best For**: Uniform object distribution, frequent updates, predictable worlds
**Performance**: O(1) add/remove/update, O(k) queries where k = objects in region
**Memory**: Sparse allocation, minimal overhead
**Trade-offs**: Less efficient for clustered objects

**Use When**:

- Objects are roughly the same size
- World bounds are known and reasonably bounded
- Frequent position updates (moving objects)
- Simple collision detection needs

**Configuration**:

```lua
local loc = create_strategy("fixed_grid", {
  cell_size = 32  -- Should match typical object size
})
```

### Hash Grid

**Best For**: Large sparse worlds, negative coordinates, high object counts
**Performance**: O(1) average operations, handles unbounded worlds
**Memory**: Very memory efficient for sparse distributions
**Trade-offs**: Potential hash collisions, slightly more complex

**Use When**:

- World coordinates can be negative
- Very large or infinite worlds
- Sparse object distribution
- Memory usage is a primary concern

**Configuration**:

```lua
local loc = create_strategy("hash_grid", {
  cell_size = 64,  -- Larger cells for sparse worlds
  hash_size = 1024 -- Adjust based on expected object count
})
```

### Quadtree

**Best For**: Clustered objects, hierarchical worlds, variable object sizes
**Performance**: O(log n) operations, adaptive subdivision
**Memory**: Allocates based on object distribution
**Trade-offs**: More complex, potential deep recursion

**Use When**:

- Objects form natural clusters
- Large variation in object sizes
- Hierarchical world structure
- Need to handle empty regions efficiently

**Configuration**:

```lua
local loc = create_strategy("quadtree", {
  max_objects = 8,     -- Objects per leaf before subdivision
  max_depth = 10,      -- Maximum tree depth
  bounds = {0, 0, 1000, 1000}  -- World bounds
})
```

### BSP Tree (Binary Space Partitioning)

**Best For**: Ray casting, line-of-sight, geometric queries
**Performance**: O(log n) for ray intersections, O(n) for construction
**Memory**: Tree structure with geometric partitions
**Trade-offs**: Optimized for specific query types

**Use When**:

- Frequent ray casting or line intersection queries
- 2D visibility calculations
- Geometric collision detection
- Static or semi-static environments

**Configuration**:

```lua
local loc = create_strategy("bsp_tree", {
  split_threshold = 10,  -- Objects before splitting
  balance_factor = 0.3   -- Balancing preference
})
```

### BVH (Bounding Volume Hierarchy)

**Best For**: Mixed object sizes, nearest neighbor queries, complex shapes
**Performance**: O(log n) queries, good for various query types
**Memory**: Hierarchical bounding volumes
**Trade-offs**: Construction overhead, complex updates

**Use When**:

- Objects have very different sizes
- Frequent nearest neighbor queries
- Complex or non-rectangular shapes
- Quality of spatial organization is critical

**Configuration**:

```lua
local loc = create_strategy("bvh", {
  leaf_capacity = 4,     -- Objects per leaf node
  rebalance_threshold = 0.7  -- When to trigger rebalancing
})
```

## Selection Workflow

### 1. Analyze Your Game

Start by characterizing your game's spatial properties:

```lua
-- Game analysis questions
local game_profile = {
  world_size = "small|medium|large|infinite",
  object_count = 100,  -- Typical number of objects
  object_size_variation = "uniform|mixed|extreme",
  object_movement = "static|slow|fast|teleporting",
  query_patterns = "local|global|mixed",
  special_queries = {"ray_cast", "nearest_neighbor", "range"},
  memory_constraints = "strict|moderate|none"
}
```

### 2. Apply Decision Rules

**Rule 1: Start Simple**

- Most games work well with Fixed Grid
- Use cell_size = typical object size
- Only optimize if performance issues arise

**Rule 2: Scale Considerations**

- < 500 objects: Any strategy works
- 500-5000 objects: Choose based on distribution
- > 5000 objects: Consider Hash Grid or BVH

**Rule 3: Distribution Patterns**

- Uniform distribution → Fixed Grid
- Clustered objects → Quadtree
- Sparse worlds → Hash Grid

**Rule 4: Query Optimization**

- Frequent ray casting → BSP Tree
- Nearest neighbor queries → BVH
- Simple collision detection → Fixed Grid

### 3. Performance Testing

Always benchmark with your actual data:

```lua
-- Create benchmark function
function benchmark_strategy(strategy_name, test_objects)
  local loc = create_strategy(strategy_name, config)
  
-- Test object insertion
local start_time = time()  -- Picotron's high-resolution timer
for _, obj in ipairs(test_objects) do
  loc:add_object(obj.obj, obj.x, obj.y, obj.w, obj.h)
end
local add_time = time() - start_time

-- Test query performance
start_time = time()  -- Picotron's high-resolution timer
for i = 1, 100 do
  loc:query_region(math.random(0, 1000), math.random(0, 1000), 64, 64)
end
local query_time = time() - start_time  return {add_time = add_time, query_time = query_time}
end
```

## Common Patterns

### Survivor Games (Hundreds of Entities)

```lua
-- Recommended: Fixed Grid with optimized cell size
local loc = create_strategy("fixed_grid", {
  cell_size = 32  -- Match player/enemy size
})
```

### Open World Games

```lua
-- Recommended: Hash Grid for infinite worlds
local loc = create_strategy("hash_grid", {
  cell_size = 128,  -- Larger cells for open worlds
  hash_size = 2048
})
```

### Tower Defense Games

```lua
-- Recommended: Quadtree for path optimization
local loc = create_strategy("quadtree", {
  max_objects = 6,
  max_depth = 8,
  bounds = {0, 0, map_width, map_height}
})
```

### Bullet Hell Games

```lua
-- Recommended: Fixed Grid for fast-moving projectiles
local loc = create_strategy("fixed_grid", {
  cell_size = 16  -- Small cells for precise collision
})
```

## Migration Strategy

### From Single Strategy to Multi-Strategy

1. **Assessment Phase**
   - Profile current performance
   - Identify bottlenecks
   - Characterize object patterns

2. **Implementation Phase**
   - Add strategy interface
   - Implement alternative strategies
   - Create benchmark suite

3. **Optimization Phase**
   - Test strategies with real data
   - Select optimal strategy
   - Monitor performance

### Strategy Switching

```lua
-- Example: Dynamic strategy selection
function select_optimal_strategy(object_count, world_bounds, movement_factor)
  if object_count < 500 then
    return "fixed_grid"
  elseif world_bounds.width > 10000 or world_bounds.height > 10000 then
    return "hash_grid"
  elseif movement_factor < 0.1 then  -- Mostly static
    return "quadtree"
  else
    return "fixed_grid"
  end
end
```

## Performance Expectations

### Typical Performance Characteristics

| Strategy | Add/Remove | Query | Memory | Best Object Count |
|----------|------------|-------|--------|-------------------|
| Fixed Grid | O(1) | O(k) | Low | 100-5000 |
| Hash Grid | O(1) | O(k) | Very Low | 1000+ |
| Quadtree | O(log n) | O(log n + k) | Medium | 100-2000 |
| BSP Tree | O(n) | O(log n) | Medium | 100-1000 |
| BVH | O(log n) | O(log n) | High | 500-5000 |

*Where k = objects in query region, n = total objects*

## Troubleshooting

### Common Issues

**Performance Degradation**

- Check cell_size matches object sizes
- Verify objects aren't spanning too many cells
- Consider strategy switch if object patterns changed

**Memory Usage**

- Use Hash Grid for sparse distributions
- Tune Quadtree parameters (max_objects, max_depth)
- Consider BVH rebalancing frequency

**Query Accuracy**

- Verify bounding box calculations
- Check coordinate system consistency
- Test edge cases at cell boundaries

### Debug Tools

```lua
-- Strategy performance monitoring
function monitor_strategy_performance(loc)
  local stats = loc:get_statistics()
  print(string.format("Objects: %d, Memory: %d KB, Efficiency: %.2f",
    stats.object_count, stats.memory_usage / 1024, stats.efficiency))
  
  local debug_info = loc:get_debug_info()
  for _, hint in ipairs(debug_info.performance_hints) do
    print("Hint: " .. hint)
  end
end
```

## Conclusion

Strategy selection should be driven by your specific use case rather than theoretical performance. Start with Fixed Grid for most scenarios, then optimize based on actual performance measurements and game requirements.

The multi-strategy architecture allows you to:

- Experiment safely with different approaches
- Optimize for specific game phases or areas
- Adapt to changing object patterns over time
- Learn from real performance data

Remember: **Profile first, optimize second**. The best strategy is the one that works well for your specific game's object patterns and query requirements.
