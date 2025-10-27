# Locustron Copilot Instructions

## Project Overview

Locustron is a **2D spatial hash library** for Picotron games, optimized for performance. It provides efficient collision detection and spatial queries using an unbounded, sparse grid system with userdata optimization and object pooling to minimize garbage collection.

**Official Documentation**: All Picotron-specific functionality and syntax should reference the Official Picotron Manual: <https://www.lexaloffle.com/dl/docs/picotron_manual.html> as the authoritative source.

## Architecture & Core Concepts

### Spatial Hash Design

- **Fixed Grid Pattern**: Implements the "Fixed Grid" spatial partitioning pattern from Game Programming Patterns: <https://gameprogrammingpatterns.com/spatial-partition.html>
- **Grid-based**: Objects stored in squared cells (default 32x32 pixels)
- **Sparse allocation**: Cells created only when containing objects  
- **Userdata optimization**: Cell storage uses Picotron userdata for memory efficiency
- **Standard query results**: Returns `{[obj]=true}` hash tables for compatibility
- **AABB representation**: Objects defined by `(x,y,w,h)` bounding boxes
- **Closure-based design**: Functions return closures with enclosed state instead of OOP patterns

### Spatial Partitioning Pattern Analysis

**Fixed Grid Characteristics:**

- **Flat (Non-Hierarchical)**: Single-level grid, no recursive subdivision like quadtrees
- **Object-Independent**: Grid boundaries fixed regardless of object positions
- **Incremental**: Objects can be added/moved one at a time efficiently
- **Simple**: Straightforward 2D array-like structure for debugging and optimization

**Comparison to Alternative Patterns:**

- **vs Quadtrees**: Simpler implementation, constant memory, faster updates, but less adaptive to clustering
- **vs BSP/k-d trees**: No tree traversal overhead, easier debugging, but fixed partitioning
- **vs Hierarchical**: Better performance with uniform distribution, worse with extreme clustering
- **vs Object-Dependent**: Fast incremental updates, but can be imbalanced

**Design Decision Rationale:**

- **Picotron constraints**: Fixed grid works well with userdata and 32MB memory limit
- **Game object patterns**: Most Picotron games have relatively uniform object distribution
- **Performance predictability**: No tree rebalancing or complex subdivision algorithms
- **Implementation simplicity**: Easier to debug, optimize, and maintain than hierarchical structures

### Key Components

- `lib/locustron/locustron.lua`: Core spatial hash implementation with userdata-optimized cell storage
- `lib/locustron/require.lua`: Custom module system replacing Picotron's `include()` with error handling via `send_message()`
- `locustron_demo.lua`: Interactive demo showing 100 moving objects with viewport culling and collision detection
- `benchmarks/benchmark_grid_tuning.lua`: Grid size optimization tool for different object sizes with comprehensive metrics and colored terminal output
- `benchmarks/benchmark_userdata_performance.lua`: Absolute performance measurements for userdata operations with professional reporting
- `benchmarks/run_all_benchmarks.lua`: Complete benchmark suite runner for comprehensive analysis with error handling
- `benchmarks/benchmark_diagnostics.lua`: Comprehensive diagnostic tool for troubleshooting benchmark execution and environment validation
- `tests/test_locustron_unit.lua`: Comprehensive unit test suite (28 test cases)
- `tests/test_helpers.lua`: Custom assert functions library with proper error handling patterns

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

### Code Style & Formatting

- **Indentation**: Use **3 spaces** for indentation in all Lua files (no tabs)
- **Consistency**: Maintain consistent indentation throughout the codebase
- **File Creation**: All new Lua files should follow the 3-space indentation standard

### Picotron-Specific Development

- **Testing Environment**: ALL tests must be run in Picotron with unitron - NEVER attempt to run in vanilla Lua
- **Test Execution**: Use `include("test_file.lua")` in Picotron console to load and run tests
- **Userdata Functions**: `userdata()` function only exists in Picotron runtime
- **Custom Require**: Uses custom `require()` system, not standard Lua modules
- **Error Handling**: Uses `send_message()` for error reporting instead of standard Lua error handling
- **Runtime Dependencies**: Code depends on Picotron-specific APIs and cannot run outside Picotron
- **Console Output**: Always use `printh()` instead of `print()` for Picotron console tests and debugging

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

