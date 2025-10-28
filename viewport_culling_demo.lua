--- Viewport Culling Demo
-- Demonstrates the viewport culling system integration with Locustron

local Locustron = require("src.locustron")
local ViewportCulling = require("src.integration.viewport_culling")

-- Create spatial partitioning system
local spatial = Locustron.create({
   strategy = "fixed_grid",
   config = {cell_size = 32}
})

-- Create viewport culling system
local culling = ViewportCulling.create(spatial)

-- Simulate a game scene with many objects
print("Setting up demo scene...")

local objects = {}
for i = 1, 100 do
   local obj = {id = i, type = "enemy"}
   -- Place objects in a 1000x1000 world
   local x = (i % 10) * 100 + math.random(-20, 20)
   local y = math.floor(i / 10) * 100 + math.random(-20, 20)
   spatial:add(obj, x, y, 16, 16)
   objects[i] = obj
end

print("Added "..spatial:count().." objects to spatial system")

-- Simulate camera movement and viewport culling
local camera_positions = {
   {x = 0,   y = 0,   name = "Top-left corner"},
   {x = 400, y = 300, name = "Center area"},
   {x = 800, y = 600, name = "Bottom-right corner"}
}

for _, cam in ipairs(camera_positions) do
   print("\n--- "..cam.name.." ---")

   -- Update viewport to camera position
   culling:update_viewport(cam.x, cam.y, 400, 300)

   -- Get visible objects
   local visible = culling:get_visible_objects()

   -- Get statistics
   local stats = culling:get_stats()

   print(string.format("Camera at (%.0f, %.0f)", cam.x, cam.y))
   print(string.format("Total objects: %d", stats.total_objects))
   print(string.format("Visible objects: %d", stats.visible_objects))
   print(string.format("Culled objects: %d", stats.culled_objects))
   print(string.format("Cull ratio: %.2f%%", stats.cull_ratio * 100))
   print(string.format("Query count: %d", stats.query_count))
end

-- Demonstrate object visibility checking
print("\n--- Individual Object Visibility ---")
local test_obj = objects[50]                -- Object somewhere in the middle
culling:update_viewport(400, 300, 400, 300) -- Center viewport

local obj_x, obj_y = spatial:get_bbox(test_obj)
print(string.format("Test object at (%.0f, %.0f)", obj_x, obj_y))
print("Is potentially visible: "..tostring(culling:is_potentially_visible(test_obj)))

-- Move viewport away from object
culling:update_viewport(0, 0, 200, 150)
print("After moving viewport to (0,0): "..tostring(culling:is_potentially_visible(test_obj)))

print("\nViewport culling demo complete!")
