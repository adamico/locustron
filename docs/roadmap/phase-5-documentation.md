# Phase 5: Documentation & Examples

## Overview

Phase 5 creates comprehensive documentation, tutorials, and examples for the multi-strategy Locustron library. Building on the foundation from Phases 1-4, this phase ensures developers can effectively use and understand the spatial partitioning system before additional strategies are implemented in Phase 6.

---

## Phase 5.1: Comprehensive Documentation

### Objectives

- Create complete API documentation with examples
- Write detailed guides for each spatial partitioning strategy
- Develop migration guides and best practices
- Generate performance optimization guides

### Documentation Structure

```bash
docs/
├── README.md                    # Main project overview
├── api/                        # API Reference
│   ├── README.md               # API overview
│   ├── core-api.md             # Core Locustron API
│   ├── strategies/             # Strategy-specific APIs
│   │   ├── fixed-grid.md
│   │   ├── quadtree.md
│   │   ├── hash-grid.md
│   │   ├── bsp-tree.md
│   │   └── bvh.md
│   └── visualization.md        # Debugging and visualization API
├── guides/                     # User Guides
│   ├── getting-started.md      # Quick start guide
│   ├── strategy-selection.md   # Choosing the right strategy
│   ├── performance-tuning.md   # Optimization guide
│   ├── migration-guide.md      # Upgrading from legacy versions
│   └── troubleshooting.md      # Common issues and solutions
├── tutorials/                  # Step-by-step tutorials
│   ├── basic-collision.md      # Basic collision detection
│   ├── viewport-culling.md     # Viewport culling tutorial
│   ├── dynamic-objects.md      # Moving objects tutorial
│   └── advanced-queries.md     # Complex spatial queries
├── examples/                   # Code examples
│   ├── survivor-like.lua       # Wave-based survival game
│   ├── space-battle.lua        # Large world with objectives
│   ├── platformer.lua          # Bounded level with platforms
│   └── dynamic-ecosystem.lua   # Birth/death object lifecycle
└── reference/                  # Reference materials
    ├── spatial-partitioning.md # Theory and concepts
    ├── performance-data.md     # Benchmark results
    └── algorithm-comparison.md # Strategy comparison matrix
```

### API Documentation Template

### Fixed Grid Strategy API

The Fixed Grid strategy divides space into a regular grid of fixed-size cells. It provides optimal performance for uniform object distributions and bounded worlds.

#### Configuration

```lua
local loc = locustron({
  strategy = "fixed_grid",
  config = {
    cell_size = 32,           -- Grid cell size in pixels
    initial_capacity = 100,   -- Initial object capacity
    growth_factor = 1.5       -- Capacity growth multiplier
  }
})
```

#### Methods

**`add(obj, x, y, w, h)`**

Adds an object to the spatial hash.

**Parameters:**

- `obj` (any): Object reference to store
- `x` (number): Object x-coordinate
- `y` (number): Object y-coordinate
- `w` (number): Object width
- `h` (number): Object height

**Returns:**

- `obj`: The added object reference

**Example:**

```lua
local player = {id = "player", health = 100}
loc.add(player, 100, 150, 16, 32)
```

**`query(x, y, w, h, filter_fn)`**

Queries objects within a rectangular region.

**Parameters:**

- `x` (number): Query region x-coordinate
- `y` (number): Query region y-coordinate
- `w` (number): Query region width
- `h` (number): Query region height
- `filter_fn` (function, optional): Filter function for results

**Returns:**

- `table`: Hash table of objects `{[obj] = true}`

**Example:**

```lua
-- Find all objects near the player
local nearby = loc.query(player.x - 50, player.y - 50, 100, 100)
for obj in pairs(nearby) do
  if obj ~= player then
    -- Handle nearby object
  end
end

-- Filter for specific object types
local enemies = loc.query(x, y, w, h, function(obj)
  return obj.type == "enemy"
end)
```

## Performance Characteristics

