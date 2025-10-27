-- Comprehensive Unit Tests for Locustron Spatial Hash Library
-- Drag and drop this file into unitron window to run tests
-- Consolidated from both 1D and 2D test suites - best test cases included

-- Include the unified locustron implementation
include "../../lib/picotron/require.lua"
local locustron = require("../../lib/picotron/locustron")

-- Include custom helpers after locustron is loaded
include "test_helpers.lua"

-- Test: Basic Creation
test("create locustron instance with default size", function()
   local loc = locustron()
   assert_eq(32, loc._size, "default size should be 32")
   assert_eq(0, loc._obj_count(), "should start with 0 objects")
end)

test("create locustron instance with custom size", function()
   local loc = locustron(64)
   assert_eq(64, loc._size, "custom size should be 64")
   assert_eq(0, loc._obj_count(), "should start with 0 objects")
end)

-- Test: Adding Objects
test("add single object", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   local returned = loc.add(obj, 10, 10, 8, 8)
   assert_eq(obj, returned, "add should return the same object")
   assert_obj_count(loc, 1, "object count should be 1")
   assert_bbox(loc, obj, 10, 10, 8, 8, "bbox should be stored correctly")
end)

test("add multiple objects", function()
   local loc = locustron(32)
   local obj1 = {id = "test1"}
   local obj2 = {id = "test2"}
   local obj3 = {id = "test3"}
   
   loc.add(obj1, 0, 0, 8, 8)
   loc.add(obj2, 16, 16, 8, 8)
   loc.add(obj3, 32, 32, 8, 8)
   
   assert_obj_count(loc, 3, "should have 3 objects")
   assert_bbox(loc, obj1, 0, 0, 8, 8, "obj1 bbox should be correct")
   assert_bbox(loc, obj2, 16, 16, 8, 8, "obj2 bbox should be correct")
   assert_bbox(loc, obj3, 32, 32, 8, 8, "obj3 bbox should be correct")
end)

test("adding same object twice should error", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   -- Test that adding same object twice fails
   assert_error(function()
      loc.add(obj, 20, 20, 8, 8)
   end, "object already in spatial hash", "adding same object twice should fail")
end)

-- Test: Removing Objects
test("remove single object", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   assert_obj_count(loc, 1, "should have 1 object after add")
   
   local returned = loc.del(obj)
   assert_eq(obj, returned, "del should return the same object")
   assert_obj_count(loc, 0, "should have 0 objects after removal")
   
   -- Getting bbox should return nil
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(nil, x, "bbox should be nil for deleted object")
end)

test("remove unknown object should error", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   -- Test that deleting unknown object fails
   assert_unknown_object_error(function()
      loc.del(obj)
   end, "deleting unknown object should fail")
end)

test("remove object from multiple cells", function()
   local loc = locustron(16) -- Smaller grid to ensure object spans cells
   local obj = {id = "test1"}
   
   -- Add large object that spans multiple cells
   loc.add(obj, 10, 10, 20, 20)
   
   -- Verify it can be found
   local results = loc.query(0, 0, 50, 50)
   assert(results[obj], "object should be found before deletion")
   
   -- Remove it
   loc.del(obj)
   
   -- Verify it's completely gone
   local results_after = loc.query(0, 0, 50, 50)
   assert_eq(nil, results_after[obj], "object should not be found after deletion")
end)

-- Test: Updating Objects
test("update object position", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   loc.update(obj, 50, 60, 8, 8)
   
   assert_bbox(loc, obj, 50, 60, 8, 8, "position should be updated")
   
   -- Object should not be found in old area
   local old_results = loc.query(5, 5, 20, 20)
   assert_eq(nil, old_results[obj], "object should not be in old area")
   
   -- Object should be found in new area
   local new_results = loc.query(45, 45, 20, 20)
   assert(new_results[obj], "object should be in new area")
end)

test("update object size", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   loc.update(obj, 10, 10, 16, 24)
   
   assert_bbox(loc, obj, 10, 10, 16, 24, "size should be updated")
end)

