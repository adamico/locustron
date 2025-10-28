--- @diagnostic disable: different-requires
include("src/require.lua")

local Locustron = require("src/locustron")

local VisualizationSystem = require("src/debugging/visualization_system")
local PerformanceProfiler = require("src/debugging/performance_profiler")
local DebugConsole = require("src/debugging/debug_console")

local loc
local GRID_SIZE = 256 -- Main grid display area
local GRID_X = 16 -- Grid offset from left
local GRID_Y = 8 -- Grid offset from top
local INFO_X = GRID_X + GRID_SIZE + 16 -- Info panel to the right of grid

local OBJECTS_MIN_WIDTH = 10
local OBJECTS_MAX_WIDTH = 32
local MAX_OBJECTS = 100
local viewport

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
   rectfill(help_x - 2, help_y - 2, 200, 80)
   color(7)
   rect(help_x - 2, help_y - 2, 200, 80)

   color(7)
   print("DEBUG CONTROLS", help_x, help_y)
   help_y += line_height

   print("Z: Toggle UI", help_x, help_y)
   help_y += line_height
   print("X: Toggle Debug Mode", help_x, help_y)
   help_y += line_height

   if debug_mode then
      print("Arrow Keys: Toggle Layers", help_x, help_y)
      help_y += line_height
      print("A/S: Zoom In/Out", help_x, help_y)
      help_y += line_height
   end

   -- Show current visualization state
   help_y += line_height
   color(11)
   print("VISUALIZATION STATE", help_x, help_y)
   help_y += line_height

   if vis_system then
      color(vis_system.show_structure and 11 or 5)
      print("Structure: " .. (vis_system.show_structure and "ON" or "OFF"), help_x, help_y)
      help_y += line_height

      color(vis_system.show_objects and 11 or 5)
      print("Objects: " .. (vis_system.show_objects and "ON" or "OFF"), help_x, help_y)
      help_y += line_height

      color(vis_system.show_queries and 11 or 5)
      print("Queries: " .. (vis_system.show_queries and "ON" or "OFF"), help_x, help_y)
      help_y += line_height

      color(vis_system.show_performance and 11 or 5)
      print("Performance: " .. (vis_system.show_performance and "ON" or "OFF"), help_x, help_y)
   else
      color(5)
      print("Visualization system not initialized", help_x, help_y)
   end
end

function draw_debug_info()
   -- Draw performance and system info
   local info_x = 320
   local info_y = 10
   local line_height = 8

   color(0)
   rectfill(info_x - 2, info_y - 2, 150, 100)
   color(7)
   rect(info_x - 2, info_y - 2, 150, 100)

   color(11)
   print("SYSTEM INFO", info_x, info_y)
   info_y += line_height * 1.5

   color(7)
   print("Objects: " .. tostr(loc:count()), info_x, info_y)
   info_y += line_height

   -- Get strategy statistics
   local strategy = loc:get_strategy()
   local stats = strategy:get_statistics()

   print("Allocated cells: " .. tostr(stats.cell_count), info_x, info_y)
   info_y += line_height

   print("CPU: " .. tostr(flr(stat(1) * 100)) .. "%", info_x, info_y)
   info_y += line_height

   print("MEM: " .. tostr(flr(stat(3) / 1024)) .. "KB", info_x, info_y)
   info_y += line_height

   if perf_profiler.enabled then
      local stats = perf_profiler.stats
      if stats.total_queries > 0 then
         info_y += line_height
         color(11)
         print("PERFORMANCE", info_x, info_y)
         info_y += line_height

         color(7)
         print("Queries: " .. tostr(stats.total_queries), info_x, info_y)
         info_y += line_height

         print("Avg: " .. tostr(flr(stats.average_query_time * 1000)) .. "ms", info_x, info_y)
         info_y += line_height

         print("QPS: " .. tostr(flr(stats.queries_per_second)), info_x, info_y)
      end
   end
end

