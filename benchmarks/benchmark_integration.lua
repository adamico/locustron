-- Benchmark Integration
-- Integration layer between benchmarking framework and strategy factory

local BenchmarkSuite = require("benchmarks.benchmark_suite")
local PerformanceProfiler = require("benchmarks.performance_profiler")

local BenchmarkIntegration = {}

-- Strategy factory integration
BenchmarkIntegration.factory = nil

-- Initialize integration with strategy factory
function BenchmarkIntegration.initialize(strategy_factory) BenchmarkIntegration.factory = strategy_factory end

-- Get available strategies from factory
function BenchmarkIntegration.get_available_strategies()
   if not BenchmarkIntegration.factory then error("BenchmarkIntegration not initialized with strategy factory") end

   return BenchmarkIntegration.factory:get_registered_strategies()
end

-- Create strategy instance for benchmarking
function BenchmarkIntegration.create_strategy(strategy_name, config)
   if not BenchmarkIntegration.factory then error("BenchmarkIntegration not initialized with strategy factory") end

   return BenchmarkIntegration.factory:create(strategy_name, config or {})
end

-- Benchmark all registered strategies
function BenchmarkIntegration.benchmark_all_strategies(scenarios, config)
   config = config or {}
   local iterations = config.iterations or 1000
   local profiling = config.profiling or false

   local available_strategies = BenchmarkIntegration.get_available_strategies()

   if #available_strategies == 0 then error("No strategies registered in factory") end

   local benchmark_suite = BenchmarkSuite.new({
      strategies = available_strategies,
      iterations = iterations,
   })

   local profiler = profiling and PerformanceProfiler.new() or nil
   local results = {}

   -- Default scenarios if none provided
   scenarios = scenarios or { "uniform", "clustered", "sparse" }

   -- Object counts to test
   local object_counts = config.object_counts or { 50, 100, 250, 500 }

   for _, scenario_name in ipairs(scenarios) do
      results[scenario_name] = {}

      -- Validate scenario exists
      if not benchmark_suite.scenarios[scenario_name] then
         print("Warning: Unknown scenario '" .. scenario_name .. "', skipping")
         goto continue_scenario
      end

      for _, count in ipairs(object_counts) do
         results[scenario_name][count] = {}

         -- Generate scenario objects
         local objects = benchmark_suite.scenarios[scenario_name](count)

         for _, strategy_name in ipairs(available_strategies) do
            -- Run benchmark
            local strategy_results = benchmark_suite:benchmark_strategy(strategy_name, objects)

            results[scenario_name][count][strategy_name] = strategy_results

            -- Add profiling if enabled
            if profiler then
               local workload = {
                  scenario = scenario_name,
                  object_count = count,
                  objects = objects,
               }

               local profile = profiler:profile_strategy(strategy_name, workload)
               results[scenario_name][count][strategy_name].profile = profile
            end
         end
      end

      ::continue_scenario::
   end

   return results, profiler
end

-- Generate strategy recommendation based on specific use case
function BenchmarkIntegration.recommend_strategy(use_case_config)
   use_case_config = use_case_config or {}

   -- Extract use case characteristics
   local object_count = use_case_config.expected_object_count or 500
   local query_frequency = use_case_config.query_frequency or "medium" -- low, medium, high
   local update_frequency = use_case_config.update_frequency or "medium"
   local memory_constraint = use_case_config.memory_constraint or "none" -- none, low, strict
   local spatial_distribution = use_case_config.spatial_distribution or "uniform" -- uniform, clustered, sparse

   -- Create targeted benchmark
   local scenarios = { spatial_distribution }
   local object_counts = { object_count }

   local benchmark_config = {
      iterations = use_case_config.benchmark_iterations or 1000,
      profiling = true,
      object_counts = object_counts,
      strategy_configs = use_case_config.strategy_configs,
   }

   local results, profiler = BenchmarkIntegration.benchmark_all_strategies(scenarios, benchmark_config)

   -- Analyze results for recommendation
   local recommendations = BenchmarkIntegration.analyze_for_recommendation(results, profiler, use_case_config)

   return recommendations
end

