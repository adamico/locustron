--- Viewport Culling System for Locustron
-- Efficient rendering optimization using spatial queries
-- Provides viewport-based culling for game engines

local class = require("lib.middleclass")

--- @class ViewportCulling
--- Efficient rendering optimization using spatial queries
--- @field spatial table The Locustron spatial partitioning instance
--- @field viewport table Viewport configuration {x, y, w, h}
--- @field cull_margin number Extra margin around viewport for culling
--- @field stats table Performance statistics for monitoring
local ViewportCulling = class("ViewportCulling")

--- Create a new viewport culling system
--- @param locustron_instance table The Locustron spatial partitioning instance
--- @param viewport_config table|nil Viewport configuration {x, y, w, h, cull_margin}
function ViewportCulling:initialize(locustron_instance, viewport_config)
   self.spatial = locustron_instance
   self.viewport = viewport_config or { x = 0, y = 0, w = 400, h = 300 }
   self.cull_margin = viewport_config and viewport_config.cull_margin or 32 -- Extra margin for safety

   -- Statistics for performance monitoring
   self.stats = {
      total_objects = 0,
      visible_objects = 0,
      culled_objects = 0,
      cull_ratio = 0,
      query_count = 0,
      average_query_time = 0,
   }
end

--- Get visible objects within the current viewport
--- @param filter_fn function|nil Optional filter function for additional culling
--- @return table Hash table of visible objects {obj = true}
function ViewportCulling:get_visible_objects(filter_fn)
   local vx, vy, vw, vh = self.viewport.x, self.viewport.y, self.viewport.w, self.viewport.h

   -- Add margin to viewport for smoother scrolling and to account for object sizes
   local query_x = vx - self.cull_margin
   local query_y = vy - self.cull_margin
   local query_w = vw + self.cull_margin * 2
   local query_h = vh + self.cull_margin * 2

   -- Query spatial system for objects in the expanded viewport
   local visible = self.spatial:query(query_x, query_y, query_w, query_h, filter_fn)

   -- Update statistics
   self.stats.total_objects = self.spatial:count()
   self.stats.visible_objects = self:count_table(visible)
   self.stats.culled_objects = self.stats.total_objects - self.stats.visible_objects
   self.stats.cull_ratio = self.stats.total_objects > 0 and (self.stats.visible_objects / self.stats.total_objects) or 0
   self.stats.query_count = self.stats.query_count + 1

   return visible
end

--- Update the viewport position and size
--- @param x number New viewport x-coordinate
--- @param y number New viewport y-coordinate
--- @param w number|nil New viewport width (optional)
--- @param h number|nil New viewport height (optional)
function ViewportCulling:update_viewport(x, y, w, h)
   self.viewport.x = x
   self.viewport.y = y
   if w then self.viewport.w = w end
   if h then self.viewport.h = h end
end

--- Set the cull margin for viewport expansion
--- @param margin number Extra margin around viewport for culling (pixels)
function ViewportCulling:set_cull_margin(margin) self.cull_margin = margin end

--- Get current viewport configuration
--- @return number x Viewport x-coordinate
--- @return number y Viewport y-coordinate
--- @return number w Viewport width
--- @return number h Viewport height
function ViewportCulling:get_viewport() return self.viewport.x, self.viewport.y, self.viewport.w, self.viewport.h end

--- Get culling statistics
--- @return table Statistics table
function ViewportCulling:get_stats()
   return {
      total_objects = self.stats.total_objects,
      visible_objects = self.stats.visible_objects,
      culled_objects = self.stats.culled_objects,
      cull_ratio = self.stats.cull_ratio,
      query_count = self.stats.query_count,
      cull_margin = self.cull_margin,
   }
end

--- Reset statistics counters
function ViewportCulling:reset_stats()
   self.stats.query_count = 0
   self.stats.average_query_time = 0
end

--- Check if an object is potentially visible in the current viewport
--- This is a quick bounds check before more expensive visibility tests
--- @param obj any Object to check
--- @return boolean True if object bounds intersect viewport, false otherwise
function ViewportCulling:is_potentially_visible(obj)
   local obj_x, obj_y, obj_w, obj_h = self.spatial:get_bbox(obj)
   if not obj_x then return false end

   local vx, vy, vw, vh = self.viewport.x, self.viewport.y, self.viewport.w, self.viewport.h

   -- Check if object bounds intersect viewport bounds
   return self:rectangles_intersect(obj_x, obj_y, obj_w, obj_h, vx, vy, vw, vh)
end

--- Check if two rectangles intersect
--- @param x1 number First rectangle x
--- @param y1 number First rectangle y
--- @param w1 number First rectangle width
--- @param h1 number First rectangle height
--- @param x2 number Second rectangle x
--- @param y2 number Second rectangle y
--- @param w2 number Second rectangle width
--- @param h2 number Second rectangle height
--- @return boolean True if rectangles intersect
function ViewportCulling:rectangles_intersect(x1, y1, w1, h1, x2, y2, w2, h2)
   if x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2 then
      return true
   else
      return false
   end
end

--- Get objects that are guaranteed to be off-screen
--- Useful for cleanup or LOD decisions
--- @param margin number|nil Additional margin around viewport (default: cull_margin)
--- @return table Hash table of off-screen objects {obj = true}
function ViewportCulling:get_offscreen_objects(margin)
   margin = margin or self.cull_margin

   local vx, vy, vw, vh = self.viewport.x, self.viewport.y, self.viewport.w, self.viewport.h
   local expanded_x = vx - margin
   local expanded_y = vy - margin
   local expanded_w = vw + margin * 2
   local expanded_h = vh + margin * 2

   -- Get all objects
   local all_objects = {}
   -- Note: This is a simplified approach. In a real implementation,
   -- you might want to iterate through all objects in the spatial system
   -- For now, we'll query a large area and assume it covers all objects
   local large_area = self.spatial:query(-10000, -10000, 20000, 20000)

   local offscreen = {}
   for obj in pairs(large_area) do
      local obj_x, obj_y, obj_w, obj_h = self.spatial:get_bbox(obj)
      if
         obj_x
         and not (
            obj_x < expanded_x + expanded_w
            and obj_x + obj_w > expanded_x
            and obj_y < expanded_y + expanded_h
            and obj_y + obj_h > expanded_y
         )
      then
         offscreen[obj] = true
      end
   end

   return offscreen
end

--- Utility function to count items in a table
--- @param t table Table to count
--- @return number Number of items
function ViewportCulling:count_table(t)
   local count = 0
   for _ in pairs(t) do
      count = count + 1
   end
   return count
end

--- Create a viewport culling instance with default settings
--- @param spatial table Locustron instance
--- @return ViewportCulling New instance with sensible defaults
function ViewportCulling.create(spatial)
   return ViewportCulling:new(spatial, {
      x = 0,
      y = 0,
      w = 400,
      h = 300, -- Standard viewport
      cull_margin = 64, -- Generous margin for most games
   })
end

return ViewportCulling
