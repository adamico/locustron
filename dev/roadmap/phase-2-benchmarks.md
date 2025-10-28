# Phase 2: Performance Framework & Analysis (2 weeks)

## Overview
Phase 2 establishes a comprehensive benchmarking and performance analysis framework. This phase focuses on creating the tools needed to make informed strategy selection decisions and optimize performance.

---

## Phase 2.1: Benchmarking Infrastructure (7 days)

### Objectives
- Create comprehensive benchmarking framework for all spatial strategies
- Implement automated performance testing with multiple scenarios
- Generate detailed performance reports and recommendations
- Establish performance regression detection

### Key Features
- **Multiple Test Scenarios**: Clustered, uniform, sparse, and moving object patterns
- **Performance Metrics**: Add/remove/query time, memory usage, accuracy validation
- **Automated Testing**: Repeatable benchmarks across object counts and scenarios
- **Report Generation**: Detailed analysis with recommendations

### Implementation Framework
```lua
local BenchmarkSuite = {}
BenchmarkSuite.__index = BenchmarkSuite

function BenchmarkSuite.new(config)
  local self = setmetatable({}, BenchmarkSuite)
  
  self.scenarios = {}
  self.strategies = {"fixed_grid"} -- Will expand as strategies are added
  self.metrics = {"add_time", "query_time", "memory_usage", "accuracy"}
  self.iterations = config.iterations or 1000
  
  self:setup_scenarios()
  
  return self
end

function BenchmarkSuite:setup_scenarios()
  -- Clustered objects scenario (survivor games)
  self.scenarios.clustered = function(count)
    local objects = {}
    local clusters = math.max(1, count // 50)
    
    for i = 1, clusters do
      local center_x = math.random(0, 800)
      local center_y = math.random(0, 600)
      local cluster_size = math.random(20, 80)
      
      for j = 1, cluster_size do
        local obj = {id = string.format("cluster_%d_%d", i, j)}
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * 50
        
        table.insert(objects, {
          obj = obj,
          x = center_x + math.cos(angle) * distance,
          y = center_y + math.sin(angle) * distance,
          w = math.random(8, 32),
          h = math.random(8, 32)
        })
      end
    end
    
    return objects
  end
  
  -- Uniform distribution scenario
  self.scenarios.uniform = function(count)
    local objects = {}
    for i = 1, count do
      local obj = {id = string.format("uniform_%d", i)}
      table.insert(objects, {
        obj = obj,
        x = math.random(0, 1000),
        y = math.random(0, 1000),
        w = math.random(8, 32),
        h = math.random(8, 32)
      })
    end
    return objects
  end
  
  -- Sparse world scenario (open world games)
  self.scenarios.sparse = function(count)
    local objects = {}
    for i = 1, count do
      local obj = {id = string.format("sparse_%d", i)}
      table.insert(objects, {
        obj = obj,
        x = math.random(-5000, 5000),
        y = math.random(-5000, 5000),
        w = math.random(8, 32),
        h = math.random(8, 32)
      })
    end
    return objects
  end
  
  -- Moving objects scenario (fast-paced games)
  self.scenarios.moving = function(count)
    local objects = {}
    for i = 1, count do
      local obj = {id = string.format("moving_%d", i)}
      table.insert(objects, {
        obj = obj,
        x = math.random(0, 1000),
        y = math.random(0, 1000),
        w = math.random(8, 32),
        h = math.random(8, 32),
        vx = math.random(-5, 5),
        vy = math.random(-5, 5)
      })
    end
    return objects
  end
end

function BenchmarkSuite:benchmark_strategy(strategy_name, objects)
  local strategy = create_strategy(strategy_name, {cell_size = 32})
  local results = {
    add_time = 0,
    query_time = 0,
    update_time = 0,
    memory_usage = 0,
    accuracy = 0
  }
  
  -- Measure add performance
  local start_time = os.clock()
  for _, obj_data in ipairs(objects) do
    strategy:add_object(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
  end
  results.add_time = (os.clock() - start_time) / #objects
  
  -- Measure memory usage
  collectgarbage("collect")
  results.memory_usage = collectgarbage("count") * 1024
  
  -- Measure query performance
  start_time = os.clock()
  for i = 1, 100 do
    local x, y = math.random(0, 1000), math.random(0, 1000)
    strategy:query_region(x, y, 64, 64)
  end
  results.query_time = (os.clock() - start_time) / 100
  
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
  
  return results
end

function BenchmarkSuite:run_complete_benchmark()
  local results = {}
  
  for scenario_name, scenario_func in pairs(self.scenarios) do
    results[scenario_name] = {}
    
    for object_count = 100, 2000, 200 do
      results[scenario_name][object_count] = {}
      
      local objects = scenario_func(object_count)
      
      for _, strategy_name in ipairs(self.strategies) do
        local strategy_results = self:benchmark_strategy(strategy_name, objects)
        results[scenario_name][object_count][strategy_name] = strategy_results
      end
    end
  end
  
  return results
end
```

