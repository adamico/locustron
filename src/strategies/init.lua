-- Strategy Initialization and Factory
-- Handles strategy registration and provides factory functions
-- Separated from interface definitions for better organization

local interface = require("src.strategies.interface")
local FixedGridStrategy = require("src.strategies.fixed_grid")

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
--- @param strategy_name string Strategy type ("fixed_grid", "quadtree", etc.)
--- @param config table|nil Strategy configuration
--- @return SpatialStrategy Strategy instance
function StrategyFactory.create_strategy(strategy_name, config)
   config = config or {}

   -- Handle auto-selection
   if strategy_name == "auto" then
      strategy_name = StrategyFactory.auto_select_strategy(config)
   end

   local entry = strategy_registry[strategy_name]
   if not entry then
      local available = table.concat(StrategyFactory.get_available_strategies(), ", ")
      error(string.format("Unknown strategy '%s'. Available strategies: %s", strategy_name, available))
   end

   local strategy_class = entry.class
   if not strategy_class or not strategy_class.new then
      error(string.format("Strategy '%s' does not have a valid constructor", strategy_name))
   end

   local instance = strategy_class.new(config)
   instance.strategy_name = strategy_name
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
   if object_count_hint < 500 and world_size ~= "infinite" then
      return "fixed_grid"
   end

   -- Quadtree: Good for clustered objects
   if object_pattern == "clustered" then
      return "quadtree"
   end

   -- Hash Grid: Good for large, sparse worlds
   if world_size == "large" or world_size == "infinite" then
      return "hash_grid"
   end

   -- Default fallback
   return "fixed_grid"
end

--- Validate strategy configuration
--- @param strategy_name string Strategy type
--- @param config table Configuration to validate
--- @return boolean valid, string|nil error_message
function StrategyFactory.validate_config(strategy_name, config)
   local entry = strategy_registry[strategy_name]
   if not entry then
      return false, "Unknown strategy type: " .. strategy_name
   end

   local metadata = entry.metadata
   if metadata and metadata.validate_config then
      return metadata.validate_config(config)
   end

   -- Default validation - just check it's a table
   if type(config) ~= "table" then
      return false, "Configuration must be a table"
   end

   return true, nil
end

-- Initialize built-in strategies
StrategyFactory.register_strategy("fixed_grid", FixedGridStrategy, {
   description = "Fixed grid spatial partitioning - good for uniform object distributions",
   optimal_for = {"uniform", "static", "bounded_worlds"},
   memory_characteristics = "low_constant",
   supports_unbounded = false,
   supports_hierarchical = false,
   supports_dynamic_resize = false,
})

-- Export module interface
local M = {
   -- Core interfaces
   SpatialStrategy = interface.SpatialStrategy,
   StrategyFactory = StrategyFactory,

   -- Convenience functions for easy access
   create_strategy = StrategyFactory.create_strategy,
   register_strategy = StrategyFactory.register_strategy,
   get_available_strategies = StrategyFactory.get_available_strategies,
   get_strategy_metadata = StrategyFactory.get_strategy_metadata,
}

return M