-- Analyze benchmark results to generate strategy recommendations
function BenchmarkIntegration.analyze_for_recommendation(results, profiler, use_case_config)
   local recommendations = {}

   -- Extract performance data for analysis
   local strategy_performance = {}

   for scenario_name, scenario_results in pairs(results) do
      for count, count_results in pairs(scenario_results) do
         for strategy_name, strategy_results in pairs(count_results) do
            if not strategy_performance[strategy_name] then
               strategy_performance[strategy_name] = {
                  add_times = {},
                  query_times = {},
                  update_times = {},
                  memory_usage = {},
                  accuracy = {},
                  profiles = {},
               }
            end

            table.insert(strategy_performance[strategy_name].add_times, strategy_results.add_time)
            table.insert(strategy_performance[strategy_name].query_times, strategy_results.query_time)
            table.insert(strategy_performance[strategy_name].update_times, strategy_results.update_time or 0)
            table.insert(strategy_performance[strategy_name].memory_usage, strategy_results.memory_usage)
            table.insert(strategy_performance[strategy_name].accuracy, strategy_results.accuracy)

            if strategy_results.profile then
               table.insert(strategy_performance[strategy_name].profiles, strategy_results.profile)
            end
         end
      end
   end

   -- Score strategies based on use case requirements
   local strategy_scores = {}

   for strategy_name, performance in pairs(strategy_performance) do
      local score = BenchmarkIntegration.calculate_strategy_score(performance, use_case_config)
      strategy_scores[strategy_name] = score
   end

   -- Sort by score (highest first)
   local sorted_strategies = {}
   for strategy_name, score in pairs(strategy_scores) do
      table.insert(
         sorted_strategies,
         { name = strategy_name, score = score, performance = strategy_performance[strategy_name] }
      )
   end

   table.sort(sorted_strategies, function(a, b) return a.score > b.score end)

   -- Generate recommendations
   for i, strategy_data in ipairs(sorted_strategies) do
      local recommendation = {
         rank = i,
         strategy = strategy_data.name,
         score = strategy_data.score,
         strengths = {},
         weaknesses = {},
         use_case_fit = BenchmarkIntegration.assess_use_case_fit(strategy_data.performance, use_case_config),
      }

      -- Analyze strengths and weaknesses
      local avg_add_time = BenchmarkIntegration.calculate_average(strategy_data.performance.add_times)
      local avg_query_time = BenchmarkIntegration.calculate_average(strategy_data.performance.query_times)
      local avg_memory = BenchmarkIntegration.calculate_average(strategy_data.performance.memory_usage)
      local avg_accuracy = BenchmarkIntegration.calculate_average(strategy_data.performance.accuracy)

      if avg_add_time < 0.001 then
         table.insert(recommendation.strengths, "Fast object insertion")
      elseif avg_add_time > 0.005 then
         table.insert(recommendation.weaknesses, "Slow object insertion")
      end

      if avg_query_time < 0.001 then
         table.insert(recommendation.strengths, "Fast spatial queries")
      elseif avg_query_time > 0.005 then
         table.insert(recommendation.weaknesses, "Slow spatial queries")
      end

      if avg_memory < 50000 then -- 50KB
         table.insert(recommendation.strengths, "Low memory usage")
      elseif avg_memory > 500000 then -- 500KB
         table.insert(recommendation.weaknesses, "High memory usage")
      end

      if avg_accuracy > 0.99 then
         table.insert(recommendation.strengths, "High query accuracy")
      elseif avg_accuracy < 0.95 then
         table.insert(recommendation.weaknesses, "Query accuracy issues")
      end

      table.insert(recommendations, recommendation)
   end

   return recommendations
end

