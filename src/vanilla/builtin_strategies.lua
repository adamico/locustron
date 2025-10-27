-- Register Built-in Strategies
-- This module registers all built-in spatial partitioning strategies

local strategy_interface = require("src.vanilla.strategy_interface")
local FixedGridStrategy = require("src.vanilla.fixed_grid_strategy")

-- Register Fixed Grid Strategy
strategy_interface.register_strategy("fixed_grid", FixedGridStrategy, {
   description = "Fixed grid spatial hash with sparse allocation",
   optimal_for = {"uniform_distribution", "medium_worlds", "frequent_updates"},
   memory_characteristics = "sparse_grid",
   supports_unbounded = true,
   supports_hierarchical = false,
   supports_dynamic_resize = false,
   default_config = {
      cell_size = 32
   },
   config_options = {
      cell_size = {
         type = "number",
         description = "Grid cell size in pixels",
         min = 8,
         max = 256,
         default = 32
      }
   }
})

return {
   registered_strategies = {"fixed_grid"}
}
