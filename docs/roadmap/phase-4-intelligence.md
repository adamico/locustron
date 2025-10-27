# Phase 4: Intelligent Selection & Benchmarks (2 weeks)

## Overview
Phase 4 implements intelligent strategy auto-selection and comprehensive benchmarking. The system analyzes object patterns and query behaviors to automatically choose the optimal spatial partitioning strategy, while providing detailed performance insights.

---

## Phase 4.1: Auto-Selection Intelligence (7 days)

### Objectives
- Implement intelligent strategy selection based on usage patterns
- Create adaptive optimization that learns from application behavior
- Develop strategy switching for dynamic scenarios
- Provide performance monitoring and recommendations

### Key Features
- **Pattern Analysis**: Real-time analysis of object distributions and query patterns
- **Adaptive Selection**: Dynamic strategy switching based on performance metrics
- **Machine Learning**: Simple heuristics that improve over time
- **Performance Monitoring**: Continuous tracking of strategy effectiveness

### Implementation Details
```lua
local IntelligentSelector = {}
IntelligentSelector.__index = IntelligentSelector

function IntelligentSelector.new(config)
  local self = setmetatable({}, IntelligentSelector)
  
  self.current_strategy = nil
  self.monitoring = {
    add_times = {},
    query_times = {},
    memory_usage = {},
    object_distribution = {},
    query_patterns = {}
  }
  
  self.thresholds = {
    performance_degradation = 0.2,  -- 20% performance drop triggers reevaluation
    pattern_change = 0.3,           -- 30% change in patterns triggers analysis
    evaluation_interval = 1000     -- Operations between evaluations
  }
  
  self.operation_count = 0
  self.strategy_history = {}
  
  return self
end

function IntelligentSelector:analyze_object_distribution(objects)
  local analysis = {
    total_objects = 0,
    clustering_coefficient = 0,
    density_variation = 0,
    world_bounds = {math.huge, math.huge, -math.huge, -math.huge},
    has_negative_coords = false,
    average_object_size = 0
  }
  
  local positions = {}
  local sizes = {}
  
  for obj, obj_node in pairs(objects) do
    analysis.total_objects = analysis.total_objects + 1
    
    -- Track world bounds
    analysis.world_bounds[1] = math.min(analysis.world_bounds[1], obj_node.x)
    analysis.world_bounds[2] = math.min(analysis.world_bounds[2], obj_node.y)
    analysis.world_bounds[3] = math.max(analysis.world_bounds[3], obj_node.x + obj_node.w)
    analysis.world_bounds[4] = math.max(analysis.world_bounds[4], obj_node.y + obj_node.h)
    
    -- Check for negative coordinates
    if obj_node.x < 0 or obj_node.y < 0 then
      analysis.has_negative_coords = true
    end
    
    -- Collect position data for clustering analysis
    table.insert(positions, {obj_node.x + obj_node.w/2, obj_node.y + obj_node.h/2})
    table.insert(sizes, obj_node.w * obj_node.h)
  end
  
  if analysis.total_objects > 0 then
    -- Calculate average object size
    local total_size = 0
    for _, size in ipairs(sizes) do
      total_size = total_size + size
    end
    analysis.average_object_size = total_size / analysis.total_objects
    
    -- Calculate clustering coefficient
    analysis.clustering_coefficient = self:calculate_clustering(positions)
    
    -- Calculate density variation
    analysis.density_variation = self:calculate_density_variation(positions)
  end
  
  return analysis
end

function IntelligentSelector:calculate_clustering(positions)
  if #positions < 2 then return 0 end
  
  local total_distance = 0
  local min_distance = math.huge
  local max_distance = 0
  
  for i = 1, #positions do
    for j = i + 1, #positions do
      local dx = positions[i][1] - positions[j][1]
      local dy = positions[i][2] - positions[j][2]
      local distance = math.sqrt(dx*dx + dy*dy)
      
      total_distance = total_distance + distance
      min_distance = math.min(min_distance, distance)
      max_distance = math.max(max_distance, distance)
    end
  end
  
  local pair_count = (#positions * (#positions - 1)) / 2
  local average_distance = total_distance / pair_count
  
  if max_distance == 0 then return 1 end
  
  -- Clustering coefficient: lower values indicate more clustering
  return 1 - (average_distance - min_distance) / (max_distance - min_distance)
end

function IntelligentSelector:analyze_query_patterns(query_history)
  local analysis = {
    average_query_size = 0,
    query_frequency = 0,
    spatial_locality = 0,
    query_overlap = 0,
    ray_casting_usage = 0,
    nearest_neighbor_usage = 0
  }
  
  if #query_history == 0 then return analysis end
  
  local total_area = 0
  local total_frequency = #query_history
  local overlap_count = 0
  
  for i, query in ipairs(query_history) do
    total_area = total_area + (query.w * query.h)
    
    -- Calculate spatial locality (queries close to previous queries)
    if i > 1 then
      local prev_query = query_history[i-1]
      local dx = query.x - prev_query.x
      local dy = query.y - prev_query.y
      local distance = math.sqrt(dx*dx + dy*dy)
      
      if distance < 100 then  -- Threshold for "local" queries
        analysis.spatial_locality = analysis.spatial_locality + 1
      end
    end
    
    -- Check for overlapping queries
    for j = i + 1, math.min(i + 10, #query_history) do  -- Check next 10 queries
      local other_query = query_history[j]
      if self:rectangles_overlap(query, other_query) then
        overlap_count = overlap_count + 1
      end
    end
    
    -- Track special query types
    if query.type == "ray_cast" then
      analysis.ray_casting_usage = analysis.ray_casting_usage + 1
    elseif query.type == "nearest_neighbor" then
      analysis.nearest_neighbor_usage = analysis.nearest_neighbor_usage + 1
    end
  end
  
  analysis.average_query_size = total_area / total_frequency
  analysis.query_frequency = total_frequency
  analysis.spatial_locality = analysis.spatial_locality / math.max(1, total_frequency - 1)
  analysis.query_overlap = overlap_count / math.max(1, total_frequency)
  analysis.ray_casting_usage = analysis.ray_casting_usage / total_frequency
  analysis.nearest_neighbor_usage = analysis.nearest_neighbor_usage / total_frequency
  
  return analysis
end

function IntelligentSelector:recommend_strategy(obj_analysis, query_analysis)
  local scores = {
    fixed_grid = 0,
    quadtree = 0,
    hash_grid = 0,
    bsp_tree = 0,
    bvh = 0
  }
  
  -- Object distribution factors
  if obj_analysis.has_negative_coords then
    scores.hash_grid = scores.hash_grid + 30
    scores.bvh = scores.bvh + 10
  end
  
  if obj_analysis.clustering_coefficient > 0.7 then
    scores.quadtree = scores.quadtree + 40
    scores.bvh = scores.bvh + 20
  else
    scores.fixed_grid = scores.fixed_grid + 30
    scores.hash_grid = scores.hash_grid + 20
  end
  
  if obj_analysis.total_objects > 5000 then
    scores.hash_grid = scores.hash_grid + 25
    scores.bvh = scores.bvh + 15
  end
  
  -- Query pattern factors
  if query_analysis.ray_casting_usage > 0.1 then
    scores.bsp_tree = scores.bsp_tree + 50
    scores.bvh = scores.bvh + 30
  end
  
  if query_analysis.nearest_neighbor_usage > 0.1 then
    scores.bvh = scores.bvh + 40
    scores.quadtree = scores.quadtree + 20
  end
  
  if query_analysis.spatial_locality > 0.8 then
    scores.fixed_grid = scores.fixed_grid + 25
    scores.quadtree = scores.quadtree + 15
  end
  
  if query_analysis.average_query_size > obj_analysis.average_object_size * 10 then
    scores.fixed_grid = scores.fixed_grid + 20
    scores.hash_grid = scores.hash_grid + 20
  end
  
  -- Find strategy with highest score
  local best_strategy = "fixed_grid"
  local best_score = scores.fixed_grid
  
  for strategy, score in pairs(scores) do
    if score > best_score then
      best_strategy = strategy
      best_score = score
    end
  end
  
  return best_strategy, scores
end

function IntelligentSelector:should_reevaluate()
  self.operation_count = self.operation_count + 1
  
  if self.operation_count % self.thresholds.evaluation_interval == 0 then
    return true
  end
  
  -- Check for performance degradation
  local recent_performance = self:get_recent_performance()
  local baseline_performance = self:get_baseline_performance()
  
  if recent_performance and baseline_performance then
    local degradation = (baseline_performance - recent_performance) / baseline_performance
    if degradation > self.thresholds.performance_degradation then
      return true
    end
  end
  
  return false
end
```

