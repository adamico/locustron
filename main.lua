include("src/require.lua")

local Locustron = require("src.locustron")
local DemoScenarios = require("demo.demo_scenarios")

local VisualizationSystem = require("demo.debugging.visualization_system")
local PerformanceProfiler = require("demo.debugging.performance_profiler")
local DebugConsole = require("demo.debugging.debug_console")

local loc
local GRID_SIZE = 256 -- Main grid display area
local GRID_X = 16 -- Grid offset from left
local GRID_Y = 8 -- Grid offset from top

-- Demo scenario system
local current_scenario
local scenario_names = DemoScenarios.get_available_scenarios()
local current_scenario_index = 1

-- Debugging system components
local vis_system
local perf_profiler
local debug_console
local show_debug_ui = true
local debug_mode = false
local show_debug_console = false

function rand(low, hi) return flr(low + rnd(hi - low)) end

function draw_debug_overlay()
   -- Draw debug controls help
   local help_x = 280
   local help_y = 120
   local line_height = 8

   rrectfill(help_x - 2, help_y - 2, 180, 110, 0, 0)
   rrect(help_x - 2, help_y - 2, 180, 110, 0, 7)

   color(11)
   print("CONTROLS", help_x, help_y)
   help_y += line_height

   print("Z: Toggle UI", help_x, help_y)
   help_y += line_height
   print("X: Toggle Debug Mode", help_x, help_y)
   help_y += line_height
   print("`: Toggle Console", help_x, help_y)
   help_y += line_height
   print("Tab: Switch Scenario", help_x, help_y)
   help_y += line_height * 1.5

   if debug_mode then
      color(8)
      print("G: Toggle Grid", help_x, help_y)
      help_y += line_height
      print("O: Toggle Objects", help_x, help_y)
      help_y += line_height
      print("Q: Toggle Queries", help_x, help_y)
      help_y += line_height
      print("P: Toggle Performance", help_x, help_y)
      help_y += line_height
      print("+/-: Zoom In/Out", help_x, help_y)
      help_y += line_height
      print("Arrows: Pan Viewport", help_x, help_y)
   end
end

function draw_visualization_ui()
   if not vis_system or not vis_system.current_strategy then return end

   -- Strategy info
   print(string.format("Strategy: %s", vis_system.current_strategy_name), 280, 230, 8)

   -- Object count
   local obj_count = 0
   if vis_system.current_strategy.objects then
      for _ in pairs(vis_system.current_strategy.objects) do
         obj_count = obj_count + 1
      end
   end
   print(string.format("Objects: %d", obj_count), 280, 240, 8)
end

function draw_debug_info()
   -- Draw performance and system info
   local info_x = 280
   local info_y = 28
   local line_height = 8

   rrectfill(info_x - 2, info_y - 2, 120, 80, 0, 0)
   rrect(info_x - 2, info_y - 2, 120, 80, 0, 7)

   print("LOCUSTRON", info_x, info_y, 11)
   info_y = info_y + line_height * 1.5

   print("Objects: " .. tostr(loc:count()), info_x, info_y, 7)
   info_y = info_y + line_height

   -- Get strategy statistics
   local strategy = loc:get_strategy()
   local stats = strategy:get_statistics()

   print("Cells: " .. tostr(stats.cell_count), info_x, info_y)
   info_y = info_y + line_height

   print("Cell size: " .. tostr(stats.cell_size), info_x, info_y)
   info_y = info_y + line_height

   print("CPU: " .. tostr(flr(stat(1) * 100)) .. "%", info_x, info_y)
   info_y = info_y + line_height

   print("MEM: " .. tostr(flr(stat(3) / 1024)) .. "KB", info_x, info_y)
   info_y = info_y + line_height

   if perf_profiler.enabled then
      local stats = perf_profiler.stats
      if stats.total_queries > 0 then
         info_y = info_y + line_height
         color(11)
         print("QUERIES", info_x, info_y)
         info_y = info_y + line_height

         color(7)
         print("Total: " .. tostr(stats.total_queries), info_x, info_y)
         info_y = info_y + line_height

         print("Avg: " .. tostr(flr(stats.average_query_time * 1000)) .. "ms", info_x, info_y)
      end
   end
end

function _init()
   -- Initialize with default scenario (survivor like)
   switch_scenario("survivor_like")
