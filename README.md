# Locustron

Locustron is a **multi-strategy spatial partitioning library** for efficient collision detection and spatial queries in Picotron. It provides multiple spatial partitioning algorithms optimized for different game scenarios. Locustron started as a port of [locus.p8](https://github.com/kikito/locus.p8). Locus.p8 could be considered as one of the strategies (fixed-grid) with a more complex and less token-friendly architecture, Locustron offers a comprehensive spatial partitioning framework with multiple algorithms. The fixed grid strategy of Locustron is not suitable for Pico-8, where locus.p8 remains the best solution for sparse grids.

**Key Features:**

- **Multiple Strategies**: Fixed Grid, Quadtree, Hash Grid, BSP Tree, Bounding Volume Hierarchy
- **Strategy Pattern**: Clean abstraction with pluggable algorithms
- **Picotron Optimized**: Userdata optimization and custom runtime features
- **Comprehensive Testing**: BDD-style tests with extensive coverage

Objects in locustron are represented by "axis-aligned bounding boxes", which we will refer to as "boxes". Objects are usually Lua tables representing game objects like enemies, bullets, coins, etc. They can be added, updated, and removed.

The library uses spatial partitioning algorithms to keep track of which objects "touch" each partition region.

This is useful in several scenarios:

- It can tell "Which objects are in a given rectangular section" quite efficiently
- This is useful for collision detection; instead of checking n-to-n interactions, locustron can be used to restrict the amount of objects to be checked, sometimes dramatically reducing the number of checks.
- Given that the query area is rectangular, locustron can be used to optimize the draw stage, by "only rendering objects that intersect with the screen"

## Demo Scenarios

[![locustron demo](https://www.lexaloffle.com/bbs/cposts/lo/locustron-0.p64.png)](https://www.lexaloffle.com/bbs/?tid=152310)

Locustron includes multiple interactive demo scenarios to showcase different spatial partitioning use cases and help you choose the optimal strategy for your game:

## Available Scenarios

| Scenario | Description | Optimal Strategy | Key Challenge |
|----------|-------------|------------------|---------------|
| **Survivor Like** | Wave-based survival with monsters spawning around player | Quadtree | Clustered objects, dynamic spawning |
| **Space Battle** | Large world with ships clustering around objectives | Hash Grid | Large world, sparse areas |
| **Platformer Level** | Bounded level with enemies on platforms | Fixed Grid | Uniform areas, bounded world |
| **Dynamic Ecosystem** | Living system with birth/death cycles | Quadtree | Changing distributions, object lifecycle |

## Running Demos

The demo can be easily run directly in Picotron through the BBS by doing `load #locustron` from the Picotron console.

- Controls:
- Tab: Switch between scenarios
- Z: Toggle debug UI
- X: Toggle debug visualization mode
- G/O/Q/P: Toggle grid/objects/queries/performance (in debug mode)
- +/-: Zoom in/out (in debug mode)
- Arrow keys: Pan viewport (in debug mode)

Each scenario demonstrates different spatial partitioning challenges and shows which strategy performs best for that use case.

## Performance Comparison

The demo scenarios help validate that different strategies excel in different situations:

- **Fixed Grid**: Best for uniform distributions (Platformer Level)
- **Quadtree**: Best for clustered/dynamic objects (Survivor Like, Dynamic Ecosystem)
- **Hash Grid**: Best for large sparse worlds (Space Battle)

## API

## Creating a locustron instance

``` lua
local loc=locustron([size])
```

Using `locustron(cell_size)` creates a spatial partitioning instance using the **Fixed Grid** strategy. This is the simplest and most memory-efficient strategy for uniform object distributions.

Parameters:

- `size`: An optional parameter that specifies the dimensions (width and height) of the squared cells inside this locustron instance. Defaults to `32` when not specified.

Return values:

- The newly created locustron instance, containing a spatial grid

It is recommended that the grid size is at least as big as one of the "typical" objects in a game, or a multiple of it. For Picotron this may be 16, 32, 64, or 128.

**Performance Note**: Grid size affects two competing factors:

- **Spatial precision**: Smaller grids (closer to object size) provide better spatial filtering with fewer false positives
- **Memory efficiency**: Larger grids reduce the number of cells and memory overhead

For optimal **query performance**, the ideal situation is that each cell contains 1 (and only 1) game object, minimizing false positives. However, for **memory efficiency** with many small objects, larger grid sizes can be beneficial.

The ideal situation balances these factors based on your game's needs:

- **High query frequency**: Use grid size ≈ object size (better spatial precision)
- **Memory constrained**: Use larger grid sizes (fewer cells, more objects per cell)
- **Many small objects**: Consider grid size 64-128 for efficiency

A too small size will make the cells not very efficient, because every object will appear in more than one cell grid.

Making the size too big will have the opposite problem: too many objects on a single grid cell, reducing spatial locality.

You can try experimenting with several sizes in order to arrive to the most optimal one for your game. The choice depends on whether you prioritize query precision (smaller grids) or memory efficiency (larger grids). For most Picotron games, sizes between 32-64 provide a good balance.

## Adding an object to an existing grid

``` lua
local object = loc:add(obj, x, y, w, h)
```

Parameters:

- `obj`: the object to be added (usually, a table representing a game object)
- `x,y`: The `left` and `top` coordinates of the axis-aligned bounding box containing the object
- `w,h`: The `width` and `height` of the axis-aligned bounding box containing the object

Return values:

- the object being added (same as `obj`)

Note that objects are *not* represented by "2 corners", but instead by a top-left corner plus width and height.

## Removing an object from locus

``` lua
local object= loc:remove(obj)
```

Parameters:

- `obj` the object to be removed from locus

Return values:

- the object being removed (same as `obj`)

Throws:

- The error `"unknown object"` if `obj` was not previously added to locus

Locus keeps (strong) references to the objects added to it. If you want to remove an object, you *must* call `remove`.

## Updating an object inside locus

``` lua
local object = loc:update(obj, x, y, w, h)
```

Parameters:

- `obj`: the object to be updated (usually, represented by a table)
- `x,y`: The `left` and`top` coordinates of the axis-aligned bounding box containing the object
- `w,h`: The `width` and `height` of the axis-aligned bounding box containing the object

Return values:

- the object being updated (same as `obj`)

Throws:

- The error `"unknown object"` if `obj` was not previously added to locus

## Querying an area for objects

``` lua
local objects = loc:query(x, y, w, h, [filter])
```

Parameters:

- `x,y`: The `left` and`top` coordinates of the axis-aligned rectangle being queried
- `w,h`: The `width` and `height` of the axis-aligned rectangle being queried
- `filter`: An optional function which can be used to "exclude" or include object from the result. `filter` is a function which takes an object as parameter and returns "truthy" when the object should be included in the result, or "falsy" to not include it. If no filter is specified locustron will include all objects it encounters on the rectangle

Return values:

- res: A table of the form `{ [obj1] = true, [obj2] = true}` containing all the objects whose boxes intersecting with the specified axis-aligned bounding box.

Notes:

- The table returned is *not ordered* in any way. You might need to sort it out in order for it to make sense in your game.
- The objects returned are *the objects contained in cells that touch the specified rectangle*. They are *not guaranteed to actually be intersecting with the given rectangle*. You might need an extra check in order to have this guarantee (see example with `rectintersect` in the FAQ section)

## Usage

## With yotta

Locustron can be installed in an existing cart with [Yotta](https://www.lexaloffle.com/bbs/?pid=143592#p):

### Install Yotta (one-time setup)

1. `> load #yotta -u` (load unsandboxed to access filesystem)
2. `> Ctrl+R` to run installer cartridge
3. `> Press X` to install yotta globally

### Install Locustron in your cart

1. `> cd /ram/cart`
2. `> yotta init`
3. `> yotta add #locustron`
4. `> yotta apply`

## Without yotta

You can also manually install locustron using one of these methods:

### From published cartridge (recommended for users)

Download the locustron cartridge from the BBS or directly in Picotron console with `load #locustron`

### From source repository (for developers)

`git clone` this repository

### Copying the files

1. Copy `src/locustron.lua` to your cart
2. Copy `src/require.lua` to your cart (if you don't have a require system)
3. Copy `src/strategies` folder to your cart
4. Copy `src/integration` folder to your cart

## Including

A [require lib](https://www.lexaloffle.com/bbs/?tid=140784) by [elgopher](https://www.lexaloffle.com/bbs/?uid=81157) is included, but you can use any require library.

## Example

``` lua
local Locustron = require("src/locustron") -- when installing with yotta locustron.lua resides in the lib/ folder

-- game objects
local coin = {}
local enemy = {}
local player = {}

-- filter function
function is_enemy(obj)
  return obj == enemy
end

-- create a grid with optimized cell size for small objects
-- (use benchmarks/benchmark_grid_tuning.lua to find optimal size for your objects)
local loc = Locustron.create(32)

-- add objects to the grid
loc:add(coin,   0,0,8,8)
loc:add(player, 10,10,8,8)
loc:add(enemy,  32,32,8,8)

-- move the player
loc:update(player, 20,10,8,8)

-- delete the coin
loc:remove(coin)

-- query all the visible objects
local visible = loc:query(0, 0, 128, 128)

-- you can then draw the objects by iterating like so:
for obj in pairs(visible) do
  -- call your draw functions like drawplayer(obj)
end

-- query only the visible enemies
local enemies = loc:query(0, 0, 128, 128, is_enemy)
```

See the contents of `main.lua` for a complete suite of demo scenarios.

## Preemptive FAQ

## What spatial partitioning pattern does Locustron use?

Locustron implements a **Fixed Grid** spatial partitioning as the default pattern, as described in [Game Programming Patterns](https://gameprogrammingpatterns.com/spatial-partition.html). This means:

- **Flat (Non-Hierarchical)**: Uses a single-level grid structure, not recursive subdivision like quadtrees
- **Object-Independent Partitioning**: Grid cell boundaries are fixed regardless of object positions  
- **Sparse Allocation**: Only creates cells when objects are present to save memory

**Other spatial partitioning patterns can be selected as the argument for `Locustron.create()` (see [API docs](docs/api/README.md))

## Can I use locustron to accelerate collision detection?

Yes. You can use the `query` method to get a "fast rough list of candidate objects for collision", and then apply a "more expensive collision detection algorithm" (like [hit.p8](https://github.com/kikito/hit.p8/tree/main) or [bump.lua](https://github.com/kikito/bump.lua/)) to use a more costly collision detection algorithm only to the list of candidates.

## Could you show me how to use it in combination with hit.p8?

Here's a partial example:

``` lua
local Locustron = require("locustron")
local loc = Locustron.create()
...

-- filter for only looking at enemies
function is_enemy(obj)
  ...
end

function createbullet(x,y)
  local b = {x = x, y = y, w = 3, h = 3}
  loc:add(b, b.x, b.y, b.w, b.h)
end

function updatebullet(b)
  -- note: bullet will move to nx,ny unless it finds an enemy
  local nx, ny = getnextposition(b)

  -- calculate the query box for the bullet moving towards nx,ny
  local l = b.x + b.vx + min(0, nx)
  local t = b.y + b.vy + min(0, ny)
  local w, h = b.w + abs(nx), b.h + abs(ny)
  
  -- check the querybox for enemies
  local first_e = nil
  local first_t = 32767 -- max integer
  
  for e in pairs(loc.query(l, t, w, h, is_enemy)) do
    local t = hit(b.x, b.y, b.w, b.h,
                  e.x, e.y, e.w, e.h,
                  b.x + dx, b.y + dy)
    -- we could hit several enemies in transit. We only want the first one (minimum t)
    if t and t < first_t then
      first_t = t
      first_e = e
    end
  end

  if first_e then
    -- collision with an enemy detected
    damageenemy(first_e, 1)
    loc:remove(b) -- destroy the bullet. Might need to remove it from other places besides loc
  else
    -- no collision. advance bullet
    b.x, b.y = nx, ny
    loc:update(b, b.x, b.y, b.w, b.h)
  end
end
```

## I don't need continuous collision detection in my game. Can I use locustron to accelerate simple (rectangle intersection-based) collision detection?

Yes. Here's an example using collision based on rectangle intersection:

```lua
local Locustron = require("locustron")
local loc = Locustron.create()
...

function createplayer(x, y)
  local p = {x = x, y = y, w = 8, h = 16}
  loc:add(p, p.x, p.y, p.w, p.h)
end

function rectintersect(x0, y0, w0, h0, x1, y1, w1, h1)
  return x0 + w0 >= x1 and x1 + w1 >= x0 and y0 + h0 >= y1 and y1 + h1 >= y0
end

function updateplayer(p)
  local nx, ny = getnextposition(p)
  p.x, p.y = nx, ny
  loc:update(p, p.x, p.y, p.w, p.h)

  for c in pairs(loc.query(p.x, p.y, p.w, p.h, is_coin)) do
    if rectintersect(p.x, p.y, p.w, p.h,
                     c.x, c.y, c.w, c.h) then
      score += 1
      loc:remove(c) -- delete coin. We might need to remove it from other places too
    end
  end
end
```

In this case, we immediately move the player to a new position and then use query on the new player's coordinates to detect coins that might be touching the player.

Notes:

- With this method, if the player is moving fast enough, they will "tunnel" through coins and other objects. With this method the velocity of the player must be limited, or we must split the movement into smaller step and do a check on every step. The method above (using hit.p8) does not have this problem
- Notice that eventhough we gave the player's bounding rectangle to `query`, we still need to call `rectintersect` to properly detect that a coin is actually intersecting with the player. This is because `query` will return the *objects that are on the cells that intersect with the given rectangle, but will not guarantee that the objects intersect the rectangle*. For example, on a grid of 32 pixels, the player might be touching 1 grid cell by only 1 pixel on the left, and a coin might be starting on pixel 22 from the left. That coin will still be returned by `query`, eventhough it is not touched by the player.
- `query` will return the objects in random order. There's no way to detect which coins get "touched" first. It is not important on this example, but it might be important in more complex games (e.g. if there's an enemy before the coins, then the player might get hurt and not pick up the coins). With hit.p8 you can know which objects go first (smaller `t`).

## Can locustron have rectangular (non-squared) grid cells?

Not at the moment. It could be added in the future.

## I am having trouble with locustron, it does not seem to work. How can I debug it?

You can visualize the spatial grid by drawing it on screen. Refer to the demo cartridge which has several custom functions (`draw_debug_overlay`, `draw_visualization_ui` and `draw_debug_info`) to visualize:

- Grid cell boundaries
- Object count per cell  
- Active vs empty cells
- Query count

For debugging specific issues:

- **Check grid size**: Use the benchmark to verify optimal grid size for your objects
- **Verify object lifecycle**: Ensure objects are added before being updated/deleted
- **Validate coordinates**: Check that bounding box coordinates are correct
- **Monitor memory usage**: Watch pool size to detect memory leaks
- **Test query precision**: Use benchmark precision metrics to understand false positive rates
