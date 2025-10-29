---@diagnostic disable: undefined-field
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
   loc = Locustron:new(64) -- Fixed cell size for now

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

   local margin = 8
   local left_side_x = margin
   local left_side_top_y = margin
   local left_side_bottom_y = 233
   local left_side_bottom_width = 480 - margin * 2
   local left_side_top_width = 192
   local right_side_x = 280
   local right_side_y = margin
   local right_width = 192
   local padding = 8

   -- Get strategy statistics
   local strategy = loc:get_strategy()
   local stats = strategy:get_statistics()


   local x = left_side_x
   local y = left_side_top_y
   local width = left_side_top_width
   -- Render scenario data info box
   y = draw_info_box(x, y, width, "DATA", Scene.draw_info) + padding

   -- Render debug UI overlay
   local x = right_side_x
   local y = right_side_y
   local width = right_width

   if show_debug_ui then
      -- Render stats info box
      y = draw_info_box(x, y, width, "STATS", {
         "Objects: " .. tostr(loc:count()),
         "Cells: " .. tostr(stats.cell_count),
         "CPU: " .. tostr(flr(stat(1) * 100)) .. "%",
         "MEM: " .. tostr(flr(stat(3) / 1024)) .. "KB",
         string.format("Strategy: %s", vis_system.current_strategy_name),
      }) + padding

      -- Render scenario info box
      y = draw_info_box(x, y, width, "SCENARIO", {
         scenes[current_scene].name,
         "Best strategy: " .. Scene.optimal_strategy,
      }) + padding

      -- Render debug mode controls info box
      if debug_mode then
         y = draw_info_box(x, y, width, "DEBUG CONTROLS", {
            "Z: Toggle UI",
            "X: Toggle Debug Mode",
            "G: Toggle Grid",
            "O: Toggle Objects",
            "Q: Toggle Queries",
            "P: Toggle Performance",
            "+/-: Zoom In/Out",
            "Arrows: Pan Viewport",
         }) + padding
      else
         -- Render UI controls info box
         y = draw_info_box(x, y, width, "CONTROLS", {
            "Z: Toggle UI",
            "X: Toggle Debug Mode",
            "`: Toggle Console",
            "Tab: Switch Scenario",
         }) + padding
      end

      -- Render scenario controls info box
      x = left_side_x
      y = left_side_bottom_y
      width = left_side_bottom_width
      draw_info_box(x, y, width, "SCENARIO CONTROLS", {
         Scene.controls or "N/A",
      })
   end

   -- Render debug console if active
   draw_debug_console()
end

function draw_info_box(x, y, width, title, lines_table, title_color)
   local line_height = 9
   local padding = 4
   local height = (#lines_table + 2) * (line_height) + padding / 2
   rrectfill(x, y, width, height, 0, 0)
   rrect(x, y, width, height, 0, 7)

   x += padding
   local line_y = y + padding
   print(title, x, line_y, title_color or 11)
   line_y += line_height * 1.5

   color(7)
   for _, line in ipairs(lines_table) do
      print(line, x, line_y)
      line_y += line_height
   end

   return y + height
end

function draw_debug_console()
   if not show_debug_console or not debug_console then return end

   local margin = 8
   local width = 480 - margin * 2
   local height = 270 - margin * 2
   local x = margin
   local y = margin
   local padding = 4
   local line_height = 9
   local max_visible_lines = 25

   -- Draw console background and border
   rrectfill(x, y, width, height, 0, 0)
   rrect(x, y, width, height, 0, 7)

   -- Draw console title bar
   rrectfill(x + 1, y + 1, width - 2, line_height + padding, 0, 1)
   rrect(x, y, width, line_height + padding + 2, 0, 7)
   x += padding
   print("DEBUG CONSOLE", x, y + padding, 11)

   -- Draw output buffer (command history and results)
   local output_start = math.max(1, #debug_console.output_buffer - max_visible_lines + 3) -- +3 for input area
   local output_y = y + line_height + padding * 2

   for i = output_start, #debug_console.output_buffer do
      if output_y + line_height > y + height - line_height * 2 then break end
      if i == 1 then
         local prompt = debug_console.output_buffer[i][1]
         print(prompt, x, output_y, 11)
         print(debug_console.output_buffer[i]:sub(2), x + padding, output_y, 7)
      else
         print(debug_console.output_buffer[i], x, output_y, 7)
      end
      output_y += line_height
   end

   -- Draw input prompt and current input
   local input_y = y + height - line_height * 3
   print("> ", x, input_y, 11)

   local input_text = debug_console.input_buffer
   if #input_text > 50 then -- Truncate long input
      input_text = "..." .. input_text:sub(-47)
   end
   print(input_text, x + margin, input_y, 7)

   -- Draw cursor (blinking effect)
   if time() % 1 < 0.5 then
      local cursor_x = x + margin + print(input_text, 0, -100) -- Measure text width
      line(cursor_x, input_y, cursor_x, input_y + line_height - 1, 7)
   end

   -- Draw help text at bottom
   rrect(margin, y + height - line_height - padding - 2, width, line_height + padding + 2, 0, 7)
   local help_y = y + height - line_height - padding + 2
   print("\fb ENTER:\f7 execute command  | \fb`:\f7 toggle console", margin, help_y, 6)
end

function draw_profiler_info()
   -- Performance profiler stats : FIXME: profiler doesn't seem to be working
   if perf_profiler.enabled then
      local stats = perf_profiler.stats
      if stats.total_queries > 0 then
         info_y = info_y + line_height
         color(11)
         print("QUERIES", ui_info_x, info_y)
         info_y = info_y + line_height

         color(7)
         print("Total: " .. tostr(stats.total_queries), ui_info_x, info_y)
         info_y = info_y + line_height

         print("Avg: " .. tostr(flr(stats.average_query_time * 1000)) .. "ms", ui_info_x, info_y)
      end
   end
end

function draw_controls_info()
   if not current_scene then return end
   local y = 248
   local lines = 2
   local padding = 2
   local line_height = 8
   local width = 480 - 12
   local height = lines * (line_height + padding) -- = 3 * (8 + 1) = 27
   rrectfill(scenario_info_x - 2, y - 2, width, height, 0, 0)
   rrect(scenario_info_x - 2, y - 2, width, height, 0, 7)
   print("CONTROLS", scenario_info_x, y, 11)
   y += line_height
   print(Scene.controls, scenario_info_x, y, 7)
end

include("error_explorer.lua")
