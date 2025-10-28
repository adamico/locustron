--- @class DebugConsole
--- Runtime debugging console for Locustron spatial partitioning
--- Provides command-line interface for inspecting and controlling spatial structures
--- Optimized for Picotron runtime with efficient command parsing and execution
--- @field commands table Available console commands
--- @field history table[] Command execution history
--- @field config table Console configuration
--- @field output_buffer table[] Output buffer for display
--- @field current_strategy table Currently inspected strategy
--- @field visualization_system table Visualization system integration
--- @field performance_profiler table Performance profiler integration
local class = require("lib.middleclass")
local DebugConsole = class("DebugConsole")

local time = os and os.time or time
local add = add and add or table.insert
local deli = deli and deli or table.remove

--- Create a new debug console instance
--- @param config table Configuration table with console settings
function DebugConsole:initialize(config)
   config = config or {}

   -- Console configuration
   self.config = {
      max_history = config.max_history or 100,
      max_output_lines = config.max_output_lines or 50,
      enable_echo = config.enable_echo == nil and true or config.enable_echo,
      case_sensitive = config and config.case_sensitive or false
   }

   -- Command system
   self.commands = {}
   self.history = {}
   self.output_buffer = {}
   self.current_command = ""
   self.cursor_pos = 0

   -- Integration with other debugging systems
   self.current_strategy = nil
   self.visualization_system = nil
   self.performance_profiler = nil

   -- Input state
   self.input_active = false
   self.input_buffer = ""

   -- Register built-in commands
   self:register_builtin_commands()
end

--- Register built-in console commands
function DebugConsole:register_builtin_commands()
   -- Information commands
   self:register_command("help", function(args)
      return self:get_help_text()
   end, "Show available commands")

   self:register_command("info", function(args)
      return self:get_system_info()
   end, "Show system information")

   self:register_command("stats", function(args)
      return self:get_strategy_stats()
   end, "Show strategy statistics")

   -- Strategy inspection commands
   self:register_command("inspect", function(args)
      return self:inspect_strategy(args[1])
   end, "Inspect spatial strategy (inspect <strategy_name>)")

   self:register_command("objects", function(args)
      return self:list_objects(args[1])
   end, "List objects in strategy (objects [filter])")

   self:register_command("cells", function(args)
      return self:list_cells(args[1])
   end, "List occupied cells (cells [limit])")

   -- Query commands
   self:register_command("query", function(args)
      return self:execute_query(args)
   end, "Execute spatial query (query <x> <y> <w> <h>)")

   self:register_command("benchmark", function(args)
      return self:run_benchmark(args)
   end, "Run performance benchmark (benchmark <iterations>)")

   -- Performance commands
   self:register_command("perf", function(args)
      return self:get_performance_report()
   end, "Show performance report")

   self:register_command("bottlenecks", function(args)
      return self:get_bottlenecks(args[1])
   end, "Show performance bottlenecks (bottlenecks [count])")

   -- Visualization commands
   self:register_command("show", function(args)
      return self:toggle_visualization(args[1])
   end, "Toggle visualization (show <structure|objects|queries|performance>)")

   self:register_command("zoom", function(args)
      return self:set_zoom(args[1])
   end, "Set zoom level (zoom <level>)")

   -- Configuration commands
   self:register_command("config", function(args)
      return self:show_config()
   end, "Show current configuration")

   self:register_command("set", function(args)
      return self:set_config(args)
   end, "Set configuration value (set <key> <value>)")

   -- Utility commands
   self:register_command("clear", function(args)
      self:clear_output()
      return "Output cleared"
   end, "Clear console output")

   self:register_command("history", function(args)
      return self:show_history(args[1])
   end, "Show command history (history [count])")

   self:register_command("echo", function(args)
      return table.concat(args, " ")
   end, "Echo arguments")
end

--- Register a custom console command
--- @param name string Command name
--- @param handler function Command handler function
--- @param description string Command description
function DebugConsole:register_command(name, handler, description)
   self.commands[name] = {
      handler = handler,
      description = description or "",
      registered_at = time()
   }
end

