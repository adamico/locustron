# Phase 5: Advanced Debugging & Visualization (2 weeks)

## Overview
Phase 5 creates comprehensive debugging and visualization tools for Locustron. These tools help developers understand spatial partitioning behavior, optimize performance, and debug spatial logic with real-time visual feedback.

---

## Phase 5.1: Real-time Visualization System (8 days)

### Objectives
- Create real-time visualization of spatial partitioning structures
- Implement interactive debugging interfaces
- Develop performance profiling visualizations
- Support multiple rendering backends (Picotron, HTML5 Canvas, etc.)

### Key Features
- **Structure Visualization**: Real-time display of grid cells, quadtree nodes, etc.
- **Object Tracking**: Visual representation of objects and their spatial relationships
- **Query Visualization**: Show query regions and results
- **Performance Heatmaps**: Visual performance analysis
- **Interactive Controls**: Zoom, pan, filter, and inspect spatial structures

### Visualization Architecture
```lua
local VisualizationSystem = {}
VisualizationSystem.__index = VisualizationSystem

function VisualizationSystem.new(config)
  local self = setmetatable({}, VisualizationSystem)
  
  self.renderer = config.renderer or "picotron"  -- "picotron", "html5", "terminal"
  self.viewport = {x = 0, y = 0, w = 400, h = 300, scale = 1.0}
  self.colors = config.colors or self:get_default_colors()
  self.show_structure = true
  self.show_objects = true
  self.show_queries = true
  self.show_performance = false
  
  self.query_history = {}
  self.performance_data = {}
  
  return self
end

function VisualizationSystem:get_default_colors()
  return {
    grid_lines = 7,      -- Light gray
    quadtree_bounds = 6, -- Dark gray
    objects = 8,         -- Red
    queries = 11,        -- Light blue
    performance_hot = 8, -- Red
    performance_cold = 12, -- Light green
    text = 7             -- White
  }
end

function VisualizationSystem:render_strategy(strategy, strategy_name)
  self:clear_screen()
  
  if self.show_structure then
    if strategy_name == "fixed_grid" then
      self:render_fixed_grid(strategy)
    elseif strategy_name == "quadtree" then
      self:render_quadtree(strategy)
    elseif strategy_name == "hash_grid" then
      self:render_hash_grid(strategy)
    elseif strategy_name == "bsp_tree" then
      self:render_bsp_tree(strategy)
    elseif strategy_name == "bvh" then
      self:render_bvh(strategy)
    end
  end
  
  if self.show_objects then
    self:render_objects(strategy)
  end
  
  if self.show_queries then
    self:render_query_history()
  end
  
  if self.show_performance then
    self:render_performance_heatmap(strategy)
  end
  
  self:render_ui()
end

function VisualizationSystem:render_fixed_grid(strategy)
  local cell_size = strategy.cell_size
  local viewport = self.viewport
  
  -- Calculate visible grid range
  local start_gx = math.floor((viewport.x) / cell_size)
  local end_gx = math.floor((viewport.x + viewport.w) / cell_size) + 1
  local start_gy = math.floor((viewport.y) / cell_size)
  local end_gy = math.floor((viewport.y + viewport.h) / cell_size) + 1
  
  -- Draw grid lines
  for gx = start_gx, end_gx do
    local world_x = gx * cell_size
    local screen_x = self:world_to_screen_x(world_x)
    if screen_x >= 0 and screen_x < viewport.w then
      self:draw_line(screen_x, 0, screen_x, viewport.h, self.colors.grid_lines)
    end
  end
  
  for gy = start_gy, end_gy do
    local world_y = gy * cell_size
    local screen_y = self:world_to_screen_y(world_y)
    if screen_y >= 0 and screen_y < viewport.h then
      self:draw_line(0, screen_y, viewport.w, screen_y, self.colors.grid_lines)
    end
  end
  
  -- Draw occupied cells with object counts
  for gy, row in pairs(strategy.grid or {}) do
    if gy >= start_gy and gy <= end_gy then
      for gx, cell in pairs(row) do
        if gx >= start_gx and gx <= end_gx and cell.count > 0 then
          local world_x = gx * cell_size
          local world_y = gy * cell_size
          local screen_x = self:world_to_screen_x(world_x)
          local screen_y = self:world_to_screen_y(world_y)
          local screen_w = cell_size * self.viewport.scale
          local screen_h = cell_size * self.viewport.scale
          
          -- Highlight occupied cells
          self:draw_rect(screen_x, screen_y, screen_w, screen_h, self.colors.grid_lines, true)
          
          -- Draw object count
          local count_str = tostring(cell.count)
          self:draw_text(count_str, screen_x + 2, screen_y + 2, self.colors.text)
        end
      end
    end
  end
end

function VisualizationSystem:render_quadtree(strategy)
  if strategy.root then
    self:render_quadtree_node(strategy.root, 0)
  end
end

function VisualizationSystem:render_quadtree_node(node, depth)
  local screen_x = self:world_to_screen_x(node.x)
  local screen_y = self:world_to_screen_y(node.y)
  local screen_w = node.w * self.viewport.scale
  local screen_h = node.h * self.viewport.scale
  
  -- Draw node bounds
  local color = depth % 4 + 4  -- Cycle through colors based on depth
  self:draw_rect(screen_x, screen_y, screen_w, screen_h, color, false)
  
  -- Draw object count for leaf nodes
  if node.is_leaf and #node.objects > 0 then
    local count_str = string.format("%d", #node.objects)
    self:draw_text(count_str, screen_x + 2, screen_y + 2, self.colors.text)
  end
  
  -- Recursively draw children
  if not node.is_leaf and node.children then
    for _, child in ipairs(node.children) do
      self:render_quadtree_node(child, depth + 1)
    end
  end
end

function VisualizationSystem:render_hash_grid(strategy)
  -- Render hash grid by showing occupied cells
  for hash, bucket in pairs(strategy.cells or {}) do
    for _, cell in ipairs(bucket) do
      if cell.count > 0 then
        local world_x = cell.gx * strategy.cell_size
        local world_y = cell.gy * strategy.cell_size
        local screen_x = self:world_to_screen_x(world_x)
        local screen_y = self:world_to_screen_y(world_y)
        local screen_w = strategy.cell_size * self.viewport.scale
        local screen_h = strategy.cell_size * self.viewport.scale
        
        -- Color based on hash to show distribution
        local color = (hash % 8) + 8
        self:draw_rect(screen_x, screen_y, screen_w, screen_h, color, true)
        
        -- Draw coordinates and count
        local label = string.format("(%d,%d):%d", cell.gx, cell.gy, cell.count)
        self:draw_text(label, screen_x + 2, screen_y + 2, self.colors.text)
      end
    end
  end
end

function VisualizationSystem:render_bsp_tree(strategy)
  if strategy.root then
    self:render_bsp_node(strategy.root, 0)
  end
end

function VisualizationSystem:render_bsp_node(node, depth)
  local screen_x = self:world_to_screen_x(node.bounds[1])
  local screen_y = self:world_to_screen_y(node.bounds[2])
  local screen_w = node.bounds[3] * self.viewport.scale
  local screen_h = node.bounds[4] * self.viewport.scale
  
  -- Draw node bounds
  local color = depth % 6 + 2
  self:draw_rect(screen_x, screen_y, screen_w, screen_h, color, false)
  
  -- Draw splitting plane for internal nodes
  if not node.is_leaf and node.split_plane then
    if node.split_axis == "x" then
      local split_screen_x = self:world_to_screen_x(node.split_pos)
      self:draw_line(split_screen_x, screen_y, split_screen_x, screen_y + screen_h, color + 8)
    elseif node.split_axis == "y" then
      local split_screen_y = self:world_to_screen_y(node.split_pos)
      self:draw_line(screen_x, split_screen_y, screen_x + screen_w, split_screen_y, color + 8)
    end
  end
  
  -- Draw object count for leaves
  if node.is_leaf and #node.objects > 0 then
    local count_str = string.format("D%d:%d", depth, #node.objects)
    self:draw_text(count_str, screen_x + 2, screen_y + 2, self.colors.text)
  end
  
  -- Recursively draw children
  if not node.is_leaf then
    if node.front_child then
      self:render_bsp_node(node.front_child, depth + 1)
    end
    if node.back_child then
      self:render_bsp_node(node.back_child, depth + 1)
    end
  end
end

function VisualizationSystem:render_objects(strategy)
  for obj, obj_node in pairs(strategy.objects or {}) do
    local screen_x = self:world_to_screen_x(obj_node.x)
    local screen_y = self:world_to_screen_y(obj_node.y)
    local screen_w = obj_node.w * self.viewport.scale
    local screen_h = obj_node.h * self.viewport.scale
    
    -- Draw object
    self:draw_rect(screen_x, screen_y, screen_w, screen_h, self.colors.objects, true)
    
    -- Draw object ID if zoom level is high enough
    if self.viewport.scale > 2 then
      local id_str = tostring(obj.id or "?")
      self:draw_text(id_str, screen_x + 1, screen_y + 1, self.colors.text)
    end
  end
end
```

