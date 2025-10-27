--- @diagnostic disable: undefined-global, undefined-field
-- Fixed Grid Strategy Tests
-- BDD tests for the vanilla Lua Fixed Grid implementation

local FixedGridStrategy = require("src.vanilla.fixed_grid_strategy")
local strategy_interface = require("src.vanilla.strategy_interface")

describe("FixedGridStrategy", function()
   local strategy

   before_each(function() strategy = FixedGridStrategy.new({ cell_size = 32 }) end)

   describe("initialization", function()
      it("should create with default configuration", function()
         local default_strategy = FixedGridStrategy.new({})
         assert.equals(32, default_strategy.cell_size)
         assert.equals(0, default_strategy.object_count)
         assert.equals("fixed_grid", default_strategy.strategy_name)
      end)

      it("should create with custom cell size", function()
         local custom_strategy = FixedGridStrategy.new({ cell_size = 64 })
         assert.equals(64, custom_strategy.cell_size)
      end)

      it("should implement SpatialStrategy interface", function()
         assert.is_not_nil(strategy.add_object)
         assert.is_not_nil(strategy.remove_object)
         assert.is_not_nil(strategy.update_object)
         assert.is_not_nil(strategy.query_region)
         assert.is_not_nil(strategy.get_bbox)
         assert.is_not_nil(strategy.clear)
      end)
   end)

   describe("object management", function()
      it("should add objects correctly", function()
         local obj = { id = 1 }
         local result = strategy:add_object(obj, 10, 20, 16, 16)

         assert.equals(obj, result)
         assert.equals(1, strategy.object_count)

         local x, y, w, h = strategy:get_bbox(obj)
         assert.equals(10, x)
         assert.equals(20, y)
         assert.equals(16, w)
         assert.equals(16, h)
      end)

      it("should error when adding duplicate objects", function()
         local obj = { id = 1 }
         strategy:add_object(obj, 10, 20, 16, 16)

         assert.has_error(function() strategy:add_object(obj, 30, 40, 16, 16) end, "object already in spatial hash")
      end)

      it("should remove objects correctly", function()
         local obj = { id = 1 }
         strategy:add_object(obj, 10, 20, 16, 16)

         local result = strategy:remove_object(obj)
         assert.equals(obj, result)
         assert.equals(0, strategy.object_count)

         local x, y, w, h = strategy:get_bbox(obj)
         assert.is_nil(x)
      end)

      it("should error when removing unknown objects", function()
         local obj = { id = 1 }

         assert.has_error(function() strategy:remove_object(obj) end, "unknown object")
      end)

      it("should update object positions", function()
         local obj = { id = 1 }
         strategy:add_object(obj, 10, 20, 16, 16)

         local result = strategy:update_object(obj, 50, 60, 24, 24)
         assert.equals(obj, result)

         local x, y, w, h = strategy:get_bbox(obj)
         assert.equals(50, x)
         assert.equals(60, y)
         assert.equals(24, w)
         assert.equals(24, h)
      end)

      it("should error when updating unknown objects", function()
         local obj = { id = 1 }

         assert.has_error(function() strategy:update_object(obj, 10, 20, 16, 16) end, "unknown object")
      end)

      it("should clear all objects", function()
         local obj1 = { id = 1 }
         local obj2 = { id = 2 }
         strategy:add_object(obj1, 10, 20, 16, 16)
         strategy:add_object(obj2, 50, 60, 16, 16)

         strategy:clear()

         assert.equals(0, strategy.object_count)
         assert.is_nil(strategy:get_bbox(obj1))
         assert.is_nil(strategy:get_bbox(obj2))
      end)
   end)

   describe("spatial queries", function()
      local obj1, obj2, obj3

      before_each(function()
         obj1 = { id = 1, type = "enemy" }
         obj2 = { id = 2, type = "player" }
         obj3 = { id = 3, type = "enemy" }

         strategy:add_object(obj1, 10, 10, 16, 16) -- At grid (0,0)
         strategy:add_object(obj2, 50, 50, 16, 16) -- At grid (1,1)
         strategy:add_object(obj3, 100, 100, 16, 16) -- At grid (3,3)
      end)

      it("should query single cell regions", function()
         local results = strategy:query_region(5, 5, 20, 20)

         assert.equals(true, results[obj1])
         assert.is_nil(results[obj2])
         assert.is_nil(results[obj3])
      end)

      it("should query multi-cell regions", function()
         local results = strategy:query_region(0, 0, 80, 80)

         assert.equals(true, results[obj1])
         assert.equals(true, results[obj2])
         assert.is_nil(results[obj3])
      end)

      it("should query empty regions", function()
         local results = strategy:query_region(200, 200, 50, 50)

         local count = 0
         for _ in pairs(results) do
            count = count + 1
         end
         assert.equals(0, count)
      end)

      it("should apply filter functions", function()
         local enemy_filter = function(obj) return obj.type == "enemy" end
         local results = strategy:query_region(0, 0, 150, 150, enemy_filter)

         assert.equals(true, results[obj1])
         assert.is_nil(results[obj2]) -- Filtered out (not enemy)
         assert.equals(true, results[obj3])
      end)

      it("should handle objects spanning multiple cells", function()
         local large_obj = { id = 4 }
         strategy:add_object(large_obj, 30, 30, 40, 40) -- Spans multiple cells

         local results1 = strategy:query_region(25, 25, 20, 20) -- Top-left portion
         local results2 = strategy:query_region(45, 45, 20, 20) -- Bottom-right portion

         assert.equals(true, results1[large_obj])
         assert.equals(true, results2[large_obj])
      end)

      it("should deduplicate objects in multi-cell queries", function()
         local large_obj = { id = 4 }
         strategy:add_object(large_obj, 30, 30, 40, 40) -- Spans multiple cells

         local results = strategy:query_region(25, 25, 50, 50) -- Covers all cells with large_obj

         -- Object should appear only once despite spanning multiple cells
         local count = 0
         for obj in pairs(results) do
            if obj == large_obj then count = count + 1 end
         end
         assert.equals(1, count)
      end)
   end)

   describe("grid coordinate calculations", function()
      it("should convert world coordinates to grid coordinates correctly", function()
         -- Test the private method through public behavior
         local obj = { id = 1 }

         -- Cell (0,0): world coordinates 0-31
         strategy:add_object(obj, 0, 0, 16, 16)
         local results = strategy:query_region(0, 0, 32, 32)
         assert.equals(true, results[obj])

         -- Move to cell (1,1): world coordinates 32-63
         strategy:update_object(obj, 32, 32, 16, 16)
         local results2 = strategy:query_region(32, 32, 32, 32)
         assert.equals(true, results2[obj])

         -- Verify it's not in the old cell
         local results3 = strategy:query_region(0, 0, 32, 32)
         assert.is_nil(results3[obj])
      end)

      it("should handle negative coordinates", function()
         local obj = { id = 1 }
         strategy:add_object(obj, -10, -10, 16, 16)

         local results = strategy:query_region(-20, -20, 40, 40)
         assert.equals(true, results[obj])
      end)
   end)

   describe("performance optimizations", function()
      it("should only update grid when object crosses cell boundaries", function()
         local obj = { id = 1 }
         strategy:add_object(obj, 10, 10, 16, 16)

         -- Move within same cell - should be optimized
         strategy:update_object(obj, 15, 15, 16, 16)
         local x, y, w, h = strategy:get_bbox(obj)
         assert.equals(15, x)
         assert.equals(15, y)

         -- Move to different cell - should update grid
         strategy:update_object(obj, 50, 50, 16, 16)
         local x2, y2, w2, h2 = strategy:get_bbox(obj)
         assert.equals(50, x2)
         assert.equals(50, y2)
      end)

      it("should maintain sparse grid allocation", function()
         local stats_before = strategy:get_statistics()
         assert.equals(0, stats_before.cell_count)

         local obj = { id = 1 }
         strategy:add_object(obj, 100, 100, 16, 16)

         local stats_after = strategy:get_statistics()
         assert.equals(1, stats_after.cell_count) -- Only one cell allocated

         strategy:remove_object(obj)
         local stats_removed = strategy:get_statistics()
         assert.equals(0, stats_removed.cell_count) -- Cell deallocated
      end)
   end)

   describe("strategy information", function()
      it("should provide capabilities information", function()
         local capabilities = strategy:get_capabilities()

         assert.equals(true, capabilities.supports_unbounded)
         assert.equals(false, capabilities.supports_hierarchical)
         assert.equals(false, capabilities.supports_dynamic_resize)
         assert.equals("sparse_grid", capabilities.memory_characteristics)
      end)

      it("should provide statistics", function()
         local obj1 = { id = 1 }
         local obj2 = { id = 2 }
         strategy:add_object(obj1, 10, 10, 16, 16) -- Grid (0,0) only
         strategy:add_object(obj2, 40, 40, 16, 16) -- Grid (1,1) only (40+16-1=55, 55//32=1)

         local stats = strategy:get_statistics()
         assert.equals(2, stats.object_count)
         assert.equals(2, stats.cell_count)
         assert.equals(32, stats.cell_size)
         assert.is_number(stats.memory_usage)
         assert.is_number(stats.grid_efficiency)
      end)

      it("should provide debug information", function()
         local obj = { id = 1 }
         strategy:add_object(obj, 10, 10, 16, 16)

         local debug_info = strategy:get_debug_info()
         assert.equals("fixed_grid", debug_info.structure_type)
         assert.equals(32, debug_info.cell_size)
         assert.equals(1, debug_info.total_objects)
         assert.equals(1, debug_info.allocated_cells)
         assert.is_table(debug_info.cells)
         assert.is_table(debug_info.performance_hints)
      end)
   end)

   describe("legacy API compatibility", function()
      it("should support legacy add/del/update/query methods", function()
         local obj = { id = 1 }

         -- Legacy add
         strategy:add(obj, 10, 20, 16, 16)
         assert.equals(1, strategy.object_count)

         -- Legacy query
         local results = strategy:query(5, 15, 20, 20)
         assert.equals(true, results[obj])

         -- Legacy update
         strategy:update(obj, 30, 40, 16, 16)
         local x, y, w, h = strategy:get_bbox(obj)
         assert.equals(30, x)
         assert.equals(40, y)

         -- Legacy del
         strategy:del(obj)
         assert.equals(0, strategy.object_count)
      end)
   end)

   describe("advanced queries", function()
      it("should find nearest objects", function()
         local obj1 = { id = 1 }
         local obj2 = { id = 2 }
         local obj3 = { id = 3 }

         strategy:add_object(obj1, 10, 10, 16, 16) -- Distance: ~14.14 from (0,0)
         strategy:add_object(obj2, 50, 50, 16, 16) -- Distance: ~70.71 from (0,0)
         strategy:add_object(obj3, 100, 100, 16, 16) -- Distance: ~141.42 from (0,0)

         local nearest = strategy:query_nearest(0, 0, 2)
         assert.equals(2, #nearest)
         assert.equals(obj1, nearest[1]) -- Closest
         assert.equals(obj2, nearest[2]) -- Second closest
      end)

      it("should respect count limit in nearest queries", function()
         local obj1 = { id = 1 }
         local obj2 = { id = 2 }
         local obj3 = { id = 3 }

         strategy:add_object(obj1, 10, 10, 16, 16)
         strategy:add_object(obj2, 50, 50, 16, 16)
         strategy:add_object(obj3, 100, 100, 16, 16)

         local nearest = strategy:query_nearest(0, 0, 1)
         assert.equals(1, #nearest)
         assert.equals(obj1, nearest[1])
      end)

      it("should apply filter in nearest queries", function()
         local obj1 = { id = 1, type = "enemy" }
         local obj2 = { id = 2, type = "player" }
         local obj3 = { id = 3, type = "enemy" }

         strategy:add_object(obj1, 10, 10, 16, 16)
         strategy:add_object(obj2, 30, 30, 16, 16) -- Closer but wrong type
         strategy:add_object(obj3, 50, 50, 16, 16)

         local enemy_filter = function(obj) return obj.type == "enemy" end
         local nearest = strategy:query_nearest(0, 0, 2, enemy_filter)

         assert.equals(2, #nearest)
         assert.equals(obj1, nearest[1])
         assert.equals(obj3, nearest[2])
         -- obj2 should be filtered out despite being closer
      end)
   end)
end)
