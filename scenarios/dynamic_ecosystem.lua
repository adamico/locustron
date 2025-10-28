-- Dynamic Ecosystem Scenario
-- Objects spawn, move, and die creating changing density patterns

local DynamicEcosystemScenario = {}

function DynamicEcosystemScenario.new(config)
   config = config or {}
   local scenario = {
      name = "Dynamic Ecosystem",
      description = "Objects spawn and die, creating changing density patterns",
      optimal_strategy = "quadtree", -- Adapts to changing distributions
      objects = {},
      spawn_timer = 0,
      max_objects = config.max_objects or 120,
   }

   function scenario:init(loc)
      -- Start with some initial objects
      for i = 1, 20 do
         self:spawn_object(loc)
      end
   end

   function scenario:spawn_object(loc)
      if #self.objects >= self.max_objects then return end

      local obj = {
         x = math.random(0, 512),
         y = math.random(0, 384),
         w = 4 + math.random(8), -- 4-12 pixels
         h = 4 + math.random(8),
         vx = (math.random() - 0.5) * 80,
         vy = (math.random() - 0.5) * 80,
         lifetime = 5 + math.random(10), -- 5-15 seconds
         age = 0,
         type = "organism",
         color = 3 + math.random(5), -- Green to cyan
      }

      table.insert(self.objects, obj)
      loc:add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   function scenario:update(loc, dt)
      self.spawn_timer = self.spawn_timer + dt

      -- Spawn new objects occasionally
      if self.spawn_timer > 1.0 then
         self:spawn_object(loc)
         self.spawn_timer = 0
      end

      local to_remove = {}

      for i, obj in ipairs(self.objects) do
         -- Update age
         obj.age = obj.age + dt

         -- Update position
         obj.x = obj.x + obj.vx * dt
         obj.y = obj.y + obj.vy * dt

         -- Bounce off edges
         if obj.x < 0 or obj.x > 512 then obj.vx = -obj.vx end
         if obj.y < 0 or obj.y > 384 then obj.vy = -obj.vy end

         -- Update in spatial structure
         loc:update(obj, obj.x, obj.y, obj.w, obj.h)

         -- Remove old objects
         if obj.age > obj.lifetime then
            table.insert(to_remove, i)
         end
      end

      -- Remove dead objects (in reverse order to maintain indices)
      for i = #to_remove, 1, -1 do
         local obj = table.remove(self.objects, to_remove[i])
         loc:remove(obj)
      end
   end

   function scenario:draw()
      for _, obj in ipairs(self.objects) do
         local alpha = math.max(0.3, 1.0 - (obj.age / obj.lifetime)) -- Fade out as they age
         local color = obj.color
         if alpha < 1.0 then
            color = 1 -- Dimmer color for old objects
         end
         rectfill(obj.x - obj.w/2, obj.y - obj.h/2, obj.x + obj.w/2, obj.y + obj.h/2, color)
      end

      print("Organisms: " .. #self.objects, 280, 8, 7)
   end

   function scenario:get_objects()
      return self.objects
   end

   return scenario
end

return DynamicEcosystemScenario