-- Benchmarking CLI Tool
-- Command-line interface for running spatial partitioning benchmarks

-- Initialize strategies first
require("src.vanilla.init_strategies")

local BenchmarkSuite = require("src.vanilla.benchmark_suite")
local PerformanceProfiler = require("src.vanilla.performance_profiler")

local BenchmarkCLI = {}

-- Available strategies for benchmarking
local AVAILABLE_STRATEGIES = {
   "fixed_grid",
   "quadtree",
   "spatial_hash",
   "r_tree"
}

-- Command-line argument parsing
function BenchmarkCLI.parse_args(args)
   local config = {
      strategies = {},
      scenarios = {},
      iterations = 1000,
      output_format = "text",
      profile = false,
      verbose = false,
      help = false
   }

   local i = 1
   while i <= #args do
      local arg = args[i]

      if arg == "--help" or arg == "-h" then
         config.help = true
      elseif arg == "--strategies" or arg == "-s" then
         i = i + 1
         if i <= #args then
            config.strategies = BenchmarkCLI.parse_list(args[i])
         end
      elseif arg == "--scenarios" or arg == "-c" then
         i = i + 1
         if i <= #args then
            config.scenarios = BenchmarkCLI.parse_list(args[i])
         end
      elseif arg == "--iterations" or arg == "-i" then
         i = i + 1
         if i <= #args then
            config.iterations = tonumber(args[i]) or config.iterations
         end
      elseif arg == "--output" or arg == "-o" then
         i = i + 1
         if i <= #args then
            config.output_format = args[i]
         end
      elseif arg == "--profile" or arg == "-p" then
         config.profile = true
      elseif arg == "--verbose" or arg == "-v" then
         config.verbose = true
      end

      i = i + 1
   end

   -- Set defaults if not specified
   if #config.strategies == 0 then
      config.strategies = {"fixed_grid"}
   end

   if #config.scenarios == 0 then
      config.scenarios = {"uniform", "clustered"}
   end

   return config
end

-- Parse comma-separated list
function BenchmarkCLI.parse_list(str)
   local list = {}
   for item in str:gmatch("[^,]+") do
      table.insert(list, item:match("^%s*(.-)%s*$")) -- trim whitespace
   end
   return list
end

-- Display help message
function BenchmarkCLI.show_help()
   print([[
Locustron Spatial Partitioning Benchmark CLI

USAGE:
  lua benchmark_cli.lua [OPTIONS]

OPTIONS:
  -h, --help              Show this help message
  -s, --strategies LIST   Comma-separated list of strategies to benchmark
                         Available: ]]..table.concat(AVAILABLE_STRATEGIES, ", ")..[[
  -c, --scenarios LIST    Comma-separated list of test scenarios
                         Available: uniform, clustered, sparse, moving, large_objects
  -i, --iterations NUM    Number of iterations per test (default: 1000)
  -o, --output FORMAT     Output format: text, json, csv (default: text)
  -p, --profile           Enable detailed performance profiling
  -v, --verbose           Enable verbose output

EXAMPLES:
  # Basic benchmark with default settings
  lua benchmark_cli.lua

  # Compare multiple strategies
  lua benchmark_cli.lua -s "fixed_grid,quadtree,spatial_hash"

  # Test specific scenarios with profiling
  lua benchmark_cli.lua -c "clustered,moving" -p

  # Performance testing with high iteration count
  lua benchmark_cli.lua -i 10000 -v

  # Export results as JSON
  lua benchmark_cli.lua -o json > results.json
]])
end

