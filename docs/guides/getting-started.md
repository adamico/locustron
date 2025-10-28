# Getting Started with Locustron

Welcome to Locustron! This guide will help you get up and running with spatial partitioning in your Lua/Picotron games.

## What is Spatial Partitioning?

Spatial partitioning is a technique that organizes objects in space to make collision detection, proximity queries, and rendering more efficient. Instead of checking every object against every other object (O(n²)), spatial partitioning reduces this to checking only nearby objects.

## Installation

### Picotron (Recommended)

Locustron is distributed as a Picotron cartridge via Yotta:

```bash
> yotta add #locustron
> yotta apply
```

Then in your code:

```lua
include("lib/locustron/locustron")
```

### Manual Installation

Copy these files to your project:

- `exports/locustron.lua`
- `exports/require.lua`

## Your First Spatial Partition

Let's start with the basics:

```lua
-- Create a spatial partition (fixed grid with 32px cells)
local loc = locustron(32)

-- Create some objects
local player = {id = "player", x = 100, y = 100, w = 16, h = 16}
local enemy1 = {id = "enemy1", x = 150, y = 120, w = 16, h = 16}
local enemy2 = {id = "enemy2", x = 200, y = 80, w = 16, h = 16}

-- Add objects to the spatial structure
loc.add(player, player.x, player.y, player.w, player.h)
loc.add(enemy1, enemy1.x, enemy1.y, enemy1.w, enemy1.h)
loc.add(enemy2, enemy2.x, enemy2.y, enemy2.w, enemy2.h)

-- Query objects near the player
local nearby = loc.query(player.x - 50, player.y - 50, 100, 100)

print("Objects near player:")
for obj in pairs(nearby) do
  print("  " .. obj.id .. " at (" .. obj.x .. ", " .. obj.y .. ")")
end
```

## Understanding the Results

The `query()` method returns a hash table where the keys are the objects found in the query region. This allows for O(1) membership testing:

```lua
if nearby[enemy1] then
  print("Enemy1 is nearby!")
end
```

## Moving Objects

When objects move, update their position in the spatial structure:

```lua
function move_object(loc, obj, new_x, new_y)
  obj.x, obj.y = new_x, new_y
  loc.update(obj, obj.x, obj.y, obj.w, obj.h)
end

-- Move the player
move_object(loc, player, 120, 110)
```

## Collision Detection Pattern

Here's a complete collision detection system:

```lua
function check_collisions(loc, obj)
  -- Query area around the object
  local nearby = loc.query(
    obj.x - obj.w/2, obj.y - obj.h/2,  -- Center the query
    obj.w * 2, obj.h * 2               -- Query size
  )

  -- Check precise collisions
  for other in pairs(nearby) do
    if other ~= obj and objects_collide(obj, other) then
      handle_collision(obj, other)
    end
  end
end

function objects_collide(a, b)
  -- Simple AABB collision detection
  return a.x < b.x + b.w and
         a.x + a.w > b.x and
         a.y < b.y + b.h and
         a.y + a.h > b.y
end
```

## Choosing a Strategy

Locustron supports multiple spatial partitioning strategies:

### Fixed Grid (Default)

Best for uniform object distributions and bounded worlds:

```lua
local loc = locustron({
  strategy = "fixed_grid",
  config = {cell_size = 32}
})
```

### Quadtree

Best for clustered objects and adaptive subdivision:

```lua
local loc = locustron({
  strategy = "quadtree",
  config = {
    max_objects = 8,  -- Max objects per node
    max_depth = 6     -- Maximum tree depth
  }
})
```

### Hash Grid

Best for large, sparse worlds:

```lua
local loc = locustron({
  strategy = "hash_grid",
  config = {cell_size = 64}
})
```

## Common Patterns

### Player-Centric Game Loop

```lua
function game_update(dt)
  -- Update player
  update_player(player, dt)

  -- Update player in spatial structure
  loc.update(player, player.x, player.y, player.w, player.h)

  -- Check collisions for player
  check_collisions(loc, player)

  -- Update enemies
  for _, enemy in ipairs(enemies) do
    update_enemy(enemy, dt, player)
    loc.update(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
    check_collisions(loc, enemy)
  end
end
```

### Viewport Culling

```lua
function render_game(camera)
  -- Only render objects in viewport
  local visible = loc.query(
    camera.x, camera.y,
    camera.width, camera.height
  )

  for obj in pairs(visible) do
    draw_object(obj)
  end
end
```

## Performance Tips

1. **Choose the right cell/query size**: Match your typical object sizes
2. **Update objects when they move**: Keep the spatial structure current
3. **Use filters for complex queries**: Reduce processing overhead
4. **Profile your usage patterns**: Different strategies work better for different scenarios

## Next Steps

- Read the [Strategy Selection Guide](strategy-selection.md) to choose the best algorithm
- Check out the [API Reference](../api/) for detailed method documentation
- Look at the [Code Examples](../examples/) for complete game implementations
- Run the [Tutorials](../tutorials/) for step-by-step learning

## Troubleshooting

### Common Issues

**"Object not found" errors**: Make sure to add objects before updating/removing them.

**Poor performance**: Try a different strategy or adjust cell sizes.

**Memory issues**: Reduce cell sizes or use a sparser strategy.

### Getting Help

- Check the [Troubleshooting Guide](troubleshooting.md)
- Review the [Performance Tuning Guide](performance-tuning.md)
- Look at existing issues and discussions

Happy coding with Locustron! 🚀