### Test Suite Integration
```lua
-- spec/benchmark_spec.lua
describe("BenchmarkSuite", function()
  local benchmark_suite
  
  before_each(function()
    benchmark_suite = BenchmarkSuite.new({iterations = 10})
  end)
  
  it("should create test scenarios", function()
    assert.is_function(benchmark_suite.scenarios.clustered)
    assert.is_function(benchmark_suite.scenarios.uniform)
    assert.is_function(benchmark_suite.scenarios.sparse)
    assert.is_function(benchmark_suite.scenarios.moving)
  end)
  
  it("should generate objects for scenarios", function()
    local objects = benchmark_suite.scenarios.uniform(100)
    assert.equals(100, #objects)
    
    for _, obj_data in ipairs(objects) do
      assert.is_not_nil(obj_data.obj)
      assert.is_number(obj_data.x)
      assert.is_number(obj_data.y)
      assert.is_number(obj_data.w)
      assert.is_number(obj_data.h)
    end
  end)
  
  it("should benchmark fixed grid strategy", function()
    local objects = benchmark_suite.scenarios.uniform(50)
    local results = benchmark_suite:benchmark_strategy("fixed_grid", objects)
    
    assert.is_number(results.add_time)
    assert.is_number(results.query_time)
    assert.is_number(results.memory_usage)
    assert.is_true(results.add_time > 0)
    assert.is_true(results.memory_usage > 0)
  end)
end)
```

---

## Phase 2.2: Performance Analysis Tools (7 days)

### Objectives
- Implement performance profiling and analysis tools
- Create strategy comparison utilities
- Generate performance recommendations
- Establish baseline performance metrics

