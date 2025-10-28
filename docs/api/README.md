# API Reference

This section contains complete API documentation for Locustron's spatial partitioning functionality.

## Overview

Locustron provides a unified API across all spatial partitioning strategies, with strategy-specific configuration options.

## Core Concepts

### Spatial Strategies

Locustron supports multiple spatial partitioning algorithms:

- **Fixed Grid**: Regular grid subdivision, optimal for uniform object distributions
- **Quadtree**: Hierarchical subdivision, adapts to object clustering
- **Hash Grid**: Sparse grid allocation, ideal for large worlds
- **BSP Tree**: Binary space partitioning for complex relationships
- **BVH**: Bounding volume hierarchies for dynamic objects

### Object Management

All strategies implement the same object lifecycle:

1. **Add** objects with bounding boxes
2. **Update** object positions/sizes
3. **Query** objects in regions
4. **Remove** objects when no longer needed

### Query Results

Queries return hash tables for O(1) membership testing:

```lua
local nearby = loc.query(x, y, w, h)
if nearby[some_object] then
  -- Object is in the query region
end
```

## API Structure

- [Core API](core-api.md) - Main Locustron functions and configuration
- [Fixed Grid](strategies/fixed-grid.md) - Fixed grid strategy documentation
- [Quadtree](strategies/quadtree.md) - Quadtree strategy documentation
- [Hash Grid](strategies/hash-grid.md) - Hash grid strategy documentation
- [BSP Tree](strategies/bsp-tree.md) - BSP tree strategy documentation
- [BVH](strategies/bvh.md) - BVH strategy documentation
- [Visualization](visualization.md) - Debug and visualization tools
