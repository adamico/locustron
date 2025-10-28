-- Space Battle Scenario
-- Ships spread across large area with some clusters around objectives

local SpaceBattleScenario = {}

function SpaceBattleScenario.new(config)
   config = config or {}
   local scenario = {
      name = "Space Battle",
      description = "Ships spread across large area with clusters around objectives",
      optimal_strategy = "hash_grid",
      objects = {},
      objectives = {},
      max_objects = config.max_objects or 150,
   }

   function scenario:init(loc)
      -- Create objectives (planets/stations)
      self.objectives = {
         { x = 100, y = 100, radius = 30, ships = 0 },
         { x = 400, y = 200, radius = 25, ships = 0 },
         { x = 200, y = 350, radius = 35, ships = 0 },
      }

      -- Spawn initial ships
      for i = 1, self.max_objects do
         self:spawn_ship(loc)
      end
   end

   function scenario:spawn_ship(loc)
      if #self.objects >= self.max_objects then return end

      -- 70% chance to spawn near an objective, 30% chance random
      local spawn_near_objective = math.random() < 0.7
      local x, y

      if spawn_near_objective and #self.objectives > 0 then
         local obj = self.objectives[math.random(#self.objectives)]
         local angle = math.random() * 2 * math.pi
         local distance = math.random() * obj.radius
         x = obj.x + math.cos(angle) * distance
         y = obj.y + math.sin(angle) * distance
      else
         x = math.random(0, 512)
         y = math.random(0, 384)
      end

      local obj = {
         x = x,
         y = y,
         w = 4 + math.random(4), -- 4-8 pixels
         h = 4 + math.random(4),
         vx = (math.random() - 0.5) * 100, -- -50 to 50
         vy = (math.random() - 0.5) * 100,
         type = "ship",
         color = 12 + math.random(3), -- Blue colors
      }

      table.insert(self.objects, obj)
      loc:add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   function scenario:update(loc, dt)
      -- Update ship positions
      for _, obj in ipairs(self.objects) do
         obj.x = obj.x + obj.vx * dt
         obj.y = obj.y + obj.vy * dt

         -- Wrap around screen edges
         if obj.x < 0 then obj.x = 512 end
         if obj.x > 512 then obj.x = 0 end
         if obj.y < 0 then obj.y = 384 end
         if obj.y > 384 then obj.y = 0 end

         loc:update(obj, obj.x, obj.y, obj.w, obj.h)
      end

      -- Occasionally spawn new ships
      if math.random() < 0.02 then self:spawn_ship(loc) end
   end

   function scenario:draw()
      -- Draw objectives
      for _, obj in ipairs(self.objectives) do
         circfill(obj.x, obj.y, obj.radius, 5) -- Grey circles
         circ(obj.x, obj.y, obj.radius, 6)
      end

      -- Draw ships
      for _, obj in ipairs(self.objects) do
         rectfill(obj.x - obj.w / 2, obj.y - obj.h / 2, obj.x + obj.w / 2, obj.y + obj.h / 2, obj.color)
      end

      print("Ships: " .. #self.objects, 280, 8, 7)
   end

   function scenario:get_objects() return self.objects end

   return scenario
end

return SpaceBattleScenario