--- Execute a console command
--- @param command_line string The command line to execute
--- @return string Command output
function DebugConsole:execute_command(command_line)
   if not command_line or command_line == "" then
      return ""
   end

   -- Add to history
   add(self.history, {
      command = command_line,
      timestamp = time(),
      output = nil
   })

   -- Maintain history limit
   if #self.history > self.config.max_history then
      deli(self.history, 1)
   end

   -- Parse command
   local args = self:parse_command_line(command_line)
   local cmd_name = deli(args, 1)

   if not cmd_name then
      return "Error: Empty command"
   end

   -- Find command
   local command = self.commands[cmd_name]
   if not command then
      return string.format("Error: Unknown command '%s'. Type 'help' for available commands.", cmd_name)
   end

   -- Execute command
   local success, result = pcall(command.handler, args)
   if not success then
      result = string.format("Error executing command '%s': %s", cmd_name, result)
   end

   -- Store output in history
   self.history[#self.history].output = result

   -- Add to output buffer
   self:add_output(string.format("> %s", command_line))
   if result and result ~= "" then
      for line in result:gmatch("[^\n]+") do
         self:add_output(line)
      end
   end

   return result
end

--- Parse command line into arguments
--- @param command_line string Command line to parse
--- @return table Array of arguments
function DebugConsole:parse_command_line(command_line)
   local args = {}
   local in_quotes = false
   local current_arg = ""

   for i = 1, #command_line do
      local char = string.sub(command_line, i, i)

      if char == '"' then
         in_quotes = not in_quotes
      elseif char == " " and not in_quotes then
         if current_arg ~= "" then
            add(args, current_arg)
            current_arg = ""
         end
      else
         current_arg = current_arg .. char
      end
   end

   if current_arg ~= "" then
      add(args, current_arg)
   end

   return args
end

--- Add output to the console buffer
--- @param text string Text to add
function DebugConsole:add_output(text)
   add(self.output_buffer, text)

   -- Maintain buffer limit
   if #self.output_buffer > self.config.max_output_lines then
      deli(self.output_buffer, 1)
   end
end

--- Clear the output buffer
function DebugConsole:clear_output()
   self.output_buffer = {}
end

--- Get formatted help text
--- @return string Help text
function DebugConsole:get_help_text()
   local lines = {"Available commands:"}

   -- Sort commands alphabetically
   local sorted_commands = {}
   for name, cmd in pairs(self.commands) do
      add(sorted_commands, {name = name, desc = cmd.description})
   end
   table.sort(sorted_commands, function(a, b) return a.name < b.name end)

   for _, cmd in ipairs(sorted_commands) do
      add(lines, string.format("  %-12s %s", cmd.name, cmd.desc))
   end

   add(lines, "")
   add(lines, "Type 'help <command>' for detailed help on a specific command.")

   return table.concat(lines, "\n")
end

--- Get system information
--- @return string System info
function DebugConsole:get_system_info()
   local lines = {"System Information:"}

   if self.current_strategy then
      add(lines, string.format("Strategy: %s", self.current_strategy._strategy_name or "unknown"))
      add(lines, string.format("Objects: %d", self:get_object_count()))
   else
      add(lines, "Strategy: None loaded")
   end

   if self.performance_profiler then
      local stats = self.performance_profiler.stats
      add(lines, string.format("Queries: %d", stats.total_queries))
      add(lines, string.format("Avg Query Time: %.3fms", stats.average_query_time * 1000))
   end

   if self.visualization_system then
      local vp = self.visualization_system.viewport
      add(lines, string.format("Viewport: (%.1f, %.1f) scale: %.2f", vp.x, vp.y, vp.scale))
   end

   return table.concat(lines, "\n")
end

--- Get strategy statistics
--- @return string Statistics report
function DebugConsole:get_strategy_stats()
   if not self.current_strategy then
      return "No strategy loaded"
   end

   local lines = {"Strategy Statistics:"}

   -- Basic counts
   local obj_count = self:get_object_count()
   add(lines, string.format("Total Objects: %d", obj_count))

   -- Strategy-specific stats
   if self.current_strategy.cell_size then
      add(lines, string.format("Cell Size: %d", self.current_strategy.cell_size))
   end

   if self.current_strategy.max_objects then
      add(lines, string.format("Max Objects per Node: %d", self.current_strategy.max_objects))
   end

   -- Memory estimation
   local estimated_memory = obj_count * 32 -- Rough estimate: 32 bytes per object
   add(lines, string.format("Estimated Memory: %d KB", math.floor(estimated_memory / 1024)))

   return table.concat(lines, "\n")
end

--- Inspect a specific strategy
--- @param strategy_name string Name of strategy to inspect
--- @return string Inspection results
function DebugConsole:inspect_strategy(strategy_name)
   if not strategy_name then
      return "Usage: inspect <strategy_name>"
   end

   -- This would integrate with strategy factory
   return string.format("Strategy inspection for '%s' not yet implemented", strategy_name)
end

--- List objects in current strategy
--- @param filter string Optional filter pattern
--- @return string Object list
function DebugConsole:list_objects(filter)
   if not self.current_strategy or not self.current_strategy.objects then
      return "No strategy loaded or no objects available"
   end

   local lines = {"Objects in strategy:"}
   local count = 0
   local limit = 20 -- Limit output

   for obj_id, obj_data in pairs(self.current_strategy.objects) do
      if count >= limit then
         add(lines, string.format("... and %d more objects", self:get_object_count() - limit))
         break
      end

      local matches_filter = not filter or string.find(tostring(obj_id), filter)
      if matches_filter then
         add(lines, string.format("  ID:%s Pos:(%.1f,%.1f) Size:(%.1f,%.1f)",
            obj_id, obj_data.x or 0, obj_data.y or 0, obj_data.w or 0, obj_data.h or 0))
         count = count + 1
      end
   end

   if count == 0 then
      add(lines, "  No objects found")
   end

   return table.concat(lines, "\n")
end

--- List occupied cells
--- @param limit_str string Optional limit
--- @return string Cell list
function DebugConsole:list_cells(limit_str)
   if not self.current_strategy then
      return "No strategy loaded"
   end

   local limit = tonumber(limit_str) or 10
   local lines = {"Occupied cells:"}

   -- This would need strategy-specific implementation
   -- For now, return placeholder
   add(lines, "Cell listing not yet implemented for current strategy")

   return table.concat(lines, "\n")
end

--- Execute a spatial query
--- @param args table Query arguments [x, y, w, h]
--- @return string Query results
function DebugConsole:execute_query(args)
   if #args < 4 then
      return "Usage: query <x> <y> <w> <h>"
   end

   local x, y, w, h = tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
   if not (x and y and w and h) then
      return "Error: Invalid numeric arguments"
   end

   if not self.current_strategy or not self.current_strategy.query_region then
      return "No queryable strategy loaded"
   end

   -- Execute query
   local start_time = self:get_time()
   local results = self.current_strategy:query_region(x, y, w, h)
   local end_time = self:get_time()

   local result_count = 0
   if type(results) == "table" then
      for _ in pairs(results) do result_count = result_count + 1 end
   end

   -- Add to visualization if available
   if self.visualization_system then
      self.visualization_system:add_query(x, y, w, h, result_count)
   end

   -- Measure performance if profiler available
   if self.performance_profiler then
      self.performance_profiler:measure_query(
         self.current_strategy._strategy_name or "unknown",
         function() return self.current_strategy:query_region(x, y, w, h) end,
         x, y, w, h
      )
   end

   return string.format("Query (%.1f,%.1f,%.1f,%.1f) returned %d results in %.3fms",
      x, y, w, h, result_count, (end_time - start_time) * 1000)
end

--- Run performance benchmark
--- @param args table Benchmark arguments [iterations]
--- @return string Benchmark results
function DebugConsole:run_benchmark(args)
   local iterations = tonumber(args[1]) or 100

   if not self.current_strategy or not self.current_strategy.query_region then
      return "No queryable strategy loaded"
   end

   if not self.performance_profiler then
      return "Performance profiler not available"
   end

   self.performance_profiler:start_session()

   -- Run benchmark queries
   for i = 1, iterations do
      local x, y = math.random(0, 1000), math.random(0, 1000)
      self.performance_profiler:measure_query(
         self.current_strategy._strategy_name or "benchmark",
         function() return self.current_strategy:query_region(x, y, 64, 64) end,
         x, y, 64, 64
      )
   end

   self.performance_profiler:end_session()

   local stats = self.performance_profiler.stats
   return string.format("Benchmark completed: %d queries, avg %.3fms, %.1f queries/sec",
      iterations, stats.average_query_time * 1000, stats.queries_per_second)
end

--- Get performance report
--- @return string Performance report
function DebugConsole:get_performance_report()
   if not self.performance_profiler then
      return "Performance profiler not available"
   end

   return self.performance_profiler:get_report()
end

--- Get performance bottlenecks
--- @param count_str string Number of bottlenecks to show
--- @return string Bottleneck list
function DebugConsole:get_bottlenecks(count_str)
   if not self.performance_profiler then
      return "Performance profiler not available"
   end

   local count = tonumber(count_str) or 5
   local bottlenecks = self.performance_profiler:get_bottlenecks(count)

   if #bottlenecks == 0 then
      return "No performance data available"
   end

   local lines = {"Performance Bottlenecks:"}
   for i, bottleneck in ipairs(bottlenecks) do
      add(lines, string.format("%d. %s: %.3fms",
         i, bottleneck.strategy, bottleneck.execution_time * 1000))
   end

   return table.concat(lines, "\n")
end

--- Toggle visualization options
--- @param option string Visualization option to toggle
--- @return string Result message
function DebugConsole:toggle_visualization(option)
   if not self.visualization_system then
      return "Visualization system not available"
   end

   if option == "structure" then
      self.visualization_system.show_structure = not self.visualization_system.show_structure
      return string.format("Structure visualization: %s",
         self.visualization_system.show_structure and "ON" or "OFF")
   elseif option == "objects" then
      self.visualization_system.show_objects = not self.visualization_system.show_objects
      return string.format("Object visualization: %s",
         self.visualization_system.show_objects and "ON" or "OFF")
   elseif option == "queries" then
      self.visualization_system.show_queries = not self.visualization_system.show_queries
      return string.format("Query visualization: %s",
         self.visualization_system.show_queries and "ON" or "OFF")
   elseif option == "performance" then
      self.visualization_system.show_performance = not self.visualization_system.show_performance
      return string.format("Performance visualization: %s",
         self.visualization_system.show_performance and "ON" or "OFF")
   else
      return "Usage: show <structure|objects|queries|performance>"
   end
end

--- Set zoom level
--- @param level_str string Zoom level
--- @return string Result message
function DebugConsole:set_zoom(level_str)
   if not self.visualization_system then
      return "Visualization system not available"
   end

   local level = tonumber(level_str)
   if not level or level <= 0 then
      return "Error: Invalid zoom level"
   end

   self.visualization_system.viewport.scale = level
   return string.format("Zoom level set to %.2f", level)
end

--- Show current configuration
--- @return string Configuration display
function DebugConsole:show_config()
   local lines = {"Console Configuration:"}

   for key, value in pairs(self.config) do
      add(lines, string.format("  %s: %s", key, tostring(value)))
   end

   return table.concat(lines, "\n")
end

--- Set configuration value
--- @param args table Configuration arguments [key, value]
--- @return string Result message
function DebugConsole:set_config(args)
   if #args < 2 then
      return "Usage: set <key> <value>"
   end

   local key, value_str = args[1], args[2]
   local value

   -- Parse value
   if value_str == "true" then
      value = true
   elseif value_str == "false" then
      value = false
   else
      value = tonumber(value_str) or value_str
   end

   if self.config[key] == nil then
      return string.format("Error: Unknown configuration key '%s'", key)
   end

   self.config[key] = value
   return string.format("Set %s = %s", key, tostring(value))
end

--- Show command history
--- @param count_str string Number of history items to show
--- @return string History display
function DebugConsole:show_history(count_str)
   local count = tonumber(count_str) or 10
   local lines = {"Command History:"}

   local start_idx = math.max(1, #self.history - count + 1)
   for i = start_idx, #self.history do
      local entry = self.history[i]
      add(lines, string.format("%d. %s", i, entry.command))
   end

   if #self.history == 0 then
      add(lines, "  No commands in history")
   end

   return table.concat(lines, "\n")
end

--- Get object count from current strategy
--- @return number Object count
function DebugConsole:get_object_count()
   if not self.current_strategy or not self.current_strategy.objects then
      return 0
   end

   local count = 0
   for _ in pairs(self.current_strategy.objects) do
      count = count + 1
   end
   return count
end

--- Get high-resolution time (Picotron optimized)
--- @return number Current time
function DebugConsole:get_time()
   return time and time()
end

--- Set current strategy for inspection
--- @param strategy table Strategy instance
--- @param strategy_name string Strategy name
function DebugConsole:set_strategy(strategy, strategy_name)
   self.current_strategy = strategy
   if strategy then
      strategy._strategy_name = strategy_name
   end
end

--- Set visualization system integration
--- @param visualization_system table VisualizationSystem instance
function DebugConsole:set_visualization_system(visualization_system)
   self.visualization_system = visualization_system
end

--- Set performance profiler integration
--- @param performance_profiler table PerformanceProfiler instance
function DebugConsole:set_performance_profiler(performance_profiler)
   self.performance_profiler = performance_profiler
end

--- Get output buffer for display
--- @return table Output buffer
function DebugConsole:get_output()
   return self.output_buffer
end

--- Handle keyboard input for console
--- @param key string Key pressed
function DebugConsole:handle_input(key)
   -- This would handle interactive console input
   -- Implementation depends on Picotron input system
end

return DebugConsole