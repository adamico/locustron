# Strategy Selection Guide

Choosing the right spatial partitioning strategy is crucial for optimal performance. This guide helps you select the best algorithm for your game's specific needs.

## Quick Reference

| Strategy | Best For | Performance | Memory | Complexity |
|----------|----------|-------------|--------|------------|
| **Fixed Grid** | Uniform distributions, bounded worlds | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Quadtree** | Clustered objects, adaptive needs | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Hash Grid** | Large/sparse worlds | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **BSP Tree** | Complex spatial relationships | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **BVH** | Dynamic objects, ray casting | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## Understanding Your Game

Before choosing a strategy, analyze your game's characteristics:

### Object Distribution

**Uniform Distribution**: Objects spread evenly across the world

- **Example**: RTS games, platformers with regular enemy placement
- **Best Strategy**: Fixed Grid

**Clustered Distribution**: Objects grouped in specific areas

- **Example**: Survival games, games with spawn points
- **Best Strategy**: Quadtree

**Sparse Distribution**: Objects scattered across large areas

- **Example**: Open world games, space simulations
- **Best Strategy**: Hash Grid

### World Characteristics

**Bounded World**: Fixed-size game area

- **Example**: Platformers, puzzle games, most 2D games
- **Consider**: Fixed Grid, Quadtree

**Infinite/Large World**: Procedurally generated or very large worlds

- **Example**: Open world games, space games
- **Best Strategy**: Hash Grid

### Object Behavior

**Static Objects**: Objects that don't move

- **All strategies work well**

**Slowly Moving**: Objects that move short distances

- **All strategies work well**

**Highly Dynamic**: Objects that move frequently/long distances

- **Consider**: BVH for complex movement patterns

## Strategy Deep Dive

### Fixed Grid

**How it works**: Divides space into regular grid cells of fixed size.

**Best for**:

- Uniform object distributions
- Bounded game worlds
- Objects of similar sizes
- Simple collision detection

**Performance**:

- Add/Update/Remove: O(1)
- Query: O(k) where k = objects in overlapping cells
- Memory: O(n + c) where c = active cells

**Configuration**:

```lua
local loc = locustron({
  strategy = "fixed_grid",
  config = {
    cell_size = 32,  -- Match typical object size
    initial_capacity = 100
  }
})
```

**When to choose**:

- ✅ Platformers with regular level layouts
- ✅ RTS games with uniform unit distributions
- ✅ Puzzle games with grid-based mechanics
- ✅ Memory is not a major constraint

**When to avoid**:

- ❌ Large open worlds (use Hash Grid)
- ❌ Highly clustered objects (use Quadtree)
- ❌ Memory-constrained environments

### Quadtree

**How it works**: Hierarchical subdivision that adapts to object density.

**Best for**:

- Clustered object distributions
- Adaptive spatial partitioning
- Games with varying object densities
- Survival games with spawn waves

**Performance**:

- Add/Update/Remove: O(log n) average
- Query: O(k + log n) where k = found objects
- Memory: O(n) with good locality

**Configuration**:

```lua
local loc = locustron({
  strategy = "quadtree",
  config = {
    max_objects = 8,  -- Objects per node before subdividing
    max_depth = 6     -- Maximum subdivision levels
  }
})
```

**When to choose**:

- ✅ Games with clustered enemies (survival, horde modes)
- ✅ Procedurally generated content
- ✅ Scenes with varying object densities
- ✅ Need adaptive partitioning

**When to avoid**:

- ❌ Uniform object distributions (Fixed Grid is simpler)
- ❌ Very large worlds (Hash Grid for sparse areas)

### Hash Grid

**How it works**: Uses hash functions to map coordinates to cells, only allocating memory for occupied areas.

**Best for**:

- Large or infinite worlds
- Sparse object distributions
- Open world games
- Space/planetary simulations

**Performance**:

- Add/Update/Remove: O(1)
- Query: O(k) where k = objects in cell
- Memory: O(n) - only allocates for occupied cells

**Configuration**:

```lua
local loc = locustron({
  strategy = "hash_grid",
  config = {
    cell_size = 64   -- Can be larger for sparse worlds
  }
})
```

**When to choose**:

- ✅ Open world games
- ✅ Space simulations
- ✅ Large procedural worlds
- ✅ Memory efficiency is important

