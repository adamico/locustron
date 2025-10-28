-- Collision Detection Utilities
-- Common collision detection functions for game scenarios

local CollisionUtils = {}

--- Check axis-aligned bounding box collision between two objects
--- @param obj1 table First object with x, y, w, h properties
--- @param obj2 table Second object with x, y, w, h properties
--- @return boolean True if objects collide
function CollisionUtils.check_aabb(obj1, obj2)
   local collides = false
   if obj1.x < obj2.x + obj2.w
      and obj2.x < obj1.x + obj1.w
      and obj1.y < obj2.y + obj2.h
      and obj2.y < obj1.y + obj1.h
   then
      collides = true
   end
   return collides
end

--- Check collision between an object and a platform (axis-aligned)
--- @param obj table Object with x, y, w, h properties
--- @param platform table Platform with x, y, w, h properties
--- @return boolean True if object collides with platform
function CollisionUtils.check_platform_collision(obj, platform)
   local collides = false
   if obj.x + obj.w / 2 > platform.x
      and obj.x - obj.w / 2 < platform.x + platform.w
      and obj.y + obj.h / 2 > platform.y
      and obj.y - obj.h / 2 < platform.y + platform.h
   then
      collides = true
   end
   return collides
end

return CollisionUtils