end

function switch_scenario(scenario_name)
   -- Clear existing spatial structure
   if loc then loc:clear() end

   -- Create new spatial structure
   loc = Locustron.create(64) -- Fixed cell size for now

   -- Initialize debugging system components first
   if not perf_profiler then
      perf_profiler = PerformanceProfiler:new({
         enabled = true,
         sample_rate = 0.1,
      })
   else
      -- Reset profiler for new scenario
      perf_profiler:clear()
   end

   -- Create scenario
   current_scenario = DemoScenarios.create_scenario(scenario_name, { max_objects = 200 })
   current_scenario:init(loc, perf_profiler)

   local strategy = loc:get_strategy()
   if not debug_console then debug_console = DebugConsole:new() end
   debug_console:set_strategy(strategy, "fixed_grid")
   debug_console:set_visualization_system(vis_system)
   debug_console:set_performance_profiler(perf_profiler)
   debug_console.input_buffer = debug_console.input_buffer or ""

   -- Initialize visualization system if needed
   if not vis_system then
      vis_system = VisualizationSystem:new()
   end
   vis_system.current_strategy = strategy
   vis_system.current_strategy_name = "fixed_grid"
end

function _update()
   -- Handle debug input
   if btnp(4) then -- Z key - toggle debug UI
      show_debug_ui = not show_debug_ui
   end

   if btnp(5) then -- X key - toggle debug mode
      debug_mode = not debug_mode
   end

   -- Debug console toggle (backtick key)
   if keyp("`", true) then
      show_debug_console = not show_debug_console
   end

   -- Handle debug console input when active
   if show_debug_console and debug_console then
      -- Disable pause menu to prevent conflicts with debug console
      window{pauseable = false}

      -- Handle alphanumeric and symbol input
      local key_map = {
         ["a"] = "a", ["b"] = "b", ["c"] = "c", ["d"] = "d", ["e"] = "e",
         ["f"] = "f", ["g"] = "g", ["h"] = "h", ["i"] = "i", ["j"] = "j",
         ["k"] = "k", ["l"] = "l", ["m"] = "m", ["n"] = "n", ["o"] = "o",
         ["p"] = "p", ["q"] = "q", ["r"] = "r", ["s"] = "s", ["t"] = "t",
         ["u"] = "u", ["v"] = "v", ["w"] = "w", ["x"] = "x", ["y"] = "y",
         ["z"] = "z", ["0"] = "0", ["1"] = "1", ["2"] = "2", ["3"] = "3",
         ["4"] = "4", ["5"] = "5", ["6"] = "6", ["7"] = "7", ["8"] = "8",
         ["9"] = "9", [" "] = " ", ["-"] = "-", ["="] = "=", ["["] = "[",
         ["]"] = "]", ["\\"] = "\\", [";"] = ";", ["'"] = "'", [","] = ",",
         ["."] = ".", ["/"] = "/"
      }

      for key, char in pairs(key_map) do
         if keyp(key, true) then
            debug_console.input_buffer = debug_console.input_buffer .. char
            break
         end
      end

      -- Handle backspace
      if keyp("backspace", true) and #debug_console.input_buffer > 0 then
         debug_console.input_buffer = debug_console.input_buffer:sub(1, -2)
      end

      -- Handle enter to execute command
      if keyp("return", true) or keyp("enter", true) then
         if debug_console.input_buffer ~= "" then
            debug_console:execute_command(debug_console.input_buffer)
            debug_console.input_buffer = ""
         end
      end
   else
      -- Re-enable pause menu when console is closed
      window{pauseable = true}
   end

   -- Scenario switching (Tab key)
   if keyp("tab", true) then
      current_scenario_index = current_scenario_index % #scenario_names + 1
      local next_scenario = scenario_names[current_scenario_index]
      switch_scenario(next_scenario)
   end

   if debug_mode and vis_system then
      -- Visualization system keyboard controls
      if keyp("g", true) then vis_system.show_structure = not vis_system.show_structure end
      if keyp("o", true) then vis_system.show_objects = not vis_system.show_objects end
      if keyp("q", true) then vis_system.show_queries = not vis_system.show_queries end
      if keyp("p", true) then vis_system.show_performance = not vis_system.show_performance end

      -- Zoom controls
      if keyp("+", true) or keyp("=") then
         vis_system.viewport.scale = min(vis_system.viewport.scale * 1.2, 10.0)
      elseif keyp("-", true) then
         vis_system.viewport.scale = max(vis_system.viewport.scale / 1.2, 0.1)
      end

      -- Pan controls
      local pan_speed = 16 / vis_system.viewport.scale
      if btn(2) then -- Up arrow
         vis_system.viewport.y = vis_system.viewport.y - pan_speed
      elseif btn(3) then -- Down arrow
         vis_system.viewport.y = vis_system.viewport.y + pan_speed
      elseif btn(0) then -- Left arrow
         vis_system.viewport.x = vis_system.viewport.x - pan_speed
      elseif btn(1) then -- Right arrow
         vis_system.viewport.x = vis_system.viewport.x + pan_speed
      end
   end

   -- Update current scenario
   if current_scenario then
      current_scenario:update(loc, 1 / 30) -- Assume 30 FPS
   end

   -- Track the update query for visualization (if scenario supports it)
   if debug_mode and vis_system and current_scenario.get_objects then
      local objects = current_scenario:get_objects()
      if vis_system then vis_system:add_query(0, 0, 256, 256, #objects) end
   end
end

function _draw()
   cls()

   if debug_mode and vis_system then
      -- Debug visualization mode
      vis_system:render_strategy(loc:get_strategy(), "fixed_grid")

      -- Render visualization UI overlay
      draw_visualization_ui()
   else
      -- Scenario visualization mode
      if current_scenario and current_scenario.draw then current_scenario:draw() end
   end

   -- Render debug UI overlay
   if show_debug_ui then
      draw_debug_overlay()
      draw_debug_info()
      draw_scenario_info()
   end

   -- Render debug console if active
   draw_debug_console()
end

function draw_scenario_info()
   if not current_scenario then return end

   local info = DemoScenarios.get_scenario_info(scenario_names[current_scenario_index])
   if not info then return end

   local info_x = 8
   local info_y = 120
   local line_height = 8

   rrectfill(info_x - 2, info_y - 2, 140, 50, 0, 0)
   rrect(info_x - 2, info_y - 2, 140, 50, 0, 7)

   color(11)
   print("SCENARIO", info_x, info_y)
   info_y += line_height

   color(7)
   print(info.name, info_x, info_y)
   info_y += line_height

   print("Tab: Switch", info_x, info_y)
   info_y += line_height

   print("Best: " .. info.optimal_strategy, info_x, info_y)
end

function draw_debug_console()
   if not show_debug_console or not debug_console then return end

   -- Console dimensions and positioning
   local console_width = 400
   local console_height = 200
   local console_x = 8
   local console_y = 240 - console_height - 8
   local line_height = 8
   local max_visible_lines = 20

   -- Draw console background
   rrectfill(console_x - 2, console_y - 2, console_width + 4, console_height + 4, 0, 0)
   rrect(console_x - 2, console_y - 2, console_width + 4, console_height + 4, 0, 7)

   -- Draw console header
   color(11)
   print("DEBUG CONSOLE", console_x, console_y)
   local header_y = console_y + line_height

   -- Draw output buffer (command history and results)
   local output_start = math.max(1, #debug_console.output_buffer - max_visible_lines + 3) -- +3 for input area
   local output_y = header_y

   for i = output_start, #debug_console.output_buffer do
      if output_y + line_height > console_y + console_height - line_height * 2 then break end
      print(debug_console.output_buffer[i], console_x, output_y, 7)
      output_y += line_height
   end

   -- Draw input prompt and current input
   local input_y = console_y + console_height - line_height * 2
   print("> ", console_x, input_y, 10)

   local input_text = debug_console.input_buffer
   if #input_text > 50 then -- Truncate long input
      input_text = "..." .. input_text:sub(-47)
   end
   print(input_text, console_x + 16, input_y, 7)

   -- Draw cursor (blinking effect)
   if time() % 1 < 0.5 then
      local cursor_x = console_x + 16 + print(input_text, 0, -100) -- Measure text width
      line(cursor_x, input_y, cursor_x, input_y + line_height - 1, 7)
   end

   -- Draw help text at bottom
   local help_y = console_y + console_height - line_height
   print("Enter: Execute | `: Toggle", console_x, help_y, 6)
end

include("error_explorer.lua")
