# Locustron Copilot Instructions

## Project Overview
Locustron is a **2D spatial hash library** for Picotron games, optimized for performance. It provides efficient collision detection and spatial queries using an unbounded, sparse grid system with userdata optimization and object pooling to minimize garbage collection.

## Architecture & Core Concepts

### Spatial Hash Design
- **Grid-based**: Objects stored in squared cells (default 32x32 pixels)
- **Sparse allocation**: Cells created only when containing objects  
- **Userdata optimization**: Cell storage uses Picotron userdata for memory efficiency
- **Standard query results**: Returns `{[obj]=true}` hash tables for compatibility
- **AABB representation**: Objects defined by `(x,y,w,h)` bounding boxes
- **Closure-based design**: Functions return closures with enclosed state instead of OOP patterns

### Key Components
- `src/lib/locustron.lua`: Core spatial hash implementation with userdata-optimized cell storage
- `src/lib/require.lua`: Custom module system replacing Picotron's `include()` with error handling via `send_message()`
- `src/test_locustron.lua`: Interactive demo showing 100 moving objects with viewport culling and collision detection
- `src/benchmark_compact.lua`: Performance analysis tool for grid size optimization
- `test_locustron_unit.lua`: Comprehensive unit test suite using unitron framework (18 test cases)
- `test_locustron.p64`: Picotron cartridge containing the packaged library and demo

### Memory Management Pattern
```lua
-- Userdata-optimized storage for cells and bounding boxes:
loc._bbox_data    -- userdata("f32", MAX_OBJECTS * 4) - packed AABB storage
obj_to_id         -- Object -> unique ID mapping
id_to_obj         -- ID -> object reverse mapping
bbox_map          -- obj_id -> bbox_index mapping

-- Cell storage uses userdata for efficiency:
cell_data         -- userdata("i32", MAX_CELLS * MAX_CELL_CAPACITY) - object IDs in cells
cell_counts       -- userdata("i32", MAX_CELLS) - track object count per cell

-- Query results use standard Lua tables:
-- {[obj] = true} format for compatibility and deduplication

-- Pool usage patterns:
-- add/del/update: balanced pool usage (take and return tables)
-- query: returns standard {[obj]=true} tables with automatic cleanup

-- Sparse grid structure:
loc._rows         -- {[cy] = {[cx] = cell_idx}} - maps coordinates to userdata cell indices
loc._size         -- Grid cell dimensions (default 32)
```

## Development Conventions

### Performance Guidelines
- **Grid size**: Should match typical object size (32-128 pixels recommended for userdata optimization)
- **Query results**: Returned as `{[obj]=true}` hash tables for deduplication
- **Update efficiency**: Only modifies grid when object crosses cell boundaries
- **Pool monitoring**: Track `_pool` size during development to verify memory management
- **Userdata capacity**: Limited to MAX_OBJECTS (10,000) simultaneous objects

### Picotron-Specific Development
- **Testing Environment**: ALL tests must be run in Picotron with unitron - NEVER attempt to run in vanilla Lua
- **Userdata Functions**: `userdata()` function only exists in Picotron runtime
- **Custom Require**: Uses custom `require()` system, not standard Lua modules
- **Error Handling**: Uses `send_message()` for error reporting instead of standard Lua error handling
- **Runtime Dependencies**: Code depends on Picotron-specific APIs and cannot run outside Picotron

### Integration Patterns
```lua
-- Collision detection workflow (userdata-optimized):
local candidates = loc.query(x, y, w, h, filter_function)
for obj in pairs(candidates) do
  -- Get bbox directly from userdata for consistency
  local ox, oy, ow, oh = loc.get_bbox(obj)
  if rectintersect(player.x, player.y, player.w, player.h, ox, oy, ow, oh) then
    -- Handle collision
  end
end

-- Viewport culling (from test_locustron.lua):
clip(viewport.x, viewport.y, viewport.w, viewport.h)
for obj in pairs(loc.query(viewport.x, viewport.y, viewport.w, viewport.h)) do
  local x, y, w, h = loc.get_bbox(obj)
  if x then rrectfill(grid_x + x, grid_y + y, w, h, 0, obj.col) end
end
clip()
```

## File Structure & Dependencies

### Picotron Integration
- **Main entry**: `locustron.p64` → `main.lua` → `cd("/desktop/projects/locustron/src")`
- **Module loading**: Custom `require()` function loads from local filesystem
- **Error reporting**: Uses `send_message(3, {event="report_error"})` for syntax errors
- **Token optimization**: Uses closure-based API instead of `:` syntax to save tokens

### Testing & Debugging
- `test_locustron.lua`: Interactive demo with moving objects and viewport culling
- `benchmark_compact.lua`: Performance analysis and grid size optimization tool
- `draw_locus()`: Visualization function showing grid cells and object counts
- Pool monitoring: Track `_pool` size to verify memory management
- Userdata debugging: Use `loc.get_bbox(obj)` and `loc.get_obj_id(obj)` for inspection

### Development Environment
- `.luarc.json`: Lua Language Server config with Picotron-specific symbols
- Custom `include()` mapped to `require()` for Picotron compatibility
- Error handling via `send_message()` for syntax errors in module loading
- Picotron runtime symbols: `!=`, `+=`, `-=`, etc. enabled via `nonstandardSymbol`
- **Unit Testing**: Comprehensive test coverage with unitron framework (18 test cases covering all functionality)
- **Test Results**: All tests passing as of current implementation

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
- Userdata capacity: MAX_OBJECTS (10,000) limit enforced

## Performance Considerations

### Optimized for Picotron Scale
- **Userdata Storage**: Cell data stored in userdata arrays for memory efficiency and reduced GC pressure
- **Standard Query Format**: Returns `{[obj]=true}` hash tables for compatibility with existing code patterns
- **Automatic Deduplication**: Objects spanning multiple cells appear only once in query results
- **Balanced Pool Management**: Cell tables recycled efficiently, query results use standard table format
- **Benchmark results**: Handles 10,000+ objects efficiently (11ms for 10k additions, 13ms for 1k queries)
- **Memory Limits**: Support for up to 10,000 simultaneous objects with userdata optimization

### Traditional Guidelines  
- Objects spanning multiple cells reduce efficiency
- Very large or very small grid sizes hurt performance
- Filter functions should be lightweight (called frequently during queries)
- Pool size should stabilize after initial allocation phase
- **Grid size scaling**: Use larger grid sizes (64+ pixels) for games with thousands of objects

## Debugging & Development Workflows

- **Grid visualization**: Use `draw_locus()` to visualize cell occupancy and object distribution
- **Picotron Testing Only**: Never attempt to run locustron code in vanilla Lua - it requires Picotron's userdata and custom runtime

### Common Development Patterns
- **Object management**: Always call `loc.del()` for cleanup to prevent memory leaks
- **Grid size tuning**: Test with different grid sizes (8, 16, 32, 64) based on typical object size
- **Pool monitoring**: Watch `_pool` size stabilization during development
- **Viewport optimization**: Use `loc.query(screen_bounds)` for rendering culling
- **Benchmark-driven optimization**: Use `benchmark_compact.lua` to find optimal grid sizes for your specific object patterns
- **Testing Protocol**: All functionality validation must be done in Picotron environment with unitron framework