test("update object across grid boundaries", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   -- Add object in one grid cell
   loc.add(obj, 10, 10, 8, 8)
   
   -- Move to different grid cell
   loc.update(obj, 100, 100, 8, 8)
   
   -- Verify it moved correctly
   assert_bbox(loc, obj, 100, 100, 8, 8, "object should be at new position")
   
   local old_results = loc.query(0, 0, 50, 50)
   local new_results = loc.query(90, 90, 50, 50)
   
   assert_eq(nil, old_results[obj], "should not be in old area")
   assert(new_results[obj], "should be in new area")
end)

test("update unknown object should error", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   -- Test that updating unknown object fails
   assert_unknown_object_error(function()
      loc.update(obj, 20, 30, 8, 8)
   end, "updating unknown object should fail")
end)

-- Test: Querying Objects
test("query single object in range", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   local results = loc.query(5, 5, 20, 20)
   assert_query_contains(results, obj, "should find the correct object")
   assert_query_count(results, 1, "should find exactly 1 object")
end)

test("query with no objects in range", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   local results = loc.query(100, 100, 20, 20)
   assert_query_count(results, 0, "should find no objects")
end)

test("query multiple objects", function()
   local loc = locustron(32)
   local obj1 = {id = "test1"}
   local obj2 = {id = "test2"}
   local obj3 = {id = "test3"}
   
   loc.add(obj1, 10, 10, 8, 8)
   loc.add(obj2, 20, 20, 8, 8)
   loc.add(obj3, 100, 100, 8, 8) -- Far away
   
   -- Query area that should contain obj1 and obj2 but not obj3
   local results = loc.query(0, 0, 50, 50)
   
   assert_query_count(results, 2, "should find exactly 2 objects")
   assert_query_contains(results, obj1, "should find obj1")
   assert_query_contains(results, obj2, "should find obj2")
   assert_eq(nil, results[obj3], "should not find obj3")
end)

test("query with filter function", function()
   local loc = locustron(32)
   local obj1 = {id = "test1", type = "enemy"}
   local obj2 = {id = "test2", type = "player"}
   local obj3 = {id = "test3", type = "enemy"}
   
   loc.add(obj1, 10, 10, 8, 8)
   loc.add(obj2, 15, 15, 8, 8)
   loc.add(obj3, 20, 20, 8, 8)
   
   local results = loc.query(0, 0, 50, 50, function(obj)
      return obj.type == "enemy"
   end)
   
   local found = {}
   for obj in pairs(results) do
      found[obj] = true
   end
   
   assert_eq(true, found[obj1], "should find enemy obj1")
   assert_eq(nil, found[obj2], "should not find player obj2")
   assert_eq(true, found[obj3], "should find enemy obj3")
end)

-- Test: Edge Cases
test("object spanning multiple cells", function()
   local loc = locustron(32)
   local obj = {id = "large"}
   
   -- Object that spans 4 cells (32x32 grid)
   loc.add(obj, 30, 30, 10, 10)
   
   -- Query each corner
   local results1 = loc.query(25, 25, 10, 10)  -- Top-left cell
   local results2 = loc.query(35, 25, 10, 10)  -- Top-right cell
   local results3 = loc.query(25, 35, 10, 10)  -- Bottom-left cell
   local results4 = loc.query(35, 35, 10, 10)  -- Bottom-right cell
   
   assert_eq(obj, next(results1), "should be found in top-left")
   assert_eq(obj, next(results2), "should be found in top-right")
   assert_eq(obj, next(results3), "should be found in bottom-left")
   assert_eq(obj, next(results4), "should be found in bottom-right")
end)

test("zero-size objects", function()
   local loc = locustron(32)
   local obj = {id = "point"}
   
   loc.add(obj, 10, 10, 0, 0)
   
   assert_bbox(loc, obj, 10, 10, 0, 0, "zero-size bbox should be stored")
   
   local results = loc.query(10, 10, 1, 1)
   assert_query_contains(results, obj, "zero-size object should be queryable")
end)

test("negative coordinates", function()
   local loc = locustron(32)
   local obj = {id = "negative"}
   
   loc.add(obj, -10, -20, 8, 8)
   
   assert_bbox(loc, obj, -10, -20, 8, 8, "negative coordinates should be stored")
   
   local results = loc.query(-15, -25, 20, 20)
   assert_query_contains(results, obj, "should be found with negative coords")
end)

