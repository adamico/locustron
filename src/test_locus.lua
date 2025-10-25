include("lib/require.lua")
local locus = require("lib/locus_userdata")
local loc
local VIEWING_W = 128
local VIEWING_H = 128

local viewport

function rand(low, hi)
   return flr(low + rnd(hi - low))
end

function _init()
   -- viewport. It's a rectangle that moves around, printing the objects it "sees" in color
   viewport = {x = 40, y = 40, w = 80, h = 64, dx = 2, dy = 1}

   loc = locus(32)  -- Optimal grid size for demo objects (5-15px) - better than 128!
   -- add 50 objects to locus
   for _ = 1, 50 do
      local w = rand(5, 15)
      local obj = {
         x = rand(30, 110),
         y = rand(30, 110),
         w = w,
         h = w,
         av = rnd(),
         r = rnd(),
         col = rand(6, 15)
      }
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   end
end

function _update()
   -- move all the objects in locus
   -- we use a bigger box than just the screen so that we also update the objects that
   -- are outside of the visible screen
   for obj in pairs(loc.query(-128, -128, 256, 256)) do
      obj.x += sin(obj.av * t()) * obj.r
      obj.y += cos(obj.av * t()) * obj.r
      -- Use userdata-optimized update which leverages get_bbox internally
      loc.update(obj, obj.x, obj.y, obj.w, obj.h)
   end

   -- update the viewport
   viewport.x += viewport.dx
   viewport.y += viewport.dy
   -- make the viewport bounce when it touches the screen borders
   if viewport.x < 0 or viewport.x + viewport.w > VIEWING_W then
      viewport.dx *= -1
   end
   if viewport.y < 0 or viewport.y + viewport.h > VIEWING_H then
      viewport.dy *= -1
   end
end

function draw_locus(loc)
   local cl, ct, cr, cb = loc._box2grid(0, 0, 128, 128)
   local size = loc._size
   local row, cell
   -- draw the cells
   for cy = ct, cb do
      row = loc._rows[cy]
      if row then
         for cx = cl, cr do
            cell = row[cx]
            if cell then
               local x, y = (cx - 1) * size, (cy - 1) * size
               rrect(x, y, size, size)
               local count = 0
               for _ in pairs(cell) do count += 1 end
               print(count, x + 2, y + 2)
            end
         end
      end
   end

   -- draw the boxes containing each object (optimized for userdata)
   for obj in pairs(loc.query(-128, -128, 256, 256)) do
      local x, y, w, h = loc.get_bbox(obj)
      if x then
         rrect(x, y, w, h)
      end
   end
   
   -- print how many objects are in locus (use userdata-optimized count)
   print("Objects in locus: "..tostr(loc._obj_count()), VIEWING_W + 8, 8)

   -- print the pool size
   local poolsize = 0
   for _ in pairs(loc._pool) do poolsize += 1 end
   print("Objects in pool: "..tostr(poolsize), VIEWING_W + 8, 18)
   
   -- show userdata is always active in Picotron
   print("Userdata: active", VIEWING_W + 8, 28)
end

function _draw()
   cls()

   color(13)
   -- draw locus in magenta
   draw_locus(loc)

   -- draw the viewport
   color(10)
   rrect(viewport.x, viewport.y, viewport.w, viewport.h)

   -- draw the objects that are visible through the viewport with rectfill+color
   -- Use userdata-optimized approach: get bbox coordinates directly from userdata
   clip(viewport.x, viewport.y, viewport.w, viewport.h)
   for obj in pairs(loc.query(viewport.x, viewport.y, viewport.w, viewport.h)) do
      -- Leverage userdata bbox access for consistent coordinates
      local x, y, w, h = loc.get_bbox(obj)
      if x then
         rrectfill(x, y, w, h, 0, obj.col)
      end
   end
   clip()
end