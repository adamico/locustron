--- @diagnostic disable: different-requires
include("src/require.lua")

local Locustron = require("src.locustron")

local VisualizationSystem = require("src.debugging.visualization_system")
local PerformanceProfiler = require("src.debugging.performance_profiler")
local DebugConsole = require("src.debugging.debug_console")

local loc
local GRID_SIZE = 256 -- Main grid display area
local GRID_X = 16 -- Grid offset from left
local GRID_Y = 8 -- Grid offset from top

local OBJECTS_MIN_WIDTH = 10
local OBJECTS_MAX_WIDTH = 32
local MAX_OBJECTS = 100

-- Debugging system components
local vis_system
local perf_profiler
local debug_console
local show_debug_ui = true
local debug_mode = false

function rand(low, hi) return flr(low + rnd(hi - low)) end

function draw_debug_overlay()
   -- Draw debug controls help
   local help_x = 10
   local help_y = 10
   local line_height = 8

   color(0)
   rectfill(help_x - 2, help_y - 2, 180, 60)
   color(7)
   rect(help_x - 2, help_y - 2, 180, 60)

   color(11)
   print("CONTROLS", help_x, help_y)
   help_y = help_y + line_height

   print("Z: Toggle UI", help_x, help_y)
   help_y = help_y + line_height
   print("X: Toggle Debug Mode", help_x, help_y)
   help_y = help_y + line_height

   if debug_mode then
      print("Arrows: Toggle Layers", help_x, help_y)
      help_y = help_y + line_height
      print("A/S: Zoom In/Out", help_x, help_y)
   end
end

function draw_debug_info()
   -- Draw performance and system info
   local info_x = 280
   local info_y = 10
   local line_height = 8

   color(0)
   rectfill(info_x - 2, info_y - 2, 120, 80)
   color(7)
   rect(info_x - 2, info_y - 2, 120, 80)

   color(11)
   print("LOCUSTRON", info_x, info_y)
   info_y = info_y + line_height * 1.5

   color(7)
   print("Objects: " .. tostr(loc:count()), info_x, info_y)
   info_y = info_y + line_height

   -- Get strategy statistics
   local strategy = loc:get_strategy()
   local stats = strategy:get_statistics()

   print("Cells: " .. tostr(stats.cell_count), info_x, info_y)
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
   loc = Locustron.create(32)

   -- Initialize debugging system
   vis_system = VisualizationSystem:new({
      viewport = {x = 0, y = 0, w = GRID_SIZE, h = GRID_SIZE, scale = 1.0}
   })

   perf_profiler = PerformanceProfiler:new({
      enabled = true,
      sample_rate = 0.1
   })

   debug_console = DebugConsole:new()
   debug_console:set_strategy(loc:get_strategy(), "fixed_grid")
   debug_console:set_visualization_system(vis_system)
   debug_console:set_performance_profiler(perf_profiler)

   for _ = 1, MAX_OBJECTS do
      local w = rand(OBJECTS_MIN_WIDTH, OBJECTS_MAX_WIDTH)
      local obj = {
         x = rand(20, 220), -- Spread across the 256x256 grid area
         y = rand(20, 220),
         w = w,
         h = w,
         av = rnd(),
         r = rnd() * 2, -- Slightly more movement for the larger space
         col = rand(6, 15),
      }
      loc:add(obj, obj.x, obj.y, obj.w, obj.h)
   end
end

function _update()
   -- Handle debug input
   if btnp(4) then -- Z key - toggle debug UI
      show_debug_ui = not show_debug_ui
   end

   if btnp(5) then -- X key - toggle debug mode
      debug_mode = not debug_mode
   end

   if debug_mode and vis_system then
      -- Debug visualization controls
      if btnp(0) then vis_system.show_structure = not vis_system.show_structure end -- Left - toggle structure
      if btnp(1) then vis_system.show_objects = not vis_system.show_objects end -- Right - toggle objects
      if btnp(2) then vis_system.show_queries = not vis_system.show_queries end -- Up - toggle queries
      if btnp(3) then vis_system.show_performance = not vis_system.show_performance end -- Down - toggle performance

      -- Zoom controls
      if btnp(6) then -- A key - zoom in
         vis_system.viewport.scale = vis_system.viewport.scale * 1.2
      end
      if btnp(7) then -- S key - zoom out
         vis_system.viewport.scale = vis_system.viewport.scale / 1.2
      end
   end

   -- move all the objects in locus
   -- we use a bigger box than just the grid so that we also update the objects that
   -- are outside of the visible grid area
   for obj in pairs(loc:query(-64, -64, 384, 384)) do
      obj.x = obj.x + sin(obj.av * t()) * obj.r
      obj.y = obj.y + cos(obj.av * t()) * obj.r
      -- Use userdata-optimized update which leverages get_bbox internally
      loc:update(obj, obj.x, obj.y, obj.w, obj.h)
   end
end

function _draw()
   cls()

   if debug_mode and vis_system then
      -- Debug visualization mode
      vis_system:render_strategy(loc, "fixed_grid")

      -- Render debug UI overlay
      if show_debug_ui then
         draw_debug_overlay()
      end
   else
      -- Simple visualization mode - just show objects
      color(1)
      for obj in pairs(loc:query(-64, -64, 384, 384)) do
         local x, y, w, h = loc:get_bbox(obj)
         if x then
            rectfill(GRID_X + x, GRID_Y + y, w, h, obj.col)
            rect(GRID_X + x, GRID_Y + y, w, h, 0)
         end
      end
   end

   -- Always show debug info if enabled
   if show_debug_ui then
      draw_debug_info()
   end
end
