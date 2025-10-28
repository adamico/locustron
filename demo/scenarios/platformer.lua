-- Platformer Level Scenario
-- Objects in a bounded level with some clustering around platforms

local CollisionUtils = require("demo.collision_utils")

local PlatformerScenario = {}

function PlatformerScenario.new(config)
   config = config or {}
   local scenario = {
      name = "Platformer Level",
      description = "Objects in bounded level with clustering around platforms",
      optimal_strategy = "fixed_grid",
      objects = {},
      platforms = {},
      player = { x = 256, y = 100, w = 8, h = 16, vx = 0, vy = 0, grounded = false },
      max_objects = config.max_objects or 20, -- Reduced from 30 for better performance
      query_cooldown = 0,
      query_interval = 6, -- Perform spatial queries every 6 frames
   }

   function scenario:init(loc, perf_profiler)
      -- Store performance profiler for measuring queries
      self.perf_profiler = perf_profiler

      -- Create platforms
      self.platforms = {
         { x = 50, y = 200, w = 100, h = 20 },
         { x = 200, y = 150, w = 80, h = 20 },
         { x = 350, y = 250, w = 120, h = 20 },
         { x = 100, y = 320, w = 150, h = 20 },
      }

      -- Add player
      loc:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

      -- Spawn objects on platforms
      for i = 1, self.max_objects do
         self:spawn_on_platform(loc)
      end
   end

   function scenario:spawn_on_platform(loc)
      if #self.objects >= self.max_objects then return end

      local platform = self.platforms[math.random(#self.platforms)]
      local obj = {
         x = platform.x + math.random(platform.w - 16),
         y = platform.y - 8 - math.random(32), -- Above platform
         w = 6 + math.random(6), -- 6-12 pixels
         h = 6 + math.random(6),
         vx = (math.random() - 0.5) * 40, -- Reduced speed
         vy = 0,
         grounded = false,
         lifetime = 0, -- Track how long enemy has been alive
         type = "enemy",
         color = 8 + math.random(7),
      }

      table.insert(self.objects, obj)
      loc:add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   function scenario:update(loc, dt)
      local gravity = 200

      -- Update AI cooldown
      self.query_cooldown = self.query_cooldown - 1
      if self.query_cooldown <= 0 then
         self.query_cooldown = self.query_interval
      end

      -- Simple player movement (for demo purposes)
      if btn(0) then self.player.vx = -100 end -- Left
      if btn(1) then self.player.vx = 100 end  -- Right
      if not btn(0) and not btn(1) then self.player.vx = 0 end
      if btnp(4) and self.player.grounded then self.player.vy = -150 end -- Jump

      -- Update player
      self.player.vy = self.player.vy + gravity * dt
      self.player.x = self.player.x + self.player.vx * dt
      self.player.y = self.player.y + self.player.vy * dt

      -- Player platform collision
      self.player.grounded = false
      for _, platform in ipairs(self.platforms) do
         if CollisionUtils.check_platform_collision(self.player, platform) then
            if self.player.vy > 0 then
               self.player.y = platform.y - self.player.h
               self.player.vy = 0
               self.player.grounded = true
            end
         end
      end

      loc:update(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

      -- Remove dead enemies and update living ones
      local to_remove = {}
      for i, obj in ipairs(self.objects) do
         -- Track lifetime
         obj.lifetime = (obj.lifetime or 0) + dt

         -- Remove enemies that have lived too long or fallen off screen
         if obj.lifetime > 30 or obj.y > 450 then -- 30 second lifetime (increased)
            loc:remove(obj)
            table.insert(to_remove, i)
         else
            -- Update AI with occasional spatial queries for player detection
            if self.query_cooldown == self.query_interval then
               -- Perform spatial query to check player proximity
               local nearby_player = {}
               if self.perf_profiler then
                  nearby_player = self.perf_profiler:measure_query(
                     "fixed_grid",
                     function() return loc:query(obj.x - 60, obj.y - 60, 120, 120, function(other)
                        return other == self.player
                     end) end
                  )
               else
                  nearby_player = loc:query(obj.x - 60, obj.y - 60, 120, 120, function(other)
                     return other == self.player
                  end)
               end

               -- Cache player proximity for smooth AI
               obj.player_nearby = next(nearby_player) ~= nil
            end

            -- Smooth AI behavior based on cached player proximity
            if obj.player_nearby and math.random() < 0.3 then -- 30% chance to pursue when player nearby
               local dx = self.player.x - obj.x
               if dx > 0 then
                  obj.vx = obj.vx + 15 * dt -- Smooth acceleration toward player
               elseif dx < 0 then
                  obj.vx = obj.vx - 15 * dt
               end
            elseif math.random() < 0.05 then -- 5% chance for random direction change
               obj.vx = (math.random() - 0.5) * 30
            else
               -- Gradual slowdown
               obj.vx = obj.vx * 0.95
            end

            -- Apply gravity (always)
            obj.vy = obj.vy + gravity * dt

            -- Update position
            obj.x = obj.x + obj.vx * dt
            obj.y = obj.y + obj.vy * dt

            -- Platform collision (only when falling)
            if obj.vy > 0 then
               obj.grounded = false
               for _, platform in ipairs(self.platforms) do
                  if CollisionUtils.check_platform_collision(obj, platform) then
                     obj.y = platform.y - obj.h / 2
                     obj.vy = 0
                     obj.grounded = true
                     break -- Only check one platform collision per frame
                  end
               end
            end

            -- Simple edge bouncing (reduced energy loss)
            if obj.x < 0 or obj.x > 512 then
               obj.vx = -obj.vx * 0.9 -- Less energy loss
            end

            loc:update(obj, obj.x, obj.y, obj.w, obj.h)
         end
      end

      -- Remove dead enemies (in reverse order)
      for i = #to_remove, 1, -1 do
         table.remove(self.objects, to_remove[i])
      end

      -- Spawn new enemies to maintain population
      local target_population = math.floor(self.max_objects * 0.7) -- Maintain ~70% of max
      if #self.objects < target_population and math.random() < 0.03 then -- 3% chance per frame
         self:spawn_on_platform(loc)
      end
   end

   function scenario:draw()
      -- Draw platforms
      for _, platform in ipairs(self.platforms) do
         rectfill(platform.x, platform.y, platform.x + platform.w, platform.y + platform.h, 5)
      end

      -- Draw player
      rectfill(self.player.x - self.player.w / 2, self.player.y - self.player.h / 2,
               self.player.x + self.player.w / 2, self.player.y + self.player.h / 2, 11)

      -- Draw objects
      for _, obj in ipairs(self.objects) do
         rectfill(obj.x - obj.w / 2, obj.y - obj.h / 2, obj.x + obj.w / 2, obj.y + obj.h / 2, obj.color)
      end

      print("Enemies: " .. #self.objects, 280, 8, 7)
   end

   function scenario:get_objects()
      local all_objects = { self.player }
      for _, obj in ipairs(self.objects) do
         table.insert(all_objects, obj)
      end
      return all_objects
   end

   return scenario
end

return PlatformerScenario
