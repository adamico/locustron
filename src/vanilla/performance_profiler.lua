-- Performance Profiler for Spatial Partitioning Strategies
-- Detailed operation profiling and analysis tools

---@class PerformanceProfiler
---@field operation_history table History of all operations
---@field memory_snapshots table Timeline of memory usage
---@field query_patterns table Analysis of query patterns
---@field recommendations table Generated optimization suggestions
local PerformanceProfiler = {}
PerformanceProfiler.__index = PerformanceProfiler

---Create a new performance profiler
---@return PerformanceProfiler
function PerformanceProfiler.new()
  local self = setmetatable({}, PerformanceProfiler)
  
  self.operation_history = {}
  self.memory_snapshots = {}
  self.query_patterns = {}
  self.recommendations = {}
  
  return self
end

---Profile a strategy with a given workload
---@param strategy_name string Name of strategy to profile
---@param workload table Workload specification {objects, queries, config}
---@return table Complete performance profile
function PerformanceProfiler:profile_strategy(strategy_name, workload)
  local strategy_interface = require("src.vanilla.strategy_interface")
  local strategy = strategy_interface.create_strategy(strategy_name, workload.config or {})
  
  local profile = {
    strategy_name = strategy_name,
    operations = {},
    memory_timeline = {},
    query_analysis = {},
    recommendations = {},
    workload_info = {
      object_count = #workload.objects,
      query_count = workload.queries and #workload.queries or 0,
      config = workload.config or {}
    }
  }
  
  -- Profile object additions
  print(string.format("Profiling %s with %d objects...", strategy_name, #workload.objects))
  
  for i, obj_data in ipairs(workload.objects) do
    local start_time = os.clock()
    strategy:add_object(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
    local duration = os.clock() - start_time
    
    table.insert(profile.operations, {
      type = "add",
      duration = duration,
      object_count = strategy:get_statistics().object_count,
      operation_index = i
    })
    
    -- Memory snapshot every 100 operations
    if i % 100 == 0 then
      collectgarbage("collect")
      table.insert(profile.memory_timeline, {
        operation_count = i,
        memory_kb = collectgarbage("count"),
        object_count = strategy:get_statistics().object_count
      })
    end
  end
  
  -- Profile queries if provided
  if workload.queries then
    print(string.format("Profiling %d queries...", #workload.queries))
    
    for i, query in ipairs(workload.queries) do
      local start_time = os.clock()
      local results = strategy:query_region(query.x, query.y, query.w, query.h, query.filter)
      local duration = os.clock() - start_time
      
      local result_count = 0
      for _ in pairs(results) do result_count = result_count + 1 end
      
      table.insert(profile.query_analysis, {
        query = query,
        duration = duration,
        result_count = result_count,
        query_area = query.w * query.h,
        efficiency = result_count > 0 and (duration / result_count) or duration
      })
    end
  end
  
  -- Profile updates if objects have velocity
  if workload.objects[1] and workload.objects[1].vx then
    print("Profiling object updates...")
    
    for i, obj_data in ipairs(workload.objects) do
      local new_x = obj_data.x + (obj_data.vx or 0)
      local new_y = obj_data.y + (obj_data.vy or 0)
      
      local start_time = os.clock()
      strategy:update_object(obj_data.obj, new_x, new_y, obj_data.w, obj_data.h)
      local duration = os.clock() - start_time
      
      table.insert(profile.operations, {
        type = "update",
        duration = duration,
        object_count = strategy:get_statistics().object_count,
        operation_index = #workload.objects + i
      })
    end
  end
  
  -- Generate recommendations
  profile.recommendations = self:generate_recommendations(profile, workload)
  
  return profile
end

---Generate optimization recommendations based on profile data
---@param profile table Performance profile
---@param workload table Original workload
---@return table Array of recommendations
function PerformanceProfiler:generate_recommendations(profile, workload)
  local recommendations = {}
  
  -- Analyze add performance
  local add_operations = {}
  for _, op in ipairs(profile.operations) do
    if op.type == "add" then
      table.insert(add_operations, op)
    end
  end
  
  if #add_operations > 0 then
    local total_add_time = 0
    for _, op in ipairs(add_operations) do
      total_add_time = total_add_time + op.duration
    end
    local avg_add_time = total_add_time / #add_operations
    
    if avg_add_time > 0.001 then  -- 1ms threshold
      table.insert(recommendations, {
        type = "performance",
        severity = "warning",
        category = "add_operations",
        message = string.format("Average add time is %.3f ms. Consider Hash Grid or optimizing cell size.", avg_add_time * 1000),
        metric_value = avg_add_time,
        threshold = 0.001
      })
    end
  end
  
  -- Analyze memory usage
  if #profile.memory_timeline > 1 then
    local first_snapshot = profile.memory_timeline[1]
    local last_snapshot = profile.memory_timeline[#profile.memory_timeline]
    
    local memory_growth = last_snapshot.memory_kb - first_snapshot.memory_kb
    local objects_added = last_snapshot.operation_count - first_snapshot.operation_count
    local memory_per_object = objects_added > 0 and (memory_growth / objects_added) or 0
    
    if memory_per_object > 1.0 then  -- 1KB per object threshold
      table.insert(recommendations, {
        type = "memory",
        severity = "warning",
        category = "memory_usage",
        message = string.format("High memory usage: %.2f KB per object. Consider larger cell size or Hash Grid.", memory_per_object),
        metric_value = memory_per_object,
        threshold = 1.0
      })
    end
    
    -- Check for memory growth rate
    if #profile.memory_timeline >= 3 then
      local growth_rates = {}
      for i = 2, #profile.memory_timeline do
        local prev = profile.memory_timeline[i-1]
        local curr = profile.memory_timeline[i]
        local ops_diff = curr.operation_count - prev.operation_count
        local mem_diff = curr.memory_kb - prev.memory_kb
        
        if ops_diff > 0 then
          table.insert(growth_rates, mem_diff / ops_diff)
        end
      end
      
      if #growth_rates > 0 then
        local avg_growth = 0
        for _, rate in ipairs(growth_rates) do
          avg_growth = avg_growth + rate
        end
        avg_growth = avg_growth / #growth_rates
        
        if avg_growth > 2.0 then  -- 2KB per operation growth
          table.insert(recommendations, {
            type = "memory",
            severity = "critical",
            category = "memory_growth",
            message = string.format("High memory growth rate: %.2f KB per operation. Check for memory leaks.", avg_growth),
            metric_value = avg_growth,
            threshold = 2.0
          })
        end
      end
    end
  end
  
  -- Analyze query patterns
  if #profile.query_analysis > 0 then
    local small_query_count = 0
    local large_query_count = 0
    local total_query_time = 0
    local empty_result_count = 0
    
    for _, query_data in ipairs(profile.query_analysis) do
      total_query_time = total_query_time + query_data.duration
      
      if query_data.query_area < 1000 then
        small_query_count = small_query_count + 1
      elseif query_data.query_area > 10000 then
        large_query_count = large_query_count + 1
      end
      
      if query_data.result_count == 0 then
        empty_result_count = empty_result_count + 1
      end
    end
    
    local avg_query_time = total_query_time / #profile.query_analysis
    
    if avg_query_time > 0.005 then  -- 5ms threshold
      table.insert(recommendations, {
        type = "performance",
        severity = "warning", 
        category = "query_performance",
        message = string.format("Average query time is %.3f ms. Consider Quadtree for clustered data.", avg_query_time * 1000),
        metric_value = avg_query_time,
        threshold = 0.005
      })
    end
    
    if small_query_count > large_query_count * 2 then
      table.insert(recommendations, {
        type = "optimization",
        severity = "info",
        category = "query_patterns",
        message = "Many small queries detected. Fixed Grid with smaller cell size may improve performance.",
        metric_value = small_query_count / #profile.query_analysis,
        threshold = 0.6
      })
    end
    
    local empty_ratio = empty_result_count / #profile.query_analysis
    if empty_ratio > 0.5 then
      table.insert(recommendations, {
        type = "optimization",
        severity = "info",
        category = "query_efficiency",
        message = string.format("%.1f%% of queries return no results. Consider spatial locality optimization.", empty_ratio * 100),
        metric_value = empty_ratio,
        threshold = 0.5
      })
    end
  end
  
  -- Analyze object distribution for strategy recommendations
  local object_bounds = self:analyze_object_distribution(workload.objects)
  
  if object_bounds.has_negative_coords then
    table.insert(recommendations, {
      type = "strategy",
      severity = "info", 
      category = "coordinates",
      message = "Negative coordinates detected. Hash Grid may be more suitable than Fixed Grid.",
      metric_value = 1,
      threshold = 1
    })
  end
  
  if object_bounds.clustering_factor > 0.7 then
    table.insert(recommendations, {
      type = "strategy",
      severity = "info",
      category = "distribution",
      message = "High clustering detected. Quadtree may provide better performance.",
      metric_value = object_bounds.clustering_factor,
      threshold = 0.7
    })
  end
  
  return recommendations
end

---Analyze object distribution characteristics
---@param objects table Array of object data
---@return table Distribution analysis
function PerformanceProfiler:analyze_object_distribution(objects)
  local analysis = {
    total_objects = #objects,
    world_bounds = {math.huge, math.huge, -math.huge, -math.huge},
    has_negative_coords = false,
    average_object_size = 0,
    clustering_factor = 0,
    size_variation = 0
  }
  
  if #objects == 0 then return analysis end
  
  local positions = {}
  local sizes = {}
  
  for _, obj_data in ipairs(objects) do
    -- Track world bounds
    analysis.world_bounds[1] = math.min(analysis.world_bounds[1], obj_data.x)
    analysis.world_bounds[2] = math.min(analysis.world_bounds[2], obj_data.y)
    analysis.world_bounds[3] = math.max(analysis.world_bounds[3], obj_data.x + obj_data.w)
    analysis.world_bounds[4] = math.max(analysis.world_bounds[4], obj_data.y + obj_data.h)
    
    -- Check for negative coordinates
    if obj_data.x < 0 or obj_data.y < 0 then
      analysis.has_negative_coords = true
    end
    
    -- Collect position and size data
    table.insert(positions, {obj_data.x + obj_data.w/2, obj_data.y + obj_data.h/2})
    table.insert(sizes, obj_data.w * obj_data.h)
  end
  
  -- Calculate average object size
  local total_size = 0
  for _, size in ipairs(sizes) do
    total_size = total_size + size
  end
  analysis.average_object_size = total_size / #sizes
  
  -- Calculate size variation (coefficient of variation)
  local size_variance = 0
  for _, size in ipairs(sizes) do
    local diff = size - analysis.average_object_size
    size_variance = size_variance + (diff * diff)
  end
  size_variance = size_variance / #sizes
  analysis.size_variation = math.sqrt(size_variance) / analysis.average_object_size
  
  -- Calculate clustering factor
  analysis.clustering_factor = self:calculate_clustering_factor(positions)
  
  return analysis
end

---Calculate clustering factor using average nearest neighbor distance
---@param positions table Array of {x, y} positions
---@return number Clustering factor (0 = uniform, 1 = highly clustered)
function PerformanceProfiler:calculate_clustering_factor(positions)
  if #positions < 2 then return 0 end
  
  local total_min_distance = 0
  local total_distance = 0
  local pair_count = 0
  
  for i = 1, #positions do
    local min_distance = math.huge
    
    for j = 1, #positions do
      if i ~= j then
        local dx = positions[i][1] - positions[j][1]
        local dy = positions[i][2] - positions[j][2]
        local distance = math.sqrt(dx*dx + dy*dy)
        
        min_distance = math.min(min_distance, distance)
        total_distance = total_distance + distance
        pair_count = pair_count + 1
      end
    end
    
    total_min_distance = total_min_distance + min_distance
  end
  
  local avg_min_distance = total_min_distance / #positions
  local avg_all_distance = total_distance / pair_count
  
  -- Clustering factor: ratio of average minimum distance to average all distances
  -- Lower ratio indicates more clustering
  if avg_all_distance > 0 then
    return 1.0 - (avg_min_distance / avg_all_distance)
  end
  
  return 0
end

---Calculate average add time from operations
---@param profile table Performance profile
---@return number Average add time in seconds
function PerformanceProfiler:calculate_average_add_time(profile)
  local add_times = {}
  for _, op in ipairs(profile.operations) do
    if op.type == "add" then
      table.insert(add_times, op.duration)
    end
  end
  
  if #add_times == 0 then return 0 end
  
  local total = 0
  for _, time in ipairs(add_times) do
    total = total + time
  end
  
  return total / #add_times
end

---Calculate average query time from query analysis
---@param profile table Performance profile
---@return number Average query time in seconds
function PerformanceProfiler:calculate_average_query_time(profile)
  if #profile.query_analysis == 0 then return 0 end
  
  local total = 0
  for _, query_data in ipairs(profile.query_analysis) do
    total = total + query_data.duration
  end
  
  return total / #profile.query_analysis
end

---Generate comprehensive performance report
---@param profiles table Array of performance profiles
---@return string Formatted report
function PerformanceProfiler:generate_report(profiles)
  local report = {
    "# Locustron Performance Analysis Report",
    string.format("Generated: %s", os.date()),
    "",
    "## Executive Summary",
    ""
  }
  
  -- Strategy comparison table
  table.insert(report, "| Strategy | Avg Add Time (ms) | Avg Query Time (ms) | Memory Usage (KB) | Accuracy | Recommendations |")
  table.insert(report, "|----------|------------------|-------------------|------------------|----------|-----------------|")
  
  for _, profile in ipairs(profiles) do
    local avg_add = self:calculate_average_add_time(profile)
    local avg_query = self:calculate_average_query_time(profile)
    local final_memory = 0
    
    if #profile.memory_timeline > 0 then
      final_memory = profile.memory_timeline[#profile.memory_timeline].memory_kb
    end
    
    -- Count critical/warning recommendations
    local critical_count = 0
    local warning_count = 0
    for _, rec in ipairs(profile.recommendations) do
      if rec.severity == "critical" then
        critical_count = critical_count + 1
      elseif rec.severity == "warning" then
        warning_count = warning_count + 1
      end
    end
    
    local rec_summary = ""
    if critical_count > 0 then
      rec_summary = string.format("%d critical", critical_count)
    end
    if warning_count > 0 then
      if rec_summary ~= "" then rec_summary = rec_summary .. ", " end
      rec_summary = rec_summary .. string.format("%d warnings", warning_count)
    end
    if rec_summary == "" then rec_summary = "none" end
    
    table.insert(report, string.format(
      "| %s | %.3f | %.3f | %.1f | N/A | %s |",
      profile.strategy_name,
      avg_add * 1000,
      avg_query * 1000,
      final_memory,
      rec_summary
    ))
  end
  
  table.insert(report, "")
  
  -- Detailed recommendations for each strategy
  table.insert(report, "## Detailed Analysis")
  table.insert(report, "")
  
  for _, profile in ipairs(profiles) do
    table.insert(report, string.format("### %s Performance Analysis", profile.strategy_name))
    table.insert(report, "")
    
    -- Performance metrics summary
    table.insert(report, "**Performance Metrics:**")
    table.insert(report, string.format("- Objects processed: %d", profile.workload_info.object_count))
    table.insert(report, string.format("- Average add time: %.3f ms", self:calculate_average_add_time(profile) * 1000))
    
    if #profile.query_analysis > 0 then
      table.insert(report, string.format("- Average query time: %.3f ms", self:calculate_average_query_time(profile) * 1000))
      table.insert(report, string.format("- Queries processed: %d", #profile.query_analysis))
    end
    
    if #profile.memory_timeline > 0 then
      local final_memory = profile.memory_timeline[#profile.memory_timeline].memory_kb
      table.insert(report, string.format("- Final memory usage: %.1f KB", final_memory))
    end
    
    table.insert(report, "")
    
    -- Recommendations
    if #profile.recommendations > 0 then
      table.insert(report, "**Recommendations:**")
      
      for _, rec in ipairs(profile.recommendations) do
        local icon = ""
        if rec.severity == "critical" then
          icon = "🔴"
        elseif rec.severity == "warning" then
          icon = "⚠️"
        else
          icon = "ℹ️"
        end
        
        table.insert(report, string.format("- %s **%s**: %s", icon, rec.category:upper(), rec.message))
      end
    else
      table.insert(report, "**No performance issues detected.**")
    end
    
    table.insert(report, "")
  end
  
  return table.concat(report, "\n")
end

return PerformanceProfiler