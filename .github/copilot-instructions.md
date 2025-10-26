# Locustron Copilot Instructions

## Project Overview
Locustron is a **2D spatial hash library** for Picotron games, optimized for performance. It provides efficient collision detection and spatial queries using an unbounded, sparse grid system with userdata optimization and object pooling to minimize garbage collection.

**Official Documentation**: All Picotron-specific functionality and syntax should reference the [Official Picotron Manual](https://www.lexaloffle.com/dl/docs/picotron_manual.html) as the authoritative source.

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
- `benchmarks/benchmark_grid_tuning.lua`: Grid size optimization tool for different object sizes with comprehensive metrics and colored terminal output
- `benchmarks/benchmark_userdata_performance.lua`: Absolute performance measurements for userdata operations with professional reporting
- `benchmarks/run_all_benchmarks.lua`: Complete benchmark suite runner for comprehensive analysis with error handling
- `benchmarks/benchmark_diagnostics.lua`: Comprehensive diagnostic tool for troubleshooting benchmark execution and environment validation
- `tests/test_locustron_unit.lua`: Comprehensive unit test suite (25+ test cases)
- `tests/test_helpers.lua`: Custom assert functions library with proper error handling patterns
- `test_locustron.p64`: Picotron cartridge containing the packaged library and demo

### Memory Management Pattern
```lua
-- Userdata-optimized memory management for cells and bounding boxes:
loc._bbox_data    -- userdata("f64", MAX_OBJECTS, 4) - AABB storage [obj_id][coord]
obj_to_id         -- Object -> unique ID mapping
id_to_obj         -- ID -> object reverse mapping
bbox_map          -- obj_id -> bbox_index mapping

-- Cell storage uses userdata with direct indexing:
cell_data_2d      -- userdata("i32", MAX_CELLS, MAX_CELL_CAPACITY) - object IDs in cells
cell_counts       -- userdata("i32", MAX_CELLS, 1) - track object count per cell

-- Picotron userdata access patterns:
-- cell_data_2d:set(cell_idx, count, obj_id)  -- writing objects to cells
-- obj_id = cell_data_2d:get(cell_idx, count, 1)  -- reading objects from cells

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
- **Test Execution**: Use `include("test_file.lua")` in Picotron console to load and run tests
- **Userdata Functions**: `userdata()` function only exists in Picotron runtime (see [Official Manual - Userdata](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata))
- **Custom Require**: Uses custom `require()` system, not standard Lua modules
- **Error Handling**: Uses `send_message()` for error reporting instead of standard Lua error handling (see [Official Manual - System](https://www.lexaloffle.com/dl/docs/picotron_manual.html#system))
- **Runtime Dependencies**: Code depends on Picotron-specific APIs and cannot run outside Picotron
- **Console Output**: Always use `printh()` instead of `print()` for Picotron console tests and debugging (see [Official Manual - System](https://www.lexaloffle.com/dl/docs/picotron_manual.html#system))
- **Integer Division Operator**: Picotron supports `\` for integer division (`a \ b` equivalent to `flr(a / b)`). Use magic comment to suppress linter errors:
  ```lua
  --- @diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
  -- Example usage:
  local result = (#objects) \ 10  -- Integer division
  local cell_x = x \ grid_size    -- Grid coordinate calculation
  ```
  **Linter Compatibility**: When the `\` operator causes linter issues in complex expressions (e.g., within `max()` calls), fallback to `flr(a / b)` syntax for compatibility while maintaining equivalent functionality.

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
- `benchmarks/benchmark_grid_tuning.lua`: Performance analysis and grid size optimization tool
- `draw_locus()`: Visualization function showing grid cells and object counts
- Pool monitoring: Track `_pool` size to verify memory management
- Userdata debugging: Use `loc.get_bbox(obj)` and `loc.get_obj_id(obj)` for inspection

### Development Environment
- `.luarc.json`: Lua Language Server config with Picotron-specific symbols
- Custom `include()` mapped to `require()` for Picotron compatibility
- Error handling via `send_message()` for syntax errors in module loading
- Picotron runtime symbols: `!=`, `+=`, `-=`, etc. enabled via `nonstandardSymbol`
- **Unit Testing**: Comprehensive test coverage with unitron framework (25+ test cases)
- **Test Results**: All tests passing as of current implementation
- **Unitron API Reference**: Always use https://github.com/elgopher/unitron as the main reference for unitron API
- **Test Directory**: All test files are in `tests/` directory
- **Test File Paths**: Test files use `../src/lib/` paths to reference implementation files
- **Benchmark Directory**: All benchmark files are in `benchmarks/` directory
- **Benchmark File Paths**: Benchmark files use `../src/lib/` paths to reference implementation files
- **Unitron Error Testing**: Use `test_fail(err)` to generate test errors. Pattern:
  ```lua
  test("operation should error", function()
     -- Try operation that should fail
     loc.operation_that_should_fail()
     test_fail("Expected operation to fail but it succeeded")
  end)
  ```
- **Custom Assert Functions**: Create custom assert functions using `test_fail()` and `test_helper()`:
  ```lua
  function assert_unknown_object_error(operation_func, message)
     test_helper() -- mark this function as test helper for better error reporting
     local error_caught = false
     local old_error = _G.error
     
     _G.error = function(msg)
        if string.find(msg, "unknown object") then
           error_caught = true
           -- Use a custom error type that we can catch specifically
           error("__EXPECTED_UNKNOWN_OBJECT_ERROR__")
        end
        old_error(msg)
     end
     
     local success, err = pcall(operation_func)
     _G.error = old_error
     
     if success then
        test_fail(message or "Expected 'unknown object' error but operation succeeded")
     elseif not error_caught and not string.find(err, "__EXPECTED_UNKNOWN_OBJECT_ERROR__") then
        -- Re-throw unexpected errors
        error(err)
     end
     -- If we get here, the expected error was caught successfully
  end
  
  -- Usage: assert_unknown_object_error(function() loc.del(unknown_obj) end)
  ```
- **Console Testing**: Use basic `assert()` for error validation in console tests
- **Test Structure**: Unitron provides `test()`, `assert_eq()`, `test_fail()` globals in Picotron runtime only
- **Error Testing**: MUST use `pcall()` pattern with custom error markers in unitron to prevent "arithmetic on nil" errors
- **Critical Error Testing Pattern**: Custom assert functions must use `pcall()` to prevent code continuation after error:
  ```lua
  -- CORRECT: Use pcall with custom error markers
  local success, err = pcall(operation_func)
  if success then
     test_fail("Expected error but operation succeeded")
  elseif not string.find(err, "__EXPECTED_ERROR__") then
     error(err) -- Re-throw unexpected errors
  end
  
  -- WRONG: Using return allows code execution to continue
  _G.error = function(msg) 
     if expected_error then return end  -- DON'T DO THIS - causes arithmetic nil errors
  end
  ```
- **Custom Assert Helpers**: Use `test_helpers.lua` for locustron-specific assertions:
  - `assert_unknown_object_error(func, msg)` - Test that operation throws "unknown object" error
  - `assert_error(func, error_text, msg)` - Test that operation throws any specific error text
  - `assert_obj_count(loc, expected, msg)` - Test object count matches expected value
  - `assert_bbox(loc, obj, x, y, w, h, msg)` - Test object bounding box values
  - `assert_query_contains(results, obj, msg)` - Test query results contain specific object
  - `assert_query_count(results, expected, msg)` - Test query result count
  - `assert_type(expected_type, value, msg)` - Test value type matches expected
  - `assert_ne(value1, value2, msg)` - Test values are not equal
  - **Critical Pattern**: ALL custom asserts use `pcall()` to prevent "arithmetic on nil" errors
  - **Important**: Include helpers AFTER locustron: `local locustron = require(...); include("test_helpers.lua")`
- **2D Userdata Syntax**: Confirmed working in Picotron using method-based access (see [Official Manual - Userdata](https://www.lexaloffle.com/dl/docs/picotron_manual.html)):
  - `userdata("type", width, height)` creates 2D arrays
  - `ud:set(x, y, value)` for writing
  - `ud:get(x, y, n)` for reading (n = number of values to return)
  - **NOT** bracket syntax: `ud[x][y]` is unsupported

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
- **Always refer to the [Official Picotron Manual](https://www.lexaloffle.com/dl/docs/picotron_manual.html) for authoritative guidance on Picotron-specific functions and error handling**

## Git commit convention

We follow the Conventional Commits specification: https://www.conventionalcommits.org/en/v1.0.0/.

All commits to this repository MUST use the Conventional Commits format:

  <type>[optional scope]: <short description>

Required guidance:

- Use one of the conventional types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `revert`.
- The optional scope should be a single token describing the module or area, for example `locustron`, `tests`, or `benchmarks`.
- Keep the subject line concise and written in imperative mood (e.g. `add`, `fix`, `update`).
- Add an empty line and a longer body when more context is needed.
- Use the footer for metadata (e.g. `BREAKING CHANGE: <description>`, or `Closes #<issue>`).

Examples:

- `feat(locustron): add spatial hash optimization`
- `fix(tests): handle unknown object error in delete tests`
- `docs: update README to reference benchmarks/ directory`

**Multi-line commit messages:**

For commits that need detailed descriptions, use separate `-m` flags (reference: https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13):

```bash
git commit -m "feat(locustron): add spatial hash optimization" \
           -m "" \
           -m "Implement userdata for improved code readability" \
           -m "- Direct cell indexing eliminates manual base calculations" \
           -m "- Optimized performance for typical Picotron games" \
           -m "- Full API compatibility preserved"
```

**Never** use single `-m` flag with `\n` characters as Git will truncate at the first line.

Tooling and enforcement suggestions:

- Use commit hooks (e.g. `husky`) and a commitlint configuration in CI to validate messages where possible.
- Reviewers should enforce the format on PRs where automated checks are not available.
- For automated/CI commits include context in the footer and a descriptive body when necessary.

This repository's contributors should follow Conventional Commits for all local commits and PRs. The change history will be easier to parse, generate changelogs from, and integrate with release tooling.

## Performance Considerations

### Optimized for Picotron Scale
- **Userdata Storage**: Cell data stored in userdata arrays for memory efficiency and reduced GC pressure
- **Standard Query Format**: Returns `{[obj]=true}` hash tables for compatibility with existing code patterns
- **Automatic Deduplication**: Objects spanning multiple cells appear only once in query results
- **Balanced Pool Management**: Cell tables recycled efficiently, query results use standard table format
- **Native Math Functions**: Use Picotron's built-in functions (`rnd()`, `max()`, `min()`, `flr()`) instead of `math.*` for C-level performance
- **Integer Division**: Use `a \ b` instead of `flr(a / b)` for optimal performance and token savings
- **Benchmark results**: Operations achieve 1M-10M operations/sec for spatial operations, 1.024M ops/sec for queries
- **Memory Limits**: Picotron has 32MB RAM limit. Support for up to 10,000 simultaneous objects with userdata optimization (uses ~6-7MB for 10k objects)
- **Userdata Implementation**: Picotron's userdata provides optimal performance for cell storage with direct 2D indexing
- **Benchmark Memory Constraints**: Picotron's 32MB RAM limit requires careful memory management. Use single-iteration intensive operations rather than high iteration counts. Focus on measuring aggregate time for complex operations that stress 1D vs 2D userdata access patterns. Memory reported by `stat(3)` is in kilobytes.
- **Benchmark Timing Strategy**: Instead of increasing iterations, increase operation complexity per single iteration. Measure time for intensive workloads like: bulk queries across grid, complex update patterns, large-scale object reorganization. Target workloads that highlight 1D array indexing vs 2D userdata method calls.
- **Picotron Timing Limitations**: `time()` function only updates once per frame and measures seconds since program start. Cannot measure sub-frame operations accurately. For performance benchmarking, use operation counting with throughput measurement (operations per second) rather than attempting microsecond timing precision.
- **Operations-per-Second Benchmarking**: Count individual operations (add/query/update/delete) during single intensive workloads. Calculate ops/sec using `operation_counter / elapsed_time` where elapsed_time comes from `time()` difference. This provides meaningful relative performance comparisons between implementations while working within Picotron's timing constraints.
- **Benchmark results**: Comprehensive performance testing shows excellent performance. Operations achieve frame-rate level execution speed (completing in <0.001s per operation). Memory usage scales appropriately (100 objects: ~3MB, 2000 objects: ~3.4MB, total benchmark memory: ~615KB). The userdata implementation provides optimal performance with clean, readable code patterns and professional colored terminal output.
- **Benchmark Status**: All benchmark files working correctly with proper memory reporting (stat(3) bytes correctly displayed as KB), colored terminal output using ANSI escape sequences, and meaningful performance analysis despite Picotron's frame-based timing resolution.
- **Performance Insights**: Grid size optimization shows clear trade-offs (16px grid + 32x32 objects = 82.7% precision), memory efficiency (realistic 3MB range for 2000 objects), and frame-rate level operation completion indicating excellent real-world performance.

### Traditional Guidelines  
- Objects spanning multiple cells reduce efficiency
- Very large or very small grid sizes hurt performance
- Filter functions should be lightweight (called frequently during queries)
- Pool size should stabilize after initial allocation phase
- **Grid size scaling**: Use larger grid sizes (64+ pixels) for games with thousands of objects

## Debugging & Development Workflows

- **Grid visualization**: Use `draw_locus()` to visualize cell occupancy and object distribution
- **Picotron Testing Only**: Never attempt to run locustron code in vanilla Lua - it requires Picotron's userdata and custom runtime
- **Console Output**: Use `printh()` for all console debugging and test output in Picotron environment
- **Official Reference**: For all Picotron-specific debugging techniques, consult the [Official Picotron Manual](https://www.lexaloffle.com/dl/docs/picotron_manual.html)

### Common Development Patterns
- **Object management**: Always call `loc.del()` for cleanup to prevent memory leaks
- **Grid size tuning**: Use `benchmarks/benchmark_grid_tuning.lua` to find optimal grid sizes for your specific object patterns with colored output and professional metrics
- **Pool monitoring**: Watch `_pool` size stabilization during development
- **Viewport optimization**: Use `loc.query(screen_bounds)` for rendering culling
- **Benchmark-driven optimization**: Use the complete benchmark suite to find optimal configurations
- **Testing Protocol**: All functionality validation must be done in Picotron environment with unitron framework
- **Console Testing**: When creating console test scripts, always use `printh()` for proper Picotron output
- **Professional Output**: All benchmark files include colored terminal output using ANSI escape sequences for better readability