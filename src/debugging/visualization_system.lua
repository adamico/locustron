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
local deli = deli and deli or table.remove
local flr = flr and flr or math.floor

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

   -- UI rendering moved to main.lua
end

--- Render fixed grid structure
-- @param strategy Fixed grid strategy instance
function VisualizationSystem:render_fixed_grid(strategy)
   local debug_info = strategy:get_debug_info()
   local cell_size = debug_info.cell_size

   -- Calculate visible grid range
   local start_gx = flr(self.viewport.x / cell_size)
   local end_gx = flr((self.viewport.x + self.viewport.w / self.viewport.scale) / cell_size) + 1
   local start_gy = flr(self.viewport.y / cell_size)
   local end_gy = flr((self.viewport.y + self.viewport.h / self.viewport.scale) / cell_size) + 1

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

   -- Draw occupied cells with object counts using debug info
   for _, cell_info in ipairs(debug_info.cells) do
      if cell_info.object_count > 0 then
         local screen_x = self:world_to_screen_x(cell_info.world_x)
         local screen_y = self:world_to_screen_y(cell_info.world_y)
         local screen_w = cell_size * self.viewport.scale
         local screen_h = cell_size * self.viewport.scale

         -- Highlight occupied cells
         self:draw_rect(screen_x, screen_y, screen_w, screen_h, 0, self.colors.grid_lines, true)

         -- Draw object count
         if self.viewport.scale > 0.5 then
            local count_str = tostring(cell_info.object_count)
            self:draw_text(count_str, screen_x + 2, screen_y + 2, self.colors.text)
         end
      end
   end
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
   self:draw_text("Performance heatmap not yet implemented", 280, 220, self.colors.performance_hot)
end

--- Render user interface overlay
function VisualizationSystem:render_ui()
   -- UI rendering moved to main.lua draw_visualization_ui()
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
   -- Input handling moved to main.lua _update()
end

--- Reset viewport to default
function VisualizationSystem:reset_viewport()
   self.viewport.x = 0
   self.viewport.y = 0
   self.viewport.scale = 1.0
end

return VisualizationSystem
