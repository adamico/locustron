--- @diagnostic disable: undefined-global, undefined-field, inject-field
-- BDD Tests for Strategy Interface
-- Testing the abstract strategy contract

local strategy_module = require("src.strategies.interface")
local SpatialStrategy = strategy_module.SpatialStrategy

describe("Strategy Interface Foundation", function()
   describe("SpatialStrategy abstract class", function()
      local strategy

      before_each(function() strategy = setmetatable({}, SpatialStrategy) end)

      it("should throw errors for unimplemented abstract methods", function()
         assert.has_error(
            function() strategy:add_object({}, 0, 0, 8, 8) end,
            "add_object must be implemented by concrete strategy"
         )

         assert.has_error(
            function() strategy:remove_object({}) end,
            "remove_object must be implemented by concrete strategy"
         )

         assert.has_error(
            function() strategy:update_object({}, 0, 0, 8, 8) end,
            "update_object must be implemented by concrete strategy"
         )

         assert.has_error(
            function() strategy:query_region(0, 0, 10, 10) end,
            "query_region must be implemented by concrete strategy"
         )

         assert.has_error(function() strategy:get_bbox({}) end, "get_bbox must be implemented by concrete strategy")
      end)

      it("should provide default implementations for optional methods", function()
         -- query_point should have a default implementation
         assert.has_error(
            function() strategy:query_point(5, 5) end,
            "query_region must be implemented by concrete strategy"
         ) -- It calls query_region internally

         -- get_info should work
         local info = strategy:get_info()
         assert.equals("table", type(info))
         assert.equals("unknown", info.name)

         -- get_capabilities should work
         local caps = strategy:get_capabilities()
         assert.equals("table", type(caps))
         assert.falsy(caps.supports_unbounded)
      end)

      it("should provide debug and visualization support", function()
         local debug_info = strategy:get_debug_info()
         assert.equals("table", type(debug_info))
         assert.equals("unknown", debug_info.structure_type)

         -- get_all_objects should throw error (abstract method)
         assert.has_error(
            function() strategy:get_all_objects() end,
            "get_all_objects must be implemented by concrete strategy"
         )
      end)
   end)

   describe("Strategy interface compliance", function()
      it("should define all required methods in the interface", function()
         local required_methods = {
            "add_object",
            "remove_object",
            "update_object",
            "query_region",
            "get_bbox",
            "contains",
            "clear",
            "get_info",
            "get_capabilities",
            "get_statistics",
         }

         for _, method_name in ipairs(required_methods) do
            assert.equals(
               "function",
               type(SpatialStrategy[method_name]),
               string.format("Method %s should be defined", method_name)
            )
         end
      end)

      it("should define optional methods with defaults", function()
         local optional_methods = {
            "query_point",
            "query_nearest",
            "get_debug_info",
            "get_all_objects",
         }

         for _, method_name in ipairs(optional_methods) do
            assert.equals(
               "function",
               type(SpatialStrategy[method_name]),
               string.format("Optional method %s should have default implementation", method_name)
            )
         end
      end)
   end)
end)
