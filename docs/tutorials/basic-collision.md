# Basic Collision Detection Tutorial

This tutorial teaches the fundamentals of using spatial partitioning for efficient collision detection in games.

## What You'll Learn

- How spatial queries improve collision detection performance
- Basic broad-phase vs narrow-phase collision detection
- Implementing collision detection in a simple game

## Prerequisites

- Basic Lua knowledge
- Understanding of game loops and object movement
- Completed the [Getting Started Guide](../guides/getting-started.md)

## Step 1: Setting Up

Create a new Picotron cartridge with this basic structure:

```lua
function _init()
  -- Initialize game state
  player = {
    x = 64, y = 64,
    w = 16, h = 16,
    vx = 0, vy = 0
  }

  -- Create some obstacles
  obstacles = {}
  for i = 1, 10 do
    table.insert(obstacles, {
      x = math.random(0, 120),
      y = math.random(0, 120),
      w = 16, h = 16
    })
  end

  -- Initialize spatial partitioning
  loc = locustron(32)  -- 32px grid cells

  -- Add player and obstacles to spatial structure
  loc.add(player, player.x, player.y, player.w, player.h)
  for _, obs in ipairs(obstacles) do
    loc.add(obs, obs.x, obs.y, obs.w, obs.h)
  end
end
```

## Step 2: Basic Movement

Add player movement without collision detection first:

```lua
function _update()
  -- Handle input
  player.vx = 0
  player.vy = 0

  if btn(0) then player.vx = -2 end  -- Left
  if btn(1) then player.vx = 2 end   -- Right
  if btn(2) then player.vy = -2 end  -- Up
  if btn(3) then player.vy = 2 end   -- Down

  -- Apply movement
  player.x = player.x + player.vx
  player.y = player.y + player.vy

  -- Keep player in bounds
  player.x = mid(0, player.x, 128 - player.w)
  player.y = mid(0, player.y, 128 - player.h)

  -- Update player in spatial structure
  loc.update(player, player.x, player.y, player.w, player.h)
end
```

## Step 3: Broad-Phase Collision Detection

Now add collision detection using spatial queries:

```lua
function check_collisions()
  -- Query area around player (broad phase)
  local nearby = loc.query(
    player.x - 16, player.y - 16,  -- Query position
    48, 48                        -- Query size (player + buffer)
  )

  -- Check precise collisions (narrow phase)
  for obj in pairs(nearby) do
    if obj ~= player and collides(player, obj) then
      -- Handle collision
      handle_collision(player, obj)
    end
  end
end

function collides(a, b)
  -- Axis-Aligned Bounding Box (AABB) collision
  return a.x < b.x + b.w and
         a.x + a.w > b.x and
         a.y < b.y + b.h and
         a.y + a.h > b.y
end

function handle_collision(player, obstacle)
  -- Simple collision response: move player back
  player.x = player.x - player.vx
  player.y = player.y - player.vy

  -- Update spatial structure
  loc.update(player, player.x, player.y, player.w, player.h)
end
```

Update the game loop to include collision checking:

```lua
function _update()
  -- Handle input
  player.vx = 0
  player.vy = 0

  if btn(0) then player.vx = -2 end
  if btn(1) then player.vx = 2 end
  if btn(2) then player.vy = -2 end
  if btn(3) then player.vy = 2 end

  -- Calculate new position
  local new_x = player.x + player.vx
  local new_y = player.y + player.vy

  -- Keep in bounds
  new_x = mid(0, new_x, 128 - player.w)
  new_y = mid(0, new_y, 128 - player.h)

  -- Try moving to new position
  player.x = new_x
  player.y = new_y

  -- Check for collisions
  check_collisions()

  -- Update spatial structure
  loc.update(player, player.x, player.y, player.w, player.h)
end
```

## Step 4: Rendering

Add rendering to visualize the collision system:

```lua
function _draw()
  cls(1)  -- Clear screen with dark blue

  -- Draw obstacles
  for _, obs in ipairs(obstacles) do
    rectfill(obs.x, obs.y, obs.x + obs.w, obs.y + obs.h, 8)  -- Red
  end

  -- Draw player
  rectfill(player.x, player.y, player.x + player.w, player.y + player.h, 11)  -- Green

  -- Debug: Show query region
  if btn(4) then  -- Hold Z to show debug info
    -- Draw query region
    local qx, qy, qw, qh = player.x - 16, player.y - 16, 48, 48
    rect(qx, qy, qx + qw, qy + qh, 7)  -- White outline

    -- Count objects in query
    local nearby = loc.query(qx, qy, qw, qh)
    local count = 0
    for _ in pairs(nearby) do count = count + 1 end

    print("Query objects: " .. count, 2, 2, 7)
    print("Total objects: " .. (#obstacles + 1), 2, 10, 7)
  end
end
```

## Step 5: Understanding Performance

Run the game and observe the performance difference:

1. **Without spatial partitioning**: Would check player vs all 10 obstacles = 10 checks
2. **With spatial partitioning**: Only checks objects in nearby cells = ~2-4 checks

