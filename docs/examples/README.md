# Code Examples

This directory contains complete, runnable examples demonstrating Locustron usage in different game scenarios.

## Available Examples

### 🎮 [Survivor-like Game](survivor-like.lua)

**Strategy**: Quadtree
**Scenario**: Wave-based survival game with clustered enemy spawning

Features:

- Dynamic enemy spawning in waves around player
- Quadtree spatial partitioning for efficient collision detection
- Lifespan-based enemy lifecycle management
- Performance visualization showing spatial partitioning benefits

**Best for**: Games with clustered object distributions, survival mechanics

### 🚀 [Space Battle](space-battle.lua)

**Strategy**: Hash Grid
**Scenario**: Large-scale space battle with many moving ships

Features:

- Large world with multiple objectives
- Hash grid for efficient sparse world management
- High object counts (150+ ships)
- Dynamic ship movement and collision detection

**Best for**: Open world games, large-scale simulations

### 🏃 [Platformer](platformer.lua)

**Strategy**: Fixed Grid
**Scenario**: Traditional platformer with collision detection

Features:

- Bounded level with platforms and player character
- Fixed grid for uniform spatial partitioning
- Platform collision and player physics
- Viewport culling for rendering optimization

**Best for**: Bounded worlds, uniform object distributions

### 🌱 [Dynamic Ecosystem](dynamic-ecosystem.lua)

**Strategy**: Quadtree
**Scenario**: Birth/death simulation with dynamic object lifecycle

Features:

- Organisms with lifespans and dynamic spawning
- Quadtree adaptation to changing object distributions
- Real-time population management
- Visual feedback showing spatial partitioning efficiency

**Best for**: Dynamic scenes, adaptive spatial partitioning

## Running Examples

### In Picotron

1. Load the Locustron cartridge
2. Include the desired example:

   ```lua
   include("examples/survivor-like.lua")
   ```

3. Run the cartridge

### Standalone Testing

Each example can be run independently to test specific strategies and scenarios.

## Strategy Comparison

| Example | Objects | World Size | Best Strategy | Performance Focus |
|---------|---------|------------|---------------|-------------------|
| Survivor-like | 200+ | Medium | Quadtree | Clustered objects |
| Space Battle | 150+ | Large | Hash Grid | Sparse world |
| Platformer | 10-20 | Small | Fixed Grid | Uniform distribution |
| Dynamic Ecosystem | 120+ | Medium | Quadtree | Adaptive partitioning |

## Learning Path

1. **Start here**: [Platformer](platformer.lua) - Simple bounded world
2. **Next**: [Survivor-like](survivor-like.lua) - Dynamic object management
3. **Advanced**: [Space Battle](space-battle.lua) - Large-scale optimization
4. **Complex**: [Dynamic Ecosystem](dynamic-ecosystem.lua) - Adaptive strategies

## Implementation Notes

### Common Patterns

All examples demonstrate these core patterns:

- **Object Registration**: Adding objects to spatial structures
- **Position Updates**: Keeping spatial data current during movement
- **Query Operations**: Using spatial queries for collision detection
- **Lifecycle Management**: Adding/removing objects dynamically

### Performance Monitoring

Each example includes debug visualization to show:

- Spatial partitioning structure
- Query efficiency
- Object distribution
- Performance metrics

### Strategy Selection

Examples are chosen to showcase optimal strategies for their use cases:

- Fixed Grid for predictable, uniform scenarios
- Quadtree for adaptive, clustered scenarios
- Hash Grid for sparse, large-world scenarios

## Contributing Examples

To add a new example:

1. Create a new `.lua` file in this directory
2. Follow the naming convention: `descriptive-name.lua`
3. Include comprehensive comments
4. Add debug/visualization features
5. Update this README with the new example
6. Test across different Picotron environments

## Example Structure

Each example follows this structure:

```lua
-- Example: Descriptive Title
-- Strategy: Strategy Name
-- Demonstrates: Key concepts

function init_example()
  -- Setup game state and spatial partitioning
end

function update_example(dt)
  -- Game logic and spatial operations
end

function draw_example()
  -- Rendering and debug visualization
end

-- Export functions for inclusion
return {
  init = init_example,
  update = update_example,
  draw = draw_example
}
```

This ensures examples are modular, well-documented, and easy to understand.
