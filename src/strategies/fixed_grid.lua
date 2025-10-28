-- Fixed Grid Strategy Implementation
-- Vanilla Lua version using doubly linked lists instead of userdata
-- Maintains 100% API compatibility with existing Locustron

local dll = require("src/strategies/doubly_linked_list")
local strategy_interface = require("src/strategies/interface")
local SpatialStrategy = strategy_interface.SpatialStrategy

--- @class FixedGridStrategy : SpatialStrategy
--- @field public cell_size number Grid cell size in pixels
--- @field private grid table Sparse grid of cells {[cy] = {[cx] = SpatialCell}}
--- @field private objects table Object to metadata mapping {[obj] = {nodes = {}, bbox = {}}}
--- @field public object_count number Number of objects in the spatial structure
--- @field strategy_name string Strategy identifier
--- @field config table Strategy configuration
local FixedGridStrategy = {}
FixedGridStrategy.__index = FixedGridStrategy
setmetatable(FixedGridStrategy, { __index = SpatialStrategy })

--- Create a new Fixed Grid strategy
--- @param config table Configuration options
--- @return FixedGridStrategy
function FixedGridStrategy.new(config)
   local self = setmetatable({}, FixedGridStrategy)

   self.cell_size = config.cell_size or 32
   self.grid = {} -- Sparse grid: {[cy] = {[cx] = SpatialCell}}
   self.objects = {} -- Object metadata: {[obj] = {nodes = {{cell, node}}, bbox = {x,y,w,h}}}
   self.object_count = 0
   self.config = config or {}

   -- Strategy identification
   self.strategy_name = "fixed_grid"

   return self
end

-- Private helper methods

--- Convert world coordinates to grid coordinates
--- @param x number World X coordinate
--- @param y number World Y coordinate
--- @return number gx Grid X coordinate
--- @return number gy Grid Y coordinate
function FixedGridStrategy:_world_to_grid(x, y)
   -- Use Lua 5.3+ integer division for performance
   local gx = x // self.cell_size
   local gy = y // self.cell_size
   return gx, gy
end

--- Convert bounding box to grid bounds
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return number gx0, number gy0, number gx1, number gy1 Grid bounds
function FixedGridStrategy:_bbox_to_grid_bounds(x, y, w, h)
   local gx0, gy0 = self:_world_to_grid(x, y)
   local gx1, gy1 = self:_world_to_grid(x + w - 1, y + h - 1)
   return gx0, gy0, gx1, gy1
end

--- Get or create a cell at grid coordinates
--- @param gx number Grid X coordinate
--- @param gy number Grid Y coordinate
--- @return SpatialCell
function FixedGridStrategy:_get_or_create_cell(gx, gy)
   if not self.grid[gy] then self.grid[gy] = {} end

   if not self.grid[gy][gx] then self.grid[gy][gx] = dll.createCell() end

   return self.grid[gy][gx]
end

--- Get an existing cell at grid coordinates
--- @param gx number Grid X coordinate
--- @param gy number Grid Y coordinate
--- @return SpatialCell|nil
function FixedGridStrategy:_get_cell(gx, gy)
   local row = self.grid[gy]
   return row and row[gx]
end

--- Remove empty cells to keep grid sparse
--- @param gx number Grid X coordinate
--- @param gy number Grid Y coordinate
function FixedGridStrategy:_cleanup_empty_cell(gx, gy)
   local cell = self:_get_cell(gx, gy)
   if cell and cell:isEmpty() then
      self.grid[gy][gx] = nil

      -- Clean up empty rows
      local row = self.grid[gy]
      local has_cells = false
      for _ in pairs(row) do
         has_cells = true
         break
      end
      if not has_cells then self.grid[gy] = nil end
   end
end

--- Add object to all cells it overlaps
--- @param obj any Object reference
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return table Array of {cell, node} pairs
function FixedGridStrategy:_add_to_cells(obj, x, y, w, h)
   local gx0, gy0, gx1, gy1 = self:_bbox_to_grid_bounds(x, y, w, h)
   local nodes = {}

   for gy = gy0, gy1 do
      for gx = gx0, gx1 do
         local cell = self:_get_or_create_cell(gx, gy)
         local node = cell:insertEnd(obj, x, y, w, h)
         table.insert(nodes, { cell = cell, node = node })
      end
   end

   return nodes
end

--- Remove object from all cells it was in
--- @param obj any Object reference
function FixedGridStrategy:_remove_from_cells(obj)
   local obj_data = self.objects[obj]
   if not obj_data then return end

   local cleanup_coords = {}

   for _, entry in ipairs(obj_data.nodes) do
      entry.cell:remove(entry.node)

      -- Mark cells for cleanup if they become empty
      -- We need to find the grid coordinates for cleanup
      local bbox = obj_data.bbox
      local gx0, gy0, gx1, gy1 = self:_bbox_to_grid_bounds(bbox.x, bbox.y, bbox.w, bbox.h)
      for gy = gy0, gy1 do
         for gx = gx0, gx1 do
            table.insert(cleanup_coords, { gx, gy })
         end
      end
   end

   -- Clean up empty cells
   for _, coords in ipairs(cleanup_coords) do
      self:_cleanup_empty_cell(coords[1], coords[2])
   end
