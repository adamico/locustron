-- Platformer Scene
-- Objects in a bounded level with some clustering around platforms


local CollisionUtils = require("demo_src.collision_utils")
local fps_time_step = 1 / 60

local Platformer = SceneManager:addState("Platformer")

local enemy_acceleration = 120

function Platformer:initialize(config)
   SceneManager.initialize(self, config)
end

function Platformer:enteredState()
   -- Initialize platformer specific properties
   self.name = "Platformer Level"
   self.description = "Objects in bounded level with clustering around platforms"
   self.controls = "Move: LEFT, RIGHT, Jump: UP"
   self.optimal_strategy = "fixed_grid"

   -- Platform constants
   self.platform_height = 16

   -- Scenario-specific state
   self.platforms = {}
   self.player = {
      x = 256,
      y = 100,
      w = 8,
      h = 16,
      vx = 0,
      vy = 0,
      grounded = false,
      jumps = 0,
      max_jumps = 2,
      drop_timer = 0,
      drop_velocity = 0,
      health = 3,
      max_health = 3,
      invulnerability_timer = 0,
      blink_timer = 0,
      knockback_timer = 0
   }
   self.query_cooldown = 0
   self.query_interval = 6 -- Perform spatial queries every 6 frames
end

function Platformer:init(loc, perf_profiler)
   -- Call parent init
   self.loc = loc

   self.player.health = self.player.max_health
   -- Generate platforms spread across screen width, accessible with double jump
   self.platforms = {}
   local num_platforms = 5 + math.random(3)                                    -- 5-7 platforms (increased minimum)
   local screen_width = 480
   local section_width = screen_width / num_platforms
   
   for i = 1, num_platforms do
      local w = 50 + math.random(60)                                           -- width 50-110 (slightly smaller for better spread)
      local h = self.platform_height                                           -- constant height
      
      -- Try to find a non-overlapping position using spatial queries
      local max_attempts = 10
      local placed = false
      local platform = nil
      
      for attempt = 1, max_attempts do
         -- Spread platforms across screen width with some randomization
         local section_start = (i - 1) * section_width + 16
         local section_end = i * section_width - w - 16
         -- Ensure section_end > section_start to avoid math.random errors
         section_end = math.max(section_end, section_start + 1)
         local x = section_start + math.random(section_end - section_start)
         
         -- Vertical positioning with much more randomness (no longer linear progression)
         local min_y = 60
         local max_y = 250
         local y = min_y + math.random() * (max_y - min_y)  -- Random y position across full range
         
         -- Check for overlaps with existing platforms using spatial query
         local overlapping = self.loc:query(x - 5, y - 5, w + 10, h + 10, function(other)
            return other.type == "platform"
         end)
         
         -- If no overlaps found, place the platform
         if not next(overlapping) then
            platform = {x = x, y = y, w = w, h = h, type = "platform"}
            table.insert(self.platforms, platform)
            self.loc:add(platform, x, y, w, h)
            placed = true
            break
         end
      end
      
      -- If we couldn't find a non-overlapping position after max attempts, place it anyway
      if not placed then
         local section_start = (i - 1) * section_width + 16
         local section_end = i * section_width - w - 16
         section_end = math.max(section_end, section_start + 1)
         local x = section_start + math.random(section_end - section_start)
         local min_y = 60
         local max_y = 250
         local y = min_y + math.random() * (max_y - min_y)
         
         platform = {x = x, y = y, w = w, h = h, type = "platform"}
         table.insert(self.platforms, platform)
         self.loc:add(platform, x, y, w, h)
      end
   end

   -- Initialize/reset game state
   self.objects = {}
   self.pending_removal = {}

   self.loc:clear()

   self:reset_player()

   -- Reduce initial enemy count drastically
   for i = 1, 4 do
      self:spawn_on_platform()
   end
end

