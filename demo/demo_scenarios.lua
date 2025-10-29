-- Demo Scenarios for Locustron
-- Different game scenarios to showcase spatial partitioning strategies

local DemoScenarios = {}

-- Load individual scenario modules
local SurvivorLikeScenario = require("demo.scenarios.survivor_like")
local SpaceBattleScenario = require("demo.scenarios.space_battle")
local PlatformerScenario = require("demo.scenarios.platformer")
local DynamicEcosystemScenario = require("demo.scenarios.dynamic_ecosystem")

-- Scenario: Survivor Like
-- Monsters spawn in waves around player, creating dense clusters
function DemoScenarios.survivor_like(config) return SurvivorLikeScenario(config) end

-- Scenario: Space Battle
-- Ships spread across large area with some clusters around objectives
function DemoScenarios.space_battle(config) return SpaceBattleScenario.new(config) end

-- Scenario: Platformer Level
-- Objects in a bounded level with some clustering around platforms
function DemoScenarios.platformer(config) return PlatformerScenario.new(config) end

-- Scenario: Dynamic Ecosystem
-- Objects spawn, move, and die creating changing density patterns
function DemoScenarios.dynamic_ecosystem(config) return DynamicEcosystemScenario.new(config) end

-- Scenario Manager
function DemoScenarios.create_scenario(scenario_name, config)
   if DemoScenarios[scenario_name] then
      return DemoScenarios[scenario_name](config)
   else
      error("Unknown scenario: " .. scenario_name)
   end
end

function DemoScenarios.get_available_scenarios()
   return {
      "survivor_like",
      "space_battle",
      "platformer",
      "dynamic_ecosystem",
   }
end

function DemoScenarios.get_scenario_info(scenario_name)
   local scenarios = {
      survivor_like = {
         name = "Survivor Like",
         description = "Wave-based survival with clustered monster spawns",
         optimal_strategy = "quadtree",
         challenges = { "clustered objects", "dynamic spawning", "dense areas" },
      },
      space_battle = {
         name = "Space Battle",
         description = "Large world with objective-based clustering",
         optimal_strategy = "hash_grid",
         challenges = { "large world", "sparse areas", "clustered objectives" },
      },
      platformer = {
         name = "Platformer Level",
         description = "Bounded level with platform-based object distribution",
         optimal_strategy = "fixed_grid",
         challenges = { "uniform areas", "bounded world", "predictable distribution" },
      },
      dynamic_ecosystem = {
         name = "Dynamic Ecosystem",
         description = "Living system with birth/death creating changing patterns",
         optimal_strategy = "quadtree",
         challenges = { "changing distributions", "object lifecycle", "adaptive partitioning" },
      },
   }

   return scenarios[scenario_name]
end

return DemoScenarios