### Performance Profiler
```lua
local PerformanceProfiler = {}
PerformanceProfiler.__index = PerformanceProfiler

function PerformanceProfiler.new()
  local self = setmetatable({}, PerformanceProfiler)
  
  self.operation_history = {}
  self.memory_snapshots = {}
  self.query_patterns = {}
  
  return self
end

function PerformanceProfiler:profile_strategy(strategy_name, workload)
  local strategy = create_strategy(strategy_name, workload.config)
  local profile = {
    strategy_name = strategy_name,
    operations = {},
    memory_timeline = {},
    query_analysis = {},
    recommendations = {}
  }
  
  -- Profile object additions
  for _, obj_data in ipairs(workload.objects) do
    local start_time = os.clock()
    strategy:add_object(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
    local duration = os.clock() - start_time
    
    table.insert(profile.operations, {
      type = "add",
      duration = duration,
      object_count = strategy:get_statistics().object_count
    })
    
    -- Memory snapshot every 100 operations
    if #profile.operations % 100 == 0 then
      collectgarbage("collect")
      table.insert(profile.memory_timeline, {
        operation_count = #profile.operations,
        memory_kb = collectgarbage("count")
      })
    end
  end
  
  -- Profile query performance
  for _, query in ipairs(workload.queries) do
    local start_time = os.clock()
    local results = strategy:query_region(query.x, query.y, query.w, query.h)
    local duration = os.clock() - start_time
    
    local result_count = 0
    for _ in pairs(results) do result_count = result_count + 1 end
    
    table.insert(profile.query_analysis, {
      query = query,
      duration = duration,
      result_count = result_count
    })
  end
  
  -- Generate recommendations
  profile.recommendations = self:generate_recommendations(profile, workload)
  
  return profile
end

function PerformanceProfiler:generate_recommendations(profile, workload)
  local recommendations = {}
  
  -- Analyze add performance
  local avg_add_time = 0
  for _, op in ipairs(profile.operations) do
    if op.type == "add" then
      avg_add_time = avg_add_time + op.duration
    end
  end
  avg_add_time = avg_add_time / #profile.operations
  
  if avg_add_time > 0.001 then  -- 1ms threshold
    table.insert(recommendations, {
      type = "performance",
      severity = "warning",
      message = "Add operations are slow. Consider using Hash Grid for better performance."
    })
  end
  
  -- Analyze memory usage
  if #profile.memory_timeline > 1 then
    local memory_growth = profile.memory_timeline[#profile.memory_timeline].memory_kb - 
                         profile.memory_timeline[1].memory_kb
    local objects_added = profile.memory_timeline[#profile.memory_timeline].operation_count
    local memory_per_object = memory_growth / objects_added
    
    if memory_per_object > 1.0 then  -- 1KB per object threshold
      table.insert(recommendations, {
        type = "memory",
        severity = "warning", 
        message = string.format("High memory usage: %.2f KB per object. Consider optimizing cell size.", memory_per_object)
      })
    end
  end
  
  -- Analyze query patterns
  local small_query_count = 0
  local large_query_count = 0
  
  for _, query_data in ipairs(profile.query_analysis) do
    local query_area = query_data.query.w * query_data.query.h
    if query_area < 1000 then
      small_query_count = small_query_count + 1
    elseif query_area > 10000 then
      large_query_count = large_query_count + 1
    end
  end
  
  if small_query_count > large_query_count * 2 then
    table.insert(recommendations, {
      type = "optimization",
      severity = "info",
      message = "Many small queries detected. Fixed Grid with smaller cell size may improve performance."
    })
  end
  
  return recommendations
end
```

### Report Generation
```lua
function PerformanceProfiler:generate_report(profiles)
  local report = {
    "# Locustron Performance Analysis Report",
    string.format("Generated: %s", os.date()),
    "",
    "## Executive Summary",
    ""
  }
  
  -- Strategy comparison table
  table.insert(report, "| Strategy | Avg Add Time (ms) | Avg Query Time (ms) | Memory Usage (KB) | Recommendations |")
  table.insert(report, "|----------|------------------|-------------------|------------------|-----------------|")
  
  for _, profile in ipairs(profiles) do
    local avg_add = self:calculate_average_add_time(profile)
    local avg_query = self:calculate_average_query_time(profile)
    local final_memory = profile.memory_timeline[#profile.memory_timeline].memory_kb
    local rec_count = #profile.recommendations
    
    table.insert(report, string.format(
      "| %s | %.3f | %.3f | %.1f | %d issues |",
      profile.strategy_name,
      avg_add * 1000,
      avg_query * 1000,
      final_memory,
      rec_count
    ))
  end
  
  table.insert(report, "")
  
  -- Detailed recommendations
  table.insert(report, "## Recommendations")
  table.insert(report, "")
  
  for _, profile in ipairs(profiles) do
    if #profile.recommendations > 0 then
      table.insert(report, string.format("### %s", profile.strategy_name))
      
      for _, rec in ipairs(profile.recommendations) do
        local icon = rec.severity == "warning" and "⚠️" or "ℹ️"
        table.insert(report, string.format("- %s **%s**: %s", icon, rec.type:upper(), rec.message))
      end
      
      table.insert(report, "")
    end
  end
  
  return table.concat(report, "\n")
end
```