function Platformer:spawn_on_platform()
   if #self.objects >= self.max_objects then return end

   -- Try up to 10 times to find a suitable spawn location
   for attempt = 1, 10 do
      local platform = self.platforms[math.random(#self.platforms)]
      local spawn_x = platform.x + math.random(platform.w - 16)
      local spawn_y = platform.y - 8 - math.random(32)

      -- Check distance from player
      local dx = spawn_x - self.player.x
      local dy = spawn_y - self.player.y
      local distance = math.sqrt(dx * dx + dy * dy)

      -- Only spawn if far enough from player (at least 80 pixels)
      if distance >= 80 then
         local obj = {
            x = spawn_x,
            y = spawn_y,
            w = 6 + math.random(6),          -- 6-12 pixels
            h = 6 + math.random(6),
            vx = (math.random() - 0.5) * 40, -- Reduced speed
            vy = 0,
            grounded = false,
            lifetime = 0, -- Track how long enemy has been alive
            type = "enemy",
            color = 8 + math.random(7),
         }

         table.insert(self.objects, obj)
         self.loc:add(obj, obj.x, obj.y, obj.w, obj.h)
         return -- Successfully spawned
      end
   end
   -- If we couldn't find a suitable location after 10 attempts, don't spawn
end

function Platformer:update()
   if keyp("r", true) then self:init(self.loc) end

   self:handle_player_input()
   self:handle_enemy_player_collision()  -- Check collision BEFORE physics update
   self:process_pending_removal()
   self:update_player_physics()
   self:handle_player_platform_collision()
   self.loc:update(self.player, self.player.x, self.player.y, self.player.w, self.player.h)
   self:update_enemies()
   self:update_spawn()
   self:handle_player_stomp()
   self.draw_info = {
      "Enemies: "..tostring(#self.objects),
      "Health: "..tostring(self.player.health)
   }
end

function Platformer:handle_player_input()
   -- Update invulnerability timer
   if self.player.invulnerability_timer > 0 then
      self.player.invulnerability_timer = self.player.invulnerability_timer - fps_time_step
      self.player.blink_timer = self.player.blink_timer + fps_time_step
   else
      self.player.invulnerability_timer = 0
      self.player.blink_timer = 0
   end

   -- Update knockback timer
   if self.player.knockback_timer > 0 then
      self.player.knockback_timer = self.player.knockback_timer - fps_time_step
   else
      self.player.knockback_timer = 0
   end

   -- Handle platform drop-through
   if btn(3) and self.player.grounded then
      self.player.grounded = false
      self.player.drop_velocity = 20 -- Start with small initial velocity
      self.player.drop_timer = 0.3   -- Allow dropping for 0.3 seconds
   end

   -- Update drop timer
   if self.player.drop_timer and self.player.drop_timer > 0 then
      self.player.drop_timer = self.player.drop_timer - fps_time_step
      if self.player.drop_timer <= 0 then
         self.player.drop_timer = 0
         self.player.drop_velocity = 0 -- Stop dropping
      end
   end

   -- Simple player movement (for demo purposes) - only if not in knockback
   if self.player.knockback_timer <= 0 then
      if btn(0) then self.player.vx = -100 end -- Left
      if btn(1) then self.player.vx = 100 end  -- Right
      if not btn(0) and not btn(1) then self.player.vx = 0 end
   end

   -- Double jump logic - only if not in knockback
   if self.player.knockback_timer <= 0 then
      if not self.player._jump_pressed_last then self.player._jump_pressed_last = false end
      local jump_pressed = btn(2)
      if jump_pressed and not self.player._jump_pressed_last and self.player.jumps < self.player.max_jumps then
         self.player.vy = -150
         self.player.jumps = self.player.jumps + 1
      end
      self.player._jump_pressed_last = jump_pressed
   end
end

function Platformer:update_player_physics()
   local gravity = 200
   local drop_acceleration = 200 -- Reduced acceleration for more controlled drop

   -- Apply gravity only when not grounded and not dropping through
   if not self.player.grounded and self.player.drop_velocity == 0 then
      self.player.vy = self.player.vy + gravity * fps_time_step
   elseif self.player.drop_velocity > 0 then
      -- Apply acceleration for smooth platform drop-through with increasing speed
      self.player.drop_velocity = self.player.drop_velocity + drop_acceleration * fps_time_step
      self.player.vy = self.player.drop_velocity
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

   -- Update living enemies (dead ones are handled by pending_removal)
   for i, obj in ipairs(self.objects) do
      -- Track lifetime
      obj.lifetime = (obj.lifetime or 0) + fps_time_step

      -- Mark enemies for removal that have lived too long or fallen off screen
      if obj.lifetime > 30 or obj.y > 450 then
         table.insert(self.pending_removal, {obj = obj, index = i})
      else
         -- Update AI with occasional spatial queries for player detection
         if self.query_cooldown == self.query_interval then
            local nearby_player = {}
            if self.perf_profiler then
               nearby_player = self.perf_profiler:measure_query("fixed_grid", function()
                     return self.loc:query(obj.x - 80, obj.y - 80, 160, 160, function(other)
                        return other == self.player
                     end)
                  end
               )
            else
               nearby_player = self.loc:query(obj.x - 80, obj.y - 80, 160, 160, function(other)
                  return other == self.player
               end)
            end
            obj.player_nearby = next(nearby_player) ~= nil
         end

         -- Aggressive AI behavior based on cached player proximity
         if obj.player_nearby then
            -- High chance to aggressively pursue player
            if math.random() < 0.7 then
               local dx = self.player.x - obj.x
               if dx > 0 then
                  obj.vx = obj.vx + enemy_acceleration * fps_time_step
               elseif dx < 0 then
                  obj.vx = obj.vx - enemy_acceleration * fps_time_step
               end
            end
            -- Reduced random movement when chasing player
            obj.vx = obj.vx * 0.98 -- Less friction when pursuing
         else
            -- Normal behavior when player not nearby
            if math.random() < 0.05 then
               obj.vx = (math.random() - 0.5) * 30
            else
               obj.vx = obj.vx * 0.95
            end
         end

         -- Apply gravity (always)
         obj.vy = obj.vy + 200 * fps_time_step

         -- Update position
         obj.x = obj.x + obj.vx * fps_time_step
         obj.y = obj.y + obj.vy * fps_time_step

         -- Update spatial structure immediately after position update
         self.loc:update(obj, obj.x, obj.y, obj.w, obj.h)

         -- Enemy-to-enemy collision using spatial query (bumping)
         local nearby_enemies = self.loc:query(
            obj.x - obj.w * 1.5, obj.y - obj.h * 1.5,
            obj.w * 3, obj.h * 3,
            function(other)
               return other ~= obj and other.type == "enemy"
            end
         )

         for other in pairs(nearby_enemies) do
            -- Check collision using CollisionUtils (center-based coordinates)
            if CollisionUtils.check_center_aabb(obj, other) then
               -- Collision detected - bump each other
               local dx = obj.x - other.x
               local dy = obj.y - other.y

               -- Normalize direction and apply bump force
               local dist = math.sqrt(dx * dx + dy * dy)
               if dist > 0 then
                  dx = dx / dist
                  dy = dy / dist

                  -- Apply bump velocity (stronger force for fast-moving enemies)
                  local bump_force = 100
                  obj.vx = obj.vx + dx * bump_force * fps_time_step
                  obj.vy = obj.vy + dy * bump_force * fps_time_step
                  other.vx = other.vx - dx * bump_force * fps_time_step
                  other.vy = other.vy - dy * bump_force * fps_time_step
               end
            end
         end

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

         -- Spatial structure already updated above
      end
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
         -- Check AABB overlap for stomp (player landing on enemy from above)
         local px1 = self.player.x - self.player.w / 2
         local px2 = self.player.x + self.player.w / 2
         local py1 = self.player.y - self.player.h / 2
         local py2 = self.player.y + self.player.h / 2
         local ox1 = obj.x - obj.w / 2
         local ox2 = obj.x + obj.w / 2
         local oy1 = obj.y - obj.h / 2
         local oy2 = obj.y + obj.h / 2

         -- Player must be falling, overlap horizontally, and player's bottom must be near enemy's top
         if px2 > ox1 and px1 < ox2 and py2 >= oy1 - 2 and py2 <= oy1 + 8 and py1 < oy1 then
            -- Stomped! Mark for removal
            table.insert(self.pending_removal, {obj = obj, index = i})
            self.player.vy = -120 -- Bounce up after stomp
         end
      end
   end
end

function Platformer:handle_enemy_player_collision()
   -- Enemy damage to player (only if not invulnerable)
   if self.player.invulnerability_timer <= 0 then
      for _, obj in ipairs(self.objects) do
         if obj.type == "enemy" then
            -- Check AABB overlap
            local px1 = self.player.x - self.player.w / 2
            local px2 = self.player.x + self.player.w / 2
            local py1 = self.player.y - self.player.h / 2
            local py2 = self.player.y + self.player.h / 2
            local ox1 = obj.x - obj.w / 2
            local ox2 = obj.x + obj.w / 2
            local oy1 = obj.y - obj.h / 2
            local oy2 = obj.y + obj.h / 2

            if px2 > ox1 and px1 < ox2 and py2 > oy1 and py1 < oy2 then
               -- Player takes damage
               self.player.health = self.player.health - 1
               self.player.invulnerability_timer = 1.5 -- 1.5 seconds of invulnerability
               self.player.blink_timer = 0
               self.player.knockback_timer = 0.5 -- 0.5 seconds of knockback

               -- Push player in the direction the enemy is moving
               local enemy_speed = math.sqrt(obj.vx * obj.vx + obj.vy * obj.vy)
               if enemy_speed > 0 then
                  -- Normalize enemy velocity and apply push force
                  local push_force = 120
                  self.player.vx = (obj.vx / enemy_speed) * push_force
                  self.player.vy = (obj.vy / enemy_speed) * push_force + 30  -- Add upward boost
               else
                  -- Enemy not moving, fallback to basic knockback
                  local dx = self.player.x - obj.x
                  if dx > 0 then
                     self.player.vx = 120
                  else
                     self.player.vx = -120
                  end
                  self.player.vy = -30
               end

               -- Check for death
               if self.player.health <= 0 then
                  self:init(self.loc)
               end
               break -- Only take damage from one enemy at a time
            end
         end
      end
   end
end

function Platformer:reset_player()
   self.player.health = self.player.max_health
   self.player.invulnerability_timer = 0
   self.player.blink_timer = 0
   self.player.knockback_timer = 0
   self.player.vx = 0
   self.player.vy = 0
   self.player.jumps = 0
   self.player.drop_timer = 0
   self.player.drop_velocity = 0

   -- Place player on a random platform
   if #self.platforms > 0 then
      local p = self.platforms[math.random(#self.platforms)]
      self.player.x = p.x + p.w / 2
      self.player.y = p.y - self.player.h / 2
      self.player.grounded = true
   end
   self.loc:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)
end

function Platformer:process_pending_removal()
   -- Process pending removal for both spatial structure and array cleanup
   local indices_to_remove = {}
   for _, removal in ipairs(self.pending_removal) do
      -- Remove from spatial structure
      self.loc:remove(removal.obj)
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

   -- Draw player (with blinking during invulnerability)
   local should_draw_player = true
   if self.player.invulnerability_timer > 0 then
      -- Blink every 0.1 seconds
      should_draw_player = math.floor(self.player.blink_timer * 10) % 2 == 0
   end

   if should_draw_player then
      rectfill(self.player.x - self.player.w / 2, self.player.y - self.player.h / 2,
         self.player.x + self.player.w / 2, self.player.y + self.player.h / 2, 11)
   end
end

function Platformer:get_objects()
   local all_objects = {self.player}
   for _, obj in ipairs(self.objects) do
      table.insert(all_objects, obj)
   end
   return all_objects
end

return Platformer