### Interactive Debugging Interface
```lua
function VisualizationSystem:handle_input()
  -- Handle keyboard input for debugging controls
  local input = self:get_input()
  
  if input.key_pressed then
    if input.key == "g" then
      self.show_structure = not self.show_structure
    elseif input.key == "o" then
      self.show_objects = not self.show_objects
    elseif input.key == "q" then
      self.show_queries = not self.show_queries
    elseif input.key == "p" then
      self.show_performance = not self.show_performance
    elseif input.key == "r" then
      self:reset_viewport()
    elseif input.key == "+" then
      self:zoom_in()
    elseif input.key == "-" then
      self:zoom_out()
    elseif input.key == "up" then
      self:pan(0, -32)
    elseif input.key == "down" then
      self:pan(0, 32)
    elseif input.key == "left" then
      self:pan(-32, 0)
    elseif input.key == "right" then
      self:pan(32, 0)
    end
  end
  
  if input.mouse_clicked then
    self:inspect_position(input.mouse_x, input.mouse_y)
  end
  
  if input.mouse_dragged then
    local world_dx = input.mouse_dx / self.viewport.scale
    local world_dy = input.mouse_dy / self.viewport.scale
    self:pan(-world_dx, -world_dy)
  end
end

function VisualizationSystem:inspect_position(screen_x, screen_y)
  local world_x = self:screen_to_world_x(screen_x)
  local world_y = self:screen_to_world_y(screen_y)
  
  -- Show inspection panel
  local info = {
    world_pos = {world_x, world_y},
    screen_pos = {screen_x, screen_y},
    objects_at_pos = {},
    grid_info = {}
  }
  
  -- Find objects at position
  for obj, obj_node in pairs(self.current_strategy.objects or {}) do
    if world_x >= obj_node.x and world_x < obj_node.x + obj_node.w and
       world_y >= obj_node.y and world_y < obj_node.y + obj_node.h then
      table.insert(info.objects_at_pos, obj)
    end
  end
  
  self:show_inspection_panel(info)
end

function VisualizationSystem:show_inspection_panel(info)
  local panel_x = 10
  local panel_y = 10
  local panel_w = 200
  local panel_h = 150
  
  -- Draw panel background
  self:draw_rect(panel_x, panel_y, panel_w, panel_h, 0, true)
  self:draw_rect(panel_x, panel_y, panel_w, panel_h, 7, false)
  
  local y_offset = panel_y + 10
  
  -- Position info
  self:draw_text(string.format("World: (%.1f, %.1f)", info.world_pos[1], info.world_pos[2]), 
                panel_x + 5, y_offset, 7)
  y_offset = y_offset + 10
  
  self:draw_text(string.format("Screen: (%d, %d)", info.screen_pos[1], info.screen_pos[2]), 
                panel_x + 5, y_offset, 7)
  y_offset = y_offset + 15
  
  -- Objects at position
  self:draw_text(string.format("Objects: %d", #info.objects_at_pos), 
                panel_x + 5, y_offset, 7)
  y_offset = y_offset + 10
  
  for i, obj in ipairs(info.objects_at_pos) do
    if i <= 5 then  -- Show first 5 objects
      self:draw_text(string.format("  %s", tostring(obj.id or obj)), 
                    panel_x + 10, y_offset, 6)
      y_offset = y_offset + 8
    end
  end
  
  if #info.objects_at_pos > 5 then
    self:draw_text(string.format("  ... %d more", #info.objects_at_pos - 5), 
                  panel_x + 10, y_offset, 6)
  end
end
```

