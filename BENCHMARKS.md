# Locustron Benchmarking Framework

A comprehensive performance analysis framework for spatial partitioning strategies in Locustron.

## Quick Start

### Command-Line Interface

```bash
# Basic benchmark with default settings
lua benchmark.lua

# Compare strategies with specific scenarios
lua benchmark.lua --strategies=fixed_grid --scenarios=uniform,clustered

# Detailed profiling with verbose output
lua benchmark.lua --profile --verbose --iterations=5000

# Generate JSON output for integration
lua benchmark.lua --output=json > results.json

# CSV output for spreadsheet analysis
lua benchmark.lua --output=csv > performance.csv
```

### Programmatic Usage

```lua
local BenchmarkSuite = require("benchmarks.vanilla.benchmark_suite")
local PerformanceProfiler = require("benchmarks.vanilla.performance_profiler")

-- Create benchmark suite
local benchmark = BenchmarkSuite.new({
  strategies = {"fixed_grid"},
  iterations = 1000
})

-- Generate test data
local objects = benchmark.scenarios.uniform(100)

-- Run benchmark
local results = benchmark:benchmark_strategy("fixed_grid", objects)
print("Query time: " .. (results.query_time * 1000) .. " ms")

-- Performance profiling
local profiler = PerformanceProfiler.new()
local workload = {objects = objects, scenario = "uniform"}
local profile = profiler:profile_strategy("fixed_grid", workload)
local report = profiler:generate_report({profile})
print(report)
```

## Available Test Scenarios

1. **uniform** - Objects distributed uniformly across space
2. **clustered** - Objects grouped in clusters (typical for survivor games)
3. **sparse** - Objects spread across a large sparse world
4. **moving** - Objects with velocity vectors (fast-paced games)
5. **large_objects** - Objects with varying sizes

## Output Formats

- **text** - Human-readable terminal output (default)
- **json** - Machine-readable JSON for integration
- **csv** - Spreadsheet-compatible CSV format

## Performance Metrics

- **Add Time** - Time to insert objects into spatial structure
- **Query Time** - Time to perform spatial queries
- **Update Time** - Time to update object positions (moving objects)
- **Remove Time** - Time to remove objects from structure
- **Memory Usage** - Memory consumption in bytes
- **Accuracy** - Query result accuracy percentage

## Integration with Strategy Factory

```lua
local BenchmarkIntegration = require("benchmarks.vanilla.benchmark_integration")
local StrategyFactory = require("src.vanilla.strategy_interface")

-- Initialize integration
BenchmarkIntegration.initialize(StrategyFactory)

-- Get strategy recommendations for specific use case
local use_case = {
  expected_object_count = 500,
  query_frequency = "high",
  spatial_distribution = "clustered"
}

local recommendations = BenchmarkIntegration.recommend_strategy(use_case)
for _, rec in ipairs(recommendations) do
  print(rec.rank .. ": " .. rec.strategy .. " (score: " .. rec.score .. ")")
end
```

## Running Tests

```bash
# Run benchmark framework tests
busted tests/vanilla/benchmark_suite_spec.lua

# View example usage
lua examples/benchmark_examples.lua
```

## Directory Structure

```
benchmarks/vanilla/
├── benchmark_suite.lua       # Core benchmarking framework
├── performance_profiler.lua  # Detailed performance analysis
├── benchmark_integration.lua # Strategy factory integration
└── benchmark_cli.lua         # Command-line interface

src/vanilla/
├── strategy_interface.lua    # Strategy pattern and factory
├── fixed_grid_strategy.lua   # Fixed grid implementation
├── init_strategies.lua       # Strategy registration
└── doubly_linked_list.lua    # Utility data structure

tests/vanilla/
└── benchmark_suite_spec.lua  # BDD test suite

examples/
└── benchmark_examples.lua    # Usage examples

benchmark.lua                 # CLI runner script
```

## Use Cases

- **Performance Optimization** - Find bottlenecks and optimization opportunities
- **Strategy Comparison** - Compare different spatial partitioning approaches
- **Configuration Tuning** - Optimize parameters like grid cell size
- **Regression Testing** - Detect performance regressions during development
- **Architecture Decisions** - Choose the best strategy for specific game types

For more detailed examples, see `examples/benchmark_examples.lua`.