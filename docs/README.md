# Locustron Documentation

**Locustron** is a multi-strategy spatial partitioning library for efficient collision detection and spatial queries in Lua/Picotron games.

## Quick Start

```lua
-- Basic usage with fixed grid (default)
local loc = locustron(32)  -- 32-pixel grid cells

-- Add objects
local player = {id = "player", x = 100, y = 100}
loc.add(player, player.x, player.y, 16, 16)

-- Query nearby objects
local nearby = loc.query(80, 80, 40, 40)
for obj in pairs(nearby) do
  -- Handle nearby objects
end
```

## Documentation Sections

### 📚 [API Reference](api/)

Complete API documentation for all Locustron features.

- [Core API](api/core-api.md) - Main Locustron functions
- [Strategy APIs](api/strategies/) - Strategy-specific documentation
- [Visualization API](api/visualization.md) - Debug and visualization tools

### 🛠️ [User Guides](guides/)

Practical guides for using Locustron effectively.

- [Getting Started](guides/getting-started.md) - Quick start guide
- [Strategy Selection](guides/strategy-selection.md) - Choosing the right algorithm
- [Performance Tuning](guides/performance-tuning.md) - Optimization techniques
- [Migration Guide](guides/migration-guide.md) - Upgrading from older versions
- [Troubleshooting](guides/troubleshooting.md) - Common issues and solutions

### 🎓 [Tutorials](tutorials/)

Step-by-step tutorials teaching spatial partitioning concepts.

- [Basic Collision Detection](tutorials/basic-collision.md)
- [Viewport Culling](tutorials/viewport-culling.md)
- [Dynamic Objects](tutorials/dynamic-objects.md)
- [Advanced Queries](tutorials/advanced-queries.md)

### 💡 [Code Examples](examples/)

Complete game examples showcasing different strategies.

- [Survivor-like Game](examples/survivor-like.lua) - Wave-based survival with quadtree
- [Space Battle](examples/space-battle.lua) - Large world with hash grid
- [Platformer](examples/platformer.lua) - Bounded level with fixed grid
- [Dynamic Ecosystem](examples/dynamic-ecosystem.lua) - Birth/death lifecycle

### 📖 [Reference](reference/)

Technical reference materials and theory.

- [Spatial Partitioning Theory](reference/spatial-partitioning.md)
- [Performance Data](reference/performance-data.md)
- [Algorithm Comparison](reference/algorithm-comparison.md)

## Available Strategies

| Strategy | Best For | Performance | Memory |
|----------|----------|-------------|--------|
| **Fixed Grid** | Uniform objects, bounded worlds | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Quadtree** | Clustered objects, adaptive subdivision | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Hash Grid** | Large/sparse worlds | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **BSP Tree** | Complex spatial relationships | ⭐⭐⭐ | ⭐⭐⭐ |
| **BVH** | Dynamic objects, ray casting | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## Installation

### Picotron (Yotta Package)

```bash
> yotta add #locustron
> yotta apply
```

### Manual Installation

Copy `exports/locustron.lua` and `exports/require.lua` to your project.

## Basic Usage Patterns

### Strategy Selection

```lua
-- Explicit strategy selection
local loc = locustron({
  strategy = "quadtree",
  config = {max_objects = 8, max_depth = 6}
})

-- Legacy API (still supported)
local loc = locustron(32)  -- Fixed grid with 32px cells
```

### Object Management

```lua
-- Add object with bounding box
loc.add(object, x, y, width, height)

-- Update object position/size
loc.update(object, new_x, new_y, width, height)

-- Remove object
loc.remove(object)

-- Clear all objects
loc.clear()
```

### Spatial Queries

```lua
-- Query rectangular region
local nearby = loc.query(x, y, width, height)

-- Query with filter function
local enemies = loc.query(x, y, w, h, function(obj)
  return obj.type == "enemy"
end)

-- Iterate results
for obj in pairs(nearby) do
  -- Handle each nearby object
end
```

## Performance Tips

1. **Choose the right strategy** for your object distribution pattern
2. **Minimize query sizes** for better performance
3. **Batch updates** when possible
4. **Use filters** to reduce processing overhead
5. **Profile regularly** with the built-in benchmarking tools

## Contributing

Found an issue or want to contribute? See our [development roadmap](../ROADMAP.md) and [contributing guidelines](../CONTRIBUTING.md).

## License

Locustron is released under the MIT License. See [LICENSE](../LICENSE) for details.
