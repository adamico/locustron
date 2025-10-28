--- @diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
-- Locustron: Unified Spatial Partitioning API for Game Development
-- Clean, unified interface for spatial partitioning operations
-- Uses strategy pattern internally for extensibility

local FixedGridStrategy = require("src.strategies.fixed_grid")

--- @class Locustron
--- Main spatial partitioning API for game development
--- @field private _strategy table The active spatial strategy
--- @field private _obj_count number Current object count
local Locustron = {}
Locustron.__index = Locustron

--- Create a new Locustron spatial partitioning instance
--- @param config table|string|number|nil Configuration object, strategy name, or legacy cell size
--- @return Locustron New spatial partitioning instance
function Locustron.create(config)
   local self = setmetatable({}, Locustron)

   -- Handle different configuration formats for backward compatibility
   if type(config) == "number" then
      -- Legacy: Locustron.create(cell_size)
      config = {
         strategy = "fixed_grid",
         config = { cell_size = config },
      }
   elseif type(config) == "string" then
      -- Strategy name only
      config = { strategy = config }
   elseif not config then
      -- Default configuration
      config = { strategy = "fixed_grid" }
   end

   -- Default configuration
   config = config or {}
   config.strategy = config.strategy or "fixed_grid"
   config.config = config.config or {}

   -- Create strategy instance (currently only fixed_grid supported)
   if config.strategy == "fixed_grid" then
      self._strategy = FixedGridStrategy.new(config.config)
   else
      error("unknown strategy: " .. tostring(config.strategy))
   end

   -- Initialize object count
   self._obj_count = 0

   return self
end

--- Add an object to the spatial partitioning system
--- @param obj any The object to add
--- @param x number Object x-coordinate
--- @param y number Object y-coordinate
--- @param w number Object width
--- @param h number Object height
--- @return any The added object
function Locustron:add(obj, x, y, w, h)
   if not obj then error("cannot add nil object") end

   if self._strategy:contains(obj) then error("object already exists in spatial partitioning") end

   -- Validate parameters
   if not (x and y and w and h) then error("add requires x, y, w, h parameters") end

   if w <= 0 or h <= 0 then error("object dimensions must be positive") end

   -- Add to strategy
   self._strategy:add_object(obj, x, y, w, h)
   self._obj_count = self._obj_count + 1

   return obj
end

--- Update an object's position and/or size in the spatial system
--- @param obj any The object to update
--- @param x number New x-coordinate
--- @param y number New y-coordinate
--- @param w number New width (optional)
--- @param h number New height (optional)
--- @return any The updated object
function Locustron:update(obj, x, y, w, h)
   if not obj then error("cannot update nil object") end

   if not self._strategy:contains(obj) then error("object not found in spatial partitioning") end

   -- Validate parameters
   if not (x and y) then error("update requires at least x, y parameters") end

   -- Get current bounding box if dimensions not provided
   if not w or not h then
      local cx, cy, cw, ch = self._strategy:get_bbox(obj)
      w = w or cw
      h = h or ch
   end

   if w <= 0 or h <= 0 then error("object dimensions must be positive") end

   -- Update in strategy
   self._strategy:update_object(obj, x, y, w, h)

   return obj
end

--- Remove an object from the spatial partitioning system
--- @param obj any The object to remove
--- @return any The removed object
function Locustron:remove(obj)
   if not obj then error("cannot remove nil object") end

   if not self._strategy:contains(obj) then error("object not found in spatial partitioning") end

   -- Remove from strategy
   self._strategy:remove_object(obj)
   self._obj_count = self._obj_count - 1

   return obj
end

--- Query objects within a rectangular region
--- @param x number Query region x-coordinate
--- @param y number Query region y-coordinate
--- @param w number Query region width
--- @param h number Query region height
--- @param filter_fn function Optional filter function
--- @return table Hash table of objects {obj = true}
function Locustron:query(x, y, w, h, filter_fn)
   if not x or not y or not w or not h then error("query requires x, y, w, h parameters") end

   -- Validate parameters
   if w <= 0 or h <= 0 then error("query region must have positive width and height") end

   -- Query strategy
   local results = self._strategy:query_region(x, y, w, h, filter_fn)

   return results
end

--- Get the bounding box of an object
--- @param obj any The object
--- @return number, number, number, number x, y, w, h
function Locustron:get_bbox(obj)
   if not obj then error("cannot get bbox of nil object") end

   if not self._strategy:contains(obj) then error("object not found in spatial partitioning") end

   return self._strategy:get_bbox(obj)
end

--- Clear all objects from the spatial partitioning system
function Locustron:clear()
   self._strategy:clear()
   self._obj_count = 0
end

--- Get current object count
--- @return number Number of objects in the system
function Locustron:count() return self._obj_count end

--- Get strategy information
--- @return table Strategy metadata
function Locustron:get_strategy_info()
   return {
      name = self._strategy.strategy_name,
      description = "Fixed grid spatial partitioning",
      object_count = self._obj_count,
      config = self._strategy.config,
   }
end

--- Get the internal strategy instance (for debugging)
--- @return table The strategy instance
function Locustron:get_strategy() return self._strategy end

-- Export the Locustron class
return Locustron
