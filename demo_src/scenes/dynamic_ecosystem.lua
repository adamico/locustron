-- Dynamic Ecosystem Scene
-- Objects spawn, move, and die creating changing density patterns

local fps_time_step = 1 / 60

local DynamicEcosystem = SceneManager:addState("DynamicEcosystem")

function DynamicEcosystem:initialize(config)
   SceneManager.initialize(self, config)
end

function DynamicEcosystem:enteredState()
   -- Initialize ecosystem specific properties
   self.name = "Dynamic Ecosystem"
   self.description = "Move cursor (arrows) - X to attract, O to repel organisms"
   self.optimal_strategy = "quadtree"

   -- Scenario-specific state
   self.spawn_timer = 0
   
   -- Player cursor for environmental influence
   self.cursor = {
      x = 256,
      y = 192,
      radius = 60,
      mode = "neutral", -- "neutral", "attract", "repel"
      speed = 200,
   }
end

function DynamicEcosystem:init(loc, perf_profiler)
   -- Call parent init
   self.loc = loc

   -- Initialize/reset game state
   self.objects = {}
   self.pending_removal = {}

   self.loc:clear()

   -- Start with some initial objects
   for i = 1, 20 do
      self:spawn_object()
   end
end

function DynamicEcosystem:spawn_object()
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
   self.loc:add(obj, obj.x, obj.y, obj.w, obj.h)
end

function DynamicEcosystem:update()
   -- Process pending removal and cleanup dead objects
   self:process_pending_removal()
   
   -- Update player cursor
   self:update_cursor()

   self.spawn_timer = self.spawn_timer + fps_time_step

   -- Spawn new objects occasionally
   if self.spawn_timer > 1.0 then
      self:spawn_object()
      self.spawn_timer = 0
   end

   local to_remove = {}

   for i, obj in ipairs(self.objects) do
      -- Update age
      obj.age = obj.age + fps_time_step

      -- Flocking behavior: avoid crowding
      local nearby = {}
      if self.perf_profiler then
         nearby = self.perf_profiler:measure_query(
            "fixed_grid",
            function() return self.loc:query(obj.x - 25, obj.y - 25, 50, 50, function(other)
               return other ~= obj and other.type == "organism"
            end) end
         )
      else
         nearby = self.loc:query(obj.x - 25, obj.y - 25, 50, 50, function(other)
            return other ~= obj and other.type == "organism"
         end)
      end

      -- Convert hash table to array
      local nearby_array = {}
      for other in pairs(nearby) do
         table.insert(nearby_array, other)
      end

      -- Separation: move away from nearby organisms
      if #nearby_array > 0 then
         local center_x, center_y = 0, 0
         for _, other in ipairs(nearby_array) do
            center_x = center_x + other.x
            center_y = center_y + other.y
         end
         center_x = center_x / #nearby_array
         center_y = center_y / #nearby_array

         local sep_dx = obj.x - center_x
         local sep_dy = obj.y - center_y
         local sep_dist = math.sqrt(sep_dx * sep_dx + sep_dy * sep_dy)

         if sep_dist > 0 then
            -- Apply separation force
            obj.vx = obj.vx + (sep_dx / sep_dist) * 40 * fps_time_step
            obj.vy = obj.vy + (sep_dy / sep_dist) * 40 * fps_time_step
         end
      end

      -- Update position
      obj.x = obj.x + obj.vx * fps_time_step
      obj.y = obj.y + obj.vy * fps_time_step

      -- Bounce off edges
      if obj.x < 0 or obj.x > 512 then obj.vx = -obj.vx end
      if obj.y < 0 or obj.y > 384 then obj.vy = -obj.vy end
      
      -- Apply cursor influence
      self:apply_cursor_influence(obj)

      -- Update in spatial structure
      self.loc:update(obj, obj.x, obj.y, obj.w, obj.h)

      -- Remove old objects
      if obj.age > obj.lifetime then table.insert(to_remove, i) end
   end

   -- Remove dead objects (in reverse order to maintain indices)
   for i = #to_remove, 1, -1 do
      local obj = table.remove(self.objects, to_remove[i])
      self.loc:remove(obj)
   end
