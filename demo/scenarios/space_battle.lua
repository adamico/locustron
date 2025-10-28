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
      max_objects = config.max_objects or 25, -- Further reduced from 100
      update_cooldown = 0,
      update_interval = 2, -- Update every other frame
   }

   function scenario:init(loc, perf_profiler)
      -- Store performance profiler for measuring queries
      self.perf_profiler = perf_profiler

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

      -- Simple random spawning
      local x = math.random(0, 512)
      local y = math.random(0, 384)

      local obj = {
         x = x,
         y = y,
         w = 4 + math.random(4), -- 4-8 pixels
         h = 4 + math.random(4),
         vx = (math.random() - 0.5) * 40, -- Further reduced speed
         vy = (math.random() - 0.5) * 40,
         type = "ship",
         color = 12 + math.random(3), -- Blue colors
      }

      table.insert(self.objects, obj)
      loc:add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   function scenario:update(loc, dt)
      -- Update cooldown for batched operations
      self.update_cooldown = self.update_cooldown - 1
      if self.update_cooldown <= 0 then
         self.update_cooldown = self.update_interval
      end

      -- Update ship positions (only some ships per frame for performance)
      local ships_to_update = math.ceil(#self.objects / self.update_interval)
      local start_idx = ((self.update_cooldown - 1) * ships_to_update) + 1
      local end_idx = math.min(start_idx + ships_to_update - 1, #self.objects)

      for i = start_idx, end_idx do
         local obj = self.objects[i]

         -- Very simple AI: occasional random direction changes
         if math.random() < 0.02 then -- 2% chance per update to change direction
            obj.vx = (math.random() - 0.5) * 60 -- Reduced speed
            obj.vy = (math.random() - 0.5) * 60
         end

         -- Apply some drag to prevent infinite acceleration
         obj.vx = obj.vx * 0.995
         obj.vy = obj.vy * 0.995

         obj.x = obj.x + obj.vx * dt
         obj.y = obj.y + obj.vy * dt

         -- Wrap around screen edges
         if obj.x < 0 then obj.x = 512 end
         if obj.x > 512 then obj.x = 0 end
         if obj.y < 0 then obj.y = 384 end
         if obj.y > 384 then obj.y = 0 end

         loc:update(obj, obj.x, obj.y, obj.w, obj.h)
      end

      -- Very rare spawning
      if math.random() < 0.001 and #self.objects < self.max_objects then
         self:spawn_ship(loc)
      end
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