function _init()
   -- viewport. It's a rectangle that moves around, printing the objects it "sees" in color
   viewport = { x = 60, y = 60, w = 128, h = 128, dx = 2, dy = 1 }

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
      obj.x += sin(obj.av * t()) * obj.r
      obj.y += cos(obj.av * t()) * obj.r
      -- Use userdata-optimized update which leverages get_bbox internally
      loc:update(obj, obj.x, obj.y, obj.w, obj.h)
   end

   -- update the viewport within the grid bounds
   viewport.x += viewport.dx
   viewport.y += viewport.dy
   -- make the viewport bounce when it touches the grid borders
   if viewport.x < 0 or viewport.x + viewport.w > GRID_SIZE then
      viewport.dx *= -1
   end
   if viewport.y < 0 or viewport.y + viewport.h > GRID_SIZE then
      viewport.dy *= -1
   end
end

function draw_grid_cells(loc, color)
   local strategy = loc:get_strategy()
   local debug_info = strategy:get_debug_info()
   local cell_size = debug_info.cell_size

   -- draw the cells within the grid area
   for _, cell_info in ipairs(debug_info.cells) do
      local count = cell_info.object_count
      if count > 0 then
         local x, y = GRID_X + cell_info.world_x, GRID_Y + cell_info.world_y
         rrect(x, y, cell_size, cell_size)
         print(count, x + 2, y + 2, color or 1)
      end
   end
end

function draw_locus(loc)
   -- draw the boxes containing each object (optimized for userdata)
   for obj in pairs(loc:query(-64, -64, 384, 384)) do
      local x, y, w, h = loc:get_bbox(obj)
      if x then rrect(GRID_X + x, GRID_Y + y, w, h) end
   end

   -- Draw information panel on the right side
   local info_y = 16
   local line_height = 12

   print("LOCUSTRON SPATIAL HASH", INFO_X, info_y, 11)
   info_y += line_height * 2

   print("Objects in locus: " .. tostr(loc:count()), INFO_X, info_y, 7)
   info_y += line_height

   -- Get strategy statistics for additional info
   local strategy = loc:get_strategy()
   local stats = strategy:get_statistics()

   print("Allocated cells: " .. tostr(stats.cell_count), INFO_X, info_y, 7)
   info_y += line_height * 2

   print("Grid size: " .. tostr(stats.cell_size) .. "px", INFO_X, info_y, 6)
   info_y += line_height

   print("Object size: min " .. OBJECTS_MIN_WIDTH .. ", max " .. OBJECTS_MAX_WIDTH, INFO_X, info_y, 6)
   info_y += line_height

   print("Display area: " .. GRID_SIZE .. "x" .. GRID_SIZE, INFO_X, info_y, 6)
   info_y += line_height

   print("Viewport: " .. viewport.w .. "x" .. viewport.h, INFO_X, info_y, 6)
   info_y += line_height * 2

   -- Performance info
   print("PERFORMANCE", INFO_X, info_y, 11)
   info_y += line_height

   print("CPU: " .. tostr(flr(stat(1) * 10)) .. "%", INFO_X, info_y, 6)
   info_y += line_height

   print("MEM: " .. tostr(flr(stat(3) / 1024)) .. " KB", INFO_X, info_y, 6)
   info_y += line_height

   print("Grid efficiency: " .. tostr(flr(stats.grid_efficiency * 100)) .. "%", INFO_X, info_y, 6)
   info_y += line_height
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
      -- Original visualization
      -- Draw grid border
      -- color(13)
      -- rrect(GRID_X - 1, GRID_Y - 1, GRID_SIZE + 2, GRID_SIZE + 2)

      -- draw locus in magenta
      color(1)
      draw_locus(loc)

      -- draw the viewport (translated to grid coordinates)
      color(10)
      rrect(GRID_X + viewport.x, GRID_Y + viewport.y, viewport.w, viewport.h)

      -- draw the objects that are visible through the viewport with rectfill+color
      -- Use userdata-optimized approach: get bbox coordinates directly from userdata
      clip(GRID_X + viewport.x, GRID_Y + viewport.y, viewport.w, viewport.h)
      for obj in pairs(loc:query(viewport.x, viewport.y, viewport.w, viewport.h)) do
         -- Leverage userdata bbox access for consistent coordinates
         local x, y, w, h = loc:get_bbox(obj)
         if x then rrectfill(GRID_X + x, GRID_Y + y, w, h, 0, obj.col) end
      end
      draw_grid_cells(loc, 13)
      clip()
   end

   -- Always show debug info if enabled
   if show_debug_ui then
      draw_debug_info()
   end
end
