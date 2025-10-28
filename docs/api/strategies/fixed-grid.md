# Fixed Grid Strategy

The Fixed Grid strategy divides space into a regular grid of fixed-size cells. It provides optimal performance for uniform object distributions and bounded worlds.

## Overview

Fixed Grid is the default strategy and works by dividing the game world into a regular grid of equally-sized cells. Each object is stored in the cells that its bounding box overlaps.

## Configuration

```lua
local loc = locustron({
  strategy = "fixed_grid",
  config = {
    cell_size = 32,           -- Grid cell size in pixels (default: 32)
    initial_capacity = 100,   -- Initial object capacity per cell (default: 100)
    growth_factor = 1.5       -- Capacity growth multiplier (default: 1.5)
  }
})
```

### Configuration Options

- **`cell_size`** (number): Size of each grid cell in pixels
  - Smaller cells: More precise, higher memory usage
  - Larger cells: Less precise, lower memory usage
  - Recommended: Match typical object size

- **`initial_capacity`** (number): Initial capacity for object storage per cell
  - Higher values: Less reallocations, more memory usage
  - Lower values: More reallocations, less memory usage

- **`growth_factor`** (number): Multiplier for capacity growth when full
  - Typical values: 1.5-2.0

## Performance Characteristics

- **Time Complexity**:
  - Add/Update/Remove: O(1)
  - Query: O(k) where k is objects in overlapping cells

- **Memory Usage**: O(n + c) where n is object count and c is active cell count

- **Best Use Cases**:
  - Uniform object distributions
  - Bounded game worlds
  - Objects of similar sizes
  - Static or slowly moving objects

## Usage Examples

### Basic Setup

```lua
-- Create fixed grid with 32px cells
local loc = locustron({
  strategy = "fixed_grid",
  config = {cell_size = 32}
})

-- Add objects
for i = 1, 100 do
  local obj = {id = i, x = math.random(0, 800), y = math.random(0, 600)}
  loc.add(obj, obj.x, obj.y, 16, 16)
end
```

### Collision Detection

```lua
function check_collisions(loc, player)
  -- Query area around player
  local nearby = loc.query(
    player.x - 32, player.y - 32,  -- Query position
    64, 64                        -- Query size (player size + buffer)
  )

  -- Check precise collisions
  for obj in pairs(nearby) do
    if obj ~= player and rects_overlap(player, obj) then
      handle_collision(player, obj)
    end
  end
end
```

### Viewport Culling

```lua
function render_visible_objects(loc, camera)
  -- Query only objects in viewport
  local visible = loc.query(
    camera.x, camera.y,
    camera.width, camera.height
  )

  -- Render visible objects
  for obj in pairs(visible) do
    draw_object(obj)
  end
end
```

## Best Practices

### Cell Size Selection

Choose cell size based on your game's characteristics:

| Scenario | Recommended Cell Size | Rationale |
|----------|----------------------|-----------|
| Small objects (8-16px) | 16-32px | Match object size for optimal queries |
| Medium objects (16-32px) | 32-64px | Balance precision and memory |
| Large objects (32-64px) | 64-128px | Reduce cell count for large objects |
| Mixed sizes | 32px | Compromise for varied object sizes |

### Memory Optimization

```lua
-- For memory-constrained environments
local loc = locustron({
  strategy = "fixed_grid",
  config = {
    cell_size = 64,           -- Larger cells = fewer cells
    initial_capacity = 50,    -- Smaller initial capacity
    growth_factor = 1.25      -- Conservative growth
  }
})
```

### Query Optimization

```lua
-- Prefer smaller, focused queries
local nearby = loc.query(x - 50, y - 50, 100, 100)  -- Good

-- Avoid large queries when possible
local all_nearby = loc.query(0, 0, 800, 600)        -- Less efficient
```

## Common Patterns

### Player-Centric Queries

```lua
function update_player_awareness(loc, player, awareness_radius)
  local aware = loc.query(
    player.x - awareness_radius,
    player.y - awareness_radius,
    awareness_radius * 2,
    awareness_radius * 2
  )

  for obj in pairs(aware) do
    if obj.type == "enemy" then
      -- Enemy becomes aware of player
      obj.target = player
    end
  end
end
```

### Spatial Partitioning for Physics

```lua
function broad_phase_collision(loc)
  local potential_collisions = {}

  -- Fixed grid handles broad phase automatically
  -- Just query reasonable regions for narrow phase

  for _, obj in ipairs(dynamic_objects) do
    local nearby = loc.query(
      obj.x - obj.width, obj.y - obj.height,
      obj.width * 3, obj.height * 3
    )

    for other in pairs(nearby) do
      if obj ~= other and can_collide(obj, other) then
        table.insert(potential_collisions, {obj, other})
      end
    end
  end

  return potential_collisions
end
```

## Limitations

- **Memory Usage**: Creates cells for entire world bounds
- **Sparse Worlds**: Wastes memory in empty areas
- **Dynamic Cell Sizes**: Cannot adapt cell size per region
- **Non-Uniform Distributions**: Less efficient for clustered objects

## When to Use Fixed Grid

✅ **Good for:**

- Platformers with bounded levels
- RTS games with uniform unit distributions
- Puzzle games with regular object placement
- Games with similar-sized objects
- Memory is not a major constraint

❌ **Not ideal for:**

- Large open worlds (use Hash Grid)
- Clustered object distributions (use Quadtree)
- Highly dynamic scenes (consider BVH)
- Memory-constrained environments (optimize cell size)