-- Run benchmark suite
function BenchmarkCLI.run_benchmark(config)
   if config.verbose then
      print("Starting benchmark with configuration:")
      print("  Strategies: "..table.concat(config.strategies, ", "))
      print("  Scenarios: "..table.concat(config.scenarios, ", "))
      print("  Iterations: "..config.iterations)
      print("  Output format: "..config.output_format)
      print("  Profiling: "..(config.profile and "enabled" or "disabled"))
      print()
   end

   local benchmark_suite = BenchmarkSuite.new({
      strategies = config.strategies,
      iterations = config.iterations
   })

   local profiler = config.profile and PerformanceProfiler.new() or nil
   local results = {}

   -- Object counts to test
   local object_counts = {50, 100, 250, 500, 1000}

   for _, scenario_name in ipairs(config.scenarios) do
      if config.verbose then
         print("Running scenario: "..scenario_name)
      end

      results[scenario_name] = {}

      for _, count in ipairs(object_counts) do
         if config.verbose then
            print("  Object count: "..count)
         end

         results[scenario_name][count] = {}

         -- Generate scenario objects
         local scenario_func = benchmark_suite.scenarios[scenario_name]
         if not scenario_func then
            print("Warning: Unknown scenario '"..scenario_name.."', skipping")
            goto continue_scenario
         end

         local objects = scenario_func(count)

         for _, strategy_name in ipairs(config.strategies) do
            if config.verbose then
               print("    Strategy: "..strategy_name)
            end

            -- Run benchmark
            local strategy_results = benchmark_suite:benchmark_strategy(
               strategy_name,
               objects,
               {} -- default configuration
            )

            results[scenario_name][count][strategy_name] = strategy_results

            -- Run profiling if enabled
            if profiler then
               local workload = {
                  scenario = scenario_name,
                  object_count = count,
                  objects = objects
               }

               local profile = profiler:profile_strategy(strategy_name, workload)
               results[scenario_name][count][strategy_name].profile = profile
            end
         end
      end

      ::continue_scenario::
   end

   -- Generate output
   if config.output_format == "json" then
      BenchmarkCLI.output_json(results, profiler)
   elseif config.output_format == "csv" then
      BenchmarkCLI.output_csv(results)
   else
      BenchmarkCLI.output_text(results, profiler, config.verbose)
   end

   return results
end

-- Output results in text format
function BenchmarkCLI.output_text(results, profiler, verbose)
   print("=== Locustron Spatial Partitioning Benchmark Results ===")
   print()

   -- Summary table
   print("Performance Summary (Average across all scenarios):")
   print("+"..string.rep("-", 80).."+")
   print(string.format("| %-15s | %-12s | %-12s | %-12s | %-10s |",
      "Strategy", "Add Time (ms)", "Query Time", "Memory (KB)", "Accuracy"))
   print("+"..string.rep("-", 80).."+")

   local strategy_totals = {}
   local strategy_counts = {}

   -- Aggregate results
   for scenario_name, scenario_results in pairs(results) do
      for count, count_results in pairs(scenario_results) do
         for strategy_name, strategy_results in pairs(count_results) do
            if not strategy_totals[strategy_name] then
               strategy_totals[strategy_name] = {
                  add_time = 0,
                  query_time = 0,
                  memory_usage = 0,
                  accuracy = 0
               }
               strategy_counts[strategy_name] = 0
            end

            strategy_totals[strategy_name].add_time = strategy_totals[strategy_name].add_time + strategy_results
            .add_time
            strategy_totals[strategy_name].query_time = strategy_totals[strategy_name].query_time +
               strategy_results.query_time
            strategy_totals[strategy_name].memory_usage = strategy_totals[strategy_name].memory_usage +
               strategy_results.memory_usage
            strategy_totals[strategy_name].accuracy = strategy_totals[strategy_name].accuracy + strategy_results
            .accuracy
            strategy_counts[strategy_name] = strategy_counts[strategy_name] + 1
         end
      end
   end

   -- Display averages
   for strategy_name, totals in pairs(strategy_totals) do
      local count = strategy_counts[strategy_name]
      local avg_add = totals.add_time / count
      local avg_query = totals.query_time / count
      local avg_memory = totals.memory_usage / count
      local avg_accuracy = totals.accuracy / count

      print(string.format("| %-15s | %-12.3f | %-12.3f | %-12.1f | %-10.2f%% |",
         strategy_name, avg_add * 1000, avg_query * 1000, avg_memory / 1024, avg_accuracy * 100))
   end

   print("+"..string.rep("-", 80).."+")
   print()

   -- Detailed results if verbose
   if verbose then
      print("Detailed Results by Scenario:")
      print()

      for scenario_name, scenario_results in pairs(results) do
         print("Scenario: "..scenario_name)
         print(string.rep("-", 50))

         for count, count_results in pairs(scenario_results) do
            print("  Object count: "..count)

            for strategy_name, strategy_results in pairs(count_results) do
               print(string.format("    %s: %.3fms add, %.3fms query, %.1fKB memory, %.1f%% accuracy",
                  strategy_name,
                  strategy_results.add_time * 1000,
                  strategy_results.query_time * 1000,
                  strategy_results.memory_usage / 1024,
                  strategy_results.accuracy * 100))
            end
            print()
         end
      end
   end

   -- Performance recommendations if profiling enabled
   if profiler then
      print("Performance Recommendations:")
      print(string.rep("=", 50))

      -- Generate profiler report for all strategies
      local profiles = {}
      for scenario_name, scenario_results in pairs(results) do
         for count, count_results in pairs(scenario_results) do
            for strategy_name, strategy_results in pairs(count_results) do
               if strategy_results.profile then
                  table.insert(profiles, strategy_results.profile)
               end
            end
         end
      end

      if #profiles > 0 then
         local report = profiler:generate_report(profiles)
         print(report)
      end
   end