---

## Phase 5.2: Performance Profiling Tools (6 days)

### Objectives
- Create detailed performance profiling for spatial operations
- Implement performance regression detection
- Develop performance optimization suggestions
- Create performance comparison tools

### Performance Profiler
```lua
local PerformanceProfiler = {}
PerformanceProfiler.__index = PerformanceProfiler

function PerformanceProfiler.new(config)
  local self = setmetatable({}, PerformanceProfiler)
  
  self.enabled = config.enabled or false
  self.sample_rate = config.sample_rate or 0.1  -- 10% sampling
  self.max_samples = config.max_samples or 10000
  
  self.operation_data = {
    add = {},
    remove = {},
    update = {},
    query = {},
    query_region = {},
    query_nearest = {}
  }
  
  self.memory_snapshots = {}
  self.performance_trends = {}
  
  return self
end

function PerformanceProfiler:start_operation(operation_type, context)
  if not self.enabled or math.random() > self.sample_rate then
    return nil
  end
  
  local sample_id = self:generate_sample_id()
  local sample = {
    id = sample_id,
    operation = operation_type,
    context = context,
    start_time = os.clock(),
    start_memory = collectgarbage("count") * 1024,
    call_stack = self:get_call_stack()
  }
  
  return sample_id
end

function PerformanceProfiler:end_operation(sample_id, result_context)
  if not sample_id then return end
  
  local sample = self:find_sample(sample_id)
  if not sample then return end
  
  sample.end_time = os.clock()
  sample.end_memory = collectgarbage("count") * 1024
  sample.duration = sample.end_time - sample.start_time
  sample.memory_delta = sample.end_memory - sample.start_memory
  sample.result_context = result_context
  
  -- Store sample data
  local operation_data = self.operation_data[sample.operation]
  if operation_data then
    table.insert(operation_data, sample)
    
    -- Maintain max samples limit
    if #operation_data > self.max_samples then
      table.remove(operation_data, 1)
    end
  end
  
  self:update_performance_trends(sample)
end

function PerformanceProfiler:analyze_performance()
  local analysis = {
    summary = {},
    hotspots = {},
    trends = {},
    recommendations = {}
  }
  
  -- Generate summary statistics
  for operation, samples in pairs(self.operation_data) do
    if #samples > 0 then
      local stats = self:calculate_statistics(samples)
      analysis.summary[operation] = stats
    end
  end
  
  -- Identify performance hotspots
  analysis.hotspots = self:identify_hotspots()
  
  -- Analyze trends
  analysis.trends = self:analyze_trends()
  
  -- Generate recommendations
  analysis.recommendations = self:generate_recommendations(analysis)
  
  return analysis
end

function PerformanceProfiler:calculate_statistics(samples)
  local durations = {}
  local memory_deltas = {}
  
  for _, sample in ipairs(samples) do
    table.insert(durations, sample.duration)
    table.insert(memory_deltas, sample.memory_delta)
  end
  
  return {
    count = #samples,
    duration = {
      min = math.min(table.unpack(durations)),
      max = math.max(table.unpack(durations)),
      avg = self:calculate_average(durations),
      p95 = self:calculate_percentile(durations, 0.95),
      p99 = self:calculate_percentile(durations, 0.99)
    },
    memory = {
      min = math.min(table.unpack(memory_deltas)),
      max = math.max(table.unpack(memory_deltas)),
      avg = self:calculate_average(memory_deltas),
      total = self:sum(memory_deltas)
    }
  }
end

function PerformanceProfiler:identify_hotspots()
  local hotspots = {}
  
  -- Find operations that consistently take longer than average
  for operation, samples in pairs(self.operation_data) do
    if #samples >= 10 then
      local stats = self:calculate_statistics(samples)
      
      -- Flag operations with high p95 times
      if stats.duration.p95 > 0.01 then  -- 10ms threshold
        table.insert(hotspots, {
          operation = operation,
          p95_time = stats.duration.p95,
          sample_count = stats.count,
          severity = "high"
        })
      elseif stats.duration.p95 > 0.005 then  -- 5ms threshold
        table.insert(hotspots, {
          operation = operation,
          p95_time = stats.duration.p95,
          sample_count = stats.count,
          severity = "medium"
        })
      end
    end
  end
  
  -- Sort by severity and impact
  table.sort(hotspots, function(a, b)
    if a.severity ~= b.severity then
      return a.severity == "high"
    end
    return a.p95_time > b.p95_time
  end)
  
  return hotspots
end

function PerformanceProfiler:generate_recommendations(analysis)
  local recommendations = {}
  
  -- Performance recommendations based on hotspots
  for _, hotspot in ipairs(analysis.hotspots) do
    if hotspot.operation == "query" then
      table.insert(recommendations, {
        type = "optimization",
        priority = "high",
        message = string.format("Query operations are slow (%.1fms p95). Consider using a different spatial strategy or optimizing query regions.", hotspot.p95_time * 1000),
        suggestion = "Try 'hash_grid' strategy for large worlds or 'quadtree' for clustered objects."
      })
    elseif hotspot.operation == "add" then
      table.insert(recommendations, {
        type = "optimization",
        priority = "medium",
        message = string.format("Object insertion is slow (%.1fms p95). This may indicate strategy overhead.", hotspot.p95_time * 1000),
        suggestion = "Consider 'fixed_grid' strategy for uniform object distributions."
      })
    end
  end
  
  -- Memory recommendations
  local total_memory = 0
  for _, stats in pairs(analysis.summary) do
    total_memory = total_memory + stats.memory.total
  end
  
  if total_memory > 50 * 1024 * 1024 then  -- 50MB threshold
    table.insert(recommendations, {
      type = "memory",
      priority = "high",
      message = string.format("High memory usage detected (%.1fMB). Consider memory optimization.", total_memory / (1024 * 1024)),
      suggestion = "Use object pooling or consider a more memory-efficient strategy."
    })
  end
  
  return recommendations
end
```

