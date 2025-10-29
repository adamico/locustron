-- Test script to validate the state-based scenario refactoring
local DemoScenarios = require("demo.demo_scenarios")

print("Testing state-based scenario refactoring...")

-- Test creating each scenario type
local scenarios = {
   "survivor_like",
   "space_battle",
   "platformer",
   "dynamic_ecosystem"
}

for _, scenario_name in ipairs(scenarios) do
   print("Testing " .. scenario_name .. "...")

   -- Create scenario
   local scenario = DemoScenarios.create_scenario(scenario_name, {max_objects = 10})

   -- Check that it has the expected interface
   assert(scenario.update, "Scenario should have update method")
   assert(scenario.draw, "Scenario should have draw method")
   assert(scenario.get_objects, "Scenario should have get_objects method")
   assert(scenario.name, "Scenario should have name property")
   assert(scenario.description, "Scenario should have description property")
   assert(scenario.optimal_strategy, "Scenario should have optimal_strategy property")

   -- Check scenario info
   local info = DemoScenarios.get_scenario_info(scenario_name)
   assert(info, "Should have scenario info for " .. scenario_name)
   assert(info.name, "Scenario info should have name")
   assert(info.description, "Scenario info should have description")
   assert(info.optimal_strategy, "Scenario info should have optimal_strategy")

   print("✓ " .. scenario_name .. " created successfully")
end

print("All scenarios validated successfully!")
print("State-based refactoring completed!")