- **Time Complexity**: O(1) for add/remove/update operations
- **Query Complexity**: O(k) where k is the number of objects in query region
- **Memory Usage**: O(n + c) where n is object count and c is active cell count
- **Best Use Cases**: Small to medium bounded worlds with uniform distributions

## Best Practices

1. **Cell Size**: Choose cell size to match typical object size
2. **Object Density**: Works best with 1-10 objects per cell
3. **World Bounds**: Optimal for worlds up to 4096x4096 pixels
4. **Update Frequency**: Efficient for frequently moving objects

## Configuration Guidelines

| World Size | Object Count | Recommended Cell Size |
|------------|--------------|----------------------|
| 512x512    | <1000        | 16-32               |
| 1024x1024  | 1000-5000    | 32-64               |
| 2048x2048  | 5000+        | 64-128              |

## Migration from Legacy API

```lua
-- Legacy (still supported)
local loc = locustron(32)  -- Cell size only

-- New strategy API
local loc = locustron({
  strategy = "fixed_grid",
  config = {cell_size = 32}
})
```

## Interactive Documentation System

```lua
local DocumentationGenerator = {}
DocumentationGenerator.__index = DocumentationGenerator

function DocumentationGenerator.new(config)
  local self = setmetatable({}, DocumentationGenerator)

  self.output_format = config.format or "markdown"  -- "markdown", "html", "json"
  self.include_examples = config.include_examples or true
  self.include_performance = config.include_performance or true
  self.api_version = config.api_version or "1.0.0"

  return self
end

function DocumentationGenerator:generate_complete_docs(locustron_instance)
  local docs = {
    meta = {
      version = self.api_version,
      generated = os.date(),
      strategies = {}
    },
    api = {},
    guides = {},
    examples = {},
    performance = {}
  }

  -- Generate API documentation
  docs.api = self:generate_api_docs(locustron_instance)

  -- Generate strategy-specific docs
  for _, strategy_name in ipairs({"fixed_grid", "quadtree", "hash_grid", "bsp_tree", "bvh"}) do
    docs.meta.strategies[strategy_name] = self:generate_strategy_docs(strategy_name)
  end

  -- Generate examples
  if self.include_examples then
    docs.examples = self:generate_example_docs()
  end

  -- Generate performance data
  if self.include_performance then
    docs.performance = self:generate_performance_docs()
  end

  return docs
end

function DocumentationGenerator:generate_api_docs(locustron_instance)
  local api_docs = {
    core_functions = {},
    strategy_interface = {},
    visualization = {},
    profiling = {}
  }

  -- Core API functions
  api_docs.core_functions = {
    {
      name = "locustron",
      signature = "locustron(config)",
      description = "Creates a new spatial partitioning instance",
      parameters = {
        {name = "config", type = "table|number", description = "Configuration object or cell size"}
      },
      returns = {
        {type = "table", description = "Locustron instance with spatial operations"}
      },
      examples = {
        {
          title = "Basic Usage",
          code = [[
local loc = locustron(32)  -- 32-pixel grid cells
local obj = {id = "player"}
loc.add(obj, 100, 100, 16, 16)
local nearby = loc.query(90, 90, 40, 40)
]]
        },
        {
          title = "Strategy Configuration",
          code = [[
local loc = locustron({
  strategy = "quadtree",
  config = {
    max_objects = 8,
    max_depth = 6
  }
})
]]
        }
      }
    }
  }

  return api_docs
end

function DocumentationGenerator:export_documentation(docs, output_path)
  if self.output_format == "markdown" then
    self:export_markdown_docs(docs, output_path)
  elseif self.output_format == "html" then
    self:export_html_docs(docs, output_path)
  elseif self.output_format == "json" then
    self:export_json_docs(docs, output_path)
  end
end
```

---

## Phase 5.2: Educational Examples & Tutorials

- Create interactive tutorials that teach spatial partitioning concepts
- Develop complete game examples using different strategies
- Build educational visualizations showing algorithm behavior
- Generate comparative examples demonstrating strategy selection

### Interactive Tutorial System