### Adaptive Strategy Switching
```lua
local AdaptiveLocustron = {}
AdaptiveLocustron.__index = AdaptiveLocustron

function AdaptiveLocustron.new(config)
  local self = setmetatable({}, AdaptiveLocustron)
  
  self.selector = IntelligentSelector.new(config.intelligence or {})
  self.current_strategy = create_strategy("fixed_grid", config.config)
  self.current_strategy_name = "fixed_grid"
  
  self.performance_monitor = PerformanceMonitor.new()
  self.switch_threshold = config.switch_threshold or 0.25  -- 25% improvement needed
  
  return self
end

function AdaptiveLocustron:add(obj, x, y, w, h)
  local start_time = os.clock()
  local result = self.current_strategy:add_object(obj, x, y, w, h)
  local duration = os.clock() - start_time
  
  self.performance_monitor:record_add_time(duration)
  
  if self.selector:should_reevaluate() then
    self:evaluate_strategy_switch()
  end
  
  return result
end

function AdaptiveLocustron:evaluate_strategy_switch()
  local obj_analysis = self.selector:analyze_object_distribution(self.current_strategy.objects)
  local query_analysis = self.selector:analyze_query_patterns(self.performance_monitor.query_history)
  
  local recommended_strategy, scores = self.selector:recommend_strategy(obj_analysis, query_analysis)
  
  if recommended_strategy ~= self.current_strategy_name then
    -- Test performance with recommended strategy
    local test_performance = self:benchmark_strategy(recommended_strategy, obj_analysis)
    local current_performance = self.performance_monitor:get_current_performance()
    
    local improvement = (test_performance - current_performance) / current_performance
    
    if improvement > self.switch_threshold then
      self:switch_to_strategy(recommended_strategy)
      
      print(string.format("Strategy switched from %s to %s (%.1f%% improvement)",
        self.current_strategy_name, recommended_strategy, improvement * 100))
    end
  end
end

function AdaptiveLocustron:switch_to_strategy(new_strategy_name)
  -- Migrate all objects to new strategy
  local all_objects = {}
  for obj, obj_node in pairs(self.current_strategy.objects) do
    table.insert(all_objects, {
      obj = obj,
      x = obj_node.x,
      y = obj_node.y,
      w = obj_node.w,
      h = obj_node.h
    })
  end
  
  -- Create new strategy
  local new_strategy = create_strategy(new_strategy_name, self.current_strategy.config)
  
  -- Migrate objects
  for _, obj_data in ipairs(all_objects) do
    new_strategy:add_object(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
  end
  
  self.current_strategy = new_strategy
  self.current_strategy_name = new_strategy_name
  self.performance_monitor:reset_baseline()
end
```

