--[[pod_format="raw",created="2025-10-26 18:13:48",modified="2025-10-26 18:13:48",revision=0]]
include("lib/require.lua")
local locustron = require("lib/locustron")
local loc
local GRID_SIZE = 256                  -- Main grid display area
local GRID_X = 16                      -- Grid offset from left
local GRID_Y = 8                       -- Grid offset from top
local INFO_X = GRID_X + GRID_SIZE + 16 -- Info panel to the right of grid

local OBJECTS_MIN_WIDTH = 10
local OBJECTS_MAX_WIDTH = 32
local MAX_OBJECTS = 100
local viewport

function rand(low, hi)
   return flr(low + rnd(hi - low))
end

function _init()
   -- viewport. It's a rectangle that moves around, printing the objects it "sees" in color
   viewport = {x = 60, y = 60, w = 128, h = 128, dx = 2, dy = 1}

   loc = locustron(32)
   for _ = 1, MAX_OBJECTS do
      local w = rand(OBJECTS_MIN_WIDTH, OBJECTS_MAX_WIDTH)
      local obj = {
         x = rand(20, 220), -- Spread across the 256x256 grid area
         y = rand(20, 220),
         w = w,
         h = w,
         av = rnd(),
         r = rnd() * 2, -- Slightly more movement for the larger space
         col = rand(6, 15)
      }
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   end
end

function _update()
   -- move all the objects in locus
   -- we use a bigger box than just the grid so that we also update the objects that
   -- are outside of the visible grid area
   for obj in pairs(loc.query(-64, -64, 384, 384)) do
      obj.x += sin(obj.av * t()) * obj.r
      obj.y += cos(obj.av * t()) * obj.r
      -- Use userdata-optimized update which leverages get_bbox internally
      loc.update(obj, obj.x, obj.y, obj.w, obj.h)
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
   local cl, ct, cr, cb = loc._box2grid(0, 0, GRID_SIZE, GRID_SIZE)
   local size = loc._size

   -- draw the cells within the grid area
   for cy = ct, cb do
      for cx = cl, cr do
         local count = loc._get_cell_count(cx, cy)
         if count > 0 then
            local x, y = GRID_X + cx * size, GRID_Y + cy * size
            rrect(x, y, size, size)
            print(count, x + 2, y + 2, color or 1)
         end
      end
   end
end

function draw_locus(loc)
   -- draw the boxes containing each object (optimized for userdata)
   for obj in pairs(loc.query(-64, -64, 384, 384)) do
      local x, y, w, h = loc.get_bbox(obj)
      if x then
         rrect(GRID_X + x, GRID_Y + y, w, h)
      end
   end

   -- Draw information panel on the right side
   local info_y = 16
   local line_height = 12

   print("LOCUSTRON SPATIAL HASH", INFO_X, info_y, 11)
   info_y += line_height * 2

   print("Objects in locus: "..tostr(loc._obj_count()), INFO_X, info_y, 7)
   info_y += line_height

   print("Query pool size: "..tostr(loc._pool()), INFO_X, info_y, 7)
   info_y += line_height * 2

   print("Grid size: "..tostr(loc._size).."px", INFO_X, info_y, 6)
   info_y += line_height

   print("Object size: min "..OBJECTS_MIN_WIDTH..", max "..OBJECTS_MAX_WIDTH, INFO_X, info_y, 6)
   info_y += line_height

   print("Display area: "..GRID_SIZE.."x"..GRID_SIZE, INFO_X, info_y, 6)
   info_y += line_height

   print("Viewport: "..viewport.w.."x"..viewport.h, INFO_X, info_y, 6)
   info_y += line_height * 2

   -- Performance info
   print("PERFORMANCE", INFO_X, info_y, 11)
   info_y += line_height

   print("CPU: "..tostr(flr(stat(1) * 10)).."%", INFO_X, info_y, 6)
   info_y += line_height

   print("MEM: "..tostr(flr(stat(3) / 1024)).." KB", INFO_X, info_y, 6)
   info_y += line_height

   print("Cell pool size: "..tostr(loc._cell_pool_size()), INFO_X, info_y, 6)
   info_y += line_height
end

function _draw()
   cls()

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
   for obj in pairs(loc.query(viewport.x, viewport.y, viewport.w, viewport.h)) do
      -- Leverage userdata bbox access for consistent coordinates
      local x, y, w, h = loc.get_bbox(obj)
      if x then
         rrectfill(GRID_X + x, GRID_Y + y, w, h, 0, obj.col)
      end
   end
   draw_grid_cells(loc, 13)
   clip()
end
