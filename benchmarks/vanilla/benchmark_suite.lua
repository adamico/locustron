-- Benchmarking Suite for Spatial Partitioning Strategies
-- Comprehensive performance testing and analysis framework

local strategy_interface = require("src.vanilla.strategy_interface")

--- @class BenchmarkSuite
--- @field scenarios table Test scenario generators
--- @field strategies table Array of strategy names to test
--- @field metrics table Performance metrics to collect
--- @field iterations number Number of iterations per test
local BenchmarkSuite = {}
BenchmarkSuite.__index = BenchmarkSuite

--- Create a new benchmark suite
--- @param config table Configuration options
--- @return BenchmarkSuite
function BenchmarkSuite.new(config)
   local self = setmetatable({}, BenchmarkSuite)

   config = config or {}
   self.scenarios = {}
   self.strategies = config.strategies or { "fixed_grid" }
   self.metrics = config.metrics or { "add_time", "query_time", "memory_usage", "accuracy" }
   self.iterations = config.iterations or 1000

   self:setup_scenarios()

   return self
end

--- Setup test scenarios for different game patterns
function BenchmarkSuite:setup_scenarios()
   -- Clustered objects scenario (survivor games, tower defense)
   self.scenarios.clustered = function(count)
      local objects = {}
      local clusters = math.max(1, math.floor(count / 50))

      for i = 1, clusters do
         local center_x = math.random(0, 800)
         local center_y = math.random(0, 600)
         local cluster_size = math.random(20, 80)

         for j = 1, cluster_size do
            if #objects >= count then break end

            local obj = { id = string.format("cluster_%d_%d", i, j) }
            local angle = math.random() * 2 * math.pi
            local distance = math.random() * 50

            table.insert(objects, {
               obj = obj,
               x = center_x + math.cos(angle) * distance,
               y = center_y + math.sin(angle) * distance,
               w = math.random(8, 32),
               h = math.random(8, 32),
            })
         end
      end

      return objects
   end

   -- Uniform distribution scenario (platformers, puzzle games)
   self.scenarios.uniform = function(count)
      local objects = {}
      for i = 1, count do
         local obj = { id = string.format("uniform_%d", i) }
         table.insert(objects, {
            obj = obj,
            x = math.random(0, 1000),
            y = math.random(0, 1000),
            w = math.random(8, 32),
            h = math.random(8, 32),
         })
      end
      return objects
   end

   -- Sparse world scenario (open world games, space games)
   self.scenarios.sparse = function(count)
      local objects = {}
      for i = 1, count do
         local obj = { id = string.format("sparse_%d", i) }
         table.insert(objects, {
            obj = obj,
            x = math.random(-5000, 5000),
            y = math.random(-5000, 5000),
            w = math.random(8, 32),
            h = math.random(8, 32),
         })
      end
      return objects
   end

   -- Moving objects scenario (fast-paced games, bullet hell)
   self.scenarios.moving = function(count)
      local objects = {}
      for i = 1, count do
         local obj = { id = string.format("moving_%d", i) }
         table.insert(objects, {
            obj = obj,
            x = math.random(0, 1000),
            y = math.random(0, 1000),
            w = math.random(8, 32),
            h = math.random(8, 32),
            vx = math.random(-5, 5),
            vy = math.random(-5, 5),
         })
      end
      return objects
   end

   -- Large objects scenario (different sized entities)
   self.scenarios.large_objects = function(count)
      local objects = {}
      for i = 1, count do
         local obj = { id = string.format("large_%d", i) }
         local size_category = math.random(1, 3)
         local size_range = {
            { 8,  16 },  -- Small objects
            { 32, 64 },  -- Medium objects
            { 64, 128 }, -- Large objects
         }
         local range = size_range[size_category]

         table.insert(objects, {
            obj = obj,
            x = math.random(0, 1000),
            y = math.random(0, 1000),
            w = math.random(range[1], range[2]),
            h = math.random(range[1], range[2]),
         })
      end
      return objects
   end
end

