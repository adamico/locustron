# Locustron

Locustron is a *Two-dimensional*, *unbounded*, *sparse*, *efficient*, *grid* spatial hash for Picotron.
This is a port of [locus.p8](https://github.com/kikito/locus.p8) for Picotron, with userdata optimizations and object pooling to minimize garbage collection.

* Two-Dimensional: The cell grids are squared, and organized in rows and columns.
* Spatial Hash: Locustron can be used to *store* objects on it, potentially moving them around, and then *making queries* related with where those objects are.
* Unbounded: A locustron grid does not need any initial/final dimensions. It grows or shrinks depending on the objects it contains.
* Sparse: Cells inside the grid are allocated only when they contain an object. Otherwise they are recycled.
* Efficient: Locustron uses userdata for cell storage and standard Lua tables for query results to minimize garbage collection

Objects in locustron are represented by "axis-aligned bounding boxes", which we will refer to as "boxes". Objects are usually Lua tables representing game objects like enemies, bullets, coins, etc. They can be added, updated, and removed.

**Object Capacity**: Locustron can handle up to **10,000 simultaneous objects** due to its userdata-optimized storage system. This limit provides excellent performance for typical Picotron games while maintaining memory efficiency.

The library uses a grid of squared cells and keeps track of which objects "touch" each cell.

This is useful in several scenarios:
* It can tell "Which objects are in a given rectangular section" quite efficiently
* This is useful for collision detection; instead of checking n-to-n interactions, locustron can be used to restrict the amount of objects to be checked, sometimes dramatically reducing the number of checks.
* Given that the query area is rectangular, locustron can be used to optimize the draw stage, by "only rendering objects that intersect with the screen"


[![locustron demo](https://www.lexaloffle.com/bbs/cposts/lo/locustron-0.p64.png)](https://www.lexaloffle.com/bbs/?tid=152310)

# API

## Creating a locustron instance

``` lua
local loc=locustron([size])
```
Parameters:
- `size`: An optional parameter that specifies the dimensions (width and height) of the squared cells inside this locustron instance. Defaults to `32` when not specified.

Return values:
- `loc`: The newly created locustron instance, containing a spatial grid

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


## Adding an object to an existing grid:

``` lua
local o=loc.add(obj,x,y,w,h)
```
Parameters:
- `obj`: the object to be added (usually, a table representing a game object)
- `x,y`: The `left` and `top` coordinates of the axis-aligned bounding box containing the object
- `w,h`: The `width` and `height` of the axis-aligned bounding box containing the object

Return values:
- `o`: the object being added (same as `obj`)

Note that objects are *not* represented by "2 corners", but instead by a top-left corner plus width and height.

## Removing an object from locus:

``` lua
local o=loc.del(obj)
```
Parameters:
- `obj` the object to be removed from locus

Return values:
- `o`: the object being removed (same as `obj`)

Throws:
- The error `"unknown object"` if `obj` was not previously added to locus

Locus keeps (strong) references to the objects added to it. If you want to remove an object, you *must* call `del`.


## Updating an object inside locus:

``` lua
local o=loc.update(obj,x,y,w,h)
```
Parameters:
- `obj`: the object to be updated (usually, represented by a table)
- `x,y`: The `left` and`top` coordinates of the axis-aligned bounding box containing the object
- `w,h`: The `width` and `height` of the axis-aligned bounding box containing the object

Return values:
- `o`: the object being updated (same as `obj`)

Throws:
- The error `"unknown object"` if `obj` was not previously added to locus

## Querying an area for objects:

``` lua
local res=loc.query(x,y,w,h,[filter])
```
Parameters:
- `x,y`: The `left` and`top` coordinates of the axis-aligned rectangle being queried
- `w,h`: The `width` and `height` of the axis-aligned rectangle being queried
- `filter`: An optional function which can be used to "exclude" or include object from the result. `filter` is a function which takes an object as parameter and returns "truthy" when the object should be included in the result, or "falsy" to not include it. If no filter is specified `locus` will include all objects it encounters on the rectangle

Return values:
- res: A table of the form `{[obj1]=true, [obj2]=true}` containing all the objects whose boxes intersecting with the specified axis-aligned bounding box.

Notes:
- The table returned is *not ordered* in any way. You might need to sort it out in order for it to make sense in your game.
- The objects returned are *the objects contained in cells that touch the specified rectangle*. They are *not guaranteed to actually be intersecting with the given rectangle*. You might need an extra check in order to have this guarantee (see example with `rectintersect` in the FAQ section)


# Usage

## With yotta
The lib can be installed in an existing cart with [Yotta](https://www.lexaloffle.com/bbs/?pid=143592#p):

1. `> cd /ram/cart`
2. `> yotta init`
3. `> yotta add #locustron`
4. `> yotta apply`


## Without yotta
You can also save locustron to a single file (locustron.lua).

## Including
A [require lib](https://www.lexaloffle.com/bbs/?tid=140784) by [elgopher](https://www.lexaloffle.com/bbs/?uid=81157) is included, but you can use any require library.

## Development Setup

### Git Commit Message Enforcement

This repository uses [Conventional Commits](https://www.conventionalcommits.org/) for consistent commit messages. To enable automatic validation of your commit messages:

```bash
# After cloning the repository, enable the commit-msg hook:
chmod +x .git/hooks/commit-msg
```

This will enforce the following commit message format:
```
<type>[optional scope]: <description>
```

**Valid commit types:**
- `feat` - A new feature
- `fix` - A bug fix  
- `docs` - Documentation changes
- `test` - Adding or updating tests
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `chore` - Build process or auxiliary tool changes

**Examples:**
```bash
git commit -m "feat(locustron): add spatial hash optimization"
git commit -m "fix(tests): handle unknown object error in delete tests"  
git commit -m "docs: update README with setup instructions"
```

If your commit message doesn't follow this format, the commit will be rejected with helpful guidance.
``` lua
local locustron = require("lib/locustron")
```

# Example

``` lua
local locus = require("lib/locus")

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
local loc = locus(128)

-- add objects to the grid
loc.add(coin,   0,0,8,8)
loc.add(player, 10,10,8,8)
loc.add(enemy,  32,32,8,8)

-- move the player
loc.update(player, 20,10,8,8)

-- delete the coin
loc.del(coin)

-- query all the visible objects
local visible = loc.query(0,0,128,128)

-- you can then draw the objects by iterating like so:
for obj in pairs(visible) do
  -- call your draw functions like drawplayer(obj)
end

-- query only the visible enemies
local enemies = loc.query(0,0,128,128,is_enemy)
```

See `locustron_demo.lua` for a complete interactive example with moving objects and our comprehensive benchmark suite for performance analysis tools:

- `benchmarks/benchmark_grid_tuning.lua` - Grid size optimization for different object sizes
- `benchmarks/benchmark_userdata_performance.lua` - Absolute performance measurements  
- `benchmarks/run_all_benchmarks.lua` - Complete benchmark suite runner 


# Performance

Locustron is designed for high performance with thousands of objects. Based on comprehensive benchmarking with our userdata implementation:

## Performance Characteristics

- **Add operations**: ~0.001ms per object (11ms for 10,000 objects)
- **Query operations**: ~0.013ms per query (13ms for 1,000 queries)
- **Update operations**: Very fast when objects don't cross cell boundaries
- **Memory usage**: Object pooling minimizes garbage collection

## Grid Size Impact

Grid size dramatically affects performance efficiency:

| Grid Size | Objects/Cell | Efficiency | Use Case |
|-----------|--------------|------------|-----------|
| 32        | 1.87         | 2.6%       | Default (legacy) |
| 64        | 4.14         | 7.1%       | Medium objects |
| **128**   | **13.00**    | **25.0%**  | **Small objects (recommended)** |

**Key Finding**: Grid size 128 provides ~10x better efficiency than the default 32 for typical game objects.

## Memory Management

- **Object pooling**: Tables are recycled to minimize GC pressure
- **Sparse allocation**: Grid cells created only when needed
- **Pool behavior**: Queries act as "pool sink", balancing memory usage
- **Stable memory**: Pool size stabilizes after initial allocation phase

## Scaling

Locustron handles object density well:
- **Linear scaling**: Performance remains consistent as object count increases
- **Spatial locality**: Query performance depends on result size, not total objects
- **Viewport culling**: Excellent for rendering optimization

# Benchmarking & Testing

## Compact Benchmark Suite

Locustron includes a comprehensive benchmark tool to help you choose optimal grid sizes for your specific game objects and usage patterns.

### Running Benchmarks

**Running Grid Tuning Benchmark:**
```lua
include("benchmarks/benchmark_grid_tuning.lua")
```

### Benchmark Output

The benchmark tests different grid sizes against various object sizes and provides clear recommendations:

```
OBJECT SIZE: small (8x8)
Grid | Cells | Obj/Cell | Precision | Recommendation
-----|-------|----------|-----------|---------------
  16 |    25 |      2.0 |     85.2% | EXCELLENT
  32 |     9 |      5.6 |     72.1% | GOOD/MEM+
  64 |     4 |     12.5 |     45.8% | OK/MEM+
 128 |     1 |     50.0 |     22.3% | POOR/MEM+
```

### Understanding Results

- **Grid**: Grid cell size being tested
- **Cells**: Number of allocated grid cells (lower = more memory efficient)
- **Obj/Cell**: Average objects per cell (higher = denser packing)
- **Precision**: Percentage of query results that are actual hits (higher = fewer false positives)
- **Recommendation**: 
  - **EXCELLENT/GOOD/OK/POOR**: Based on query precision
  - **MEM+**: Memory efficient (few cells)
  - **MEM-**: Memory intensive (many cells)

### Choosing Grid Size

The benchmark helps you decide between two optimization strategies:

**For Query Performance (High Precision)**
- Choose grid sizes close to your object size
- Results in more cells but better spatial filtering
- Fewer false positives requiring `rectintersect()` checks
- Best for games with frequent collision detection

**For Memory Efficiency**
- Choose larger grid sizes (2-4x object size)
- Results in fewer cells but more false positives
- Better for memory-constrained games
- Best when queries are infrequent

### Interactive Testing

The included `locustron_demo.lua` provides interactive visualization:

```lua
-- Visual debugging with draw_locus() function
-- Shows grid cells, object counts, and spatial distribution
-- Helps validate benchmark results with real object movement
```

## Performance Testing Guidelines

1. **Test with your actual object sizes**: The benchmark includes tiny (4x4), small (8x8), medium (16x16), and large (32x32) objects
2. **Consider your query patterns**: Frequent queries favor precision, rare queries favor memory efficiency
3. **Monitor in real gameplay**: Use the visual debugging tools during actual game sessions
4. **Validate with profiling**: Check that chosen grid size works well under game load

# Preemptive FAQ

## What spatial partitioning pattern does Locustron use?

Locustron implements a **Fixed Grid** spatial partitioning pattern, as described in [Game Programming Patterns](https://gameprogrammingpatterns.com/spatial-partition.html). This means:

- **Flat (Non-Hierarchical)**: Uses a single-level grid structure, not recursive subdivision like quadtrees
- **Object-Independent Partitioning**: Grid cell boundaries are fixed regardless of object positions  
- **Sparse Allocation**: Only creates cells when objects are present to save memory

**Comparison to other spatial partitioning patterns:**
- **vs Quadtrees/Octrees**: Simpler implementation, constant memory usage, faster updates, but can be imbalanced with clustered objects
- **vs BSP/k-d trees**: No tree traversal overhead, easier to understand, but less adaptive to object distribution
- **vs Bounding Volume Hierarchies**: Better for dynamic objects that move frequently, simpler memory management

**Why Fixed Grid for Locustron:**
- ✅ **Simple**: Straightforward 2D grid structure easy to debug and optimize
- ✅ **Fast updates**: Moving objects between cells is a simple operation
- ✅ **Predictable performance**: No tree rebalancing or complex subdivision logic
- ✅ **Memory efficient**: Sparse allocation only creates cells when needed
- ✅ **Picotron optimized**: Works well with userdata and Picotron's constraints

The trade-off is that performance can degrade if objects cluster heavily in one area, but the benchmarking tools help you choose optimal grid sizes to minimize this issue.

## How does it work?

Internally, locustron has a sparse list of "rows" (representing the `y` axis). Each row can have one or more cells (on the `x` axis).

locustron also "remembers" all of the bounding boxes it has seen in a separate table called `boxes`. `boxes` contains one axis-aligned-bounding-box per object added to locustron.

Finally, there is also an internal "table pool". When a table is no longer needed (cell depleted of objects, row doesn't have any cells left, box for object which was removed) the tables are added to the pool table instead of being garbage collected. Then the tables can be reused for other purposes, minimizing garbage collection.

While the other methods are "symmetric" with regards to pool usage (`add` takes objects from the pool, `del` adds objects to the pool, `update` adds and removes) the `query` method isn't. It acts as a "pool sink", only taking tables from the pool. This ensures that the pool won't grow too much as long as `query` is used from time to time.

## Why does `query` return a table? Wouldn't it be more efficient to use a callback, or an iterator?

Objects in locustron, even small ones, can touch multiple cells as they move. As a result, while querying the cells, we might encounter the same object more than once. The only way to detect this by introducing a `visited` table, which contains the already visited objects. A callback or an iterator would need to be built *on top* of that `visited` table in order to avoid calling the same callback multiple times for the same object. I think this will be undesirable more often than not. So `query` just returns the `visited` table, which is used internally *also* to avoid duplicated objects in the results.

## When should I *not* use locustron?

There's several reasons not to use locustron:

* Your game world is fixed in size and densely populated. In this case a non-sparse grid will make more sense; the code will be smaller and faster since it doesn't have to deal with sparse data. Since the world is densely populated, you don't have zones without objects, where locustron could save up memory.
* Your objects can not be represented properly by axis-aligned bounding boxes. Perhaps you have very long, very thin objects that are often "arranged diagonally". This is the worst case scenario for using locustron. You might need a different hash map entirely.
* Your world is already extremely sparse. The main advantage of using locustron is that it allows for very fast local queries in an area. If your game has very few interactive objects, it might be simpler to just check all of the objects on every frame. (Take into account that tiles with collision do count as "game objects")

## Can I use locustron to accelerate collision detection?

Yes. You can use the `query` method to get a "fast rough list of candidate objects for collision", and then apply a "more expensive collision detection algorithm" (like [hit.p8](https://github.com/kikito/hit.p8/tree/main)) to use a more costly collision detection algorithm only to the list of candidates.

## Could you show me how to use it in combination with hit.p8?

Here's a partial example:


``` lua
local locustron = require("lib/locustron")
local loc = locustron()
...

-- filter for only looking at enemies
function is_enemy(obj)
  ...
end

function createbullet(x,y)
  local b = {x = x, y = y, w = 3, h = 3}
  loc.add(b, b.x, b.y, b.w, b.h)
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
    loc.del(b) -- destroy the bullet. Might need to remove it from other places besides loc
  else
    -- no collision. advance bullet
    b.x, b.y = nx, ny
    loc.update(b, b.x, b.y, b.w, b.h)
  end
end
```

## I don't need continuous collision detection in my game. Can I use locustron to accelerate simple (rectangle intersection-based) collision detection?

Yes, `hit` and `locustron` can be used separately and they don't need each other to work. Here's an example using collision based on rectangle intersection:

```lua
local locustron = require("lib/locustron")
local loc = locustron()
...

function createplayer(x, y)
  local p = {x = x, y = y, w = 8, h = 16}
  loc.add(p, p.x, p.y, p.w, p.h)
end

function rectintersect(x0, y0, w0, h0, x1, y1, w1, h1)
  return x0 + w0 >= x1 and x1 + w1 >= x0 and y0 + h0 >= y1 and y1 + h1 >= y0
end

function updateplayer(p)
  local nx, ny = getnextposition(p)
  p.x, p.y = nx, ny
  loc.update(p, p.x, p.y, p.w, p.h)

  for c in pairs(loc.query(p.x, p.y, p.w, p.h, is_coin)) do
    if rectintersect(p.x, p.y, p.w, p.h,
                     c.x, c.y, c.w, c.h) then
      score += 1
      loc.del(c) -- delete coin. We might need to remove it from other places too
    end
  end
end
```

In this case, we immediately move the player to a new position and then use query on the new player's coordinates to detect coins that might be touching the player.

Notes:
* With this method, if the player is moving fast enough, they will "tunnel" through coins and other objects. With this method the velocity of the player must be limited, or we must split the movement into smaller step and do a check on every step. The method above (using hit.p8) does not have this problem
* Notice that eventhough we gave the player's bounding rectangle to `query`, we still need to call `rectintersect` to properly detect that a coin is actually intersecting with the player. This is because `query` will return the *objects that are on the cells that intersect with the given rectangle, but will not guarantee that the objects intersect the rectangle*. For example, on a grid of 32 pixels, the player might be touching 1 grid cell by only 1 pixel on the left, and a coin might be starting on pixel 22 from the left. That coin will still be returned by `query`, eventhough it is not touched by the player.
* `query` will return the objects in random order. There's no way to detect which coins get "touched" first. It is not important on this example, but it might be important in more complex games (e.g. if there's an enemy before the coins, then the player might get hurt and not pick up the coins). With hit.p8 you can know which objects go first (smaller `t`).

## Is Locustron optimized for Picotron?

Yes! Locustron is specifically designed for Picotron with several optimizations:

- **Userdata storage**: Uses Picotron's userdata for efficient cell storage and reduced garbage collection
- **Standard query format**: Returns `{[obj]=true}` hash tables for maximum compatibility
- **Custom require system**: Includes error handling via `send_message()` for Picotron
- **Performance profiling**: Includes benchmarking tools adapted for Picotron's timer resolution
- **10,000 object capacity**: Handles large numbers of objects efficiently within Picotron's constraints
- **Comprehensive testing**: Full unit test suite using unitron framework with 18 test cases

The library handles thousands of objects efficiently while staying within Picotron's resource constraints and provides excellent performance for typical game scenarios.

## Can locustron have rectangular (non-squared) grid cells?

No, only squared grid cells are supported. It would be very easy to add support for rectangular cells, but it would cost some tokens that I didn't want to spend. Feel free to fork and add support for that if you need to.
 
## I am having trouble with locustron, it does not seem to work. How can I debug it?

You can visualize the spatial grid by drawing it on screen. The included `locustron_demo.lua` file has an example function (`draw_locus`) which shows:

- Grid cell boundaries
- Object count per cell  
- Active vs empty cells
- Pool size for memory debugging

You can also run the included benchmark in the Picotron console to analyze performance and validate your grid size choice:

```lua
include("benchmarks/benchmark_grid_tuning.lua")
-- This will show grid efficiency analysis and query precision metrics
```

For debugging specific issues:
- **Check grid size**: Use the benchmark to verify optimal grid size for your objects
- **Verify object lifecycle**: Ensure objects are added before being updated/deleted
- **Validate coordinates**: Check that bounding box coordinates are correct
- **Monitor memory usage**: Watch pool size to detect memory leaks
- **Test query precision**: Use benchmark precision metrics to understand false positive rates

## Testing

Locustron includes a comprehensive unit test suite using the unitron framework:

```
tests/test_locustron_unit.lua    -- 20 test cases covering all functionality
```

**Running Tests**: Drag and drop `tests/test_locustron_unit.lua` into the unitron window in Picotron to run the full test suite.

**Test Coverage**:
- Object creation and lifecycle (add, update, delete)
- Query functionality (single objects, multiple objects, filtering)
- Grid coordinate calculations and boundary handling
- Memory management and pool usage
- Edge cases (zero-size objects, negative coordinates)
- Performance characteristics (deduplication, large objects)

All tests are currently passing, ensuring the library's reliability and correctness.
