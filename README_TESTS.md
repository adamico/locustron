# Locustron Unit Tests

## Running the Tests

1. **Open unitron.p64** in Picotron
2. **Drag and drop** `test_locustron_unit.lua` into the unitron window
3. The tests will run automatically and display results

## File Structure

The test file uses the actual locustron implementation:
```lua
-- Include the actual locustron implementation  
include "src/lib/require.lua"
local locustron = require("src/lib/locustron")
```

This ensures tests always run against the current implementation without code duplication.

## Unitron API Used

The test file follows the official unitron testing API:

### Test Functions
- `test(name, function)` - Define a test with given name
- `assert_eq(expected, actual, message?)` - Assert equality with optional message
- `assert_nil(actual, message?)` - Assert value is nil
- `assert(condition, message?)` - Standard assertion

### Test Structure
```lua
test("descriptive test name", function()
   -- Setup
   local loc = locustron(32)
   local obj = {id = "test_object"}
   
   -- Action  
   loc.add(obj, 10, 10, 8, 8)
   
   -- Assertions with proper order: expected, actual, message
   assert_eq(10, obj.x, "x coordinate should match")
   assert(loc.query(5, 5, 20, 20)[obj], "object should be found in query")
end)
```

## Key Differences from Generic Unit Testing

1. **Parameter Order**: unitron uses `assert_eq(expected, actual, message)` 
2. **Include System**: Uses Picotron's `include` instead of standard `require`
3. **No Setup Required**: unitron automatically provides test functions
4. **Drag & Drop**: Test files are executed by dragging into unitron window

## Test Coverage

The unit tests cover all major functionality of locustron:

### Core Functionality
- **Creation**: Default and custom grid sizes
- **Adding Objects**: Single and multiple object addition with bbox storage
- **Querying**: Area queries, filtered queries, result iteration
- **Updating**: Position updates, cross-boundary movement
- **Removing**: Object deletion and cleanup

### Advanced Features
- **Userdata Storage**: Bbox storage and retrieval
- **Memory Management**: Pool usage and recovery
- **Grid Coordinate System**: Coordinate calculations and cell mapping
- **Query Results**: Userdata-backed results with table-like API

### Edge Cases
- **Large Objects**: Objects spanning multiple grid cells
- **Zero-size Objects**: Point objects with 0x0 dimensions
- **Negative Coordinates**: Objects positioned at negative coordinates
- **Query Deduplication**: Ensuring objects appear only once in results

### Error Handling
- **Unknown Object Operations**: Update/delete on non-added objects
- **Capacity Limits**: Cell and query result capacity management

## Test Structure

Each test follows the pattern:
```lua
test("descriptive test name", function()
   -- Setup
   local loc = locustron(grid_size)
   local obj = {id = "test_object"}
   
   -- Action
   loc.add(obj, x, y, w, h)
   
   -- Assertion
   assert(condition, "error message")
end)
```

## Expected Results

All tests should pass, confirming:
- ✅ API compatibility with original locus interface
- ✅ Userdata optimization performance benefits
- ✅ Memory management efficiency
- ✅ Correct spatial hash behavior
- ✅ Error handling robustness

If any tests fail, it indicates a regression in the locustron implementation that needs to be addressed.