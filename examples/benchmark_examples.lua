-- Benchmarking Framework Usage Examples
-- Demonstrates how to use the Locustron benchmarking tools

local BenchmarkSuite = require("src.vanilla.benchmark_suite")
local PerformanceProfiler = require("src.vanilla.performance_profiler")
local BenchmarkIntegration = require("src.vanilla.benchmark_integration")

-- Example 1: Basic Strategy Benchmarking
print("=== Example 1: Basic Strategy Benchmarking ===")

local benchmark_suite = BenchmarkSuite.new({
  strategies = {"fixed_grid"},
  iterations = 1000
})

-- Test with uniform distribution
local objects = benchmark_suite.scenarios.uniform(100)
local results = benchmark_suite:benchmark_strategy("fixed_grid", objects, {cell_size = 32})

print("Fixed Grid Results:")
print("  Add time: " .. string.format("%.3f ms", results.add_time * 1000))
print("  Query time: " .. string.format("%.3f ms", results.query_time * 1000))
print("  Memory usage: " .. string.format("%.1f KB", results.memory_usage / 1024))
print("  Accuracy: " .. string.format("%.1f%%", results.accuracy * 100))
print()

-- Example 2: Performance Profiling
print("=== Example 2: Performance Profiling ===")

local profiler = PerformanceProfiler.new()

local workload = {
  scenario = "clustered",
  object_count = 200,
  objects = benchmark_suite.scenarios.clustered(200)
}

local profile = profiler:profile_strategy("fixed_grid", workload)
local report = profiler:generate_report({profile})

print("Profiling Report (excerpt):")
print(string.sub(report, 1, 500) .. "...")
print()

-- Example 3: Multi-Strategy Comparison
print("=== Example 3: Multi-Strategy Comparison ===")

-- Note: This example assumes multiple strategies are available
-- In practice, you would have quadtree, spatial_hash, etc. implementations

local strategies = {"fixed_grid"}  -- Add other strategies when available

for _, strategy_name in ipairs(strategies) do
  local strategy_results = benchmark_suite:benchmark_strategy(strategy_name, objects)
  print(string.format("%s: %.3f ms add, %.3f ms query",
    strategy_name,
    strategy_results.add_time * 1000,
    strategy_results.query_time * 1000))
end
print()

-- Example 4: Scenario Comparison
print("=== Example 4: Scenario Comparison ===")

local scenarios = {"uniform", "clustered", "sparse"}
local object_count = 150

for _, scenario_name in ipairs(scenarios) do
  local scenario_objects = benchmark_suite.scenarios[scenario_name](object_count)
  local scenario_results = benchmark_suite:benchmark_strategy("fixed_grid", scenario_objects)
  
  print(string.format("%s scenario: %.3f ms query, %.1f KB memory",
    scenario_name,
    scenario_results.query_time * 1000,
    scenario_results.memory_usage / 1024))
end
print()

-- Example 5: Use Case-Specific Recommendation
print("=== Example 5: Use Case-Specific Recommendation ===")

-- This example shows how to get recommendations for specific use cases
-- Note: Requires strategy factory integration

--[[
-- Initialize with strategy factory (when available)
local StrategyFactory = require("src.vanilla.strategy_factory")
local factory = StrategyFactory.new()
BenchmarkIntegration.initialize(factory)

local use_case = {
  expected_object_count = 500,
  query_frequency = "high",      -- high query frequency
  update_frequency = "medium",   -- moderate updates
  memory_constraint = "low",     -- some memory constraints
  spatial_distribution = "clustered"  -- objects tend to cluster
}

local recommendations = BenchmarkIntegration.recommend_strategy(use_case)

print("Strategy Recommendations for High-Query Clustered Use Case:")
for i, rec in ipairs(recommendations) do
  print(string.format("#%d: %s (score: %.2f, fit: %.0f%%)",
    rec.rank, rec.strategy, rec.score, rec.use_case_fit * 100))
  
  if #rec.strengths > 0 then
    print("     Strengths: " .. table.concat(rec.strengths, ", "))
  end
  if #rec.weaknesses > 0 then
    print("     Weaknesses: " .. table.concat(rec.weaknesses, ", "))
  end
end
--]]

