-- SpaceBattle Scene
-- Ships spread across large area with some clusters around objectives

local fps_time_step = 1 / 60

local SpaceBattle = SceneManager:addState("SpaceBattle")

function SpaceBattle:initialize(config)
   SceneManager.initialize(self, config)
end

function SpaceBattle:enteredState()
   -- Initialize space battle specific properties
   self.name = "Space Battle"
   self.description = "Ships spread across large area with clusters around objectives"
   self.optimal_strategy = "hash_grid"

   -- Scenario-specific state
   self.objectives = {}
   self.update_cooldown = 0
   self.update_interval = 2 -- Update every other frame
end

function SpaceBattle:init(loc, perf_profiler)
   -- Call parent init
   self.loc = loc

   -- Create objectives (planets/stations)
   self.objectives = {
      { x = 100, y = 100, radius = 30, ships = 0 },
      { x = 400, y = 200, radius = 25, ships = 0 },
      { x = 200, y = 350, radius = 35, ships = 0 },
   }

   -- Initialize/reset game state
   self.objects = {}
   self.pending_removal = {}

   self.loc:clear()

   -- Spawn initial ships
   for i = 1, self.max_objects do
      self:spawn_ship()
   end
end

function SpaceBattle:spawn_ship()
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
   self.loc:add(obj, obj.x, obj.y, obj.w, obj.h)
end

function SpaceBattle:update()
   -- Process pending removal and cleanup dead objects
   self:process_pending_removal()

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

      -- Occasionally check for nearby ships (for collision avoidance)
      if math.random() < 0.03 then -- 3% chance to check nearby ships
         local nearby_ships = {}
         if self.perf_profiler then
            nearby_ships = self.perf_profiler:measure_query(
               "fixed_grid",
               function() return self.loc:query(obj.x - 20, obj.y - 20, 40, 40, function(other)
                  return other ~= obj and other.type == "ship"
               end) end
            )
         else
            nearby_ships = self.loc:query(obj.x - 20, obj.y - 20, 40, 40, function(other)
               return other ~= obj and other.type == "ship"
            end)
         end

         -- If too many ships nearby, change direction (avoidance behavior)
         local ship_count = 0
         for _ in pairs(nearby_ships) do ship_count = ship_count + 1 end
         if ship_count > 2 then
            obj.vx = (math.random() - 0.5) * 80 -- Random direction change
            obj.vy = (math.random() - 0.5) * 80
         end
      end

      -- Apply some drag to prevent infinite acceleration
      obj.vx = obj.vx * 0.995
      obj.vy = obj.vy * 0.995

      obj.x = obj.x + obj.vx * fps_time_step
      obj.y = obj.y + obj.vy * fps_time_step

      -- Wrap around screen edges
      if obj.x < 0 then obj.x = 512 end
      if obj.x > 512 then obj.x = 0 end
      if obj.y < 0 then obj.y = 384 end
      if obj.y > 384 then obj.y = 0 end

      self.loc:update(obj, obj.x, obj.y, obj.w, obj.h)
   end

   -- Very rare spawning
   if math.random() < 0.001 and #self.objects < self.max_objects then
      self:spawn_ship()
   end
end

function SpaceBattle:process_pending_removal()
   -- Process pending removal for array cleanup only (spatial removal already done)
   local indices_to_remove = {}
   for _, removal in ipairs(self.pending_removal) do
      table.insert(indices_to_remove, removal.index)
   end
   self.pending_removal = {}

   -- Remove dead objects from objects array (in reverse order to maintain indices)
   Sort(indices_to_remove, function(a, b) return a > b end)
   for _, index in ipairs(indices_to_remove) do
      table.remove(self.objects, index)
   end
end

function SpaceBattle:draw()
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

function SpaceBattle:get_objects()
   return self.objects
end

return SpaceBattle
