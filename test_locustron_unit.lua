-- Unit Tests for Locustron Spatial Hash Library
-- Drag and drop this file into unitron window to run tests

-- Include the actual locustron implementation
include "src/lib/require.lua"
local locustron = require("src/lib/locustron")

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
   assert_eq(1, loc._obj_count(), "object count should be 1")
   
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(10, x, "x coordinate should be stored correctly")
   assert_eq(10, y, "y coordinate should be stored correctly")
   assert_eq(8, w, "width should be stored correctly")
   assert_eq(8, h, "height should be stored correctly")
end)

test("add multiple objects", function()
   local loc = locustron(32)
   local obj1 = {id = "test1"}
   local obj2 = {id = "test2"}
   local obj3 = {id = "test3"}
   
   loc.add(obj1, 0, 0, 8, 8)
   loc.add(obj2, 16, 16, 8, 8)
   loc.add(obj3, 32, 32, 8, 8)
   
   assert_eq(3, loc._obj_count(), "should have 3 objects")
   
   -- Verify all bboxes
   local x1, y1, w1, h1 = loc.get_bbox(obj1)
   local x2, y2, w2, h2 = loc.get_bbox(obj2)
   local x3, y3, w3, h3 = loc.get_bbox(obj3)
   
   assert_eq(0, x1, "obj1 x position correct")
   assert_eq(0, y1, "obj1 y position correct")
   assert_eq(16, x2, "obj2 x position correct")
   assert_eq(16, y2, "obj2 y position correct")
   assert_eq(32, x3, "obj3 x position correct")
   assert_eq(32, y3, "obj3 y position correct")
end)

-- Test: Querying Objects
test("query single object in area", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   -- Query area that contains the object
   local results = loc.query(5, 5, 20, 20)
   
   local found = false
   for result_obj in pairs(results) do
      if result_obj == obj then
         found = true
         break
      end
   end
   
   assert(found, "object should be found in query")
   assert(results[obj], "object should be accessible via index")
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
   
   local count = 0
   for obj in pairs(results) do
      count = count + 1
   end
   
   assert_eq(2, count, "should find exactly 2 objects")
   assert(results[obj1], "should find obj1")
   assert(results[obj2], "should find obj2")
   assert_nil(results[obj3], "should not find obj3")
end)

test("query with filter function", function()
   local loc = locustron(32)
   local enemy1 = {type = "enemy", id = 1}
   local enemy2 = {type = "enemy", id = 2}
   local coin = {type = "coin", id = 3}
   
   loc.add(enemy1, 10, 10, 8, 8)
   loc.add(enemy2, 20, 20, 8, 8)
   loc.add(coin, 15, 15, 4, 4)
   
   -- Filter to only get enemies
   local function is_enemy(obj)
      return obj.type == "enemy"
   end
   
   local results = loc.query(0, 0, 50, 50, is_enemy)
   
   local count = 0
   for obj in pairs(results) do
      count = count + 1
      assert_eq("enemy", obj.type, "filtered result should only be enemies")
   end
   
   assert_eq(2, count, "should find exactly 2 enemies")
   assert(results[enemy1], "should find enemy1")
   assert(results[enemy2], "should find enemy2")
   assert_nil(results[coin], "should not find coin")
end)

-- Test: Updating Objects
test("update object position", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   loc.add(obj, 10, 10, 8, 8)
   
   -- Move object to new position
   loc.update(obj, 50, 50, 8, 8)
   
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(50, x, "x should be updated")
   assert_eq(50, y, "y should be updated")
   assert_eq(8, w, "width should remain same")
   assert_eq(8, h, "height should remain same")
   
   -- Object should not be found in old area
   local old_results = loc.query(5, 5, 20, 20)
   assert_nil(old_results[obj], "object should not be in old area")
   
   -- Object should be found in new area
   local new_results = loc.query(45, 45, 20, 20)
   assert(new_results[obj], "object should be in new area")
end)