end

-- Public API implementation (SpatialStrategy interface)

--- Add an object to the spatial structure
--- @param obj any Object reference
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return any The added object
function FixedGridStrategy:add_object(obj, x, y, w, h)
   if self.objects[obj] then error("object already in spatial hash") end

   local nodes = self:_add_to_cells(obj, x, y, w, h)

   self.objects[obj] = {
      nodes = nodes,
      bbox = { x = x, y = y, w = w, h = h },
   }

   self.object_count = self.object_count + 1
   return obj
end

--- Remove an object from the spatial structure
--- @param obj any Object reference
--- @return any The removed object
function FixedGridStrategy:remove_object(obj)
   if not self.objects[obj] then error("unknown object") end

   self:_remove_from_cells(obj)
   self.objects[obj] = nil
   self.object_count = self.object_count - 1

   return obj
end

--- Update an object's position in the spatial structure
--- @param obj any Object reference
--- @param x number New X coordinate
--- @param y number New Y coordinate
--- @param w number New width
--- @param h number New height
--- @return any The updated object
function FixedGridStrategy:update_object(obj, x, y, w, h)
   if not self.objects[obj] then error("unknown object") end

   local old_bbox = self.objects[obj].bbox
   local old_gx0, old_gy0, old_gx1, old_gy1 = self:_bbox_to_grid_bounds(old_bbox.x, old_bbox.y, old_bbox.w, old_bbox.h)
   local new_gx0, new_gy0, new_gx1, new_gy1 = self:_bbox_to_grid_bounds(x, y, w, h)

   -- Only update grid if object moved to different cells
   if old_gx0 ~= new_gx0 or old_gy0 ~= new_gy0 or old_gx1 ~= new_gx1 or old_gy1 ~= new_gy1 then
      self:_remove_from_cells(obj)
      local nodes = self:_add_to_cells(obj, x, y, w, h)
      self.objects[obj].nodes = nodes
   end

   -- Always update the bounding box
   self.objects[obj].bbox = { x = x, y = y, w = w, h = h }

   return obj
end

--- Query objects in a rectangular region
--- @param x number Query region X
--- @param y number Query region Y
--- @param w number Query region width
--- @param h number Query region height
--- @param filter_fn function|nil Optional filter function
--- @return table Hash table of objects {[obj] = true}
function FixedGridStrategy:query_region(x, y, w, h, filter_fn)
   local results = {}
   local visited = {} -- Prevent duplicates since objects can span multiple cells

   local gx0, gy0, gx1, gy1 = self:_bbox_to_grid_bounds(x, y, w, h)

   for gy = gy0, gy1 do
      local row = self.grid[gy]
      if row then
         for gx = gx0, gx1 do
            local cell = row[gx]
            if cell then
               cell:traverseForwards(function(node)
                  local obj = node.data.obj
                  if not visited[obj] then
                     visited[obj] = true
                     if not filter_fn or filter_fn(obj) then results[obj] = true end
                  end
                  return true -- Continue traversal
               end)
            end
         end
      end
   end

   return results
end

--- Get bounding box of an object
--- @param obj any Object reference
--- @return number|nil x, number|nil y, number|nil w, number|nil h
function FixedGridStrategy:get_bbox(obj)
   local metadata = self.objects[obj]
   if metadata then
      local bbox = metadata.bbox
      return bbox.x, bbox.y, bbox.w, bbox.h
   end
   return nil
end

--- Check if an object exists in the spatial structure
--- @param obj any Object reference
--- @return boolean True if object exists
function FixedGridStrategy:contains(obj)
   return self.objects[obj] ~= nil
end

--- Clear all objects from the spatial structure
function FixedGridStrategy:clear()
   self.grid = {}
   self.objects = {}
   self.object_count = 0
end

-- Enhanced query methods