-- Viewport culling (from locustron_demo.lua):
clip(viewport.x, viewport.y, viewport.w, viewport.h)
for obj in pairs(loc.query(viewport.x, viewport.y, viewport.w, viewport.h)) do
  local x, y, w, h = loc.get_bbox(obj)
  if x then rrectfill(grid_x + x, grid_y + y, w, h, 0, obj.col) end
end
clip()
```

## File Structure & Dependencies

### Project Architecture

Locustron follows a **Picotron cartridge + yotta package** pattern for library distribution:

``` bash
locustron.p64/                    # Picotron cartridge (directory) + Git repository root
├── .info.pod                   # Picotron cartridge metadata
├── main.lua                    # Cartridge entry point → include("locustron_demo.lua")
├── locustron_demo.lua          # Interactive demo and library showcase
├── exports/                    # Yotta package distribution files
│   ├── locustron.lua           # Library for yotta installation
│   └── require.lua             # Bundled require system
├── lib/locustron/              # Yotta package installation directory
│   ├── locustron.lua           # (mirrors exports/locustron.lua)
│   └── require.lua             # (mirrors exports/require.lua)
├── tests/                      # Unit test suite
│   ├── test_locustron_unit.lua # Main test file (28 test cases)
│   └── test_helpers.lua        # Custom assert functions
├── benchmarks/                 # Performance analysis tools
│   ├── benchmark_grid_tuning.lua     # Grid size optimization
│   ├── benchmark_userdata_performance.lua  # Performance measurement
│   ├── run_all_benchmarks.lua        # Suite runner
│   └── benchmark_diagnostics.lua     # Environment validation
└── .luarc.json                 # Critical: Lua Language Server config
```

**Project Structure & Integration:**

- **Dual-purpose Picotron cartridge**: `locustron.p64` is both a runnable demo cartridge (`main.lua` → `locustron_demo.lua`) and a library distribution container (Git repository root with `.info.pod` metadata)
- **Yotta Package Manager**: Library distributed via yotta (see <https://www.lexaloffle.com/bbs/?tid=140833>)
  - **Installation command**: `yotta add #locustron` copies `exports/` contents to user's `/lib/locustron/`
  - **Package source**: `exports/` directory contains the distributable library files
  - **Local development**: `lib/locustron/` contains the installed yotta package for testing and local usage
- **Export Workflow**: Use `include("export_package.lua")` to prepare and export cartridge for BBS publication
  - **Build process**: `exports/` → ready for publication → `export locustron.p64.png` → BBS upload
  - **Distribution**: Users install via yotta from published cartridge
- **Module loading**: Custom `require()` function loads from local filesystem with `../lib/locustron/` paths
- **Error reporting**: Uses `send_message(3, {event="report_error"})` for syntax errors
- **Token optimization**: Uses closure-based API instead of `:` syntax to save tokens
- **File paths**: Test files use relative paths like `include "../lib/locustron/require.lua"`

### Testing & Debugging

- `locustron_demo.lua`: Interactive demo with moving objects and viewport culling
- `benchmarks/benchmark_grid_tuning.lua`: Performance analysis and grid size optimization tool
- `draw_locus()`: Visualization function showing grid cells and object counts
- Pool monitoring: Track `_pool` size to verify memory management
- Userdata debugging: Use `loc.get_bbox(obj)` and `loc.get_obj_id(obj)` for inspection

### Visual Debugging & Interactive Demo

- **Interactive Demo**: `locustron_demo.lua` provides real-time spatial hash visualization with:
  - **100 moving objects** with physics simulation and boundary wrapping
  - **Grid cell visualization**: `draw_locus()` shows occupied cells with object counts
  - **Viewport culling demo**: Objects only rendered when in screen bounds via `loc.query(viewport)`
  - **Performance metrics**: Real-time FPS, object count, and memory usage display
  - **Color-coded objects**: Each object has unique color for easy tracking
- **Grid Visualization**: Press visual debugging keys to see:
  - Cell boundaries overlaid on screen
  - Object count per cell (numerical display)
  - Active vs empty grid regions
  - Pool size monitoring for memory management validation
- **Performance Validation**: Visual demo serves as real-time performance test showing:
  - Smooth 60fps with 100 objects
  - Efficient viewport culling (only visible objects rendered)
  - Memory stability (pool size stabilization)

### Development Environment