---

## Phase 4.2: Comprehensive Benchmarking Suite (7 days)

### Objectives
- Create comprehensive benchmarking framework
- Implement automated performance testing
- Generate detailed performance reports
- Establish performance regression detection

### Benchmarking Framework
```lua
local BenchmarkSuite = {}
BenchmarkSuite.__index = BenchmarkSuite

function BenchmarkSuite.new(config)
  local self = setmetatable({}, BenchmarkSuite)
  
  self.scenarios = {}
  self.strategies = {"fixed_grid", "quadtree", "hash_grid", "bsp_tree", "bvh"}
  self.metrics = {"add_time", "query_time", "memory_usage", "accuracy"}
  self.iterations = config.iterations or 1000
  
  self:setup_scenarios()
  
  return self
end

function BenchmarkSuite:setup_scenarios()
  -- Clustered objects scenario
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
  
  -- Sparse world scenario
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
  
  -- Moving objects scenario
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

function BenchmarkSuite:run_complete_benchmark()
  local results = {}
  
  for scenario_name, scenario_func in pairs(self.scenarios) do
    results[scenario_name] = {}
    
    for object_count = 100, 5000, 500 do
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

function BenchmarkSuite:benchmark_strategy(strategy_name, objects)
  local loc = locustron({strategy = strategy_name})
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
    loc.add(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
  end
  results.add_time = (os.clock() - start_time) / #objects
  
  -- Measure memory usage
  collectgarbage("collect")
  results.memory_usage = collectgarbage("count") * 1024  -- Convert to bytes
  
  -- Measure query performance
  start_time = os.clock()
  for i = 1, 100 do
    local x, y = math.random(0, 1000), math.random(0, 1000)
    loc.query(x, y, 64, 64)
  end
  results.query_time = (os.clock() - start_time) / 100
  
  -- Measure update performance (for moving objects)
  if objects[1].vx then
    start_time = os.clock()
    for _, obj_data in ipairs(objects) do
      local new_x = obj_data.x + obj_data.vx
      local new_y = obj_data.y + obj_data.vy
      loc.update(obj_data.obj, new_x, new_y, obj_data.w, obj_data.h)
    end
    results.update_time = (os.clock() - start_time) / #objects
  end
  
  -- Measure accuracy (compare with brute force)
  local accuracy_samples = math.min(50, #objects // 10)
  local correct_results = 0
  
  for i = 1, accuracy_samples do
    local x, y = math.random(0, 1000), math.random(0, 1000)
    local w, h = 64, 64
    
    local strategy_result = loc.query(x, y, w, h)
    local brute_force_result = self:brute_force_query(objects, x, y, w, h)
    
    if self:results_match(strategy_result, brute_force_result) then
      correct_results = correct_results + 1
    end
  end
  
  results.accuracy = correct_results / accuracy_samples
  
  return results
end

function BenchmarkSuite:generate_report(results)
  local report = {
    "# Locustron Performance Benchmark Report",
    string.format("Generated: %s", os.date()),
    "",
    "## Executive Summary",
    ""
  }
  
  -- Find best strategy for each scenario
  for scenario_name, scenario_results in pairs(results) do
    table.insert(report, string.format("### %s Scenario", scenario_name:gsub("^%l", string.upper)))
    table.insert(report, "")
    table.insert(report, "| Objects | Best Strategy | Add Time (ms) | Query Time (ms) | Memory (MB) |")
    table.insert(report, "|---------|---------------|---------------|-----------------|-------------|")
    
    for object_count, strategies in pairs(scenario_results) do
      local best_strategy, best_performance = self:find_best_strategy(strategies)
      
      table.insert(report, string.format(
        "| %d | %s | %.3f | %.3f | %.1f |",
        object_count,
        best_strategy,
        best_performance.add_time * 1000,
        best_performance.query_time * 1000,
        best_performance.memory_usage / (1024 * 1024)
      ))
    end
    
    table.insert(report, "")
  end
  
  -- Strategy comparison charts
  table.insert(report, "## Detailed Strategy Comparison")
  table.insert(report, "")
  
  for scenario_name, scenario_results in pairs(results) do
    table.insert(report, string.format("### %s Performance Charts", scenario_name:gsub("^%l", string.upper)))
    table.insert(report, "")
    
    -- Generate ASCII performance charts
    local chart = self:generate_performance_chart(scenario_results)
    for _, line in ipairs(chart) do
      table.insert(report, line)
    end
    
    table.insert(report, "")
  end
  
  return table.concat(report, "\n")
end
```