-- Calculate strategy score based on use case requirements
function BenchmarkIntegration.calculate_strategy_score(performance, use_case_config)
   local weights = {
      add_time = 1.0,
      query_time = 1.0,
      update_time = 1.0,
      memory = 1.0,
      accuracy = 2.0, -- Accuracy is always important
   }

   -- Adjust weights based on use case
   if use_case_config.query_frequency == "high" then
      weights.query_time = 2.0
   elseif use_case_config.query_frequency == "low" then
      weights.query_time = 0.5
   end

   if use_case_config.update_frequency == "high" then
      weights.add_time = 2.0
      weights.update_time = 2.0
   elseif use_case_config.update_frequency == "low" then
      weights.add_time = 0.5
      weights.update_time = 0.5
   end

   if use_case_config.memory_constraint == "strict" then
      weights.memory = 3.0
   elseif use_case_config.memory_constraint == "low" then
      weights.memory = 2.0
   end

   -- Calculate normalized scores (lower times are better, higher accuracy is better)
   local avg_add_time = BenchmarkIntegration.calculate_average(performance.add_times)
   local avg_query_time = BenchmarkIntegration.calculate_average(performance.query_times)
   local avg_update_time = BenchmarkIntegration.calculate_average(performance.update_times)
   local avg_memory = BenchmarkIntegration.calculate_average(performance.memory_usage)
   local avg_accuracy = BenchmarkIntegration.calculate_average(performance.accuracy)

   -- Normalize to 0-1 scale (using reasonable maximums)
   local add_score = math.max(0, 1 - (avg_add_time / 0.01)) -- 10ms is bad
   local query_score = math.max(0, 1 - (avg_query_time / 0.01))
   local update_score = math.max(0, 1 - (avg_update_time / 0.01))
   local memory_score = math.max(0, 1 - (avg_memory / 1000000)) -- 1MB is bad
   local accuracy_score = avg_accuracy -- Already 0-1

   -- Calculate weighted score
   local total_weight = weights.add_time + weights.query_time + weights.update_time + weights.memory + weights.accuracy
   local score = (
      add_score * weights.add_time
      + query_score * weights.query_time
      + update_score * weights.update_time
      + memory_score * weights.memory
      + accuracy_score * weights.accuracy
   ) / total_weight

   return score
end

-- Assess how well a strategy fits the use case
function BenchmarkIntegration.assess_use_case_fit(performance, use_case_config)
   local fit_score = 0
   local total_checks = 0

   local avg_add_time = BenchmarkIntegration.calculate_average(performance.add_times)
   local avg_query_time = BenchmarkIntegration.calculate_average(performance.query_times)
   local avg_memory = BenchmarkIntegration.calculate_average(performance.memory_usage)
   local avg_accuracy = BenchmarkIntegration.calculate_average(performance.accuracy)

   -- Query frequency fit
   total_checks = total_checks + 1
   if use_case_config.query_frequency == "high" and avg_query_time < 0.001 then
      fit_score = fit_score + 1
   elseif use_case_config.query_frequency == "medium" and avg_query_time < 0.005 then
      fit_score = fit_score + 1
   elseif use_case_config.query_frequency == "low" then
      fit_score = fit_score + 1 -- Any performance is acceptable for low frequency
   end

   -- Update frequency fit
   total_checks = total_checks + 1
   if use_case_config.update_frequency == "high" and avg_add_time < 0.001 then
      fit_score = fit_score + 1
   elseif use_case_config.update_frequency == "medium" and avg_add_time < 0.005 then
      fit_score = fit_score + 1
   elseif use_case_config.update_frequency == "low" then
      fit_score = fit_score + 1
   end

   -- Memory constraint fit
   total_checks = total_checks + 1
   if use_case_config.memory_constraint == "strict" and avg_memory < 100000 then -- 100KB
      fit_score = fit_score + 1
   elseif use_case_config.memory_constraint == "low" and avg_memory < 500000 then -- 500KB
      fit_score = fit_score + 1
   elseif use_case_config.memory_constraint == "none" then
      fit_score = fit_score + 1
   end

   -- Accuracy requirement (always important)
   total_checks = total_checks + 1
   if avg_accuracy > 0.95 then fit_score = fit_score + 1 end

   return fit_score / total_checks
end

-- Calculate average of a list of numbers
function BenchmarkIntegration.calculate_average(numbers)
   if #numbers == 0 then return 0 end

   local sum = 0
   for _, num in ipairs(numbers) do
      sum = sum + num
   end

   return sum / #numbers
end