end

function DynamicEcosystem:update_cursor()
   local cursor = self.cursor
   
   -- Movement with arrow keys
   local move_x, move_y = 0, 0
   if btn(0) then move_x = -1 end -- Left
   if btn(1) then move_x = 1 end  -- Right
   if btn(2) then move_y = -1 end -- Up
   if btn(3) then move_y = 1 end  -- Down
   
   -- Normalize diagonal movement
   if move_x ~= 0 and move_y ~= 0 then
      local length = math.sqrt(2)
      move_x = move_x / length
      move_y = move_y / length
   end
   
   -- Apply movement
   cursor.x = cursor.x + move_x * cursor.speed * fps_time_step
   cursor.y = cursor.y + move_y * cursor.speed * fps_time_step
   
   -- Keep cursor within bounds
   cursor.x = math.max(0, math.min(512, cursor.x))
   cursor.y = math.max(0, math.min(384, cursor.y))
   
   -- Mode switching with X and O buttons
   if btn(4) then
      cursor.mode = "attract" -- X button
   elseif btn(5) then
      cursor.mode = "repel" -- O button
   else
      cursor.mode = "neutral"
   end
end

function DynamicEcosystem:apply_cursor_influence(obj)
   if self.cursor.mode == "neutral" then return end
   
   -- Calculate distance to cursor
   local dx = obj.x - self.cursor.x
   local dy = obj.y - self.cursor.y
   local dist = math.sqrt(dx * dx + dy * dy)
   
   -- Only apply influence within radius
   if dist > self.cursor.radius or dist < 0.1 then return end
   
   -- Normalize direction
   local nx = dx / dist
   local ny = dy / dist
   
   -- Calculate force based on distance (stronger when closer)
   local force_strength = (1.0 - dist / self.cursor.radius) * 150
   
   if self.cursor.mode == "attract" then
      -- Pull towards cursor (negative direction)
      obj.vx = obj.vx - nx * force_strength * fps_time_step
      obj.vy = obj.vy - ny * force_strength * fps_time_step
   elseif self.cursor.mode == "repel" then
      -- Push away from cursor (positive direction)
      obj.vx = obj.vx + nx * force_strength * fps_time_step
      obj.vy = obj.vy + ny * force_strength * fps_time_step
   end
end

function DynamicEcosystem:process_pending_removal()
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

function DynamicEcosystem:draw()
   for _, obj in ipairs(self.objects) do
      local alpha = math.max(0.3, 1.0 - (obj.age / obj.lifetime)) -- Fade out as they age
      local color = obj.color
      if alpha < 1.0 then
         color = 1 -- Dimmer color for old objects
      end
      rectfill(obj.x - obj.w / 2, obj.y - obj.h / 2, obj.x + obj.w / 2, obj.y + obj.h / 2, color)
   end
   
   -- Draw cursor
   local cursor = self.cursor
   local cursor_color = 5 -- Gray for neutral
   if cursor.mode == "attract" then
      cursor_color = 11 -- Green for attract
   elseif cursor.mode == "repel" then
      cursor_color = 8 -- Red for repel
   end
   
   -- Draw influence radius
   circ(cursor.x, cursor.y, cursor.radius, cursor_color)
   
   -- Draw cursor center
   circfill(cursor.x, cursor.y, 3, cursor_color)
   
   -- Draw crosshair
   line(cursor.x - 6, cursor.y, cursor.x - 2, cursor.y, cursor_color)
   line(cursor.x + 2, cursor.y, cursor.x + 6, cursor.y, cursor_color)
   line(cursor.x, cursor.y - 6, cursor.x, cursor.y - 2, cursor_color)
   line(cursor.x, cursor.y + 2, cursor.x, cursor.y + 6, cursor_color)

   print("Organisms: " .. #self.objects, 280, 8, 7)
   
   -- Display cursor mode
   local mode_text = "Mode: " .. cursor.mode:upper()
   print(mode_text, 280, 16, cursor_color)
end

function DynamicEcosystem:get_objects()
   return self.objects
end

return DynamicEcosystem
