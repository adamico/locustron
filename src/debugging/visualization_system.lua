--- @class VisualizationSystem
--- Picotron Visualization System for Locustron
--- Provides real-time rendering of spatial structures, objects, and query regions
--- Optimized for Picotron runtime with efficient rendering and debugging tools
--- @field viewport table Viewport configuration {x, y, w, h, scale}
--- @field colors table Color palette for different elements
--- @field show_structure boolean Whether to show spatial structure
--- @field show_objects boolean Whether to show objects
--- @field show_queries boolean Whether to show query regions
--- @field show_performance boolean Whether to show performance data
--- @field query_history table[] History of recent queries
--- @field performance_data table Performance profiling data
--- @field current_strategy table Currently rendered strategy
--- @field current_strategy_name string Name of current strategy
local class = require("middleclass")
local VisualizationSystem = class("VisualizationSystem")

local time = os and os.time or time
local add = add and add or table.insert
local min = min and min or math.min
local max = max and max or math.max
local deli = deli and deli or table.remove

--- Create a new visualization system instance
--- @param config table Configuration table with colors and viewport settings
function VisualizationSystem:initialize(config)
   config = config or {}

   -- Viewport configuration
   self.viewport = config.viewport or {x = 0, y = 0, w = 400, h = 300, scale = 1.0}

   -- Default colors optimized for Picotron
   self.colors = config.colors or {
      grid_lines = 7,        -- Light gray
      quadtree_bounds = 6,   -- Dark gray
      objects = 8,           -- Red
      queries = 11,          -- Light blue
      performance_hot = 8,   -- Red
      performance_cold = 12, -- Light green
      text = 7,              -- White
      background = 0         -- Black
   }

   -- Rendering flags
   self.show_structure = true
   self.show_objects = true
   self.show_queries = true
   self.show_performance = false

   -- Data storage
   self.query_history = {}
   self.performance_data = {}
   self.current_strategy = nil
   self.current_strategy_name = ""
end --- Set the viewport parameters

--- @param x number Viewport x offset
--- @param y number Viewport y offset
--- @param w number Viewport width
--- @param h number Viewport height
--- @param scale number Zoom scale factor
function VisualizationSystem:set_viewport(x, y, w, h, scale)
   self.viewport.x = x or self.viewport.x
   self.viewport.y = y or self.viewport.y
   self.viewport.w = w or self.viewport.w
   self.viewport.h = h or self.viewport.h
   self.viewport.scale = scale or self.viewport.scale
end

--- Convert world coordinates to screen coordinates
--- @param world_x number World x coordinate
--- @return number Screen x coordinate
function VisualizationSystem:world_to_screen_x(world_x)
   return (world_x - self.viewport.x) * self.viewport.scale
end

--- Convert world coordinates to screen coordinates
--- @param world_y number World y coordinate
--- @return number Screen y coordinate
function VisualizationSystem:world_to_screen_y(world_y)
   return (world_y - self.viewport.y) * self.viewport.scale
end

--- Convert screen coordinates to world coordinates
-- @param screen_x Screen x coordinate
-- @return World x coordinate
function VisualizationSystem:screen_to_world_x(screen_x)
   return screen_x / self.viewport.scale + self.viewport.x
end

--- Convert screen coordinates to world coordinates
-- @param screen_y Screen y coordinate
-- @return World y coordinate
function VisualizationSystem:screen_to_world_y(screen_y)
   return screen_y / self.viewport.scale + self.viewport.y
end

--- Clear the screen with background color
function VisualizationSystem:clear_screen()
   rrectfill(0, 0, self.viewport.w, self.viewport.h, 0, self.colors.background)
end

--- Draw a line (Picotron optimized)
--- @param x1 number Start x
--- @param y1 number Start y
--- @param x2 number End x
--- @param y2 number End y
--- @param color number Color index
function VisualizationSystem:draw_line(x1, y1, x2, y2, color)
   line(x1, y1, x2, y2, color)
end