test("update object across grid boundaries", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   -- Add object in one grid cell
   loc.add(obj, 10, 10, 8, 8)
   
   -- Move to different grid cell
   loc.update(obj, 100, 100, 8, 8)
   
   -- Verify it moved correctly
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(100, x, "object should be at new x position")
   assert_eq(100, y, "object should be at new y position")
   
   local old_results = loc.query(0, 0, 50, 50)
   local new_results = loc.query(90, 90, 50, 50)
   
   assert_nil(old_results[obj], "should not be in old area")
   assert(new_results[obj], "should be in new area")
end)

-- Test: Removing Objects
test("remove single object", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   loc.add(obj, 10, 10, 8, 8)
   assert_eq(1, loc._obj_count(), "should have 1 object after add")
   
   local returned = loc.del(obj)
   assert_eq(obj, returned, "del should return the same object")
   assert_eq(0, loc._obj_count(), "should have 0 objects after delete")
   
   -- Object should not be found in queries
   local results = loc.query(0, 0, 50, 50)
   assert_nil(results[obj], "deleted object should not be found")
   
   -- Getting bbox should return nil
   local x, y, w, h = loc.get_bbox(obj)
   assert_nil(x, "bbox should be nil for deleted object")
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
   assert_nil(results_after[obj], "object should not be found after deletion")
end)

-- Test: Error Handling
test("error on unknown object update", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   local success, err = pcall(function()
      loc.update(obj, 10, 10, 8, 8)
   end)
   
   assert_eq(false, success, "should throw error for unknown object")
   assert(string.find(err or "", "unknown object"), "error message should mention unknown object")
end)

test("error on unknown object delete", function()
   local loc = locustron(32)
   local obj = {id = "test1"}
   
   local success, err = pcall(function()
      loc.del(obj)
   end)
   
   assert_eq(false, success, "should throw error for unknown object")
   assert(string.find(err or "", "unknown object"), "error message should mention unknown object")
end)

-- Test: Grid Coordinate System
test("box2grid coordinate calculation", function()
   local loc = locustron(32)
   
   -- Test internal grid calculation
   local l, t, r, b = loc._box2grid(0, 0, 8, 8)
   assert_eq(1, l, "left cell coordinate")
   assert_eq(1, t, "top cell coordinate")
   assert_eq(1, r, "right cell coordinate")
   assert_eq(1, b, "bottom cell coordinate")
   
   local l2, t2, r2, b2 = loc._box2grid(32, 32, 8, 8)
   assert_eq(2, l2, "object at (32,32) should be in cell (2,2)")
   assert_eq(2, t2, "object at (32,32) should be in cell (2,2)")
   
   local l3, t3, r3, b3 = loc._box2grid(30, 30, 10, 10)
   assert_eq(1, l3, "spanning object left cell")
   assert_eq(1, t3, "spanning object top cell")
   assert_eq(2, r3, "spanning object right cell")
   assert_eq(2, b3, "spanning object bottom cell")
end)

-- Test: Memory Management
test("pool management", function()
   local loc = locustron(32)
   
   local initial_cell_pool = loc._cell_pool_size()
   local initial_query_pool = loc._query_pool_size()
   
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
   
   assert_eq(0, loc._obj_count(), "all objects should be removed")
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
   
   assert(results1[large_obj], "should be found in top-left")
   assert(results2[large_obj], "should be found in bottom-right")
   assert(results3[large_obj], "should be found in center")
end)

-- Test: Edge Cases
test("zero-size objects", function()
   local loc = locustron(32)
   local point_obj = {id = "point"}
   
   loc.add(point_obj, 10, 10, 0, 0)
   
   local results = loc.query(10, 10, 1, 1)
   assert(results[point_obj], "zero-size object should still be queryable")
end)

test("negative coordinates", function()
   local loc = locustron(32)
   local obj = {id = "negative"}
   
   loc.add(obj, -10, -10, 8, 8)
   
   local results = loc.query(-20, -20, 30, 30)
   assert(results[obj], "object with negative coordinates should be found")
   
   local x, y, w, h = loc.get_bbox(obj)
   assert_eq(-10, x, "negative x coordinate should be preserved")
   assert_eq(-10, y, "negative y coordinate should be preserved")
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