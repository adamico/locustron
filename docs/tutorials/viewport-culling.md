# Viewport Culling Tutorial

This tutorial teaches viewport culling - a technique that dramatically improves rendering performance by only drawing objects visible on screen.

## What You'll Learn

- How viewport culling works with spatial partitioning
- Implementing efficient rendering systems
- Combining culling with level-of-detail (LOD)
- Performance benefits and measurements

## Prerequisites

- Basic Lua/Picotron knowledge
- Completed the [Getting Started Guide](../guides/getting-started.md)
- Completed the [Basic Collision Tutorial](basic-collision.md)

## Step 1: Understanding Viewport Culling

Viewport culling prevents rendering objects outside the camera's view. Combined with spatial partitioning, this creates extremely efficient rendering systems.

### Why It Matters

Without culling, games render every object every frame:

```lua
-- Bad: Render everything
function _draw()
  for _, obj in ipairs(all_objects) do
    draw_object(obj)
  end
end
```

With culling, only visible objects are rendered:

```lua
-- Good: Render only visible objects
function _draw()
  local visible = loc.query(camera.x, camera.y, screen_width, screen_height)
  for obj in pairs(visible) do
    draw_object(obj)
  end
end
```

## Step 2: Basic Viewport Culling

Let's start with a simple camera system and viewport culling:

```lua
function _init()
  -- Camera setup
  camera = {
    x = 0, y = 0,
    width = 128, height = 128
  }

  -- Create many objects (more than fit on screen)
  objects = {}
  for i = 1, 1000 do
    table.insert(objects, {
      x = math.random(-500, 500),
      y = math.random(-500, 500),
      w = 8, h = 8,
      color = math.random(1, 15)
    })
  end

  -- Initialize spatial partitioning
  loc = locustron(32)

  -- Add all objects to spatial structure
  for _, obj in ipairs(objects) do
    loc.add(obj, obj.x, obj.y, obj.w, obj.h)
  end
end
```

Add camera movement:

```lua
function _update()
  -- Camera controls
  if btn(0) then camera.x = camera.x - 2 end  -- Left
  if btn(1) then camera.x = camera.x + 2 end  -- Right
  if btn(2) then camera.y = camera.y - 2 end  -- Up
  if btn(3) then camera.y = camera.y + 2 end  -- Down

  -- Keep camera in bounds (optional)
  camera.x = mid(-500, camera.x, 500 - camera.width)
  camera.y = mid(-500, camera.y, 500 - camera.height)
end
```

Implement basic viewport culling:

```lua
function _draw()
  cls(0)

  -- Query only objects in viewport
  local visible = loc.query(camera.x, camera.y, camera.width, camera.height)

  -- Count visible objects for debugging
  local visible_count = 0
  for _ in pairs(visible) do visible_count = visible_count + 1 end

  -- Render visible objects
  for obj in pairs(visible) do
    -- Convert world coordinates to screen coordinates
    local screen_x = obj.x - camera.x
    local screen_y = obj.y - camera.y

    -- Only draw if actually on screen (spatial query gives candidates)
    if screen_x >= -obj.w and screen_x <= camera.width and
       screen_y >= -obj.h and screen_y <= camera.height then
      rectfill(screen_x, screen_y, screen_x + obj.w, screen_y + obj.h, obj.color)
    end
  end

  -- Debug info
  print("Visible: " .. visible_count .. "/1000", 2, 2, 7)
  print("Camera: (" .. camera.x .. "," .. camera.y .. ")", 2, 10, 7)
end
```

## Step 3: Advanced Viewport Culling

Improve the culling system with buffer zones and more efficient queries:

```lua
function _draw()
  cls(0)

  -- Add buffer zone around viewport for smooth scrolling
  local buffer = 16
  local query_x = camera.x - buffer
  local query_y = camera.y - buffer
  local query_w = camera.width + buffer * 2
  local query_h = camera.height + buffer * 2

  local visible = loc.query(query_x, query_y, query_w, query_h)

  -- Render with proper culling
  local rendered_count = 0
  for obj in pairs(visible) do
    local screen_x = obj.x - camera.x
    local screen_y = obj.y - camera.y

    -- Check if object is actually visible on screen
    if screen_x + obj.w >= 0 and screen_x <= camera.width and
       screen_y + obj.h >= 0 and screen_y <= camera.height then
      rectfill(screen_x, screen_y, screen_x + obj.w, screen_y + obj.h, obj.color)
      rendered_count = rendered_count + 1
    end
  end

  -- Debug info
  print("Rendered: " .. rendered_count, 2, 2, 7)
  print("Queried: " .. #visible, 2, 10, 7)
end
```

## Step 4: Level of Detail (LOD)