**When to avoid**:

- ❌ Small bounded worlds (Fixed Grid is simpler)
- ❌ Very dense object clusters

### BSP Tree

**How it works**: Binary space partitioning for hierarchical spatial relationships.

**Best for**:

- Complex spatial queries
- Ray casting applications
- Games needing precise spatial relationships
- Architectural/portal-based games

**Performance**:

- Add/Update/Remove: O(log n)
- Query: O(log n + k)
- Memory: O(n)

**Configuration**:

```lua
local loc = locustron({
  strategy = "bsp_tree",
  config = {
    split_threshold = 10  -- Objects before splitting
  }
})
```

**When to choose**:

- ✅ Ray casting games
- ✅ Complex spatial analysis
- ✅ Architectural visualization
- ✅ Precise collision detection

### BVH (Bounding Volume Hierarchy)

**How it works**: Tree structure using bounding volumes for efficient collision detection.

**Best for**:

- Dynamic objects with complex shapes
- Ray tracing applications
- Physics simulations
- Games with many moving objects

**Performance**:

- Add/Update/Remove: O(log n) with refitting
- Query: O(log n + k)
- Memory: O(n)

**Configuration**:

```lua
local loc = locustron({
  strategy = "bvh",
  config = {
    rebuild_frequency = 60  -- Rebuild every N frames
  }
})
```

**When to choose**:

- ✅ Physics-heavy games
- ✅ Ray tracing applications
- ✅ Complex collision shapes
- ✅ Highly dynamic scenes

## Decision Flowchart

``` markdown
Start: Analyze your game
    ↓
Does your game have a bounded world?
    ├─ Yes → Fixed Grid (simple) or Quadtree (adaptive)
    └─ No → Hash Grid (sparse) or BSP Tree (complex queries)
        ↓
    Are objects uniformly distributed?
        ├─ Yes → Fixed Grid
        └─ No → Quadtree
            ↓
        Need ray casting or complex queries?
            ├─ Yes → BSP Tree or BVH
            └─ No → Hash Grid
```

## Performance Comparison

### Small Bounded World (512x512, 100-1000 objects)

| Strategy | Add/Update | Query | Memory | Setup |
|----------|------------|-------|--------|-------|
| Fixed Grid | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Quadtree | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Hash Grid | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| BSP Tree | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| BVH | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

### Large Open World (Infinite, sparse objects)

| Strategy | Add/Update | Query | Memory | Setup |
|----------|------------|-------|--------|-------|
| Fixed Grid | ❌ | ❌ | ❌ | ⭐⭐⭐⭐⭐ |
| Quadtree | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| Hash Grid | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| BSP Tree | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| BVH | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

### Clustered Dynamic Objects (Survival game)

| Strategy | Add/Update | Query | Memory | Setup |
|----------|------------|-------|--------|-------|
| Fixed Grid | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Quadtree | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Hash Grid | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| BSP Tree | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| BVH | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

## Migration Guide

### From Fixed Grid to Quadtree

```lua
-- Before
local loc = locustron(32)

-- After
local loc = locustron({
  strategy = "quadtree",
  config = {max_objects = 8, max_depth = 6}
})
-- Same API calls work unchanged
```

### From Legacy to Strategy API

```lua
-- Legacy
local loc = locustron(32)

-- New strategy API
local loc = locustron({
  strategy = "fixed_grid",
  config = {cell_size = 32}
})
```

## Profiling Your Choice

Always profile to confirm your strategy choice:

```lua
-- Add profiling to your game loop
local start_time = os.clock()
-- ... perform spatial operations ...
local elapsed = os.clock() - start_time
print(string.format("Spatial ops: %.2fms", elapsed * 1000))
```

## Common Mistakes

1. **Using Fixed Grid for open worlds**: Leads to excessive memory usage
2. **Using Quadtree for uniform distributions**: Unnecessary complexity
3. **Not updating object positions**: Spatial structure becomes stale
4. **Choosing based on "latest"**: Choose based on your game's needs
5. **Not profiling**: Always measure performance in your specific use case

## Getting Help

- Check the [Performance Tuning Guide](performance-tuning.md) for optimization tips
- Review the [API Reference](../api/) for strategy-specific details
- Look at [Code Examples](../examples/) for real implementations
- Run benchmarks with your specific object patterns
