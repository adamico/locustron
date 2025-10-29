-- Survivor Like Scenario
-- Monsters spawn in waves around player, creating dense clusters

local CollisionUtils = require("demo.collision_utils")

local SurvivorLikeScenario = {}

local fps_time_step = 1 / 60 -- Fixed time step for 60 FPS

function SurvivorLikeScenario.new(config)
   config = config or {}
   local scenario = {
      name = "Survivor Like",
      description = "Monsters spawn in waves around player, creating dense clusters",
      optimal_strategy = "quadtree",
      objects = {},
      player = {x = 128, y = 128, w = 8, h = 8, health = 5, max_health = 5, speed = 2},
      wave = 0,
      spawn_timer = 0,
      max_objects = config.max_objects or 200,
      damage_cooldown = 0, -- Prevent rapid damage
      to_remove = {}, -- Objects to remove at end of update
   }

   function scenario:init(loc, perf_profiler)
      -- Store performance profiler for measuring queries
      self.perf_profiler = perf_profiler

      -- Add player
      loc:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)
   end

   function scenario:update(loc)
      self:update_timers()
      self:update_player(loc)
      self:spawn_monsters_if_needed(loc)
      self:update_monsters(loc)
      self:cleanup_dead_objects()
   end

   function scenario:update_timers()
      self.spawn_timer = self.spawn_timer + fps_time_step

      -- Update damage cooldown
      if self.damage_cooldown > 0 then
         self.damage_cooldown = self.damage_cooldown - fps_time_step
      end
   end

   function scenario:update_player(loc)
      -- Handle 8-directional player movement
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
         self.player.x = self.player.x + move_x * self.player.speed
         self.player.y = self.player.y + move_y * self.player.speed

         -- Keep player within bounds (roughly the screen area)
         self.player.x = mid(8, self.player.x, 248) -- 256 - 8 for player width
         self.player.y = mid(8, self.player.y, 248) -- 256 - 8 for player height

         -- Update player position in spatial structure
         loc:update(self.player, self.player.x, self.player.y, self.player.w, self.player.h)
      end
   end

   function scenario:spawn_monsters_if_needed(loc)
      -- Spawn monsters in waves
      local spawn_cooldown = self.wave == 0 and 0 or 5.0
      if self.spawn_timer > spawn_cooldown and #self.objects < self.max_objects then
         self:spawn_wave(loc)
         self.spawn_timer = 0
         self.wave = self.wave + 1
      end
   end

   function scenario:update_monsters(loc)
      -- Clear removal list at start of update
      self.to_remove = {}

      -- Update monster movement and lifespan
      for i, obj in ipairs(self.objects) do
         if obj.alive then

            -- Update movement (move toward player)
            local dx = self.player.x - obj.x
            local dy = self.player.y - obj.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > 0 then
               obj.x = obj.x + (dx / dist) * obj.speed * fps_time_step
               obj.y = obj.y + (dy / dist) * obj.speed * fps_time_step
               loc:update(obj, obj.x, obj.y, obj.w, obj.h)
            end

            -- Collision detection with player
            if CollisionUtils.check_aabb(obj, self.player) and self.damage_cooldown <= 0 then
               -- Player hit by monster - decrease health
               self.player.health = self.player.health - 1
               self.damage_cooldown = 0.5 -- 0.5 second cooldown between damage

               -- Remove the monster that hit the player
               obj.alive = false
               loc:remove(obj)
               table.insert(self.to_remove, i)

               -- Check if player is dead
               if self.player.health <= 0 then
                  -- Player died - reset wave and restore health
                  self.wave = 0
                  self.player.health = self.player.max_health
                  self.spawn_timer = 0
                  -- Remove all monsters
                  for _, monster in ipairs(self.objects) do
                     if monster.alive then
                        loc:remove(monster)
                        monster.alive = false
                     end
                  end
                  self.objects = {}
                  self.to_remove = {} -- Clear removal list since objects table was reset
               end
               break
            end

            -- Collision detection with other monsters (avoid crowding)
            local nearby = {}
            if self.perf_profiler then
               nearby = self.perf_profiler:measure_query(
                  "fixed_grid",
                  function()
                     return loc:query(obj.x - 16, obj.y - 16, 32, 32, function(other)
                        return other ~= obj and other.alive and other.type == "monster"
                     end)
                  end
               )
            else
               nearby = loc:query(obj.x - 16, obj.y - 16, 32, 32, function(other)
                  return other ~= obj and other.alive and other.type == "monster"
               end)
            end

            -- Convert hash table to array for easier processing
            local nearby_array = {}
            for other in pairs(nearby) do
               table.insert(nearby_array, other)
            end

            if #nearby_array > 3 then
               -- Too crowded, move away from center of nearby monsters
               local center_x, center_y = 0, 0
               for _, other in ipairs(nearby_array) do
                  center_x = center_x + other.x
                  center_y = center_y + other.y
               end
               center_x = center_x / #nearby_array
               center_y = center_y / #nearby_array

               local avoid_dx = obj.x - center_x
               local avoid_dy = obj.y - center_y
               local avoid_dist = math.sqrt(avoid_dx * avoid_dx + avoid_dy * avoid_dy)

               if avoid_dist > 0 then
                  obj.x = obj.x + (avoid_dx / avoid_dist) * obj.speed * fps_time_step * 0.5
                  obj.y = obj.y + (avoid_dy / avoid_dist) * obj.speed * fps_time_step * 0.5
                  loc:update(obj, obj.x, obj.y, obj.w, obj.h)
               end
            end
         end
      end
   end

   function scenario:cleanup_dead_objects()
      -- Remove dead objects (in reverse order to maintain indices)
      for i = #self.to_remove, 1, -1 do
         table.remove(self.objects, self.to_remove[i])
      end
   end

   function scenario:spawn_wave(loc)
      local monsters_per_wave = math.min(20 + self.wave * 5, 50)
      local spawn_radius = 150

      for i = 1, monsters_per_wave do
         if #self.objects >= self.max_objects then break end

         -- Spawn around player in a circle
         local angle = (i / monsters_per_wave) * 2 * math.pi
         local distance = spawn_radius * (0.8 + math.random() * 0.4) -- Some variation

         local obj = {
            x = self.player.x + math.cos(angle) * distance,
            y = self.player.y + math.sin(angle) * distance,
            w = 6 + math.random(4),        -- 6-10 pixels
            h = 6 + math.random(4),
            speed = 20 + math.random(20),  -- 20-40 units/sec
            alive = true,
            type = "monster",
            color = 8 + math.random(7), -- Red to yellow colors
         }

         table.insert(self.objects, obj)
         loc:add(obj, obj.x, obj.y, obj.w, obj.h)
      end
   end

   function scenario:draw()
      -- Draw player with health-based color
      local player_color = 11 -- Default green
      if self.player.health <= 1 then
         player_color = 8 -- Red when low health
      elseif self.player.health <= 2 then
         player_color = 9 -- Orange when medium health
      end
      circfill(self.player.x, self.player.y, 8, player_color)

      -- Draw monsters
      for _, obj in ipairs(self.objects) do
         if obj.alive then
            local color = obj.color
            rectfill(obj.x - obj.w / 2, obj.y - obj.h / 2, obj.x + obj.w / 2, obj.y + obj.h / 2, color)
         end
      end

      -- Draw wave info
      local info_x = 8
      local info_y = 8
      local lines = 3
      local padding = 1
      local line_height = 8
      local box_width = 80
      local box_height = lines * (line_height + padding) -- = 3 * (8 + 1) = 27
      rrectfill(info_x - 2, info_y - 2, box_width, box_height, 0, 0)
      rrect(info_x - 2, info_y - 2, box_width, box_height, 0, 7)
      print("Wave: "..self.wave, info_x, info_y, 7)
      print("Monsters: "..#self.objects, info_x, info_y + 8, 7)
      print("Health: "..self.player.health.."/"..self.player.max_health, info_x, info_y + 16, 7)
   end

   function scenario:get_objects()
      local all_objects = {self.player}
      for _, obj in ipairs(self.objects) do
         if obj.alive then table.insert(all_objects, obj) end
      end
      return all_objects
   end

   return scenario
end

return SurvivorLikeScenario