end

-- Output results in JSON format
function BenchmarkCLI.output_json(results, profiler)
   local json = require("json") -- Assuming JSON library is available

   local output = {
      benchmark_results = results,
      timestamp = os.date("%Y-%m-%d %H:%M:%S"),
      format_version = "1.0"
   }

   if profiler then
      output.profiling_enabled = true
   end

   print(json.encode(output))
end

-- Output results in CSV format
function BenchmarkCLI.output_csv(results)
   -- CSV header
   print(
      "scenario,object_count,strategy,add_time_ms,query_time_ms,update_time_ms,remove_time_ms,memory_kb,accuracy_percent")

   for scenario_name, scenario_results in pairs(results) do
      for count, count_results in pairs(scenario_results) do
         for strategy_name, strategy_results in pairs(count_results) do
            print(string.format("%s,%d,%s,%.3f,%.3f,%.3f,%.3f,%.1f,%.2f",
               scenario_name,
               count,
               strategy_name,
               strategy_results.add_time * 1000,
               strategy_results.query_time * 1000,
               (strategy_results.update_time or 0) * 1000,
               (strategy_results.remove_time or 0) * 1000,
               strategy_results.memory_usage / 1024,
               strategy_results.accuracy * 100))
         end
      end
   end
end

-- Validate configuration
function BenchmarkCLI.validate_config(config)
   local errors = {}

   -- Validate strategies
   for _, strategy in ipairs(config.strategies) do
      local found = false
      for _, available in ipairs(AVAILABLE_STRATEGIES) do
         if strategy == available then
            found = true
            break
         end
      end
      if not found then
         table.insert(errors, "Unknown strategy: "..strategy)
      end
   end

   -- Validate scenarios
   local available_scenarios = {"uniform", "clustered", "sparse", "moving", "large_objects"}
   for _, scenario in ipairs(config.scenarios) do
      local found = false
      for _, available in ipairs(available_scenarios) do
         if scenario == available then
            found = true
            break
         end
      end
      if not found then
         table.insert(errors, "Unknown scenario: "..scenario)
      end
   end

   -- Validate iterations
   if config.iterations < 1 then
      table.insert(errors, "Iterations must be >= 1")
   end

   -- Validate output format
   local valid_formats = {"text", "json", "csv"}
   local format_valid = false
   for _, format in ipairs(valid_formats) do
      if config.output_format == format then
         format_valid = true
         break
      end
   end
   if not format_valid then
      table.insert(errors, "Output format must be one of: "..table.concat(valid_formats, ", "))
   end

   return errors
end

-- Main CLI entry point
function BenchmarkCLI.main(args)
   local config = BenchmarkCLI.parse_args(args or {})

   if config.help then
      BenchmarkCLI.show_help()
      return
   end

   -- Validate configuration
   local errors = BenchmarkCLI.validate_config(config)
   if #errors > 0 then
      print("Configuration errors:")
      for _, error in ipairs(errors) do
         print("  "..error)
      end
      print("\nUse --help for usage information.")
      return
   end

   -- Run benchmark
   local success, results = pcall(BenchmarkCLI.run_benchmark, config)

   if not success then
      print("Error running benchmark:")
      print(results)
      return
   end

   if config.verbose then
      print("\nBenchmark completed successfully!")
   end
end

return BenchmarkCLI