The debug view (hold Z) shows how many objects are actually checked vs the total.

## Step 6: Advanced Collision Response

Improve the collision response for better gameplay:

```lua
function handle_collision(player, obstacle)
  -- Calculate overlap on each axis
  local overlap_x = min(
    player.x + player.w - obstacle.x,  -- Player right vs obstacle left
    obstacle.x + obstacle.w - player.x -- Obstacle right vs player left
  )

  local overlap_y = min(
    player.y + player.h - obstacle.y,  -- Player bottom vs obstacle top
    obstacle.y + obstacle.h - player.y -- Obstacle bottom vs player top
  )

  -- Resolve collision on axis with smallest overlap
  if overlap_x < overlap_y then
    -- Horizontal collision
    if player.x < obstacle.x then
      player.x = obstacle.x - player.w  -- Move left of obstacle
    else
      player.x = obstacle.x + obstacle.w  -- Move right of obstacle
    end
  else
    -- Vertical collision
    if player.y < obstacle.y then
      player.y = obstacle.y - player.h  -- Move above obstacle
    else
      player.y = obstacle.y + obstacle.h  -- Move below obstacle
    end
  end

  -- Reset velocity on collision axis
  if overlap_x < overlap_y then
    player.vx = 0
  else
    player.vy = 0
  end
end
```

## Complete Code

Here's the complete tutorial code:

```lua
-- Basic Collision Detection Tutorial

function _init()
  player = {
    x = 64, y = 64,
    w = 16, h = 16,
    vx = 0, vy = 0
  }

  obstacles = {}
  for i = 1, 10 do
    table.insert(obstacles, {
      x = math.random(0, 112),
      y = math.random(0, 112),
      w = 16, h = 16
    })
  end

  loc = locustron(32)

  loc.add(player, player.x, player.y, player.w, player.h)
  for _, obs in ipairs(obstacles) do
    loc.add(obs, obs.x, obs.y, obs.w, obs.h)
  end
end

function _update()
  player.vx = 0
  player.vy = 0

  if btn(0) then player.vx = -2 end
  if btn(1) then player.vx = 2 end
  if btn(2) then player.vy = -2 end
  if btn(3) then player.vy = 2 end

  local new_x = player.x + player.vx
  local new_y = player.y + player.vy

  new_x = mid(0, new_x, 128 - player.w)
  new_y = mid(0, new_y, 128 - player.h)

  player.x = new_x
  player.y = new_y

  check_collisions()
  loc.update(player, player.x, player.y, player.w, player.h)
end

function check_collisions()
  local nearby = loc.query(
    player.x - 16, player.y - 16,
    48, 48
  )

  for obj in pairs(nearby) do
    if obj ~= player and collides(player, obj) then
      handle_collision(player, obj)
    end
  end
end

function collides(a, b)
  return a.x < b.x + b.w and
         a.x + a.w > b.x and
         a.y < b.y + b.h and
         a.y + a.h > b.y
end

function handle_collision(player, obstacle)
  local overlap_x = min(
    player.x + player.w - obstacle.x,
    obstacle.x + obstacle.w - player.x
  )

  local overlap_y = min(
    player.y + player.h - obstacle.y,
    obstacle.y + obstacle.h - player.y
  )

  if overlap_x < overlap_y then
    if player.x < obstacle.x then
      player.x = obstacle.x - player.w
    else
      player.x = obstacle.x + obstacle.w
    end
    player.vx = 0
  else
    if player.y < obstacle.y then
      player.y = obstacle.y - player.h
    else
      player.y = obstacle.y + obstacle.h
    end
    player.vy = 0
  end
end

function _draw()
  cls(1)

  for _, obs in ipairs(obstacles) do
    rectfill(obs.x, obs.y, obs.x + obs.w, obs.y + obs.h, 8)
  end

  rectfill(player.x, player.y, player.x + player.w, player.y + player.h, 11)

  if btn(4) then
    local qx, qy, qw, qh = player.x - 16, player.y - 16, 48, 48
    rect(qx, qy, qx + qw, qy + qh, 7)

    local nearby = loc.query(qx, qy, qw, qh)
    local count = 0
    for _ in pairs(nearby) do count = count + 1 end

    print("Query objects: " .. count, 2, 2, 7)
    print("Total objects: " .. (#obstacles + 1), 2, 10, 7)
  end
end
```

## What You Learned

- **Broad-phase collision detection**: Using spatial queries to find potential collisions
- **Narrow-phase collision detection**: Precise collision checking with AABB
- **Collision response**: Proper handling of collision resolution
- **Performance benefits**: Spatial partitioning reduces collision checks from O(n²) to O(k)
- **Debug visualization**: Tools to understand what's happening under the hood

## Next Steps

- Try the [Viewport Culling Tutorial](viewport-culling.md) for rendering optimization
- Experiment with different spatial strategies in the [Strategy Selection Guide](../guides/strategy-selection.md)
- Look at complete game examples in the [Examples](../examples/) directory
