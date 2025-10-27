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

--- Visualize the spatial structure (for debugging)
--- @param renderer function Function to handle visualization rendering
function SpatialStrategy:visualize_structure(renderer)
   -- Default implementation - can be overridden by strategies
   local debug_info = self:get_debug_info()
   if renderer then renderer(debug_info) end
end

--- @class StrategyConfig
--- @field strategy string Strategy type name
--- @field config table Strategy-specific configuration

--- @class StrategyFactory
local StrategyFactory = {}

-- Registry of available strategies
local strategy_registry = {}

--- Register a strategy implementation
--- @param name string Strategy name
--- @param strategy_class table Strategy class
--- @param metadata table Strategy metadata
function StrategyFactory.register_strategy(name, strategy_class, metadata)
   strategy_registry[name] = {
      class = strategy_class,
      metadata = metadata or {},
   }
end

--- Get list of available strategies
--- @return table Array of strategy names
function StrategyFactory.get_available_strategies()
   local strategies = {}
   for name, _ in pairs(strategy_registry) do
      table.insert(strategies, name)
   end
   table.sort(strategies)
   return strategies
end

--- Get strategy metadata
--- @param name string Strategy name
--- @return table|nil Strategy metadata
function StrategyFactory.get_strategy_metadata(name)
   local entry = strategy_registry[name]
   return entry and entry.metadata
end

--- Create a strategy instance
--- @param strategy_type string Strategy type ("fixed_grid", "quadtree", etc.)
--- @param config table|nil Strategy configuration
--- @return SpatialStrategy Strategy instance
function StrategyFactory.create_strategy(strategy_type, config)
   config = config or {}

   -- Handle auto-selection
   if strategy_type == "auto" then strategy_type = StrategyFactory.auto_select_strategy(config) end

   local entry = strategy_registry[strategy_type]
   if not entry then
      local available = table.concat(StrategyFactory.get_available_strategies(), ", ")
      error(string.format("Unknown strategy '%s'. Available strategies: %s", strategy_type, available))
   end

   local strategy_class = entry.class
   if not strategy_class or not strategy_class.new then
      error(string.format("Strategy '%s' does not have a valid constructor", strategy_type))
   end

   local instance = strategy_class.new(config)
   instance.strategy_name = strategy_type
   instance.config = config

   return instance
end

--- Auto-select best strategy based on configuration hints
--- @param config table Configuration with hints like world_size, object_pattern, etc.
--- @return string Selected strategy name
function StrategyFactory.auto_select_strategy(config)
   -- Simple heuristics for auto-selection
   -- This can be enhanced in Phase 4 with more sophisticated analysis

   local world_size = config.world_size or "medium"
   local object_pattern = config.object_pattern or "uniform"
   local object_count_hint = config.expected_object_count or 100

   -- Fixed Grid: Good default for most cases
   if object_count_hint < 500 and world_size ~= "infinite" then return "fixed_grid" end

   -- Quadtree: Good for clustered objects
   if object_pattern == "clustered" then return "quadtree" end

   -- Hash Grid: Good for large, sparse worlds
   if world_size == "large" or world_size == "infinite" then return "hash_grid" end

   -- Default fallback
   return "fixed_grid"
end

--- Validate strategy configuration
--- @param strategy_type string Strategy type
--- @param config table Configuration to validate
--- @return boolean valid, string|nil error_message
function StrategyFactory.validate_config(strategy_type, config)
   local entry = strategy_registry[strategy_type]
   if not entry then return false, "Unknown strategy type: " .. strategy_type end

   local metadata = entry.metadata
   if metadata and metadata.validate_config then return metadata.validate_config(config) end

   -- Default validation - just check it's a table
   if type(config) ~= "table" then return false, "Configuration must be a table" end

   return true, nil
end

-- Export the main interfaces
local M = {}

M.SpatialStrategy = SpatialStrategy
M.StrategyFactory = StrategyFactory

-- Convenience function for creating strategies
--- Create a spatial partitioning strategy
--- @param options table|string Strategy options or strategy type string
--- @return SpatialStrategy Strategy instance
function M.create_strategy(options)
   if type(options) == "string" then
      -- Simple string form: create_strategy("fixed_grid")
      return StrategyFactory.create_strategy(options, {})
   elseif type(options) == "table" then
      -- Full options form: create_strategy({strategy = "fixed_grid", config = {...}})
      local strategy_type = options.strategy or "fixed_grid"
      local config = options.config or options
      return StrategyFactory.create_strategy(strategy_type, config)
   else
      error("Invalid options type. Expected string or table.")
   end
end

-- Convenience functions
M.register_strategy = StrategyFactory.register_strategy
M.get_available_strategies = StrategyFactory.get_available_strategies
M.get_strategy_metadata = StrategyFactory.get_strategy_metadata

return M