### Performance Visualization
```lua
function BenchmarkSuite:generate_performance_chart(scenario_results)
  local chart_lines = {}
  
  -- Create ASCII chart for query performance
  table.insert(chart_lines, "Query Performance (lower is better):")
  table.insert(chart_lines, "```")
  
  local max_time = 0
  local object_counts = {}
  
  -- Find max time and object counts
  for object_count, strategies in pairs(scenario_results) do
    table.insert(object_counts, object_count)
    for _, strategy_data in pairs(strategies) do
      max_time = math.max(max_time, strategy_data.query_time)
    end
  end
  
  table.sort(object_counts)
  
  -- Generate chart for each strategy
  for _, strategy_name in ipairs(self.strategies) do
    local line = string.format("%-12s: ", strategy_name)
    
    for _, object_count in ipairs(object_counts) do
      local strategy_data = scenario_results[object_count][strategy_name]
      if strategy_data then
        local normalized = strategy_data.query_time / max_time
        local bar_length = math.floor(normalized * 40)
        line = line .. string.rep("█", bar_length) .. string.rep("░", 40 - bar_length) .. " "
      end
    end
    
    table.insert(chart_lines, line)
  end
  
  table.insert(chart_lines, "```")
  
  return chart_lines
end
```

## Phase 4 Summary

**Duration**: 2 weeks (14 days)
**Key Achievement**: Intelligent optimization and comprehensive performance analysis
**Auto-Selection**: Smart strategy choice based on real-time analysis
**Benchmarking**: Complete performance testing framework
**Optimization**: Adaptive strategy switching for optimal performance

**Ready for Phase 5**: Advanced debugging and visualization tools.