test("floating point coordinates", function()
   local loc = locustron(32)
   local obj = {id = "float"}
   
   loc.add(obj, 10.5, 20.7, 8.3, 16.9)
   
   assert_bbox(loc, obj, 10.5, 20.7, 8.3, 16.9, "float coordinates should be preserved")
end)

test("update with floating point", function()
   local loc = locustron(32)
   local obj = {id = "float"}
   
   loc.add(obj, 10, 10, 8, 8)
   loc.update(obj, 15.25, 25.75, 12.5, 18.125)
   
   assert_bbox(loc, obj, 15.25, 25.75, 12.5, 18.125, "updated float coordinates should be preserved")
end)

-- Test: Error Handling
test("error on unknown object update", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   -- Try to update unknown object, should fail
   assert_unknown_object_error(function() 
      loc.update(obj, 10, 10, 8, 8) 
   end)
end)

test("error on unknown object delete", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   -- Try to delete unknown object, should fail
   assert_unknown_object_error(function() 
      loc.del(obj) 
   end)
end)

-- Test: Grid Coordinate System
test("box2grid coordinate calculation", function()
   local loc = locustron(32)
   
   -- Test internal grid calculation (0-based coordinates)
   local l, t, r, b = loc._box2grid(0, 0, 8, 8)
   assert_eq(0, l, "left cell coordinate")
   assert_eq(0, t, "top cell coordinate")
   assert_eq(0, r, "right cell coordinate")
   assert_eq(0, b, "bottom cell coordinate")
   
   local l2, t2, r2, b2 = loc._box2grid(32, 32, 8, 8)
   assert_eq(1, l2, "object at (32,32) should be in cell (1,1)")
   assert_eq(1, t2, "object at (32,32) should be in cell (1,1)")
   
   local l3, t3, r3, b3 = loc._box2grid(30, 30, 10, 10)
   assert_eq(0, l3, "spanning object left cell")
   assert_eq(0, t3, "spanning object top cell")
   assert_eq(1, r3, "spanning object right cell")
   assert_eq(1, b3, "spanning object bottom cell")
end)

-- Test: Memory Management  
test("pool management", function()
   local loc = locustron(32)
   
   local initial_cell_pool = loc._cell_pool_size()
   local initial_query_pool = loc._pool()
   
   -- Add and remove objects to test pool usage
   local objects = {}
   for i = 1, 10 do
      objects[i] = {id = "obj" .. i}
      loc.add(objects[i], i * 10, i * 10, 8, 8)
   end
   
   -- Remove all objects
   for i = 1, 10 do
      loc.del(objects[i])
   end
   
   assert_obj_count(loc, 0, "all objects should be removed")
end)

-- Test: Large Object Handling
test("large objects spanning many cells", function()
   local loc = locustron(16)
   local large_obj = {id = "large"}
   
   -- Object that spans 4x4 grid cells
   loc.add(large_obj, 0, 0, 64, 64)
   
   -- Should be found in various query areas
   local results1 = loc.query(0, 0, 20, 20)
   local results2 = loc.query(40, 40, 20, 20)
   local results3 = loc.query(20, 20, 20, 20)
   
   assert_query_contains(results1, large_obj, "should be found in top-left")
   assert_query_contains(results2, large_obj, "should be found in bottom-right")
   assert_query_contains(results3, large_obj, "should be found in center")
end)

-- Test: API Compatibility
test("get_obj_id function", function()
   local loc = locustron(32)
   local obj = {id = "test"}
   
   local id_before = loc.get_obj_id(obj)
   assert_eq(nil, id_before, "should return nil for unknown object")
   
   loc.add(obj, 10, 10, 8, 8)
   
   local id_after = loc.get_obj_id(obj)
   assert_eq("number", type(id_after), "should return number for known object")
   assert(id_after ~= nil, "should not be nil for known object")
end)

-- Test: Performance Characteristics
test("query deduplication", function()
   local loc = locustron(16) -- Small grid to force object into multiple cells
   local obj = {id = "spanning"}
   
   -- Object that spans multiple cells
   loc.add(obj, 15, 15, 10, 10)
   
   local results = loc.query(10, 10, 20, 20)
   
   -- Count how many times the object appears
   local count = 0
   for result_obj in pairs(results) do
      if result_obj == obj then
         count = count + 1
      end
   end
   
   assert_eq(1, count, "object should appear only once despite spanning multiple cells")
end)