```lua
local TutorialSystem = {}
TutorialSystem.__index = TutorialSystem

function TutorialSystem.new()
  local self = setmetatable({}, TutorialSystem)

  self.current_tutorial = nil
  self.step_index = 1
  self.interactive_mode = true
  self.visualization = VisualizationSystem.new({renderer = "picotron"})

  self.tutorials = {
    "basic_concepts",
    "collision_detection",
    "viewport_culling",
    "strategy_comparison",
    "performance_optimization"
  }

  return self
end

function TutorialSystem:start_tutorial(tutorial_name)
  self.current_tutorial = tutorial_name
  self.step_index = 1

  if tutorial_name == "basic_concepts" then
    self:run_basic_concepts_tutorial()
  elseif tutorial_name == "collision_detection" then
    self:run_collision_detection_tutorial()
  elseif tutorial_name == "viewport_culling" then
    self:run_viewport_culling_tutorial()
  elseif tutorial_name == "strategy_comparison" then
    self:run_strategy_comparison_tutorial()
  elseif tutorial_name == "performance_optimization" then
    self:run_performance_optimization_tutorial()
  end
end

function TutorialSystem:run_basic_concepts_tutorial()
  local steps = {
    {
      title = "Spatial Partitioning Introduction",
      description = "Spatial partitioning divides space to make queries faster",
      code = function()
        -- Create simple visualization
        local loc = locustron({strategy = "fixed_grid", config = {cell_size = 64}})

        -- Add some objects
        local objects = {}
        for i = 1, 20 do
          local obj = {id = string.format("obj_%d", i)}
          local x, y = math.random(50, 350), math.random(50, 250)
          table.insert(objects, {obj = obj, x = x, y = y, w = 16, h = 16})
          loc.add(obj, x, y, 16, 16)
        end

        return loc, objects
      end,
      explanation = "Objects are placed in grid cells. Queries only check relevant cells."
    },

    {
      title = "Query Efficiency",
      description = "Spatial queries are faster than checking every object",
      code = function()
        -- Demonstrate query vs brute force
        local loc, objects = self:get_tutorial_state()

        -- Show query region
        local query_x, query_y = 100, 100
        local query_w, query_h = 80, 80

        -- Highlight query region
        self.visualization:highlight_region(query_x, query_y, query_w, query_h)

        -- Show which cells are checked
        local relevant_objects = loc.query(query_x, query_y, query_w, query_h)

        return relevant_objects
      end,
      explanation = "Only objects in overlapping cells are checked, not all objects."
    },

    {
      title = "Different Strategies",
      description = "Different algorithms work better for different scenarios",
      code = function()
        -- Show side-by-side strategy comparison
        self:demonstrate_strategy_differences()
      end,
      explanation = "Grid works for uniform distribution, Quadtree for clustering."
    }
  }

  self:execute_tutorial_steps(steps)
end

function TutorialSystem:run_collision_detection_tutorial()
  local steps = {
    {
      title = "Basic Collision Detection",
      description = "Use spatial queries to find potential collision candidates",
      code = function()
        local loc = locustron(32)

        -- Create player
        local player = {id = "player", x = 200, y = 150, w = 16, h = 16}
        loc.add(player, player.x, player.y, player.w, player.h)

        -- Create walls
        local walls = {}
        for i = 1, 10 do
          local wall = {
            id = string.format("wall_%d", i),
            x = math.random(50, 350),
            y = math.random(50, 250),
            w = 32, h = 32
          }
          table.insert(walls, wall)
          loc.add(wall, wall.x, wall.y, wall.w, wall.h)
        end

        return {loc = loc, player = player, walls = walls}
      end,
      explanation = "Query around player position to find nearby collision candidates."
    },

    {
      title = "Movement with Collision",
      description = "Check collisions before moving objects",
      code = function()
        local state = self:get_tutorial_state()
        local player = state.player
        local loc = state.loc

        -- Simulate player movement
        local new_x = player.x + 32  -- Move right

        -- Query new position for collisions
        local collisions = loc.query(new_x, player.y, player.w, player.h, function(obj)
          return obj.id ~= player.id  -- Exclude self
        end)

        if next(collisions) then
          -- Collision detected, don't move
          self:show_message("Collision detected! Can't move.")
        else
          -- Safe to move
          loc.update(player, new_x, player.y, player.w, player.h)
          player.x = new_x
          self:show_message("Moved successfully!")
        end

        return state
      end,
      explanation = "Query the destination before moving to detect collisions."
    }
  }

  self:execute_tutorial_steps(steps)
end

function TutorialSystem:run_strategy_comparison_tutorial()
  local strategies = {"fixed_grid", "quadtree", "hash_grid"}
  local object_patterns = {
    clustered = function() return self:generate_clustered_objects(100) end,
    uniform = function() return self:generate_uniform_objects(100) end,
    sparse = function() return self:generate_sparse_objects(100) end
  }

  for pattern_name, pattern_func in pairs(object_patterns) do
    local step = {
      title = string.format("Strategy Comparison: %s Objects", pattern_name:gsub("^%l", string.upper)),
      description = string.format("Compare strategies with %s object distribution", pattern_name),
      code = function()
        local objects = pattern_func()
        local results = {}

        for _, strategy_name in ipairs(strategies) do
          local loc = locustron({strategy = strategy_name})

          -- Add all objects and measure time
          local start_time = os.clock()
          for _, obj_data in ipairs(objects) do
            loc.add(obj_data.obj, obj_data.x, obj_data.y, obj_data.w, obj_data.h)
          end
          local add_time = os.clock() - start_time

          -- Measure query time
          start_time = os.clock()
          for i = 1, 50 do
            loc.query(math.random(0, 400), math.random(0, 300), 64, 64)
          end
          local query_time = os.clock() - start_time

          results[strategy_name] = {
            add_time = add_time,
            query_time = query_time,
            loc = loc
          }
        end

        return results
      end,
      explanation = function()
        local results = self:get_tutorial_state()
        local explanation = string.format("Performance for %s distribution:\n", pattern_name)

        for strategy, data in pairs(results) do
          explanation = explanation .. string.format(
            "%s: Add=%.1fms, Query=%.1fms\n",
            strategy, data.add_time * 1000, data.query_time * 1000
          )
        end

        return explanation
      end
    }

    table.insert(steps, step)
  end

  self:execute_tutorial_steps(steps)
end
```

