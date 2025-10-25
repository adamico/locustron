# Locustron Copilot Instructions

## Project Overview
Locustron is a **2D spatial hash library** for Picotron games, optimized for performance. It provides efficient collision detection and spatial queries using an unbounded, sparse grid system with object pooling to minimize garbage collection.

## Architecture & Core Concepts

### Spatial Hash Design
- **Grid-based**: Objects stored in squared cells (default 32x32 pixels)
- **Sparse allocation**: Cells created only when containing objects  
- **Object pooling**: Tables recycled via `pool` to minimize GC pressure
- **AABB representation**: Objects defined by `(x,y,w,h)` bounding boxes
- **Closure-based design**: Functions return closures with enclosed state instead of OOP patterns

### Key Components
- `src/lib/locus.lua`: Core spatial hash implementation with closure-based API
- `src/lib/require.lua`: Custom module system replacing Picotron's `include()` with error handling via `send_message()`
- `src/test_locus.lua`: Interactive demo showing 50 moving objects with viewport culling and collision detection
- `locustron.p64`: Picotron cartridge containing the packaged library and demo

### Memory Management Pattern
```lua
-- Pool usage is asymmetric by design:
-- add/del/update: balanced pool usage (take and return tables)
-- query: pool sink (only takes tables for results)

-- Internal structure (exposed for debugging):
loc._pool     -- Recycled table pool to minimize GC
loc._boxes    -- {[obj] = {x,y,w,h}} - object bounding boxes
loc._rows     -- Sparse grid: {[cy] = {[cx] = {[obj] = true}}}
loc._size     -- Grid cell dimensions (default 32)
```

## Development Conventions

### Performance Guidelines
- **Grid size**: Should match typical object size (8, 16, or 32 pixels recommended)
- **Query results**: Returned as `{[obj]=true}` hash tables for deduplication
- **Update efficiency**: Only modifies grid when object crosses cell boundaries
- **Pool monitoring**: Track `_pool` size during development to verify memory management

### Integration Patterns
```lua
-- Collision detection workflow:
local candidates = loc.query(x, y, w, h, filter_function)
for obj in pairs(candidates) do
  -- Additional intersection check required
  if rectintersect(player.x, player.y, player.w, player.h,
                   obj.x, obj.y, obj.w, obj.h) then
    -- Handle collision
  end
end

-- Viewport culling (from test_locus.lua):
for obj in pairs(loc.query(viewport.x, viewport.y, viewport.w, viewport.h)) do
  rrectfill(obj.x, obj.y, obj.w, obj.h, 0, obj.col)
end
```

## File Structure & Dependencies

### Picotron Integration
- **Main entry**: `locustron.p64` → `main.lua` → `cd("/desktop/projects/locustron/src")`
- **Module loading**: Custom `require()` function loads from local filesystem
- **Error reporting**: Uses `send_message(3, {event="report_error"})` for syntax errors
- **Token optimization**: Uses closure-based API instead of `:` syntax to save tokens

### Testing & Debugging
- `test_locus.lua`: Interactive demo with moving objects and viewport culling
- `draw_locus()`: Visualization function showing grid cells and object counts
- Pool monitoring: Track `_pool` size to verify memory management

### Development Environment
- `.luarc.json`: Lua Language Server config with Picotron-specific symbols
- Custom `include()` mapped to `require()` for Picotron compatibility
- Error handling via `send_message()` for syntax errors in module loading
- Picotron runtime symbols: `!=`, `+=`, `-=`, etc. enabled via `nonstandardSymbol`

## API Usage Patterns

### Object Lifecycle
```lua
-- Creation: Store reference AND add to spatial hash
local obj = {x=10, y=10, w=8, h=8}
loc.add(obj, obj.x, obj.y, obj.w, obj.h)

-- Movement: Update coordinates in both object and spatial hash
obj.x, obj.y = new_x, new_y
loc.update(obj, obj.x, obj.y, obj.w, obj.h)

-- Cleanup: Remove from spatial hash (obj reference handled separately)
loc.del(obj)
```

### Query Optimization
- **Viewport culling**: Query screen bounds to limit rendering
- **Collision candidates**: Use filter functions to pre-filter object types
- **Movement prediction**: Query movement path for continuous collision detection

## Error Handling
- `"unknown object"` thrown when operating on non-added objects
- Always pair `loc.add()` with `loc.del()` to prevent memory leaks
- Validate grid size against typical object dimensions during setup

## Performance Considerations

### Optimized for Picotron Scale
- **Specialized functions**: Replaced token-optimized `each()` with dedicated `add_to_cells()`, `del_from_cells()`, `free_empty_cells()`, and `query_cells()` for better performance
- **Eliminates string comparisons**: No runtime operation type checking
- **Reduced branching**: Each function has a single, focused responsibility
- **Benchmark results**: Handles 10,000+ objects efficiently (11ms for 10k additions, 13ms for 1k queries)

### Traditional Guidelines  
- Objects spanning multiple cells reduce efficiency
- Very large or very small grid sizes hurt performance
- Filter functions should be lightweight (called frequently during queries)
- Pool size should stabilize after initial allocation phase
- **Grid size scaling**: Use larger grid sizes (64+ pixels) for games with thousands of objects

## Debugging & Development Workflows

- **Grid visualization**: Use `draw_locus()` to visualize cell occupancy and object distribution

### Common Development Patterns
- **Object management**: Always call `loc.del()` for cleanup to prevent memory leaks
- **Grid size tuning**: Test with different grid sizes (8, 16, 32, 64) based on typical object size
- **Pool monitoring**: Watch `_pool` size stabilization during development
- **Viewport optimization**: Use `loc.query(screen_bounds)` for rendering culling