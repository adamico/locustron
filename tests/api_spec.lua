-- Locustron API Tests
-- Tests for the main unified Locustron API

local Locustron = require("src.locustron")

describe("Locustron API", function()
   local spatial

   before_each(function() spatial = Locustron.create({ strategy = "fixed_grid", config = { cell_size = 32 } }) end)

   describe("creation", function()
      it("should create a spatial partitioning instance", function()
         assert.is_not_nil(spatial)
         assert.is_table(spatial)
      end)

      it("should accept legacy number parameter", function()
         local legacy = Locustron.create(32)
         assert.is_not_nil(legacy)
      end)

      it("should accept strategy name string", function()
         local named = Locustron.create("fixed_grid")
         assert.is_not_nil(named)
      end)

      it("should use default configuration", function()
         local default = Locustron.create()
         assert.is_not_nil(default)
      end)
   end)

   describe("object management", function()
      it("should add objects", function()
         local obj = { id = "test" }
         spatial:add(obj, 10, 20, 16, 16)
         assert.are.equal(1, spatial:count())
      end)

      it("should update objects", function()
         local obj = { id = "test" }
         spatial:add(obj, 10, 20, 16, 16)
         spatial:update(obj, 30, 40, 16, 16)

         local x, y, w, h = spatial:get_bbox(obj)
         assert.are.equal(30, x)
         assert.are.equal(40, y)
         assert.are.equal(16, w)
         assert.are.equal(16, h)
      end)

      it("should remove objects", function()
         local obj = { id = "test" }
         spatial:add(obj, 10, 20, 16, 16)
         assert.are.equal(1, spatial:count())

         spatial:remove(obj)
         assert.are.equal(0, spatial:count())
      end)

      it("should handle partial updates", function()
         local obj = { id = "test" }
         spatial:add(obj, 10, 20, 16, 16)
         spatial:update(obj, 30, 40) -- No width/height specified

         local x, y, w, h = spatial:get_bbox(obj)
         assert.are.equal(30, x)
         assert.are.equal(40, y)
         assert.are.equal(16, w) -- Should keep original
         assert.are.equal(16, h) -- Should keep original
      end)
   end)

   describe("query operations", function()
      before_each(function()
         -- Add some test objects
         spatial:add({ id = "obj1" }, 0, 0, 16, 16)
         spatial:add({ id = "obj2" }, 50, 50, 16, 16)
         spatial:add({ id = "obj3" }, 10, 10, 16, 16)
      end)

      it("should query rectangular regions", function()
         local results = spatial:query(0, 0, 32, 32)
         -- Should find obj1 and obj3
         assert.is_table(results)
         -- Count results
         local count = 0
         for _ in pairs(results) do
            count = count + 1
         end
         assert.are.equal(2, count)
      end)

      it("should support filter functions", function()
         local results = spatial:query(0, 0, 100, 100, function(obj) return obj.id == "obj2" end)

         local count = 0
         for _ in pairs(results) do
            count = count + 1
         end
         assert.are.equal(1, count)
      end)
   end)

   describe("error handling", function()
      it("should reject nil objects", function()
         assert.has_error(function() spatial:add(nil, 0, 0, 16, 16) end)
         assert.has_error(function() spatial:update(nil, 0, 0) end)
         assert.has_error(function() spatial:remove(nil) end)
         assert.has_error(function() spatial:get_bbox(nil) end)
      end)

      it("should reject duplicate objects", function()
         local obj = { id = "test" }
         spatial:add(obj, 0, 0, 16, 16)
         assert.has_error(function() spatial:add(obj, 10, 10, 16, 16) end)
      end)

      it("should reject operations on non-existent objects", function()
         local obj = { id = "missing" }
         assert.has_error(function() spatial:update(obj, 0, 0) end)
         assert.has_error(function() spatial:remove(obj) end)
         assert.has_error(function() spatial:get_bbox(obj) end)
      end)

      it("should validate parameters", function()
         local obj = { id = "test" }
         assert.has_error(function() spatial:add(obj, nil, 0, 16, 16) end)
         assert.has_error(function() spatial:query(nil, 0, 32, 32) end)
         assert.has_error(function() spatial:query(0, 0, 0, 32) end) -- Zero width
         assert.has_error(function() spatial:query(0, 0, 32, -1) end) -- Negative height
      end)
   end)

   describe("strategy info", function()
      it("should provide strategy information", function()
         local info = spatial:get_strategy_info()
         assert.are.equal("fixed_grid", info.name)
         assert.are.equal("Fixed grid spatial partitioning", info.description)
         assert.are.equal(0, info.object_count)
         assert.is_table(info.config)
      end)
   end)
end)
