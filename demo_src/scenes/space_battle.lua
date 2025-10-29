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
   self.description = "Navigate your ship (arrows) - AI ships react to your presence"
   self.controls = "Move: Arrows"
   self.optimal_strategy = "hash_grid"

   -- Scenario-specific state
   self.objectives = {}
   self.update_cooldown = 0
   self.update_interval = 2 -- Update every other frame

   -- Player ship definition
   self.player_ship = {
      x = 256,
      y = 192,
      w = 8,
      h = 8,
      vx = 0,
      vy = 0,
      speed = 120,
      type = "player_ship",
      color = 10, -- Green
   }
end

function SpaceBattle:init(loc, perf_profiler)
   -- Call parent init
   self.loc = loc

   -- Create objectives (planets/stations)
   self.objectives = {
      {x = 100, y = 100, radius = 30, ships = 0},
      {x = 400, y = 200, radius = 25, ships = 0},
      {x = 200, y = 350, radius = 35, ships = 0},
   }

   -- Initialize/reset game state
   self.objects = {}
   self.pending_removal = {}

   self.loc:clear()

   -- Add player ship to spatial structure
   self.loc:add(self.player_ship, self.player_ship.x, self.player_ship.y, self.player_ship.w, self.player_ship.h)

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
      w = 4 + math.random(4),          -- 4-8 pixels
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

   -- Update player ship
   self:update_player_ship()

   -- Update cooldown for batched operations
   self.update_cooldown = self.update_cooldown - 1
   if self.update_cooldown <= 0 then
      self.update_cooldown = self.update_interval
   end

   -- Update AI ship positions (only some ships per frame for performance)
   self:update_ai_ships()

   -- Very rare spawning
   if math.random() < 0.001 and #self.objects < self.max_objects then
      self:spawn_ship()
   end

   self.draw_info = {
      "Ships: " .. tostring(#self.objects),
   }
end

function SpaceBattle:update_player_ship()
   -- 8-directional player movement
   local move_x = 0
   local move_y = 0

   if btn(0) then move_x = move_x - 1 end -- Left
   if btn(1) then move_x = move_x + 1 end -- Right
   if btn(2) then move_y = move_y - 1 end -- Up
   if btn(3) then move_y = move_y + 1 end -- Down

   -- Normalize diagonal movement
   if move_x ~= 0 and move_y ~= 0 then
      move_x = move_x * 0.7071 -- 1/sqrt(2) for diagonal normalization
      move_y = move_y * 0.7071
   end

   -- Apply movement
   if move_x ~= 0 or move_y ~= 0 then
      self.player_ship.vx = move_x * self.player_ship.speed
      self.player_ship.vy = move_y * self.player_ship.speed
   else
      -- Apply drag when not moving
      self.player_ship.vx = self.player_ship.vx * 0.9
      self.player_ship.vy = self.player_ship.vy * 0.9
   end

   -- Update position
   self.player_ship.x = self.player_ship.x + self.player_ship.vx * fps_time_step
   self.player_ship.y = self.player_ship.y + self.player_ship.vy * fps_time_step

   -- Wrap around screen edges
   if self.player_ship.x < 0 then self.player_ship.x = 512 end
   if self.player_ship.x > 512 then self.player_ship.x = 0 end
   if self.player_ship.y < 0 then self.player_ship.y = 384 end
   if self.player_ship.y > 384 then self.player_ship.y = 0 end

   -- Update in spatial structure
   self.loc:update(self.player_ship, self.player_ship.x, self.player_ship.y,
      self.player_ship.w, self.player_ship.h)
end

function SpaceBattle:update_ai_ships()
   local ships_to_update = math.ceil(#self.objects / self.update_interval)
   local start_idx = ((self.update_cooldown - 1) * ships_to_update) + 1
   local end_idx = math.min(start_idx + ships_to_update - 1, #self.objects)

   for i = start_idx, end_idx do
      local obj = self.objects[i]

      -- Check for player proximity and react
      local nearby_entities = {}
      if self.perf_profiler then
         nearby_entities = self.perf_profiler:measure_query(
            "fixed_grid",
            function()
               return self.loc:query(obj.x - 60, obj.y - 60, 120, 120, function(other)
                  return other ~= obj
               end)
            end
         )
      else
         nearby_entities = self.loc:query(obj.x - 60, obj.y - 60, 120, 120, function(other)
            return other ~= obj
         end)
      end

      -- React to player presence
      if nearby_entities[self.player_ship] then
         local dx = self.player_ship.x - obj.x
         local dy = self.player_ship.y - obj.y
         local dist = math.sqrt(dx * dx + dy * dy)

         if dist > 0 then
            -- Ships flee from player
            obj.vx = obj.vx - (dx / dist) * 60 * fps_time_step
            obj.vy = obj.vy - (dy / dist) * 60 * fps_time_step
         end
      else
         -- Normal behavior: occasional random direction changes
         if math.random() < 0.02 then
            obj.vx = (math.random() - 0.5) * 60
            obj.vy = (math.random() - 0.5) * 60
         end

         -- Check for ship crowding
         local ship_count = 0
         for other in pairs(nearby_entities) do
            if other.type == "ship" then
               ship_count = ship_count + 1
            end
         end

         if ship_count > 2 then
            obj.vx = (math.random() - 0.5) * 80
            obj.vy = (math.random() - 0.5) * 80
         end
      end

      -- Apply drag to prevent infinite acceleration
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

   -- Draw AI ships
   for _, obj in ipairs(self.objects) do
      rectfill(obj.x - obj.w / 2, obj.y - obj.h / 2, obj.x + obj.w / 2, obj.y + obj.h / 2, obj.color)
   end

   -- Draw player ship (distinct appearance)
   circfill(self.player_ship.x, self.player_ship.y, 4, self.player_ship.color)
   -- Draw direction indicator
   local dir_x = self.player_ship.vx
   local dir_y = self.player_ship.vy
   local dir_len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
   if dir_len > 0 then
      line(self.player_ship.x, self.player_ship.y,
         self.player_ship.x + (dir_x / dir_len) * 6,
         self.player_ship.y + (dir_y / dir_len) * 6,
         7)   -- White direction line
   end
end

function SpaceBattle:get_objects()
   return self.objects
end

return SpaceBattle
