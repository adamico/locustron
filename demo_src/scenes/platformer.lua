-- Platformer Scene
-- Objects in a bounded level with some clustering around platforms


local CollisionUtils = require("demo_src.collision_utils")
local fps_time_step = 1 / 60

local Platformer = SceneManager:addState("Platformer")

function Platformer:initialize(config)
   SceneManager.initialize(self, config)
end

function Platformer:enteredState()
   -- Initialize platformer specific properties
   self.name = "Platformer Level"
   self.description = "Objects in bounded level with clustering around platforms"
   self.controls = "Move: LEFT, RIGHT, Jump: UP"
   self.optimal_strategy = "fixed_grid"

   -- Scenario-specific state
   self.platforms = {}
   self.player = {x = 256, y = 100, w = 8, h = 16, vx = 0, vy = 0, grounded = false, jumps = 0, max_jumps = 2, drop_timer = 0}
   self.query_cooldown = 0
   self.query_interval = 6 -- Perform spatial queries every 6 frames
end

function Platformer:init(loc, perf_profiler)
   -- Call parent init
   self.loc = loc

      -- Randomize number and placement of platforms (min 3, max 5)
      self.platforms = {}
      local num_platforms = 3 + math.random(3) - 1 -- 3, 4, or 5
      for i = 1, num_platforms do
         local w = 60 + math.random(100) -- width 60-160
         local h = 16 + math.random(8)   -- height 16-24
         local x = math.random(32, 512 - w - 32)
         local y = 80 + (i-1) * 60 + math.random(-20, 20) -- vertical spread
         table.insert(self.platforms, { x = x, y = y, w = w, h = h })
      end

   -- Initialize/reset game state
   self.objects = {}
   self.pending_removal = {}

   self.loc:clear()

   -- Place player on a random platform
   if #self.platforms > 0 then
      local p = self.platforms[math.random(#self.platforms)]
      self.player.x = p.x + p.w / 2
      self.player.y = p.y - self.player.h / 2
   end
   self.loc:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

   -- Reduce initial enemy count drastically
   for i = 1, 4 do
      self:spawn_on_platform()
   end
end

function Platformer:spawn_on_platform()
   if #self.objects >= self.max_objects then return end

   local platform = self.platforms[math.random(#self.platforms)]
   local obj = {
      x = platform.x + math.random(platform.w - 16),
      y = platform.y - 8 - math.random(32), -- Above platform
      w = 6 + math.random(6),               -- 6-12 pixels
      h = 6 + math.random(6),
      vx = (math.random() - 0.5) * 40,      -- Reduced speed
      vy = 0,
      grounded = false,
      lifetime = 0, -- Track how long enemy has been alive
      type = "enemy",
      color = 8 + math.random(7),
   }

   table.insert(self.objects, obj)
   self.loc:add(obj, obj.x, obj.y, obj.w, obj.h)
end

function Platformer:update()
   self:handle_player_input()
   self:process_pending_removal()
   self:update_player_physics()
   self:handle_player_platform_collision()
   self.loc:update(self.player, self.player.x, self.player.y, self.player.w, self.player.h)
   self:update_enemies()
   self:update_spawn()
   self:handle_player_stomp()
   self.draw_info = {"Enemies: "..tostring(#self.objects)}
end

function Platformer:handle_player_input()
   -- Handle platform drop-through
   if btn(3) and self.player.grounded then
      self.player.drop_timer = 0.18 -- About 10 frames at 60fps
      self.player.grounded = false
      self.player.y = self.player.y + 2 -- Nudge down to avoid instant re-collision
   end
   if self.player.drop_timer and self.player.drop_timer > 0 then
      self.player.drop_timer = self.player.drop_timer - fps_time_step
   else
      self.player.drop_timer = 0
   end

   -- Simple player movement (for demo purposes)
   if btn(0) then self.player.vx = -100 end -- Left
   if btn(1) then self.player.vx = 100 end  -- Right
   if not btn(0) and not btn(1) then self.player.vx = 0 end

   -- Double jump logic
   if not self.player._jump_pressed_last then self.player._jump_pressed_last = false end
   local jump_pressed = btn(2)
   if jump_pressed and not self.player._jump_pressed_last and self.player.jumps < self.player.max_jumps then
      self.player.vy = -150
      self.player.jumps = self.player.jumps + 1
   end
   self.player._jump_pressed_last = jump_pressed
end

function Platformer:update_player_physics()
   local gravity = 200

   -- Apply gravity only when not grounded
   if not self.player.grounded then
      self.player.vy = self.player.vy + gravity * fps_time_step
   end

   -- Update player position
   self.player.x = self.player.x + self.player.vx * fps_time_step
   self.player.y = self.player.y + self.player.vy * fps_time_step
end

function Platformer:handle_player_platform_collision()
   -- Player platform collision (skip if dropping through)
   self.player.grounded = false
   if not (self.player.drop_timer and self.player.drop_timer > 0) then
      for _, platform in ipairs(self.platforms) do
         -- Calculate player bounds (center-based)
         local player_bottom = self.player.y + self.player.h / 2
         local player_top = self.player.y - self.player.h / 2
         local player_left = self.player.x - self.player.w / 2
         local player_right = self.player.x + self.player.w / 2
         -- Check if player is overlapping platform horizontally
         if player_right > platform.x and player_left < platform.x + platform.w then
            -- Check if player is landing on top of platform
            if self.player.vy >= 0 and player_bottom >= platform.y and player_top < platform.y then
               self.player.y = platform.y - self.player.h / 2
               self.player.vy = 0
               self.player.grounded = true
               self.player.jumps = 0 -- Reset jumps on landing
               break
            end
         end
      end
   end
end

function Platformer:update_enemies()
   -- Update AI cooldown
   self.query_cooldown = self.query_cooldown - 1
   if self.query_cooldown <= 0 then
      self.query_cooldown = self.query_interval
   end

   -- Remove dead enemies and update living ones
   local to_remove = {}
   for i, obj in ipairs(self.objects) do
      -- Track lifetime
      obj.lifetime = (obj.lifetime or 0) + fps_time_step

      -- Remove enemies that have lived too long or fallen off screen
      if obj.lifetime > 30 or obj.y > 450 then
         self.loc:remove(obj)
         table.insert(to_remove, i)
      else
         -- Update AI with occasional spatial queries for player detection
         if self.query_cooldown == self.query_interval then
            local nearby_player = {}
            if self.perf_profiler then
               nearby_player = self.perf_profiler:measure_query(
                  "fixed_grid",
                  function()
                     return self.loc:query(obj.x - 60, obj.y - 60, 120, 120, function(other)
                        return other == self.player
                     end)
                  end
               )
            else
               nearby_player = self.loc:query(obj.x - 60, obj.y - 60, 120, 120, function(other)
                  return other == self.player
               end)
            end
            obj.player_nearby = next(nearby_player) ~= nil
         end

         -- Smooth AI behavior based on cached player proximity
         if obj.player_nearby and math.random() < 0.3 then
            local dx = self.player.x - obj.x
            if dx > 0 then
               obj.vx = obj.vx + 15 * fps_time_step
            elseif dx < 0 then
               obj.vx = obj.vx - 15 * fps_time_step
            end
         elseif math.random() < 0.05 then
            obj.vx = (math.random() - 0.5) * 30
         else
            obj.vx = obj.vx * 0.95
         end

         -- Apply gravity (always)
         obj.vy = obj.vy + 200 * fps_time_step

         -- Update position
         obj.x = obj.x + obj.vx * fps_time_step
         obj.y = obj.y + obj.vy * fps_time_step

         -- Platform collision (only when falling)
         if obj.vy > 0 then
            obj.grounded = false
            for _, platform in ipairs(self.platforms) do
               if CollisionUtils.check_platform_collision(obj, platform) then
                  obj.y = platform.y - obj.h / 2
                  obj.vy = 0
                  obj.grounded = true
                  break
               end
            end
         end

         -- Simple edge bouncing (reduced energy loss)
         if obj.x < 0 or obj.x > 512 then
            obj.vx = -obj.vx * 0.9
         end

         self.loc:update(obj, obj.x, obj.y, obj.w, obj.h)
      end
   end

   -- Remove dead enemies (in reverse order)
   for i = #to_remove, 1, -1 do
      table.remove(self.objects, to_remove[i])
   end
end

function Platformer:update_spawn()
   -- Spawn new enemies to maintain population (drastically reduced)
   local target_population = 4
   if #self.objects < target_population and math.random() < 0.01 then -- 1% chance per frame
      self:spawn_on_platform()
   end
end

function Platformer:handle_player_stomp()
   -- Player stomp-to-kill mechanic
   for i = #self.objects, 1, -1 do
      local obj = self.objects[i]
      -- Only check if player is falling
      if self.player.vy > 0 then
         -- Check AABB overlap
         local px1 = self.player.x - self.player.w / 2
         local px2 = self.player.x + self.player.w / 2
         local py2 = self.player.y + self.player.h / 2
         local ox1 = obj.x - obj.w / 2
         local ox2 = obj.x + obj.w / 2
         local oy1 = obj.y - obj.h / 2
         if px2 > ox1 and px1 < ox2 and py2 > oy1 and py2 < obj.y then
            -- Stomped!
            self.loc:remove(obj)
            table.remove(self.objects, i)
            self.player.vy = -120 -- Bounce up after stomp
         end
      end
   end
end

function Platformer:process_pending_removal()
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

function Platformer:draw()
   -- Draw platforms
   for _, platform in ipairs(self.platforms) do
      rectfill(platform.x, platform.y, platform.x + platform.w, platform.y + platform.h, 5)
   end

   -- Draw objects
   for _, obj in ipairs(self.objects) do
      rectfill(obj.x - obj.w / 2, obj.y - obj.h / 2, obj.x + obj.w / 2, obj.y + obj.h / 2, obj.color)
   end

   -- Draw player
   rectfill(self.player.x - self.player.w / 2, self.player.y - self.player.h / 2,
      self.player.x + self.player.w / 2, self.player.y + self.player.h / 2, 11)
end

function Platformer:get_objects()
   local all_objects = {self.player}
   for _, obj in ipairs(self.objects) do
      table.insert(all_objects, obj)
   end
   return all_objects
end

return Platformer