### Complete Game Examples

```lua
-- examples/survivor-like.lua - Wave-based survival game
local function create_survivor_like_example()
  local game = {
    loc = locustron({strategy = "quadtree", config = {max_objects = 8, max_depth = 6}}),
    player = {x = 128, y = 128, w = 8, h = 8},
    monsters = {},
    wave = 1,
    spawn_timer = 0,
    max_monsters = 200
  }

  -- Add player to spatial hash
  game.loc.add(game.player, game.player.x, game.player.y, game.player.w, game.player.h)

  return game
end

local function update_survivor_like(game, dt)
  -- Spawn monsters in waves
  game.spawn_timer = game.spawn_timer + dt
  if game.spawn_timer > 2.0 and #game.monsters < game.max_monsters then
    -- Spawn monsters around player
    local monsters_per_wave = math.min(20 + game.wave * 5, 50)
    local spawn_radius = 150

    for i = 1, monsters_per_wave do
      if #game.monsters >= game.max_monsters then break end

      local angle = (i / monsters_per_wave) * 2 * math.pi
      local distance = spawn_radius * (0.8 + math.random() * 0.4)

      local monster = {
        x = game.player.x + math.cos(angle) * distance,
        y = game.player.y + math.sin(angle) * distance,
        w = 6 + math.random(4),
        h = 6 + math.random(4),
        speed = 20 + math.random(20),
        age = 0,
        lifespan = 5 + math.random(2),
        alive = true,
        type = "monster"
      }

      table.insert(game.monsters, monster)
      game.loc.add(monster, monster.x, monster.y, monster.w, monster.h)
    end

    game.spawn_timer = 0
    game.wave = game.wave + 1
  end

  -- Update monsters
  local to_remove = {}
  for i, monster in ipairs(game.monsters) do
    if monster.alive then
      monster.age = monster.age + dt

      if monster.age > monster.lifespan then
        monster.alive = false
        game.loc.remove(monster)
        table.insert(to_remove, i)
      else
        -- Move toward player
        local dx = game.player.x - monster.x
        local dy = game.player.y - monster.y
        local dist = math.sqrt(dx*dx + dy*dy)

        if dist > 0 then
          monster.x = monster.x + (dx/dist) * monster.speed * dt
          monster.y = monster.y + (dy/dist) * monster.speed * dt
          game.loc.update(monster, monster.x, monster.y, monster.w, monster.h)
        end
      end
    end
  end

  -- Remove dead monsters
  for i = #to_remove, 1, -1 do
    table.remove(game.monsters, to_remove[i])
  end
end

-- examples/space-battle.lua - Large world with objectives
local function create_space_battle_example()
  local game = {
    loc = locustron({strategy = "hash_grid"}),
    ships = {},
    objectives = {},
    max_ships = 150
  }

  -- Create objectives
  game.objectives = {
    {x = 200, y = 150, radius = 40},
    {x = 600, y = 300, radius = 35},
    {x = 400, y = 500, radius = 45}
  }

  -- Spawn initial ships
  for i = 1, game.max_ships do
    local ship = {
      x = math.random(0, 800),
      y = math.random(0, 600),
      w = 4 + math.random(4),
      h = 4 + math.random(4),
      vx = (math.random() - 0.5) * 200,
      vy = (math.random() - 0.5) * 200,
      type = "ship"
    }

    table.insert(game.ships, ship)
    game.loc.add(ship, ship.x, ship.y, ship.w, ship.h)
  end

  return game
end

-- examples/platformer.lua - Bounded level with platforms
local function create_platformer_example()
  local game = {
    loc = locustron({strategy = "fixed_grid", config = {cell_size = 32}}),
    player = {x = 100, y = 100, w = 16, h = 24, vx = 0, vy = 0, on_ground = false},
    platforms = {},
    enemies = {}
  }

  -- Create platforms
  local platform_data = {
    {50, 200, 100, 16},   -- Ground platforms
    {200, 200, 100, 16},
    {350, 200, 100, 16},
    {125, 150, 50, 16},   -- Floating platforms
    {275, 100, 50, 16}
  }

  for i, data in ipairs(platform_data) do
    local platform = {
      id = string.format("platform_%d", i),
      x = data[1], y = data[2], w = data[3], h = data[4],
      type = "platform"
    }
    table.insert(game.platforms, platform)
    game.loc.add(platform, platform.x, platform.y, platform.w, platform.h)
  end

  -- Add player to spatial hash
  game.loc.add(game.player, game.player.x, game.player.y, game.player.w, game.player.h)

  return game
end

-- examples/dynamic-ecosystem.lua - Birth/death object lifecycle
local function create_dynamic_ecosystem_example()
  local game = {
    loc = locustron({strategy = "quadtree", config = {max_objects = 8, max_depth = 6}}),
    organisms = {},
    spawn_timer = 0,
    max_organisms = 120
  }

  -- Start with initial organisms
  for i = 1, 20 do
    local organism = {
      x = math.random(0, 512),
      y = math.random(0, 384),
      w = 4 + math.random(8),
      h = 4 + math.random(8),
      vx = (math.random() - 0.5) * 80,
      vy = (math.random() - 0.5) * 80,
      age = 0,
      lifespan = 5 + math.random(10),
      type = "organism"
    }

    table.insert(game.organisms, organism)
    game.loc.add(organism, organism.x, organism.y, organism.w, organism.h)
  end

  return game
end
```

## Phase 5 Summary

**Key Achievement**: Complete documentation and educational resources
**Documentation**: Comprehensive API docs, guides, and tutorials
**Examples**: Real-world game implementations showcasing each strategy
**Education**: Interactive tutorials teaching spatial partitioning concepts

**Ready for Phase 6**: Additional strategy implementation.