print("(Strategy recommendations require strategy factory integration)")
print()

-- Example 6: Custom Performance Analysis
print("=== Example 6: Custom Performance Analysis ===")

-- Test different grid sizes for fixed grid
local grid_sizes = {16, 32, 64, 128}
local test_objects = benchmark_suite.scenarios.uniform(100)

print("Grid Size Performance Analysis:")
for _, grid_size in ipairs(grid_sizes) do
  local grid_results = benchmark_suite:benchmark_strategy(
    "fixed_grid", 
    test_objects,
    {cell_size = grid_size}
  )
  
  print(string.format("  %dx%d grid: %.3f ms query, %.1f KB memory, %.1f%% accuracy",
    grid_size, grid_size,
    grid_results.query_time * 1000,
    grid_results.memory_usage / 1024,
    grid_results.accuracy * 100))
end
print()

-- Example 7: Memory Usage Analysis
print("=== Example 7: Memory Usage Analysis ===")

local object_counts = {50, 100, 250, 500, 1000}

print("Memory Scaling Analysis:")
for _, count in ipairs(object_counts) do
  local scaling_objects = benchmark_suite.scenarios.uniform(count)
  local scaling_results = benchmark_suite:benchmark_strategy("fixed_grid", scaling_objects)
  
  print(string.format("  %d objects: %.1f KB (%.1f bytes/object)",
    count,
    scaling_results.memory_usage / 1024,
    scaling_results.memory_usage / count))
end
print()

-- Example 8: Accuracy Analysis
print("=== Example 8: Accuracy Analysis ===")

-- Test accuracy with different object densities
local densities = {
  {name = "sparse", count = 25},
  {name = "medium", count = 100},
  {name = "dense", count = 400}
}

print("Accuracy vs Object Density:")
for _, density in ipairs(densities) do
  local density_objects = benchmark_suite.scenarios.uniform(density.count)
  local accuracy_results = benchmark_suite:benchmark_strategy("fixed_grid", density_objects)
  
  print(string.format("  %s density (%d objects): %.2f%% accuracy",
    density.name,
    density.count,
    accuracy_results.accuracy * 100))
end
print()

-- Example 9: Query Pattern Analysis  
print("=== Example 9: Query Pattern Analysis ===")

-- Analyze performance with different query sizes
local query_sizes = {
  {name = "small", size = 32},
  {name = "medium", size = 64},
  {name = "large", size = 128}
}

print("Query Size Performance:")
for _, query_info in ipairs(query_sizes) do
  -- Create strategy instance for custom query testing
  -- Note: This requires actual strategy implementation
  print(string.format("  %s queries (%dx%d): [Would test %dx%d query performance]",
    query_info.name,
    query_info.size, query_info.size,
    query_info.size, query_info.size))
end
print()

-- Example 10: Moving Objects Performance
print("=== Example 10: Moving Objects Performance ===")

local moving_objects = benchmark_suite.scenarios.moving(100)
local moving_results = benchmark_suite:benchmark_strategy("fixed_grid", moving_objects)

print("Moving Objects Performance:")
print("  Initial add time: " .. string.format("%.3f ms", moving_results.add_time * 1000))
print("  Update time: " .. string.format("%.3f ms", (moving_results.update_time or 0) * 1000))
print("  Query time: " .. string.format("%.3f ms", moving_results.query_time * 1000))
print()

print("=== Benchmarking Examples Complete ===")
print()
print("Usage Tips:")
print("1. Use BenchmarkSuite for comparing different strategies")
print("2. Use PerformanceProfiler for detailed performance analysis")
print("3. Use BenchmarkIntegration for use-case specific recommendations")
print("4. Run 'lua benchmark.lua --help' for command-line interface")
print("5. Customize scenarios and object counts based on your specific needs")