### Real-time Performance Dashboard
```lua
function VisualizationSystem:render_performance_dashboard(profiler)
  local dashboard_x = 10
  local dashboard_y = self.viewport.h - 120
  local dashboard_w = self.viewport.w - 20
  local dashboard_h = 110
  
  -- Draw dashboard background
  self:draw_rect(dashboard_x, dashboard_y, dashboard_w, dashboard_h, 0, true)
  self:draw_rect(dashboard_x, dashboard_y, dashboard_w, dashboard_h, 7, false)
  
  -- Title
  self:draw_text("Performance Dashboard", dashboard_x + 5, dashboard_y + 5, 7)
  
  local y_offset = dashboard_y + 20
  local col_width = dashboard_w // 4
  
  -- Operation statistics
  local operations = {"add", "query", "update", "remove"}
  for i, operation in ipairs(operations) do
    local col_x = dashboard_x + (i - 1) * col_width
    
    self:draw_text(string.upper(operation), col_x + 5, y_offset, 6)
    
    local samples = profiler.operation_data[operation]
    if samples and #samples > 0 then
      local stats = profiler:calculate_statistics(samples)
      
      -- Average time
      self:draw_text(string.format("Avg: %.2fms", stats.duration.avg * 1000), 
                    col_x + 5, y_offset + 15, 7)
      
      -- P95 time
      self:draw_text(string.format("P95: %.2fms", stats.duration.p95 * 1000), 
                    col_x + 5, y_offset + 25, 7)
      
      -- Sample count
      self:draw_text(string.format("Samples: %d", stats.count), 
                    col_x + 5, y_offset + 35, 7)
      
      -- Performance indicator
      local color = 12  -- Green
      if stats.duration.p95 > 0.01 then
        color = 8  -- Red
      elseif stats.duration.p95 > 0.005 then
        color = 9  -- Orange
      end
      
      self:draw_rect(col_x + 5, y_offset + 50, 10, 10, color, true)
    else
      self:draw_text("No data", col_x + 5, y_offset + 15, 6)
    end
  end
  
  -- Performance trend graph
  local graph_y = y_offset + 70
  local graph_h = 20
  self:render_performance_trend_graph(dashboard_x + 5, graph_y, dashboard_w - 10, graph_h, profiler)
end

function VisualizationSystem:render_performance_trend_graph(x, y, w, h, profiler)
  -- Draw graph background
  self:draw_rect(x, y, w, h, 1, true)
  self:draw_rect(x, y, w, h, 7, false)
  
  -- Collect recent performance data
  local recent_samples = {}
  for operation, samples in pairs(profiler.operation_data) do
    for _, sample in ipairs(samples) do
      if #recent_samples < 100 then  -- Last 100 samples
        table.insert(recent_samples, {
          time = sample.start_time,
          duration = sample.duration,
          operation = operation
        })
      end
    end
  end
  
  if #recent_samples == 0 then
    self:draw_text("No performance data", x + 5, y + 5, 6)
    return
  end
  
  -- Sort by time
  table.sort(recent_samples, function(a, b) return a.time < b.time end)
  
  -- Find time range and max duration
  local min_time = recent_samples[1].time
  local max_time = recent_samples[#recent_samples].time
  local max_duration = 0
  
  for _, sample in ipairs(recent_samples) do
    max_duration = math.max(max_duration, sample.duration)
  end
  
  if max_duration == 0 then return end
  
  -- Draw trend line
  for i = 1, #recent_samples - 1 do
    local sample1 = recent_samples[i]
    local sample2 = recent_samples[i + 1]
    
    local x1 = x + math.floor((sample1.time - min_time) / (max_time - min_time) * w)
    local y1 = y + h - math.floor(sample1.duration / max_duration * h)
    local x2 = x + math.floor((sample2.time - min_time) / (max_time - min_time) * w)
    local y2 = y + h - math.floor(sample2.duration / max_duration * h)
    
    local color = 11  -- Light blue for trend
    if sample2.duration > sample1.duration * 1.5 then
      color = 8  -- Red for performance spikes
    end
    
    self:draw_line(x1, y1, x2, y2, color)
  end
end
```

## Phase 5 Summary

**Duration**: 2 weeks (14 days)
**Key Achievement**: Comprehensive debugging and visualization tools
**Visualization**: Real-time display of spatial structures and performance
**Profiling**: Detailed performance analysis and optimization recommendations
**Debugging**: Interactive tools for inspecting spatial partitioning behavior

**Ready for Phase 6**: Documentation and educational content creation.