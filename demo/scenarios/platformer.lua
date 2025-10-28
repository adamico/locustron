-- Platformer Level Scenario
-- Objects in a bounded level with some clustering around platforms

local PlatformerScenario = {}

function PlatformerScenario.new(config)
   config = config or {}
   local scenario = {
      name = "Platformer Level",
      description = "Objects in bounded level with clustering around platforms",
      optimal_strategy = "fixed_grid",
      objects = {},
      platforms = {},
      max_objects = config.max_objects or 100,
   }

   function scenario:init(loc)
      -- Create platforms
      self.platforms = {
         { x = 50, y = 200, w = 100, h = 20 },
         { x = 200, y = 150, w = 80, h = 20 },
         { x = 350, y = 250, w = 120, h = 20 },
         { x = 100, y = 320, w = 150, h = 20 },
      }

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
         vx = (math.random() - 0.5) * 60, -- -30 to 30
         vy = 0,
         grounded = false,
         type = "enemy",
         color = 8 + math.random(7),
      }

      table.insert(self.objects, obj)
      loc:add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   function scenario:update(loc, dt)
      local gravity = 200

      for _, obj in ipairs(self.objects) do
         -- Apply gravity
         obj.vy = obj.vy + gravity * dt

         -- Update position
         obj.x = obj.x + obj.vx * dt
         obj.y = obj.y + obj.vy * dt

         -- Platform collision (simple)
         obj.grounded = false
         for _, platform in ipairs(self.platforms) do
            if
               obj.x + obj.w / 2 > platform.x
               and obj.x - obj.w / 2 < platform.x + platform.w
               and obj.y + obj.h / 2 > platform.y
               and obj.y - obj.h / 2 < platform.y + platform.h
            then
               if obj.vy > 0 then -- Falling down
                  obj.y = platform.y - obj.h / 2
                  obj.vy = 0
                  obj.grounded = true
               end
            end
         end

         -- Bounce off edges
         if obj.x < 0 or obj.x > 512 then
            obj.vx = -obj.vx * 0.8 -- Some energy loss
         end

         -- Respawn if fallen off bottom
         if obj.y > 400 then
            obj.y = -10
            obj.vy = 0
         end

         loc:update(obj, obj.x, obj.y, obj.w, obj.h)
      end
   end

   function scenario:draw()
      -- Draw platforms
      for _, platform in ipairs(self.platforms) do
         rectfill(platform.x, platform.y, platform.x + platform.w, platform.y + platform.h, 5)
      end

      -- Draw objects
      for _, obj in ipairs(self.objects) do
         rectfill(obj.x - obj.w / 2, obj.y - obj.h / 2, obj.x + obj.w / 2, obj.y + obj.h / 2, obj.color)
      end

      print("Enemies: " .. #self.objects, 280, 8, 7)
   end

   function scenario:get_objects() return self.objects end

   return scenario
end

return PlatformerScenario
