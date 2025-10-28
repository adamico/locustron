-- Strategy Interface for Spatial Partitioning
-- Defines the contract that all spatial partitioning strategies must implement
-- Follows Strategy Pattern with Factory for dynamic strategy selection

--- @class SpatialStrategy
--- @field config table Strategy configuration
--- @field strategy_name string Strategy identifier/name
local SpatialStrategy = {}
SpatialStrategy.__index = SpatialStrategy

-- Abstract methods that must be implemented by concrete strategies
-- These will throw errors if called on the base class

--- Add an object to the spatial structure
--- @param obj any Object reference
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return any The added object
function SpatialStrategy:add_object(obj, x, y, w, h) error("add_object must be implemented by concrete strategy") end

--- Remove an object from the spatial structure
--- @param obj any Object reference
--- @return any The removed object
function SpatialStrategy:remove_object(obj) error("remove_object must be implemented by concrete strategy") end

--- Update an object's position in the spatial structure
--- @param obj any Object reference
--- @param x number New X coordinate
--- @param y number New Y coordinate
--- @param w number New width
--- @param h number New height
--- @return any The updated object
function SpatialStrategy:update_object(obj, x, y, w, h) error("update_object must be implemented by concrete strategy") end

--- Query objects in a rectangular region
--- @param x number Query region X
--- @param y number Query region Y
--- @param w number Query region width
--- @param h number Query region height
--- @param filter_fn function|nil Optional filter function
--- @return table Hash table of objects {[obj] = true}
function SpatialStrategy:query_region(x, y, w, h, filter_fn)
   error("query_region must be implemented by concrete strategy")
end

--- Query objects at a specific point
--- @param x number Point X coordinate
--- @param y number Point Y coordinate
--- @param filter_fn function|nil Optional filter function
--- @return table Hash table of objects {[obj] = true}
function SpatialStrategy:query_point(x, y, filter_fn)
   -- Default implementation uses region query with 1x1 area
   return self:query_region(x, y, 1, 1, filter_fn)
end

--- Query nearest objects to a point
--- @param x number Point X coordinate
--- @param y number Point Y coordinate
--- @param count number Maximum number of objects to return
--- @param filter_fn function|nil Optional filter function
--- @return table Array of objects sorted by distance
function SpatialStrategy:query_nearest(x, y, count, filter_fn)
   error("query_nearest must be implemented by concrete strategy")
end

--- Get bounding box of an object
--- @param obj any Object reference
--- @return number|nil x, number|nil y, number|nil w, number|nil h
function SpatialStrategy:get_bbox(obj) error("get_bbox must be implemented by concrete strategy") end

--- Check if an object exists in the spatial structure
--- @param obj any Object reference
--- @return boolean True if object exists
function SpatialStrategy:contains(obj) error("contains must be implemented by concrete strategy") end

-- Strategy management and information methods

--- Get strategy information
--- @return table Strategy information including name, config, and capabilities
function SpatialStrategy:get_info()
   return {
      name = self.strategy_name or "unknown",
      type = self.strategy_name or "abstract", -- Use strategy_name for both name and type
      config = self.config or {},
      capabilities = self:get_capabilities(),
      statistics = self:get_statistics(),
   }
end

--- Get strategy capabilities
--- @return table Capabilities table
function SpatialStrategy:get_capabilities()
   return {
      supports_unbounded = false,
      supports_hierarchical = false,
      supports_dynamic_resize = false,
      optimal_for = {},
      memory_characteristics = "unknown",
   }
end

--- Get strategy statistics
--- @return table Statistics table
function SpatialStrategy:get_statistics()
   return {
      object_count = 0,
      memory_usage = 0,
      operation_count = 0,
   }
end

--- Clear all objects from the spatial structure
function SpatialStrategy:clear() error("clear must be implemented by concrete strategy") end

-- Debug and visualization support

--- Get debug information for visualization and development
--- @return table Debug information
function SpatialStrategy:get_debug_info()
   return {
      structure_type = self.strategy_name or "unknown",
      internal_state = {},
      performance_hints = {},
   }
end

--- Get all objects in the spatial structure for visualization
--- @return table Table of objects {obj = {x, y, w, h, ...}}
function SpatialStrategy:get_all_objects() error("get_all_objects must be implemented by concrete strategy") end

--- @class StrategyConfig
--- @field strategy string Strategy type name
--- @field config table Strategy-specific configuration

-- Export the main interface
local M = {}

M.SpatialStrategy = SpatialStrategy

return M
