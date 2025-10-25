include("lib/require.lua")
local locus = require("lib/locus_userdata")
local loc
local GRID_SIZE = 256  -- Main grid display area
local GRID_X = 16      -- Grid offset from left
local GRID_Y = 8       -- Grid offset from top
local INFO_X = GRID_X + GRID_SIZE + 16  -- Info panel to the right of grid

local viewport

function rand(low, hi)
   return flr(low + rnd(hi - low))
end

function _init()
   -- viewport. It's a rectangle that moves around, printing the objects it "sees" in color
   viewport = {x = 60, y = 60, w = 120, h = 80, dx = 2, dy = 1}

   loc = locus(32)  -- Optimal grid size for demo objects (5-15px)
   -- add 80 objects to locus (more for the larger display area)
   for _ = 1, 80 do
      local w = rand(5, 15)
      local obj = {
         x = rand(20, 220),  -- Spread across the 256x256 grid area
         y = rand(20, 220),
         w = w,
         h = w,
         av = rnd(),
         r = rnd() * 2,      -- Slightly more movement for the larger space
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

function draw_locus(loc)
   local cl, ct, cr, cb = loc._box2grid(0, 0, GRID_SIZE, GRID_SIZE)
   local size = loc._size
   local row, cell
   
   -- draw the cells within the grid area
   for cy = ct, cb do
      row = loc._rows[cy]
      if row then
         for cx = cl, cr do
            cell = row[cx]
            if cell then
               local x, y = GRID_X + (cx - 1) * size, GRID_Y + (cy - 1) * size
               rrect(x, y, size, size)
               local count = 0
               for _ in pairs(cell) do count += 1 end
               print(count, x + 2, y + 2, 1)  -- Small font for cell counts
            end
         end
      end
   end

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

   local poolsize = 0
   for _ in pairs(loc._pool) do poolsize += 1 end
   print("Objects in pool: "..tostr(poolsize), INFO_X, info_y, 7)
   info_y += line_height
   
   print("Userdata: active", INFO_X, info_y, 10)
   info_y += line_height * 2
   
   print("Grid size: "..tostr(loc._size).."px", INFO_X, info_y, 6)
   info_y += line_height
   
   print("Display area: "..GRID_SIZE.."x"..GRID_SIZE, INFO_X, info_y, 6)
   info_y += line_height
   
   print("Viewport: "..viewport.w.."x"..viewport.h, INFO_X, info_y, 6)
   info_y += line_height * 2
   
   -- Performance info
   print("PERFORMANCE", INFO_X, info_y, 11)
   info_y += line_height
   
   local active_cells = 0
   for _ in pairs(loc._rows) do active_cells += 1 end
   print("Active rows: "..active_cells, INFO_X, info_y, 6)
   info_y += line_height
   
   -- Controls
   info_y += line_height
   print("CONTROLS", INFO_X, info_y, 11)
   info_y += line_height
   print("Objects move automatically", INFO_X, info_y, 6)
   info_y += line_height
   print("Viewport shows culling", INFO_X, info_y, 6)
end

function _draw()
   cls()

   -- Draw grid border
   color(13)
   rrect(GRID_X - 1, GRID_Y - 1, GRID_SIZE + 2, GRID_SIZE + 2)
   
   -- draw locus in magenta
   color(13)
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
   clip()
end