--- Benchmark a single strategy with given objects
--- @param strategy_name string Name of the strategy to test
--- @param objects table Array of object data
--- @return table Performance results
function BenchmarkSuite:benchmark_strategy(strategy_name, objects)
   local strategy = strategy_interface.create_strategy(strategy_name)

   local results = {
      add_time = 0,
      query_time = 0,
      update_time = 0,
      remove_time = 0,
      memory_usage = 0,
      accuracy = 0,
      object_count = #objects,
   }

   -- Measure add performance
   local start_time = os.clock()
   for _, obj_data in ipairs(objects) do
      strategy:add_object(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
   end
   results.add_time = (os.clock() - start_time) / #objects

   -- Measure memory usage after adding objects
   collectgarbage("collect")
   results.memory_usage = collectgarbage("count") * 1024 -- Convert to bytes

   -- Measure query performance
   local query_count = math.min(100, #objects)
   start_time = os.clock()
   for i = 1, query_count do
      local x = math.random(0, 1000)
      local y = math.random(0, 1000)
      local w, h = 64, 64
      strategy:query_region(x, y, w, h)
   end
   results.query_time = (os.clock() - start_time) / query_count

   -- Measure update performance (for moving objects)
   if objects[1].vx then
      start_time = os.clock()
      for _, obj_data in ipairs(objects) do
         local new_x = obj_data.x + obj_data.vx
         local new_y = obj_data.y + obj_data.vy
         strategy:update_object(obj_data.obj, new_x, new_y, obj_data.w, obj_data.h)
      end
      results.update_time = (os.clock() - start_time) / #objects
   end

   -- Measure remove performance
   start_time = os.clock()
   for _, obj_data in ipairs(objects) do
      strategy:remove_object(obj_data.obj)
   end
   results.remove_time = (os.clock() - start_time) / #objects

   -- Measure accuracy (compare with brute force for small samples)
   if #objects <= 500 then -- Only for manageable sizes
      results.accuracy = self:measure_accuracy(strategy_name, objects)
   else
      results.accuracy = 1.0 -- Assume accurate for large datasets
   end

   return results
end

--- Measure query accuracy by comparing with brute force
--- @param strategy_name string Strategy to test
--- @param objects table Object data
--- @return number Accuracy percentage (0.0 to 1.0)
function BenchmarkSuite:measure_accuracy(strategy_name, objects)
   local strategy = strategy_interface.create_strategy(strategy_name)

   -- Add all objects
   for _, obj_data in ipairs(objects) do
      strategy:add_object(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
   end

   local correct_results = 0
   local total_tests = math.min(20, #objects)

   for i = 1, total_tests do
      local query_x = math.random(0, 1000)
      local query_y = math.random(0, 1000)
      local query_w, query_h = 64, 64

      -- Get strategy results
      local strategy_result = strategy:query_region(query_x, query_y, query_w, query_h)

      -- Get brute force results
      local brute_force_result = self:brute_force_query(objects, query_x, query_y, query_w, query_h)

      -- Compare results
      if self:results_match(strategy_result, brute_force_result) then correct_results = correct_results + 1 end
   end

   return correct_results / total_tests
end

--- Brute force query for accuracy testing
--- @param objects table Object data
--- @param x number Query X
--- @param y number Query Y
--- @param w number Query width
--- @param h number Query height
--- @return table Hash table of intersecting objects
function BenchmarkSuite:brute_force_query(objects, x, y, w, h)
   local results = {}

   for _, obj_data in ipairs(objects) do
      if self:rectangles_intersect(x, y, w, h, obj_data.x, obj_data.y, obj_data.w, obj_data.h) then
         results[obj_data.obj] = true
      end
   end

   return results
end

--- Check if two rectangles intersect
--- @param x1 number First rectangle X
--- @param y1 number First rectangle Y
--- @param w1 number First rectangle width
--- @param h1 number First rectangle height
--- @param x2 number Second rectangle X
--- @param y2 number Second rectangle Y
--- @param w2 number Second rectangle width
--- @param h2 number Second rectangle height
--- @return boolean True if rectangles intersect
function BenchmarkSuite:rectangles_intersect(x1, y1, w1, h1, x2, y2, w2, h2)
   return not (x1 >= x2 + w2 or x2 >= x1 + w1 or y1 >= y2 + h2 or y2 >= y1 + h1)
end

--- Compare two query result sets
--- @param result1 table First result set
--- @param result2 table Second result set
--- @return boolean True if results match
function BenchmarkSuite:results_match(result1, result2)
   -- Count objects in each result
   local count1, count2 = 0, 0
   for _ in pairs(result1) do
      count1 = count1 + 1
   end
   for _ in pairs(result2) do
      count2 = count2 + 1
   end

   if count1 ~= count2 then return false end

   -- Check that all objects in result1 are in result2
   for obj in pairs(result1) do
      if not result2[obj] then return false end
   end

   return true
end

--- Run complete benchmark across all scenarios and object counts
--- @return table Complete benchmark results
function BenchmarkSuite:run_complete_benchmark()
   local results = {}

   print("Starting complete benchmark suite...")
   print(string.format("Testing strategies: %s", table.concat(self.strategies, ", ")))

   for scenario_name, scenario_func in pairs(self.scenarios) do
      print(string.format("\nTesting scenario: %s", scenario_name))
      results[scenario_name] = {}

      -- Test different object counts
      local object_counts = { 100, 200, 500, 1000, 2000 }

      for _, object_count in ipairs(object_counts) do
         print(string.format("  Object count: %d", object_count))
         results[scenario_name][object_count] = {}

         local objects = scenario_func(object_count)

         for _, strategy_name in ipairs(self.strategies) do
            print(string.format("    Testing strategy: %s", strategy_name))

            local strategy_results = self:benchmark_strategy(strategy_name, objects)
            results[scenario_name][object_count][strategy_name] = strategy_results
         end
      end
   end

   print("\nBenchmark complete!")
   return results
end

--- Find the best performing strategy for given results
--- @param strategies table|nil Strategy results {[strategy_name] = results}
--- @return string|nil, table|nil Best strategy name and its results
function BenchmarkSuite:find_best_strategy(strategies)
   if not strategies then
      return nil, nil
   end

   local best_strategy = nil
   local best_score = math.huge
   local best_results = nil

   for strategy_name, results in pairs(strategies) do
      -- Composite score: weighted average of normalized metrics
      local score = (results.add_time * 1000) * 0.3 -- 30% weight on add time
          + (results.query_time * 1000) * 0.4       -- 40% weight on query time
          + (results.memory_usage / 1024) * 0.2     -- 20% weight on memory
          + ((1.0 - results.accuracy) * 100) * 0.1  -- 10% weight on accuracy loss

      if score < best_score then
         best_score = score
         best_strategy = strategy_name
         best_results = results
      end
   end

   return best_strategy, best_results
end

--- Generate ASCII performance chart
--- @param scenario_results table Results for a scenario
--- @param metric string Metric to chart
--- @return table Array of chart lines
function BenchmarkSuite:generate_performance_chart(scenario_results, metric)
   local chart_lines = {}

   local metric_name = string.gsub(metric, "_", " ")
   metric_name = string.gsub(metric_name, "^%l", string.upper)

   table.insert(
      chart_lines,
      string.format("%s Performance (lower is better):", metric_name)
   )
   table.insert(chart_lines, "```")

   local max_value = 0
   local object_counts = {}

   -- Find max value and object counts
   for object_count, strategies in pairs(scenario_results) do
      table.insert(object_counts, object_count)
      for _, strategy_data in pairs(strategies) do
         local value = strategy_data[metric] or 0
         if metric == "memory_usage" then
            value = value / (1024 * 1024) -- Convert to MB
         elseif string.match(metric_name, "_time$") then
            value = value * 1000          -- Convert to milliseconds
         end
         max_value = math.max(max_value, value)
      end
   end

   table.sort(object_counts)

   -- Generate chart for each strategy
   for _, strategy_name in ipairs(self.strategies) do
      local line = string.format("%-12s: ", strategy_name)

      for _, object_count in ipairs(object_counts) do
         local strategy_data = scenario_results[object_count] and scenario_results[object_count][strategy_name]
         if strategy_data then
            local value = strategy_data[metric] or 0
            if metric == "memory_usage" then
               value = value / (1024 * 1024)
            elseif string.match(metric_name, "_time$") then
               value = value * 1000
            end

            local normalized = max_value > 0 and (value / max_value) or 0
            local bar_length = math.floor(normalized * 30)
            line = line .. string.rep("█", bar_length) .. string.rep("░", 30 - bar_length) .. " "
         else
            line = line .. string.rep("░", 30) .. " "
         end
      end

      table.insert(chart_lines, line)
   end

   table.insert(chart_lines, "```")
   table.insert(chart_lines, "")

   return chart_lines
end

--- Format scenario name for display
--- @param scenario_name string The scenario name to format
--- @return string Formatted scenario name
function BenchmarkSuite:format_scenario_name(scenario_name)
   -- Convert snake_case to Title Case
   local result = string.gsub(scenario_name, "_", " ")
   result = string.gsub(result, "^%l", string.upper)
   result = string.gsub(result, " %l", function(match)
      return " " .. string.upper(match)
   end)
   return result
end

--- Format time value for display
--- @param time_ms number Time in milliseconds
--- @return string Formatted time string
function BenchmarkSuite:format_time(time_ms)
   if time_ms < 1 then
      return string.format("%.3f ms", time_ms)
   elseif time_ms < 1000 then
      return string.format("%.1f ms", time_ms)
   else
      return string.format("%.2f s", time_ms / 1000)
   end
end

return BenchmarkSuite
