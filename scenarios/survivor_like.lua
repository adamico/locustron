-- Survivor Like Scenario
-- Monsters spawn in waves around player, creating dense clusters

local SurvivorLikeScenario = {}

function SurvivorLikeScenario.new(config)
   config = config or {}
   local scenario = {
      name = "Survivor Like",
      description = "Monsters spawn in waves around player, creating dense clusters",
      optimal_strategy = "quadtree",
      objects = {},
      player = { x = 128, y = 128, w = 8, h = 8 },
      wave = 1,
      spawn_timer = 0,
      max_objects = config.max_objects or 200,
   }

   function scenario:init(loc)
      -- Add player
      loc:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)
   end

   function scenario:update(loc, dt)
      self.spawn_timer = self.spawn_timer + dt

      -- Spawn monsters in waves
      if self.spawn_timer > 2.0 and #self.objects < self.max_objects then
         self:spawn_wave(loc)
         self.spawn_timer = 0
         self.wave = self.wave + 1
      end

      -- Update monster movement and lifespan
      local to_remove = {}
      for i, obj in ipairs(self.objects) do
         if obj.alive then
            -- Update age
            obj.age = obj.age + dt

            -- Remove if lifespan exceeded
            if obj.age > obj.lifespan then
               obj.alive = false
               loc:remove(obj)
               table.insert(to_remove, i)
            else
               -- Update movement (move toward player)
               local dx = self.player.x - obj.x
               local dy = self.player.y - obj.y
               local dist = math.sqrt(dx*dx + dy*dy)

               if dist > 0 then
                  obj.x = obj.x + (dx/dist) * obj.speed * dt
                  obj.y = obj.y + (dy/dist) * obj.speed * dt
                  loc:update(obj, obj.x, obj.y, obj.w, obj.h)
               end
            end
         end
      end

      -- Remove dead objects (in reverse order to maintain indices)
      for i = #to_remove, 1, -1 do
         table.remove(self.objects, to_remove[i])
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
            w = 6 + math.random(4), -- 6-10 pixels
            h = 6 + math.random(4),
            speed = 20 + math.random(20), -- 20-40 units/sec
            age = 0, -- Track how long this monster has been alive
            lifespan = 5 + math.random(2), -- 5-7 seconds lifespan
            alive = true,
            type = "monster",
            color = 8 + math.random(7), -- Red to yellow colors
         }

         table.insert(self.objects, obj)
         loc:add(obj, obj.x, obj.y, obj.w, obj.h)
      end
   end

   function scenario:draw()
      -- Draw player
      rectfill(self.player.x - 4, self.player.y - 4, self.player.x + 4, self.player.y + 4, 11)

      -- Draw monsters
      for _, obj in ipairs(self.objects) do
         if obj.alive then
            -- Fade out monsters as they approach end of lifespan
            local age_ratio = obj.age / obj.lifespan
            local color = obj.color
            if age_ratio > 0.7 then
               -- Fade to darker color as they age
               color = 1 -- Dark grey for old monsters
            end
            rectfill(obj.x - obj.w/2, obj.y - obj.h/2, obj.x + obj.w/2, obj.y + obj.h/2, color)
         end
      end

      -- Draw wave info
      print("Wave: " .. self.wave, 280, 8, 7)
      print("Monsters: " .. #self.objects, 280, 16, 7)
   end

   function scenario:get_objects()
      local all_objects = {self.player}
      for _, obj in ipairs(self.objects) do
         if obj.alive then
            table.insert(all_objects, obj)
         end
      end
      return all_objects
   end

   return scenario
end

return SurvivorLikeScenario