--- Draw a rectangle (Picotron optimized)
--- @param x number X position
--- @param y number Y position
--- @param w number Width
--- @param h number Height
--- @param color number Color index
--- @param radius number Corner radius
--- @param filled boolean Whether to fill the rectangle
function VisualizationSystem:draw_rect(x, y, w, h, radius, color, filled)
   if filled then
      rrectfill(x, y, w, h, radius, color)
   else
      rrect(x, y, w, h, radius, color)
   end
end

--- Draw text (Picotron optimized)
--- @param text string Text to draw
--- @param x number X position
--- @param y number Y position
--- @param color number Color index
function VisualizationSystem:draw_text(text, x, y, color)
   print(text, x, y, color)
end

--- Render the current strategy
--- @param strategy table The spatial strategy to render
--- @param strategy_name string Name of the strategy (fixed_grid, quadtree, etc.)
function VisualizationSystem:render_strategy(strategy, strategy_name)
   self.current_strategy = strategy
   self.current_strategy_name = strategy_name

   self:clear_screen()

   if self.show_structure then
      if strategy_name == "fixed_grid" then
         self:render_fixed_grid(strategy)
      elseif strategy_name == "quadtree" then
         self:render_quadtree(strategy)
      elseif strategy_name == "hash_grid" then
         self:render_hash_grid(strategy)
      elseif strategy_name == "bsp_tree" then
         self:render_bsp_tree(strategy)
      elseif strategy_name == "bvh" then
         self:render_bvh(strategy)
      end
   end

   if self.show_objects then
      self:render_objects(strategy)
   end

   if self.show_queries then
      self:render_query_history()
   end

   if self.show_performance then
      self:render_performance_heatmap(strategy)
   end

   self:render_ui()
end

--- Render fixed grid structure
-- @param strategy Fixed grid strategy instance
function VisualizationSystem:render_fixed_grid(strategy)
   local cell_size = strategy.cell_size or 32

   -- Calculate visible grid range
   local start_gx = math.floor(self.viewport.x / cell_size)
   local end_gx = math.floor((self.viewport.x + self.viewport.w / self.viewport.scale) / cell_size) + 1
   local start_gy = math.floor(self.viewport.y / cell_size)
   local end_gy = math.floor((self.viewport.y + self.viewport.h / self.viewport.scale) / cell_size) + 1

   -- Draw grid lines
   for gx = start_gx, end_gx do
      local world_x = gx * cell_size
      local screen_x = self:world_to_screen_x(world_x)
      if screen_x >= 0 and screen_x < self.viewport.w then
         self:draw_line(screen_x, 0, screen_x, self.viewport.h, self.colors.grid_lines)
      end
   end

   for gy = start_gy, end_gy do
      local world_y = gy * cell_size
      local screen_y = self:world_to_screen_y(world_y)
      if screen_y >= 0 and screen_y < self.viewport.h then
         self:draw_line(0, screen_y, self.viewport.w, screen_y, self.colors.grid_lines)
      end
   end

   -- Draw occupied cells with object counts
   if strategy.grid then
      for gy, row in pairs(strategy.grid) do
         if gy >= start_gy and gy <= end_gy then
            for gx, cell in pairs(row) do
               if gx >= start_gx and gx <= end_gx and cell.count > 0 then
                  local world_x = gx * cell_size
                  local world_y = gy * cell_size
                  local screen_x = self:world_to_screen_x(world_x)
                  local screen_y = self:world_to_screen_y(world_y)
                  local screen_w = cell_size * self.viewport.scale
                  local screen_h = cell_size * self.viewport.scale

                  -- Highlight occupied cells
                  self:draw_rect(screen_x, screen_y, screen_w, screen_h, 0, self.colors.grid_lines, true)

                  -- Draw object count
                  if self.viewport.scale > 0.5 then
                     local count_str = tostring(cell.count)
                     self:draw_text(count_str, screen_x + 2, screen_y + 2, self.colors.text)
                  end
               end
            end
         end
      end
   end
end

--- Render quadtree structure
-- @param strategy Quadtree strategy instance
function VisualizationSystem:render_quadtree(strategy)
   if strategy.root then
      self:render_quadtree_node(strategy.root, 0)
   end
