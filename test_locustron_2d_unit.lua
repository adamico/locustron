-- Unit Tests for Locustron 2D Spatial Hash Library (2D Userdata Version)
-- Drag and drop this file into unitron window to run tests

-- Include the 2D locustron implementation
include "src/lib/require.lua"
local locustron_2d = require("src/lib/locustron_2d")

-- Include custom helpers after locustron is loaded
include "test_helpers.lua"

-- Test: Basic Creation
test("create locustron_2d instance with default size", function()
   local loc = locustron_2d()
   assert_eq(32, loc._size, "default size should be 32")
   assert_eq(0, loc._obj_count(), "should start with 0 objects")
   assert_eq(true, loc._2d_version, "should be marked as 2D version")
end)

test("create locustron_2d instance with custom size", function()
   local loc = locustron_2d(64)
   assert_eq(64, loc._size, "custom size should be 64")
   assert_eq(0, loc._obj_count(), "should start with 0 objects")
end)

-- Test: Adding Objects
test("add single object", function()
   local loc = locustron_2d(32)
   local obj = {id = "test1"}
   
   loc.add(obj, 10, 10, 8, 8)
   assert_obj_count(loc, 1, "object count should be 1")
   assert_bbox(loc, obj, 10, 10, 8, 8, "bbox should be stored correctly")
end)

test("add multiple objects", function()
   local loc = locustron_2d(32)
   local obj1 = {id = "test1"}
   local obj2 = {id = "test2"}
   
   loc.add(obj1, 10, 10, 8, 8)
   loc.add(obj2, 100, 100, 16, 16)
   
   assert_obj_count(loc, 2, "should have 2 objects")
   assert_bbox(loc, obj1, 10, 10, 8, 8, "obj1 bbox should be correct")
   assert_bbox(loc, obj2, 100, 100, 16, 16, "obj2 bbox should be correct")
end)

test("adding same object twice should error", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   -- Test that adding same object twice fails
   assert_error(function()
      loc.add(obj, 20, 20, 8, 8)
   end, "object already in spatial hash", "adding same object twice should fail")
end)

-- Test: Removing Objects
test("remove single object", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   assert_obj_count(loc, 1, "should have 1 object")
   
   loc.del(obj)
   assert_obj_count(loc, 0, "should have 0 objects after removal")
   
   local bbox = loc.get_bbox(obj)
   if bbox ~= nil then
      test_fail("bbox should be nil after removal")
   end
end)

test("remove unknown object should error", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   -- Test that deleting unknown object fails
   assert_unknown_object_error(function()
      loc.del(obj)
   end, "deleting unknown object should fail")
end)

-- Test: Updating Objects
test("update object position", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   loc.update(obj, 50, 60, 8, 8)
   
   assert_bbox(loc, obj, 50, 60, 8, 8, "position should be updated")
end)

test("update object size", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   loc.update(obj, 10, 10, 16, 24)
   
   assert_bbox(loc, obj, 10, 10, 16, 24, "size should be updated")
end)

test("update unknown object should error", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   -- Test that updating unknown object fails
   assert_unknown_object_error(function()
      loc.update(obj, 20, 30, 8, 8)
   end, "updating unknown object should fail")
end)

-- Test: Querying Objects
test("query single object in range", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   local results = loc.query(5, 5, 20, 20)
   assert_query_contains(results, obj, "should find the correct object")
   assert_query_count(results, 1, "should find exactly 1 object")
end)

test("query with no objects in range", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   local results = loc.query(100, 100, 20, 20)
   assert_query_count(results, 0, "should find no objects")
end)

test("query multiple objects", function()
   local loc = locustron_2d(32)
   local obj1 = {id = "test1"}
   local obj2 = {id = "test2"}
   local obj3 = {id = "test3"}
   
   loc.add(obj1, 10, 10, 8, 8)
   loc.add(obj2, 15, 15, 8, 8)
   loc.add(obj3, 100, 100, 8, 8)
   
   local results = loc.query(0, 0, 30, 30)
   assert_query_contains(results, obj1, "should find obj1")
   assert_query_contains(results, obj2, "should find obj2")
   
   if results[obj3] then
      test_fail("should not find obj3 (it's outside query range)")
   end
end)

test("query with filter function", function()
   local loc = locustron_2d(32)
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
   local loc = locustron_2d(32)
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

test("zero-size object", function()
   local loc = locustron_2d(32)
   local obj = {id = "point"}
   
   loc.add(obj, 10, 10, 0, 0)
   
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(10, x, "x should be stored")
   assert_eq(10, y, "y should be stored")
   assert_eq(0, w, "width should be 0")
   assert_eq(0, h, "height should be 0")
   
   local results = loc.query(10, 10, 1, 1)
   assert_eq(obj, next(results), "zero-size object should be queryable")
end)

test("negative coordinates", function()
   local loc = locustron_2d(32)
   local obj = {id = "negative"}
   
   loc.add(obj, -10, -20, 8, 8)
   
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(-10, x, "negative x should be stored")
   assert_eq(-20, y, "negative y should be stored")
   
   local results = loc.query(-15, -25, 20, 20)
   assert_eq(obj, next(results), "should be found with negative coords")
end)

-- Test: API Compatibility
test("get_obj_id function", function()
   local loc = locustron_2d(32)
   local obj = {id = "test"}
   
   local id_before = loc.get_obj_id(obj)
   assert_eq(nil, id_before, "should return nil for unknown object")
   
   loc.add(obj, 10, 10, 8, 8)
   
   local id_after = loc.get_obj_id(obj)
   assert_type("number", id_after, "should return number for known object")
   assert_ne(nil, id_after, "should not be nil for known object")
end)

test("pool management", function()
   local loc = locustron_2d(32)
   
   local initial_pool = loc._pool()
   assert_type("number", initial_pool, "pool size should be a number")
   
   -- Test that queries use and return pool objects
   local obj = {id = "test"}
   loc.add(obj, 10, 10, 8, 8)
   
   local results = loc.query(0, 0, 50, 50)
   -- Note: We can't easily test pool usage without internal access
   assert_type("table", results, "query should return table")
end)

-- Test: Floating Point Coordinates (2D userdata uses f64)
test("floating point coordinates", function()
   local loc = locustron_2d(32)
   local obj = {id = "float"}
   
   loc.add(obj, 10.5, 20.7, 8.3, 16.9)
   
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(10.5, x, "float x should be preserved")
   assert_eq(20.7, y, "float y should be preserved")
   assert_eq(8.3, w, "float width should be preserved")
   assert_eq(16.9, h, "float height should be preserved")
end)

test("update with floating point", function()
   local loc = locustron_2d(32)
   local obj = {id = "float"}
   
   loc.add(obj, 10, 10, 8, 8)
   loc.update(obj, 15.25, 25.75, 12.5, 18.125)
   
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(15.25, x, "updated float x should be preserved")
   assert_eq(25.75, y, "updated float y should be preserved")
   assert_eq(12.5, w, "updated float width should be preserved")
   assert_eq(18.125, h, "updated float height should be preserved")
end)