## Deliverables

### 2.1 Benchmarking Infrastructure ✅ COMPLETED
- [x] **BenchmarkSuite Class**: Complete framework for automated testing (`src/vanilla/benchmark_suite.lua`)
- [x] **Test Scenarios**: Clustered, uniform, sparse, moving, and large object patterns  
- [x] **Strategy Testing**: Comprehensive performance measurement with accuracy validation
- [x] **Report Generation**: Automated analysis and performance charts
- [x] **CLI Tools**: Command-line interface for easy benchmarking (`benchmark.lua`)

### 2.2 Performance Analysis Tools ✅ COMPLETED
- [x] **PerformanceProfiler**: Detailed operation profiling (`src/vanilla/performance_profiler.lua`)
- [x] **Memory Tracking**: Timeline analysis of memory usage and growth patterns
- [x] **Recommendation Engine**: Automated optimization suggestions with severity levels
- [x] **Comparison Tools**: Side-by-side strategy analysis and scoring
- [x] **Integration Layer**: Strategy factory integration (`src/vanilla/benchmark_integration.lua`)
- [x] **Test Suite**: Comprehensive BDD tests (`spec/benchmark_suite_spec.lua`)
- [x] **Usage Examples**: Complete example scenarios (`benchmarks/examples/benchmark_examples.lua`)

## Success Criteria ✅ ACHIEVED

- **Comprehensive Testing**: All scenarios covered with repeatable benchmarks
- **Performance Insights**: Clear recommendations for strategy optimization with severity levels
- **Integration Ready**: Framework ready for additional strategies in Phase 5
- **Educational Value**: Reports provide learning about spatial partitioning performance
- **CLI Interface**: Easy-to-use command-line tools for automated benchmarking
- **Use Case Recommendations**: Intelligent strategy selection based on specific requirements

**Phase 2 Status**: ✅ COMPLETED - Ready for Phase 3 with comprehensive benchmarking framework

## Testing Strategy

```bash
# Run benchmark test suite
busted spec/benchmark_suite_spec.lua

# Generate performance report (command-line interface)
lua benchmark.lua --scenarios=uniform,clustered --strategies=fixed_grid --output=text

# Profile specific workload with detailed analysis
lua benchmark.lua --profile --verbose --iterations=5000

# Generate JSON output for integration
lua benchmark.lua --output=json > performance_results.json

# Quick strategy comparison
lua benchmarks/examples/benchmark_examples.lua
```

## Phase 2 Summary ✅ COMPLETED

**Duration**: 2 weeks (14 days) - COMPLETED IN ADVANCE
**Key Achievement**: Comprehensive performance analysis framework with CLI tools
**Benchmarking**: Automated testing across 5 scenarios (uniform, clustered, sparse, moving, large objects)
**Profiling**: Detailed performance insights with automated recommendations and severity levels
**Integration**: Strategy factory integration with use-case specific recommendations
**Foundation**: Ready for strategy comparison when additional strategies are implemented in Phase 5

### Key Components Delivered
1. **BenchmarkSuite** (`src/vanilla/benchmark_suite.lua`) - Complete testing framework
2. **PerformanceProfiler** (`src/vanilla/performance_profiler.lua`) - Detailed analysis tools
3. **BenchmarkIntegration** (`src/vanilla/benchmark_integration.lua`) - Strategy factory integration
4. **CLI Interface** (`src/vanilla/benchmark_cli.lua`) - Command-line tools
5. **Test Suite** (`spec/benchmark_suite_spec.lua`) - Comprehensive BDD tests
6. **Usage Examples** (`benchmarks/examples/benchmark_examples.lua`) - Complete documentation

The benchmarking framework provides the foundation for informed strategy selection decisions and will enable comprehensive performance comparison when additional strategies are implemented in Phase 5.