end

--- Render a quadtree node recursively
-- @param node Quadtree node to render
-- @param depth Current depth for color coding
function VisualizationSystem:render_quadtree_node(node, depth)
   local screen_x = self:world_to_screen_x(node.x)
   local screen_y = self:world_to_screen_y(node.y)
   local screen_w = node.w * self.viewport.scale
   local screen_h = node.h * self.viewport.scale

   -- Draw node bounds with depth-based coloring
   local color = (depth % 4) + 4 -- Cycle through colors based on depth
   self:draw_rect(screen_x, screen_y, screen_w, screen_h, 0, color, false)

   -- Draw object count for leaf nodes
   if node.is_leaf and node.objects and #node.objects > 0 then
      if self.viewport.scale > 0.3 then
         local count_str = tostring(#node.objects)
         self:draw_text(count_str, screen_x + 2, screen_y + 2, self.colors.text)
      end
   end

   -- Recursively draw children
   if not node.is_leaf and node.children then
      for _, child in ipairs(node.children) do
         self:render_quadtree_node(child, depth + 1)
      end
   end
end

--- Render hash grid structure
-- @param strategy Hash grid strategy instance
function VisualizationSystem:render_hash_grid(strategy)
   -- Render hash grid by showing occupied cells
   if strategy.cells then
      for hash, bucket in pairs(strategy.cells) do
         for _, cell in ipairs(bucket) do
            if cell.count > 0 then
               local world_x = cell.gx * (strategy.cell_size or 32)
               local world_y = cell.gy * (strategy.cell_size or 32)
               local screen_x = self:world_to_screen_x(world_x)
               local screen_y = self:world_to_screen_y(world_y)
               local screen_w = (strategy.cell_size or 32) * self.viewport.scale
               local screen_h = (strategy.cell_size or 32) * self.viewport.scale

               -- Color based on hash to show distribution
               local color = (hash % 8) + 8
               self:draw_rect(screen_x, screen_y, screen_w, screen_h, 0, color, true)

               -- Draw coordinates and count if zoomed in
               if self.viewport.scale > 1.0 then
                  local label = string.format("(%d,%d):%d", cell.gx, cell.gy, cell.count)
                  self:draw_text(label, screen_x + 2, screen_y + 2, self.colors.text)
               end
            end
         end
      end
   end
end

--- Render BSP tree structure (placeholder for future implementation)
-- @param strategy BSP tree strategy instance
function VisualizationSystem:render_bsp_tree(strategy)
   -- Placeholder - BSP tree rendering would go here
   self:draw_text("BSP Tree visualization not yet implemented", 10, 10, self.colors.text)
end

--- Render BVH structure (placeholder for future implementation)
-- @param strategy BVH strategy instance
function VisualizationSystem:render_bvh(strategy)
   -- Placeholder - BVH rendering would go here
   self:draw_text("BVH visualization not yet implemented", 10, 30, self.colors.text)
end

--- Render objects in the spatial structure
-- @param strategy Strategy containing objects to render
function VisualizationSystem:render_objects(strategy)
   if not strategy.objects then return end

   for obj, obj_data in pairs(strategy.objects) do
      local screen_x = self:world_to_screen_x(obj_data.x)
      local screen_y = self:world_to_screen_y(obj_data.y)
      local screen_w = obj_data.w * self.viewport.scale
      local screen_h = obj_data.h * self.viewport.scale

      -- Draw object bounding box
      self:draw_rect(screen_x, screen_y, screen_w, screen_h, 0, self.colors.objects, true)

      -- Draw object ID if zoom level is high enough
      if self.viewport.scale > 2.0 and obj_data.id then
         self:draw_text(tostring(obj_data.id), screen_x + 1, screen_y + 1, self.colors.text)
      end
   end
end

--- Render query history
function VisualizationSystem:render_query_history()
   for i, query in ipairs(self.query_history) do
      if i > 10 then break end -- Limit to last 10 queries

      local screen_x = self:world_to_screen_x(query.x)
      local screen_y = self:world_to_screen_y(query.y)
      local screen_w = query.w * self.viewport.scale
      local screen_h = query.h * self.viewport.scale

      -- Draw query region
      self:draw_rect(screen_x, screen_y, screen_w, screen_h, 0, self.colors.queries, false)

      -- Draw result count if available
      if query.result_count and self.viewport.scale > 0.5 then
         self:draw_text(tostring(query.result_count), screen_x + 2, screen_y + 2, self.colors.queries)
      end
   end
end

--- Render performance heatmap (placeholder)
-- @param strategy Strategy to analyze for performance
function VisualizationSystem:render_performance_heatmap(strategy)
   -- Placeholder - performance heatmap would show slow regions
   self:draw_text("Performance heatmap not yet implemented", 10, 50, self.colors.performance_hot)
end

--- Render user interface overlay
function VisualizationSystem:render_ui()
   -- Strategy info
   self:draw_text(string.format("Strategy: %s", self.current_strategy_name), 10, self.viewport.h - 20, self.colors.text)

   -- Object count
   local obj_count = 0
   if self.current_strategy and self.current_strategy.objects then
      for _ in pairs(self.current_strategy.objects) do
         obj_count = obj_count + 1
      end
   end
   self:draw_text(string.format("Objects: %d", obj_count), 10, self.viewport.h - 10, self.colors.text)

   -- Controls hint
   self:draw_text("G:toggle grid O:objects Q:queries P:perf +/-:zoom Arrows:pan", 10, 10, self.colors.text)
end

--- Add a query to the history for visualization
--- @param x number Query region x
--- @param y number Query region y
--- @param w number Query region width
--- @param h number Query region height
--- @param result_count number Number of results (optional)
function VisualizationSystem:add_query(x, y, w, h, result_count)
   add(self.query_history, {
      x = x,
      y = y,
      w = w,
      h = h,
      result_count = result_count,
      timestamp = time()
   })

   -- Keep only last 50 queries
   if #self.query_history > 50 then
      deli(self.query_history, 1)
   end
end

--- Handle keyboard input for debugging controls
function VisualizationSystem:handle_input()
   -- Toggle structure visibility
   if keyp("g", true) then -- G key
      self.show_structure = not self.show_structure
   end

   -- Toggle object visibility
   if keyp("o", true) then -- O key
      self.show_objects = not self.show_objects
   end

   -- Toggle query visibility
   if keyp("q", true) then -- Q key
      self.show_queries = not self.show_queries
   end

   -- Toggle performance visibility
   if keyp("p", true) then -- P key
      self.show_performance = not self.show_performance
   end

   -- Zoom controls
   if keyp("+", true) then     -- + key
      self:zoom_in()
   elseif keyp("-", true) then -- - key
      self:zoom_out()
   end

   -- Pan controls
   local pan_speed = 32 / self.viewport.scale
   if btnp(2) then     -- Up arrow
      self:pan(0, -pan_speed)
   elseif btnp(3) then -- Down arrow
      self:pan(0, pan_speed)
   elseif btnp(0) then -- Left arrow
      self:pan(-pan_speed, 0)
   elseif btnp(1) then -- Right arrow
      self:pan(pan_speed, 0)
   end
end

--- Zoom in
function VisualizationSystem:zoom_in()
   self.viewport.scale = min(self.viewport.scale * 1.2, 10.0)
end

--- Zoom out
function VisualizationSystem:zoom_out()
   self.viewport.scale = max(self.viewport.scale / 1.2, 0.1)
end

--- Pan the viewport
--- @param dx number Delta x
--- @param dy number Delta y
function VisualizationSystem:pan(dx, dy)
   self.viewport.x = self.viewport.x + dx
   self.viewport.y = self.viewport.y + dy
end

--- Reset viewport to default
function VisualizationSystem:reset_viewport()
   self.viewport.x = 0
   self.viewport.y = 0
   self.viewport.scale = 1.0
end

return VisualizationSystem