--- Query nearest objects to a point
--- @param x number Point X coordinate
--- @param y number Point Y coordinate
--- @param count number Maximum number of objects to return
--- @param filter_fn function|nil Optional filter function
--- @return table Array of objects sorted by distance
function FixedGridStrategy:query_nearest(x, y, count, filter_fn)
   -- Start with a small search radius and expand until we find enough objects
   local radius = self.cell_size
   local max_radius = self.cell_size * 10 -- Reasonable limit
   local found_objects = {}

   while radius <= max_radius and #found_objects < count do
      local candidates = self:query_region(x - radius, y - radius, radius * 2, radius * 2, filter_fn)

      -- Calculate distances and sort
      found_objects = {}
      for obj in pairs(candidates) do
         local obj_x, obj_y, obj_w, obj_h = self:get_bbox(obj)
         if obj_x then
            -- Distance to object center
            local obj_center_x = obj_x + obj_w / 2
            local obj_center_y = obj_y + obj_h / 2
            local dx = obj_center_x - x
            local dy = obj_center_y - y
            local distance = math.sqrt(dx * dx + dy * dy)

            table.insert(found_objects, { obj = obj, distance = distance })
         end
      end

      -- Sort by distance
      table.sort(found_objects, function(a, b) return a.distance < b.distance end)

      -- Double the radius for next iteration
      radius = radius * 2
   end

   -- Return just the objects, up to the requested count
   local result = {}
   for i = 1, math.min(count, #found_objects) do
      table.insert(result, found_objects[i].obj)
   end

   return result
end

-- Strategy-specific methods and information

--- Get strategy capabilities
--- @return table Capabilities table
function FixedGridStrategy:get_capabilities()
   return {
      supports_unbounded = true, -- Sparse grid can grow infinitely
      supports_hierarchical = false,
      supports_dynamic_resize = false, -- Fixed cell size
      optimal_for = { "uniform_distribution", "medium_worlds", "frequent_updates" },
      memory_characteristics = "sparse_grid",
   }
end

--- Get strategy statistics
--- @return table Statistics table
function FixedGridStrategy:get_statistics()
   -- Count allocated cells
   local cell_count = 0
   for _, row in pairs(self.grid) do
      for _ in pairs(row) do
         cell_count = cell_count + 1
      end
   end

   -- Estimate memory usage (rough calculation)
   local estimated_memory = cell_count * 64 + self.object_count * 128 -- Rough bytes estimate

   return {
      object_count = self.object_count,
      cell_count = cell_count,
      memory_usage = estimated_memory,
      cell_size = self.cell_size,
      grid_efficiency = self.object_count > 0 and (self.object_count / math.max(cell_count, 1)) or 0,
   }
end

--- Get debug information for visualization
--- @return table Debug information
function FixedGridStrategy:get_debug_info()
   local cells_info = {}
   for gy, row in pairs(self.grid) do
      for gx, cell in pairs(row) do
         table.insert(cells_info, {
            grid_x = gx,
            grid_y = gy,
            world_x = gx * self.cell_size,
            world_y = gy * self.cell_size,
            object_count = cell:getCount(),
         })
      end
   end

   return {
      structure_type = "fixed_grid",
      cell_size = self.cell_size,
      total_objects = self.object_count,
      allocated_cells = #cells_info,
      cells = cells_info,
      internal_state = {
         grid_bounds = self:_get_grid_bounds(),
      },
      performance_hints = {
         "Consider larger cell size if objects span many cells",
         "Consider smaller cell size if too many objects per cell",
      },
   }
end

--- Get all objects in the spatial structure for visualization
--- @return table Table of objects {obj = {x, y, w, h}}
function FixedGridStrategy:get_all_objects()
   local result = {}
   for obj, obj_data in pairs(self.objects) do
      local bbox = obj_data.bbox
      result[obj] = {
         x = bbox.x,
         y = bbox.y,
         w = bbox.w,
         h = bbox.h,
         id = obj.id or obj.name -- Try to get an ID for display
      }
   end
   return result
end

--- Get current grid bounds (for debugging)
--- @return table|nil Grid bounds {min_gx, min_gy, max_gx, max_gy}
function FixedGridStrategy:_get_grid_bounds()
   local min_gx, min_gy, max_gx, max_gy = math.huge, math.huge, -math.huge, -math.huge
   local has_cells = false

   for gy, row in pairs(self.grid) do
      for gx, _ in pairs(row) do
         has_cells = true
         min_gx = math.min(min_gx, gx)
         min_gy = math.min(min_gy, gy)
         max_gx = math.max(max_gx, gx)
         max_gy = math.max(max_gy, gy)
      end
   end

   return has_cells and { min_gx, min_gy, max_gx, max_gy } or nil
end

-- Legacy API compatibility (for existing Locustron code)

--- Legacy add method (alias for add_object)
function FixedGridStrategy:add(obj, x, y, w, h) return self:add_object(obj, x, y, w, h) end

--- Legacy del method (alias for remove_object)
function FixedGridStrategy:del(obj) return self:remove_object(obj) end

--- Legacy update method (alias for update_object)
function FixedGridStrategy:update(obj, x, y, w, h) return self:update_object(obj, x, y, w, h) end

--- Legacy query method (alias for query_region)
function FixedGridStrategy:query(x, y, w, h, filter_fn) return self:query_region(x, y, w, h, filter_fn) end

return FixedGridStrategy
