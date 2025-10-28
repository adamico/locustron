# Core API

The core Locustron API provides the main interface for spatial partitioning functionality.

## locustron(config)

Creates a new spatial partitioning instance.

### Parameters

- `config` (table|number): Configuration object or legacy cell size
  - When `number`: Legacy API using fixed grid with specified cell size
  - When `table`: Strategy configuration object

### Configuration Object

```lua
{
  strategy = "strategy_name",  -- "fixed_grid", "quadtree", "hash_grid", "bsp_tree", "bvh"
  config = {                   -- Strategy-specific configuration
    -- ... strategy options
  }
}
```

### Returns

- `table`: Locustron instance with spatial operations

### Examples

```lua
-- Legacy API (fixed grid)
local loc = locustron(32)

-- Strategy configuration
local loc = locustron({
  strategy = "quadtree",
  config = {
    max_objects = 8,
    max_depth = 6
  }
})
```

## Instance Methods

All Locustron instances provide the following methods:

### add(obj, x, y, w, h)

Adds an object to the spatial structure.

#### Add Parameters

- `obj` (any): Object reference to store
- `x` (number): Object x-coordinate
- `y` (number): Object y-coordinate
- `w` (number): Object width
- `h` (number): Object height

#### Add Returns

- `obj`: The added object reference

#### Add Example

```lua
local player = {id = "player", health = 100}
loc.add(player, 100, 150, 16, 32)
```

### update(obj, x, y, w, h)

Updates an object's position and/or size in the spatial structure.

#### Update Parameters

- `obj` (any): Object reference to update
- `x` (number): New x-coordinate
- `y` (number): New y-coordinate
- `w` (number): New width
- `h` (number): New height

#### Update Returns

- `obj`: The updated object reference

#### Update Example

```lua
-- Move player
player.x, player.y = 120, 160
loc.update(player, player.x, player.y, 16, 32)
```

### remove(obj)

Removes an object from the spatial structure.

#### Remove Parameters

- `obj` (any): Object reference to remove

#### Remove Returns

- `nil`

#### Remove Example

```lua
loc.remove(player)
```

### query(x, y, w, h, filter_fn)

Queries objects within a rectangular region.

#### Query Parameters

- `x` (number): Query region x-coordinate
- `y` (number): Query region y-coordinate
- `w` (number): Query region width
- `h` (number): Query region height
- `filter_fn` (function, optional): Filter function for results

#### Query Returns

- `table`: Hash table of objects `{[obj] = true}`

#### Query Examples

```lua
-- Basic query
local nearby = loc.query(100, 100, 50, 50)

-- Query with filter
local enemies = loc.query(100, 100, 50, 50, function(obj)
  return obj.type == "enemy"
end)

-- Iterate results
for obj in pairs(nearby) do
  print("Found object:", obj.id)
end
```

### clear()

Removes all objects from the spatial structure.

#### Clear Returns

- `nil`

#### Clear Example

```lua
loc.clear()  -- Remove all objects
```

## Strategy Information

### get_strategy_info()

Returns information about the current strategy.

#### Info Returns

- `table`: Strategy information
  - `name` (string): Strategy name
  - `config` (table): Current configuration
  - `statistics` (table): Usage statistics

#### Info Example

```lua
local info = loc.get_strategy_info()
print("Strategy:", info.name)
print("Object count:", info.statistics.object_count)
```

## Error Handling

Locustron uses Lua's error() function for contract violations:

- Adding the same object twice
- Updating/removing unknown objects
- Invalid configuration parameters

```lua
-- These will throw errors:
loc.add(obj, 0, 0, 0, 0)  -- Zero-sized object
loc.update(unknown_obj, 0, 0, 16, 16)  -- Unknown object
```

## Performance Notes

- **Add/Update/Remove**: O(1) for most strategies
- **Query**: O(k) where k is objects in query region
- **Memory**: Varies by strategy and object count
- **Strategy Selection**: Choose based on your game's object distribution patterns