- `.luarc.json`: **Critical** Lua Language Server config enabling Picotron-specific features:
  - **Picotron symbols**: `!=`, `+=`, `-=`, `\` (integer division), etc. via `nonstandardSymbol`
  - **Custom include**: Maps `include()` to `require()` via `runtime.special`
  - **Userdata support**: Workspace definitions for Picotron's `userdata()` function
  - **Diagnostic tuning**: Disables `lowercase-global` and `err-esc` for Picotron patterns
- Custom `include()` mapped to `require()` for Picotron compatibility
- Error handling via `send_message()` for syntax errors in module loading
- **Unit Testing**: Comprehensive test coverage with unitron framework (28 test cases)
- **Test Results**: All tests passing as of current implementation
- **Unitron API Reference**: Always use <https://github.com/elgopher/unitron> as the main reference for unitron API
- **Test Directory**: All test files are in `tests/` directory
- **Test File Paths**: Test files use `../lib/locustron/` paths to reference implementation files
- **Benchmark Directory**: All benchmark files are in `benchmarks/` directory
- **Benchmark File Paths**: Benchmark files use `../lib/locustron/` paths to reference implementation files
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
- **2D Userdata Syntax**: Confirmed working in Picotron using method-based access:
  - `userdata("type", width, height)` creates 2D arrays
  - `ud:set(x, y, value)` for writing
  - `ud:get(x, y, n)` for reading (n = number of values to return)
  - **NOT** bracket syntax: `ud[x][y]` is unsupported

### Lua Language Server Type Annotations

**String Method Linter Errors**: The sumneko lua-ls language server may report "Undefined field" errors for string methods (`gsub`, `match`, `sub`, etc.) when called on variables, even though they're valid Lua string methods. This is a false positive from type inference limitations.

**Solution - Use `string` Module Functions**: Instead of method syntax, use the `string` module functions:

```lua
-- ❌ AVOID: Method syntax triggers linter error
local formatted = metric:gsub("_", " "):gsub("^%l", string.upper)

-- ✅ CORRECT: Use string module functions
local formatted = string.gsub(metric, "_", " ")
formatted = string.gsub(formatted, "^%l", string.upper)

-- ✅ ALSO CORRECT: Chain using string module
local formatted = string.gsub(string.gsub(metric, "_", " "), "^%l", string.upper)
```

**Why This Matters**:

- Eliminates false positive linter warnings in VS Code
- Maintains full Lua 5.1+ compatibility
- Makes code compatible with all language server versions
- No performance difference between method and function syntax

**Pattern for Refactoring**:

1. Replace `variable:method(...)` with `string.method(variable, ...)`
2. Break long chains into intermediate variables for readability
3. Language server recognizes `string.method()` as built-in stdlib

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
- **Always refer to the Official Picotron Manual: <https://www.lexaloffle.com/dl/docs/picotron_manual.html> for authoritative guidance on Picotron-specific functions and error handling**

## Git commit convention

We follow the Conventional Commits specification: <https://www.conventionalcommits.org/en/v1.0.0/>.

All commits to this repository MUST use the Conventional Commits format:

``` bash
  <type>[optional scope]: <short description>
```

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

For commits that need detailed descriptions, use separate `-m` flags (reference: <https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13>):

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
- **Official Reference**: For all Picotron-specific debugging techniques, consult the Official Picotron Manual: <https://www.lexaloffle.com/dl/docs/picotron_manual.html>

### Common Development Patterns

- **Object management**: Always call `loc.del()` for cleanup to prevent memory leaks
- **Grid size tuning**: Use `benchmarks/benchmark_grid_tuning.lua` to find optimal grid sizes for your specific object patterns with colored output and professional metrics
- **Pool monitoring**: Watch `_pool` size stabilization during development
- **Viewport optimization**: Use `loc.query(screen_bounds)` for rendering culling
- **Benchmark-driven optimization**: Use the complete benchmark suite to find optimal configurations
- **Testing Protocol**: All functionality validation must be done in Picotron environment with unitron framework
- **Console Testing**: When creating console test scripts, always use `printh()` for proper Picotron output
- **Professional Output**: All benchmark files include colored terminal output using ANSI escape sequences for better readability
- **Yotta Package Paths**: When using locustron as an installed yotta package, import using `include("lib/locustron/require.lua")` and `require("lib/locustron/locustron")`
