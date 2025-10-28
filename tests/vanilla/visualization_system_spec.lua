--- Busted tests for VisualizationSystem
--- Tests the Picotron visualization system functionality

local class = require("middleclass")

describe("VisualizationSystem", function()
   local VisualizationSystem

   before_each(function()
      -- Load the module fresh for each test
      package.loaded["debugging.visualization_system"] = nil
      VisualizationSystem = require("debugging.visualization_system")
   end)

   describe("Class creation", function()
      it("should initialize with default config", function()
         local vis = VisualizationSystem:new()

         -- Check default viewport
         assert.are.equal(0, vis.viewport.x)
         assert.are.equal(0, vis.viewport.y)
         assert.are.equal(400, vis.viewport.w)
         assert.are.equal(300, vis.viewport.h)
         assert.are.equal(1.0, vis.viewport.scale)

         -- Check default colors
         assert.are.equal(7, vis.colors.grid_lines)
         assert.are.equal(8, vis.colors.objects)
         assert.are.equal(7, vis.colors.text)

         -- Check default flags
         assert.is_true(vis.show_structure)
         assert.is_true(vis.show_objects)
         assert.is_true(vis.show_queries)
         assert.is_false(vis.show_performance)
      end)

      it("should accept custom config", function()
         local config = {
            viewport = {x = 100, y = 200, w = 800, h = 600, scale = 2.0},
            colors = {grid_lines = 1, objects = 2, text = 3}
         }
         local vis = VisualizationSystem:new(config)

         assert.are.equal(100, vis.viewport.x)
         assert.are.equal(200, vis.viewport.y)
         assert.are.equal(800, vis.viewport.w)
         assert.are.equal(600, vis.viewport.h)
         assert.are.equal(2.0, vis.viewport.scale)

         assert.are.equal(1, vis.colors.grid_lines)
         assert.are.equal(2, vis.colors.objects)
         assert.are.equal(3, vis.colors.text)
      end)
   end)

   describe("Viewport operations", function()
      local vis

      before_each(function()
         vis = VisualizationSystem:new()
      end)

      it("should set viewport parameters", function()
         vis:set_viewport(10, 20, 800, 600, 2.0)
         assert.are.equal(10, vis.viewport.x)
         assert.are.equal(20, vis.viewport.y)
         assert.are.equal(800, vis.viewport.w)
         assert.are.equal(600, vis.viewport.h)
         assert.are.equal(2.0, vis.viewport.scale)
      end)

      it("should convert world to screen coordinates", function()
         vis:set_viewport(100, 50, 400, 300, 2.0)

         -- World point (150, 100) should be at screen (100, 100)
         -- Because: (150 - 100) * 2.0 = 100, (100 - 50) * 2.0 = 100
         assert.are.equal(100, vis:world_to_screen_x(150))
         assert.are.equal(100, vis:world_to_screen_y(100))
      end)

      it("should convert screen to world coordinates", function()
         vis:set_viewport(100, 50, 400, 300, 2.0)

         -- Screen point (100, 100) should be at world (150, 100)
         -- Because: 100/2.0 + 100 = 150, 100/2.0 + 50 = 100
         assert.are.equal(150, vis:screen_to_world_x(100))
         assert.are.equal(100, vis:screen_to_world_y(100))
      end)

      it("should zoom in", function()
         vis:zoom_in()
         assert.are.equal(1.2, vis.viewport.scale)
      end)

      it("should zoom out", function()
         vis:zoom_out()
         assert.are.equal(1.0 / 1.2, vis.viewport.scale)
      end)

      it("should pan viewport", function()
         vis:pan(10, -5)
         assert.are.equal(10, vis.viewport.x)
         assert.are.equal(-5, vis.viewport.y)
      end)

      it("should reset viewport", function()
         vis:set_viewport(100, 200, 800, 600, 3.0)
         vis:reset_viewport()
         assert.are.equal(0, vis.viewport.x)
         assert.are.equal(0, vis.viewport.y)
         assert.are.equal(1.0, vis.viewport.scale)
      end)
   end)

   describe("Query history", function()
      local vis

      before_each(function()
         vis = VisualizationSystem:new()
      end)

      it("should add queries to history", function()
         vis:add_query(10, 20, 30, 40, 5)
         assert.are.equal(1, #vis.query_history)

         local query = vis.query_history[1]
         assert.are.equal(10, query.x)
         assert.are.equal(20, query.y)
         assert.are.equal(30, query.w)
         assert.are.equal(40, query.h)
         assert.are.equal(5, query.result_count)
         assert.is_number(query.timestamp)
      end)

      it("should limit query history to 50 entries", function()
         for i = 1, 55 do
            vis:add_query(i, i, i, i, i)
         end

         assert.are.equal(50, #vis.query_history)
         -- First entry should be removed (FIFO)
         assert.are.equal(6, vis.query_history[1].x)
      end)
   end)

   describe("Rendering operations", function()
      local vis

      before_each(function()
         vis = VisualizationSystem:new()
      end)

      it("should handle input without errors", function()
         -- Mock btnp function for testing
         _G.btnp = function() return false end
         _G.keyp = function(key, _) return false end

         assert.has_no_error(function()
            vis:handle_input()
         end)

         -- Clean up
         _G.btnp = nil
         _G.keyp = nil
      end)
   end)

   describe("Drawing operations", function()
      local vis
      local draw_calls

      before_each(function()
         vis = VisualizationSystem:new()

         -- Mock Picotron drawing functions
         draw_calls = {}
         _G.line = function(x1, y1, x2, y2, color)
            table.insert(draw_calls, {type = "line", x1 = x1, y1 = y1, x2 = x2, y2 = y2, color = color})
         end
         _G.rrectfill = function(x, y, w, h, radius, color)
            table.insert(draw_calls, {type = "rrectfill", x = x, y = y, w = w, h = h, radius = radius, color = color})
         end
         _G.rrect = function(x, y, w, h, radius, color)
            table.insert(draw_calls, {type = "rrect", x = x, y = y, w = w, h = h, radius = radius, color = color})
         end
         _G.print = function(text, x, y, color)
            table.insert(draw_calls, {type = "print", text = text, x = x, y = y, color = color})
         end
      end)

      after_each(function()
         -- Clean up mocks
         _G.line = nil
         _G.rrectfill = nil
         _G.rrect = nil
         _G.print = nil
         draw_calls = {}
      end)

      it("should draw lines", function()
         vis:draw_line(10, 20, 30, 40, 5)
         assert.are.equal(1, #draw_calls)
         local call = draw_calls[1]
         assert.are.equal("line", call.type)
         assert.are.equal(10, call.x1)
         assert.are.equal(20, call.y1)
         assert.are.equal(30, call.x2)
         assert.are.equal(40, call.y2)
         assert.are.equal(5, call.color)
      end)

      it("should draw filled rectangles", function()
         vis:draw_rect(10, 20, 30, 40, 0, 5, true)
         assert.are.equal(1, #draw_calls)
         local call = draw_calls[1]
         assert.are.equal("rrectfill", call.type)
         assert.are.equal(10, call.x)
         assert.are.equal(20, call.y)
         assert.are.equal(30, call.w)
         assert.are.equal(40, call.h)
         assert.are.equal(0, call.radius)
         assert.are.equal(5, call.color)
      end)

      it("should draw outline rectangles", function()
         vis:draw_rect(10, 20, 30, 40, 0, 5, false)
         assert.are.equal(1, #draw_calls)
         local call = draw_calls[1]
         assert.are.equal("rrect", call.type)
         assert.are.equal(10, call.x)
         assert.are.equal(20, call.y)
         assert.are.equal(30, call.w)
         assert.are.equal(40, call.h)
         assert.are.equal(0, call.radius)
         assert.are.equal(5, call.color)
      end)
      it("should draw text", function()
         vis:draw_text("Hello", 10, 20, 5)
         assert.are.equal(1, #draw_calls)
         local call = draw_calls[1]
         assert.are.equal("print", call.type)
         assert.are.equal("Hello", call.text)
         assert.are.equal(10, call.x)
         assert.are.equal(20, call.y)
         assert.are.equal(5, call.color)
      end)

      it("should render strategy without errors", function()
         local mock_strategy = {
            objects = {},
            cell_size = 32
         }

         -- This should not throw errors
         assert.has_no_error(function()
            vis:render_strategy(mock_strategy, "fixed_grid")
         end)

         assert.are.equal(mock_strategy, vis.current_strategy)
         assert.are.equal("fixed_grid", vis.current_strategy_name)
      end)

      it("should clear screen", function()
         vis:clear_screen()
         assert.are.equal(1, #draw_calls)
         local call = draw_calls[1]
         assert.are.equal("rrectfill", call.type)
         assert.are.equal(0, call.x)
         assert.are.equal(0, call.y)
         assert.are.equal(400, call.w)  -- viewport width
         assert.are.equal(300, call.h)  -- viewport height
         assert.are.equal(0, call.color) -- background color
      end)
   end)
end)