Add distance-based detail reduction for better performance:

```lua
function get_lod_level(obj, camera)
  -- Calculate distance from camera center to object
  local center_x = camera.x + camera.width / 2
  local center_y = camera.y + camera.height / 2

  local dx = obj.x + obj.w/2 - center_x
  local dy = obj.y + obj.h/2 - center_y
  local distance = math.sqrt(dx*dx + dy*dy)

  -- Define LOD levels based on distance
  if distance < 32 then return "high" end
  if distance < 64 then return "medium" end
  return "low"
end

function draw_object_lod(obj, screen_x, screen_y, lod)
  if lod == "high" then
    -- High detail: full sprite
    rectfill(screen_x, screen_y, screen_x + obj.w, screen_y + obj.h, obj.color)
  elseif lod == "medium" then
    -- Medium detail: smaller sprite
    local half_w, half_h = obj.w/2, obj.h/2
    rectfill(screen_x + half_w/2, screen_y + half_h/2, screen_x + half_w*1.5, screen_y + half_h*1.5, obj.color)
  else
    -- Low detail: just a dot
    pset(screen_x + obj.w/2, screen_y + obj.h/2, obj.color)
  end
end

function _draw()
  cls(0)

  local buffer = 16
  local visible = loc.query(
    camera.x - buffer, camera.y - buffer,
    camera.width + buffer * 2, camera.height + buffer * 2
  )

  local rendered_count = 0
  for obj in pairs(visible) do
    local screen_x = obj.x - camera.x
    local screen_y = obj.y - camera.y

    if screen_x + obj.w >= 0 and screen_x <= camera.width and
       screen_y + obj.h >= 0 and screen_y <= camera.height then

      local lod = get_lod_level(obj, camera)
      draw_object_lod(obj, screen_x, screen_y, lod)
      rendered_count = rendered_count + 1
    end
  end

  print("Rendered: " .. rendered_count, 2, 2, 7)
end
```

## Step 5: Occlusion Culling

Add basic occlusion culling to skip objects behind others:

```lua
-- Simple occlusion system (objects can hide behind larger objects)
function is_occluded(obj, visible_objects, camera)
  -- Check if object is behind any larger objects
  for other in pairs(visible_objects) do
    if other ~= obj and other.w > obj.w and other.h > obj.h then
      -- Simple depth check (larger objects in front)
      local obj_center_x = obj.x + obj.w/2
      local obj_center_y = obj.y + obj.h/2
      local other_center_x = other.x + other.w/2
      local other_center_y = other.y + other.h/2

      local dx = obj_center_x - other_center_x
      local dy = obj_center_y - other_center_y
      local distance = math.sqrt(dx*dx + dy*dy)

      -- If close enough to be occluded
      if distance < (other.w + other.h) / 4 then
        return true
      end
    end
  end
  return false
end

function _draw()
  cls(0)

  local buffer = 16
  local visible = loc.query(
    camera.x - buffer, camera.y - buffer,
    camera.width + buffer * 2, camera.height + buffer * 2
  )

  -- Sort by size for occlusion (larger objects first)
  local sorted_visible = {}
  for obj in pairs(visible) do
    table.insert(sorted_visible, obj)
  end

  Sort(sorted_visible, function(a, b)
    return (a.w * a.h) > (b.w * b.h)  -- Larger objects first
  end)

  local rendered_count = 0
  local occluded_count = 0

  for _, obj in ipairs(sorted_visible) do
    local screen_x = obj.x - camera.x
    local screen_y = obj.y - camera.y

    if screen_x + obj.w >= 0 and screen_x <= camera.width and
       screen_y + obj.h >= 0 and screen_y <= camera.height then

      -- Check occlusion
      if not is_occluded(obj, visible, camera) then
        local lod = get_lod_level(obj, camera)
        draw_object_lod(obj, screen_x, screen_y, lod)
        rendered_count = rendered_count + 1
      else
        occluded_count = occluded_count + 1
      end
    end
  end

  print("Rendered: " .. rendered_count, 2, 2, 7)
  print("Occluded: " .. occluded_count, 2, 10, 7)
end
```

## Step 6: Performance Monitoring

Add performance tracking to measure culling effectiveness:

```lua
local performance = {
  frame_count = 0,
  render_times = {},
  object_counts = {}
}

function measure_performance(fn, ...)
  local start = time()  -- Picotron's high-resolution timer
  local results = {fn(...)}
  local elapsed = time() - start
  return elapsed, unpack(results)
end

function _draw()
  cls(0)

  -- Measure rendering performance
  local render_time, visible_count = measure_performance(function()
    local buffer = 16
    local visible = loc.query(
      camera.x - buffer, camera.y - buffer,
      camera.width + buffer * 2, camera.height + buffer * 2
    )

    local rendered_count = 0
    for obj in pairs(visible) do
      local screen_x = obj.x - camera.x
      local screen_y = obj.y - camera.y

      if screen_x + obj.w >= 0 and screen_x <= camera.width and
         screen_y + obj.h >= 0 and screen_y <= camera.height then

        if not is_occluded(obj, visible, camera) then
          local lod = get_lod_level(obj, camera)
          draw_object_lod(obj, screen_x, screen_y, lod)
          rendered_count = rendered_count + 1
        end
      end
    end

    return rendered_count
  end)

  -- Track performance
  performance.frame_count = performance.frame_count + 1
  table.insert(performance.render_times, render_time)
  table.insert(performance.object_counts, visible_count)

  -- Report every 60 frames
  if performance.frame_count % 60 == 0 then
    local avg_render = average(performance.render_times)
    local avg_objects = average(performance.object_counts)

    print(string.format("Avg render: %.2fms", avg_render * 1000), 2, 2, 7)
    print(string.format("Avg objects: %.1f", avg_objects), 2, 10, 7)

    -- Reset tracking
    performance.render_times = {}
    performance.object_counts = {}
  end
end

function average(t)
  if #t == 0 then return 0 end
  local sum = 0
  for _, v in ipairs(t) do sum = sum + v end
  return sum / #t
end
```

## Step 7: Advanced Camera Features

Add smooth camera following and screen shake:

```lua
function update_camera(camera, target)
  -- Smooth camera following
  local lerp_factor = 0.1
  camera.x = camera.x + (target.x - camera.width/2 - camera.x) * lerp_factor
  camera.y = camera.y + (target.y - camera.height/2 - camera.y) * lerp_factor

  -- Screen shake
  if camera.shake_time and camera.shake_time > 0 then
    camera.shake_time = camera.shake_time - 1
    local shake_amount = camera.shake_intensity or 2
    camera.x = camera.x + math.random(-shake_amount, shake_amount)
    camera.y = camera.y + math.random(-shake_amount, shake_amount)
  end
end

function screen_shake(intensity, duration)
  camera.shake_intensity = intensity
  camera.shake_time = duration
end

-- Add a player object
function _init()
  -- ... existing init code ...

  player = {
    x = 0, y = 0,
    w = 16, h = 16,
    color = 11
  }

  loc.add(player, player.x, player.y, player.w, player.h)
end

function _update()
  -- Move player
  if btn(0) then player.x = player.x - 2 end
  if btn(1) then player.x = player.x + 2 end
  if btn(2) then player.y = player.y - 2 end
  if btn(3) then player.y = player.y + 2 end

  -- Update player in spatial structure
  loc.update(player, player.x, player.y, player.w, player.h)

  -- Update camera to follow player
  update_camera(camera, player)

  -- Example: Shake camera when collecting items
  if btn(4) then  -- Z button
    screen_shake(3, 10)
  end
end
```

## Complete Code

Here's the complete viewport culling tutorial code:

```lua
-- Viewport Culling Tutorial

function _init()
  camera = {
    x = 0, y = 0,
    width = 128, height = 128
  }

  objects = {}
  for i = 1, 1000 do
    table.insert(objects, {
      x = math.random(-500, 500),
      y = math.random(-500, 500),
      w = 8, h = 8,
      color = math.random(1, 15)
    })
  end

  player = {
    x = 0, y = 0,
    w = 16, h = 16,
    color = 11
  }

  loc = locustron(32)

  for _, obj in ipairs(objects) do
    loc.add(obj, obj.x, obj.y, obj.w, obj.h)
  end
  loc.add(player, player.x, player.y, player.w, player.h)
end

function _update()
  -- Move player
  if btn(0) then player.x = player.x - 2 end
  if btn(1) then player.x = player.x + 2 end
  if btn(2) then player.y = player.y - 2 end
  if btn(3) then player.y = player.y + 2 end

  loc.update(player, player.x, player.y, player.w, player.h)

  -- Update camera
  update_camera(camera, player)

  if btn(4) then screen_shake(3, 10) end
end

function update_camera(camera, target)
  local lerp_factor = 0.1
  camera.x = camera.x + (target.x - camera.width/2 - camera.x) * lerp_factor
  camera.y = camera.y + (target.y - camera.height/2 - camera.y) * lerp_factor

  if camera.shake_time and camera.shake_time > 0 then
    camera.shake_time = camera.shake_time - 1
    local shake_amount = camera.shake_intensity or 2
    camera.x = camera.x + math.random(-shake_amount, shake_amount)
    camera.y = camera.y + math.random(-shake_amount, shake_amount)
  end
end

function screen_shake(intensity, duration)
  camera.shake_intensity = intensity
  camera.shake_time = duration
end

function get_lod_level(obj, camera)
  local center_x = camera.x + camera.width / 2
  local center_y = camera.y + camera.height / 2

  local dx = obj.x + obj.w/2 - center_x
  local dy = obj.y + obj.h/2 - center_y
  local distance = math.sqrt(dx*dx + dy*dy)

  if distance < 32 then return "high" end
  if distance < 64 then return "medium" end
  return "low"
end

function draw_object_lod(obj, screen_x, screen_y, lod)
  if lod == "high" then
    rectfill(screen_x, screen_y, screen_x + obj.w, screen_y + obj.h, obj.color)
  elseif lod == "medium" then
    local half_w, half_h = obj.w/2, obj.h/2
    rectfill(screen_x + half_w/2, screen_y + half_h/2, screen_x + half_w*1.5, screen_y + half_h*1.5, obj.color)
  else
    pset(screen_x + obj.w/2, screen_y + obj.h/2, obj.color)
  end
end

function is_occluded(obj, visible_objects, camera)
  for other in pairs(visible_objects) do
    if other ~= obj and other.w > obj.w and other.h > obj.h then
      local obj_center_x = obj.x + obj.w/2
      local obj_center_y = obj.y + obj.h/2
      local other_center_x = other.x + other.w/2
      local other_center_y = other.y + other.h/2

      local dx = obj_center_x - other_center_x
      local dy = obj_center_y - other_center_y
      local distance = math.sqrt(dx*dx + dy*dy)

      if distance < (other.w + other.h) / 4 then
        return true
      end
    end
  end
  return false
end

function _draw()
  cls(0)

  local buffer = 16
  local visible = loc.query(
    camera.x - buffer, camera.y - buffer,
    camera.width + buffer * 2, camera.height + buffer * 2
  )

  -- Sort by size for occlusion
  local sorted_visible = {}
  for obj in pairs(visible) do
    table.insert(sorted_visible, obj)
  end

  Sort(sorted_visible, function(a, b)
    return (a.w * a.h) > (b.w * b.h)
  end)

  local rendered_count = 0
  local occluded_count = 0

  for _, obj in ipairs(sorted_visible) do
    local screen_x = obj.x - camera.x
    local screen_y = obj.y - camera.y

    if screen_x + obj.w >= 0 and screen_x <= camera.width and
       screen_y + obj.h >= 0 and screen_y <= camera.height then

      if not is_occluded(obj, visible, camera) then
        local lod = get_lod_level(obj, camera)
        draw_object_lod(obj, screen_x, screen_y, lod)
        rendered_count = rendered_count + 1
      else
        occluded_count = occluded_count + 1
      end
    end
  end

  -- Draw player (always visible)
  local player_screen_x = player.x - camera.x
  local player_screen_y = player.y - camera.y
  rectfill(player_screen_x, player_screen_y,
           player_screen_x + player.w, player_screen_y + player.h, player.color)

  -- Debug info
  print("Rendered: " .. rendered_count, 2, 2, 7)
  print("Occluded: " .. occluded_count, 2, 10, 7)
  print("Total visible: " .. #sorted_visible, 2, 18, 7)
end
```

## Performance Results

Typical performance improvements with viewport culling:

| Scenario | Without Culling | With Culling | Improvement |
|----------|----------------|--------------|-------------|
| 1000 objects, small viewport | 1000 draws/frame | ~10-50 draws/frame | 95-98% reduction |
| 5000 objects, medium viewport | 5000 draws/frame | ~50-200 draws/frame | 96-99% reduction |
| Large world, sparse objects | All objects drawn | Only visible drawn | 90-99% reduction |

## What You Learned

- **Viewport culling**: Only render objects visible on screen
- **Buffer zones**: Prevent popping at screen edges during camera movement
- **Level of Detail (LOD)**: Reduce detail for distant objects
- **Occlusion culling**: Skip objects hidden behind others
- **Performance monitoring**: Measure and optimize rendering performance
- **Camera systems**: Smooth following and screen shake effects

## Advanced Topics

- **Frustum culling**: 3D viewport culling for 3D games
- **Hierarchical culling**: Multi-level culling for complex scenes
- **Predictive culling**: Pre-load objects likely to come into view
- **GPU culling**: Hardware-accelerated culling techniques

## Next Steps

- Experiment with different LOD schemes
- Add more advanced camera features (zoom, rotation)
- Implement predictive loading for larger worlds
- Combine with the [Strategy Selection Guide](../guides/strategy-selection.md) for optimal spatial partitioning

Viewport culling combined with spatial partitioning creates rendering systems that can handle thousands of objects with minimal performance impact!