-- Generate comprehensive benchmark report
function BenchmarkIntegration.generate_comprehensive_report(results, profiler, use_case_config)
   local report = {}

   table.insert(report, "=== Locustron Spatial Partitioning Strategy Analysis ===")
   table.insert(report, "")

   -- Use case summary
   if use_case_config then
      table.insert(report, "Use Case Configuration:")
      table.insert(report, "  Expected object count: " .. (use_case_config.expected_object_count or "500"))
      table.insert(report, "  Query frequency: " .. (use_case_config.query_frequency or "medium"))
      table.insert(report, "  Update frequency: " .. (use_case_config.update_frequency or "medium"))
      table.insert(report, "  Memory constraint: " .. (use_case_config.memory_constraint or "none"))
      table.insert(report, "  Spatial distribution: " .. (use_case_config.spatial_distribution or "uniform"))
      table.insert(report, "")
   end

   -- Performance summary
   table.insert(report, "Performance Summary:")
   table.insert(report, string.rep("-", 60))

   local strategy_summaries = {}
   for scenario_name, scenario_results in pairs(results) do
      for count, count_results in pairs(scenario_results) do
         for strategy_name, strategy_results in pairs(count_results) do
            if not strategy_summaries[strategy_name] then
               strategy_summaries[strategy_name] = {
                  add_times = {},
                  query_times = {},
                  memory_usage = {},
                  accuracy = {},
               }
            end

            table.insert(strategy_summaries[strategy_name].add_times, strategy_results.add_time)
            table.insert(strategy_summaries[strategy_name].query_times, strategy_results.query_time)
            table.insert(strategy_summaries[strategy_name].memory_usage, strategy_results.memory_usage)
            table.insert(strategy_summaries[strategy_name].accuracy, strategy_results.accuracy)
         end
      end
   end

   for strategy_name, summary in pairs(strategy_summaries) do
      local avg_add = BenchmarkIntegration.calculate_average(summary.add_times)
      local avg_query = BenchmarkIntegration.calculate_average(summary.query_times)
      local avg_memory = BenchmarkIntegration.calculate_average(summary.memory_usage)
      local avg_accuracy = BenchmarkIntegration.calculate_average(summary.accuracy)

      table.insert(report, string.format("%s:", strategy_name))
      table.insert(report, string.format("  Add time: %.3f ms", avg_add * 1000))
      table.insert(report, string.format("  Query time: %.3f ms", avg_query * 1000))
      table.insert(report, string.format("  Memory usage: %.1f KB", avg_memory / 1024))
      table.insert(report, string.format("  Accuracy: %.1f%%", avg_accuracy * 100))
      table.insert(report, "")
   end

   -- Profiling report if available
   if profiler then
      local profiles = {}
      for scenario_name, scenario_results in pairs(results) do
         for count, count_results in pairs(scenario_results) do
            for strategy_name, strategy_results in pairs(count_results) do
               if strategy_results.profile then table.insert(profiles, strategy_results.profile) end
            end
         end
      end

      if #profiles > 0 then
         local profiler_report = profiler:generate_report(profiles)
         table.insert(report, profiler_report)
      end
   end

   return table.concat(report, "\n")
end

-- Quick strategy comparison for common use cases
function BenchmarkIntegration.quick_comparison(strategies, object_count)
   strategies = strategies or BenchmarkIntegration.get_available_strategies()
   object_count = object_count or 500

   local config = {
      iterations = 100, -- Quick test
      object_counts = { object_count },
      profiling = false,
   }

   local results = BenchmarkIntegration.benchmark_all_strategies({ "uniform" }, config)

   -- Extract quick comparison data
   local comparison = {}
   for scenario_name, scenario_results in pairs(results) do
      for count, count_results in pairs(scenario_results) do
         for strategy_name, strategy_results in pairs(count_results) do
            comparison[strategy_name] = {
               add_time_ms = strategy_results.add_time * 1000,
               query_time_ms = strategy_results.query_time * 1000,
               memory_kb = strategy_results.memory_usage / 1024,
               accuracy_percent = strategy_results.accuracy * 100,
            }
         end
      end
   end

   return comparison
end

return BenchmarkIntegration
