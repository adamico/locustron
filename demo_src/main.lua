include("lib/require.lua")

Class = require('lib.middleclass')
Sort = require("demo_src.sort")
Stateful = require('lib.stateful')
SceneManager = require("demo_src.scene_manager")
Scene = SceneManager:new()

local Locustron = require("src.locustron")

local VisualizationSystem = require("demo_src.debugging.visualization_system")
local PerformanceProfiler = require("demo_src.debugging.performance_profiler")
local DebugConsole = require("demo_src.debugging.debug_console")

local loc

local scenes = SceneManager.Scenes
local initial_scene = scenes.SurvivorLike.name
local current_scene

-- Debugging system components
local vis_system
local perf_profiler
local debug_console
local show_debug_ui = true
local debug_mode = false
local show_debug_console = false

function count_keys(t)
   local count = 0
   for _ in pairs(t) do count = count + 1 end
   return count
end

function rand(low, hi) return flr(low + rnd(hi - low)) end

function _init()
   switch_scene(initial_scene)
end

function switch_scene(scene_name)
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
   Scene:gotoState(scene_name)
   Scene:init(loc, perf_profiler)
   current_scene = Scene:getStateStackDebugInfo()[1]
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
      switch_scene(scenes[current_scene].next)
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

   if Scene and Scene.update then Scene:update() end

   -- Track the update query for visualization (if scenario supports it)
   if debug_mode and vis_system and Scene.get_objects then
      local objects = Scene:get_objects()
      if vis_system then vis_system:add_query(0, 0, 256, 256, #objects) end
   end
end

function _draw()
   cls()

   if debug_mode and vis_system then
      -- Debug visualization mode
      vis_system:render_strategy(loc:get_strategy(), "fixed_grid")
   else
      -- Scenario visualization mode
      if Scene and Scene.draw then Scene:draw() end
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

function draw_debug_overlay()
   -- Draw debug controls help
   local info_x = 280
   local info_y = 154
   local line_height = 8
   local lines = 10
   local padding = 1
   local box_width = 180
   local box_height = lines * (line_height + padding) -- = 10 * (8 + 1) = 99
   rrectfill(info_x - 2, info_y - 2, box_width, box_height, 0, 0)
   rrect(info_x - 2, info_y - 2, box_width, box_height, 0, 7)

   color(11)
   print("CONTROLS", info_x, info_y)
   info_y += line_height

   print("Z: Toggle UI", info_x, info_y)
   info_y += line_height
   print("X: Toggle Debug Mode", info_x, info_y)
   info_y += line_height
   print("`: Toggle Console", info_x, info_y)
   info_y += line_height
   print("Tab: Switch Scenario", info_x, info_y)
   info_y += line_height

   if debug_mode then
      color(8)
      print("G: Toggle Grid", info_x, info_y)
      info_y += line_height
      print("O: Toggle Objects", info_x, info_y)
      info_y += line_height
      print("Q: Toggle Queries", info_x, info_y)
      info_y += line_height
      -- FIXME : profiler is broken
      -- print("P: Toggle Performance", help_x, help_y)
      -- help_y += line_height
      print("+/-: Zoom In/Out", info_x, info_y)
      info_y += line_height
      print("Arrows: Pan Viewport", info_x, info_y)
   end
end

function draw_debug_info()
   -- Draw performance and system info
   local info_x = 280
   local info_y = 50
   local line_height = 8
   local lines = 10
   local padding = 1
   local box_width = 180
   local box_height = lines * (line_height + padding) -- = 10 * (8 + 1) = 99
   rrectfill(info_x - 2, info_y - 2, box_width, box_height, 0, 0)
   rrect(info_x - 2, info_y - 2, box_width, box_height, 0, 7)

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

   -- Strategy info
   print(string.format("Strategy: %s", vis_system.current_strategy_name), info_x, info_y)

   -- Performance profiler stats : FIXME: profiler doesn't seem to be working
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

function draw_scenario_info()
   if not current_scene then return end

   local info_x = 280
   local info_y = 8
   local lines = 3
   local padding = 1
   local line_height = 8
   local box_width = 140
   local box_height = lines * (line_height + padding) -- = 3 * (8 + 1) = 27

   rrectfill(info_x - 2, info_y - 2, box_width, box_height, 0, 0)
   rrect(info_x - 2, info_y - 2, box_width, box_height, 0, 7)

   print("SCENARIO", info_x, info_y, 11)
   info_y += line_height

   color(7)
   print(scenes[current_scene].name, info_x, info_y)
   info_y += line_height

   print("Best: " .. Scene.optimal_strategy, info_x, info_y)
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
