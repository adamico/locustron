# Locustron Copilot Instructions

## Project Overview

Locustron is a **multi-strategy spatial partitioning library** for efficient collision detection and spatial queries. It provides multiple spatial partitioning algorithms (Fixed Grid, Quadtree, Hash Grid, BSP Tree, BVH) optimized for different game scenarios, with full Picotron optimization.

**Key Features:**
- **Multiple Strategies**: Fixed Grid, Quadtree, Hash Grid, BSP Tree, Bounding Volume Hierarchy
- **Picotron Optimized**: Userdata optimization and custom runtime features
- **Strategy Pattern**: Clean abstraction with pluggable algorithms
- **Comprehensive Testing**: BDD-style tests with 28+ test cases

**Official Documentation**: All Picotron-specific functionality references the Official Picotron Manual <https://www.lexaloffle.com/dl/docs/picotron_manual.html> as authoritative source.

## Architecture & Core Concepts

### Multi-Strategy Architecture

Locustron implements the **Strategy Pattern** for spatial partitioning, allowing dynamic selection of the optimal algorithm based on game requirements:

```lua
-- Strategy selection examples
local loc = locustron.create_strategy("fixed_grid")  -- Explicit strategy
local loc = locustron.create_strategy({              -- Configured strategy
   strategy = "quadtree",
   config = { max_objects = 8, max_depth = 6 }
})
```

### Strategy Interface Contract

All spatial strategies implement the `SpatialStrategy` interface:

```lua
-- Core methods (all strategies must implement)
strategy:add_object(obj, x, y, w, h)     -- Add object to spatial structure
strategy:remove_object(obj)              -- Remove object from spatial structure
strategy:update_object(obj, x, y, w, h)  -- Update object's position/size
strategy:query_region(x, y, w, h, filter) -- Query objects in rectangular area
strategy:get_bbox(obj)                   -- Get object's bounding box
strategy:clear()                         -- Remove all objects
```

### Available Strategies

| Strategy | Best For | Characteristics | Memory | Performance |
|----------|----------|------------------|--------|-------------|
| **Fixed Grid** | Uniform objects, bounded worlds | Simple, predictable | Low | Excellent for uniform distribution |

**Planned Strategies:**
- **Quadtree**: Clustered objects, hierarchical (adaptive subdivision)
- **Hash Grid**: Large/infinite worlds (sparse allocation)
- **BSP Tree**: Complex spatial relationships (hierarchical partitioning)
- **BVH**: Dynamic objects, ray casting (bounding volume trees)

### Picotron Implementation

Locustron is a **unified codebase** optimized for the Picotron runtime environment. The library provides a single, cohesive implementation that leverages Picotron's unique features while maintaining compatibility with standard Lua testing and development workflows.

**Key Implementation Details:**
- **Unified Architecture**: Single codebase with Picotron optimizations throughout
- **Userdata optimization**: Cell storage uses Picotron userdata for memory efficiency
- **Direct 2D array access**: `ud:get(x,y,n)` and `ud:set(x,y,value)` for optimal performance
- **Custom require system**: Error handling via `send_message()` for module loading
- **Memory constraints**: Maximum 10,000 objects with 32MB RAM limit
- **Strategy separation**: Clean separation between object management and spatial algorithms
- **Cross-platform testing**: Busted framework enables testing outside Picotron environment

## File Structure & Dependencies

### Project Architecture

Locustron follows a **unified codebase approach** with Picotron cartridge distribution and strategy pattern design:

```
locustron.p64/                    # Picotron cartridge + Git repository root
├── .github/copilot-instructions.md    # AI coding guidance (this file)
├── main.lua                        # Picotron demo entry point
├── locustron_demo.lua              # Interactive demo and library showcase
├── export_package.lua              # Automated export workflow for yotta packages
├── exports/                        # Yotta package distribution files (build artifacts)
│   ├── locustron.lua              # Main library entry point
│   ├── require.lua                # Custom require system
│   ├── viewport_culling.lua       # Viewport culling utilities
│   ├── doubly_linked_list.lua     # Memory management utility
│   ├── fixed_grid.lua             # Fixed Grid strategy implementation
│   ├── init.lua                   # Strategy initialization
│   └── interface.lua              # Strategy interface contract
├── src/                           # Unified source code (development files)
│   ├── locustron.lua              # Main library entry point
│   ├── require.lua                # Custom require system
│   ├── demo_scenarios.lua         # Demo scenario definitions
│   ├── debugging/                 # Debug utilities and visualization
│   │   ├── debug_console.lua      # Interactive debugging console
│   │   ├── performance_profiler.lua # Performance analysis tools
│   │   └── visualization_system.lua # Spatial partitioning visualization
│   ├── integration/               # Game engine integration utilities
│   │   └── viewport_culling.lua   # Viewport culling implementation
│   └── strategies/                # Spatial partitioning strategies
│       ├── doubly_linked_list.lua # Memory management utility
│       ├── fixed_grid.lua         # Fixed Grid strategy
│       ├── init.lua               # Strategy registration
│       └── interface.lua          # Strategy interface contract
├── tests/                         # Unified cross-platform test suites
│   ├── api_spec.lua               # API contract tests
│   ├── benchmark_suite_spec.lua   # Benchmark suite tests
│   ├── debug_console_spec.lua     # Debug console tests
│   ├── doubly_linked_list_spec.lua # Memory management tests
│   ├── fixed_grid_strategy_spec.lua # Fixed Grid strategy tests
│   ├── performance_profiler_spec.lua # Performance profiler tests
│   ├── setup_spec.lua             # Test setup and configuration
│   ├── strategy_interface_spec.lua # Strategy interface tests
│   ├── viewport_culling_spec.lua  # Viewport culling tests
│   └── visualization_system_spec.lua # Visualization system tests
├── benchmarks/                    # Performance analysis and benchmarking tools
│   ├── benchmark_cli.lua          # Command-line benchmarking interface
│   ├── benchmark_integration.lua  # Strategy factory integration tests
│   ├── benchmark_suite.lua        # Comprehensive benchmark suite
│   ├── performance_profiler.lua   # Performance profiling utilities
│   └── examples/                  # Benchmark usage examples
│       └── benchmark_examples.lua # Benchmark implementation examples
├── docs/                          # Comprehensive documentation
│   ├── collision-detection-reference.md
│   ├── reports/
│   │   ├── phase-1-completion.md
│   │   └── phase-2-completion.md
│   └── roadmap/                   # Phase-based development roadmap
│       ├── phase-1-foundation.md
│       ├── phase-2-benchmarks.md
│       ├── phase-3-debugging.md
│       ├── phase-4-documentation.md
│       ├── phase-5-strategies.md
│       ├── README.md
│       └── strategy-selection-guide.md
└── .luarc.json                    # Lua Language Server config
```

**Key Architectural Patterns:**

- **Unified Codebase**: Single source of truth with Picotron-optimized implementations
- **Strategy Registration**: `src/strategies/init.lua` registers concrete strategies with the factory
- **Integration Utilities**: `src/integration/viewport_culling.lua` provides game engine integration patterns
- **Debug Infrastructure**: `src/debugging/` provides comprehensive debugging and visualization tools
- **Test Coverage**: Busted-based BDD tests for all components in unified `tests/` directory
- **Benchmark Suite**: Comprehensive performance analysis tools in `benchmarks/` directory
- **Demo Integration**: `main.lua` demonstrates library with interactive visualization
- **Export Automation**: `export_package.lua` automates yotta package distribution

## Development Conventions

### Picotron Development

- **Runtime**: All code runs in Picotron environment only
- **Testing**: Use `include("test_file.lua")` in Picotron console for demo/testing and `unitron` for unit tests
- **Userdata**: `userdata("type", width, height)` creates 2D arrays
- **Console Output**: Always use `printh()` instead of `print()`
- **Error Handling**: `send_message(3, {event="report_error"})` for module loading errors

### Code Style & Formatting

- **Indentation**: **3 spaces** for all Lua files (no tabs)
- **Naming**: `snake_case` for variables/functions, `PascalCase` for classes/modules
- **Strategy Pattern**: Implement `SpatialStrategy` interface for new algorithms
- **Error Handling**: Use `error()` for contract violations, `assert()` for debugging
- **Documentation**: LuaDoc comments for all public APIs

### Testing Patterns

**BDD-style Testing (busted):**
```lua
-- Pattern: Behavior-driven test specifications
describe("Fixed Grid Strategy", function()
   it("should add objects to correct cells", function()
      local strategy = FixedGridStrategy.new({cell_size = 32})
      local obj = {id = "test"}
      strategy:add_object(obj, 10, 10, 8, 8)

      local bbox = strategy:get_bbox(obj)
      assert.equals(10, bbox.x)
      assert.equals(10, bbox.y)
   end)
end)
```

### Git Commit Convention

Follow Conventional Commits <https://www.conventionalcommits.org/> format:

```bash
<type>[optional scope]: <description>

# Examples
feat(fixed_grid): add sparse cell allocation
fix(tests): handle edge case in quadtree boundary checks
refactor(strategy_interface): simplify query_region contract
perf(hash_grid): optimize large world queries
test(vanilla): add quadtree strategy specifications
docs(readme): update API examples for multi-strategy usage
```

## API Usage Patterns

### Strategy Selection & Configuration

```lua
-- Simple strategy selection
local loc = locustron.create_strategy("fixed_grid")

-- Configured strategy
local loc = locustron.create_strategy({
   strategy = "quadtree",
   config = {
      max_objects_per_node = 8,
      max_depth = 6
   }
})
```

### Object Lifecycle Management

```lua
-- Add object with bounding box
local obj = {x = 100, y = 100, w = 16, h = 16, type = "enemy"}
loc:add_object(obj, obj.x, obj.y, obj.w, obj.h)

-- Update position (strategy handles grid cell changes automatically)
obj.x, obj.y = 120, 110
loc:update_object(obj, obj.x, obj.y, obj.w, obj.h)

-- Query objects in region
local nearby = loc:query_region(100, 100, 64, 64, function(obj)
   return obj.type == "enemy"  -- Optional filter function
end)

-- Remove object
loc:remove_object(obj)
```

### Collision Detection Integration

```lua
-- Query candidates, then precise collision check
local candidates = loc:query_region(player.x, player.y, 32, 32)
for obj in pairs(candidates) do
   local ox, oy, ow, oh = loc:get_bbox(obj)
   if rectintersect(player.x, player.y, player.w, player.h, ox, oy, ow, oh) then
      -- Handle collision
      handle_collision(player, obj)
   end
end
```

### Viewport Culling Pattern

```lua
-- Efficient rendering with spatial queries
function render_scene(camera)
   clip(camera.x, camera.y, camera.w, camera.h)

   local visible = loc:query_region(camera.x, camera.y, camera.w, camera.h)
   for obj in pairs(visible) do
      local x, y, w, h = loc:get_bbox(obj)
      draw_object(obj, x, y, w, h)
   end

   clip() -- Reset clipping
end
```

## Development Workflows

### Adding New Strategies

1. **Implement Interface**: Create new strategy class inheriting from `SpatialStrategy`
2. **Register Strategy**: Add to `init_strategies.lua` with metadata
3. **Add Tests**: Create comprehensive test suite in `tests/`
4. **Document**: Add strategy documentation and usage examples

**Example Strategy Implementation:**
```lua
local QuadtreeStrategy = {}
QuadtreeStrategy.__index = QuadtreeStrategy
setmetatable(QuadtreeStrategy, {__index = SpatialStrategy})

function QuadtreeStrategy.new(config)
   local self = setmetatable({}, QuadtreeStrategy)
   self.config = config or {}
   self.max_objects = self.config.max_objects or 8
   self.max_depth = self.config.max_depth or 6
   self.objects = {}
   self.root = self:create_node(0, 0, 1024, 1024, 0) -- World bounds
   return self
end

function QuadtreeStrategy:add_object(obj, x, y, w, h)
   -- Implementation here
end
```

### Testing Workflow

**Busted Testing:**
1. Install busted: `luarocks install busted`
2. Run `busted tests/`
3. Check test output and coverage

**Demo Cartridge Visualization:**
1. Load `locustron.p64` in Picotron
2. Visualize spatial partitioning with moving objects

**Cross-Platform Development:**
- **Source Code**: Unified implementation in `src/` directory
- **Testing**: Busted framework enables testing outside Picotron
- **Validation**: All tests pass in both vanilla Lua and Picotron environments

### Performance Benchmarking

**Grid Size Tuning:**
```lua
include("benchmarks/picotron/benchmark_grid_tuning.lua")
-- Tests different grid sizes against object patterns
-- Provides recommendations for optimal configuration
```

**Strategy Comparison:**
```lua
include("benchmarks/benchmark_suite.lua")
-- Compares all strategies across different scenarios
-- Generates performance reports and recommendations
```

**Benchmark Examples:**
```lua
include("benchmarks/examples/benchmark_examples.lua")
-- Practical examples of benchmark usage and integration
```

### Phase-Based Development

Locustron follows a structured roadmap with 6 development phases:

- **Phase 1**: Core abstraction and vanilla Lua foundation ✅
- **Phase 2**: Benchmarks and advanced testing with busted ✅
- **Phase 3**: Main locustron game engine API development ⏳
- **Phase 4**: Advanced debugging and visualization ⏳
- **Phase 5**: Documentation and examples ⏳
- **Phase 6**: Assess and implement more strategies ⏳

**Current Focus**: Main locustron game engine API development.

## Error Handling & Debugging

### Common Error Patterns

- **"unknown object"**: Object not added to spatial structure before operations
- **"Strategy not found"**: Invalid strategy name in factory creation
- **"Config validation failed"**: Invalid configuration parameters
- **Memory limits**: Exceeding Picotron's 32MB cartridge size or object capacity limits

### Debugging Strategies

**Visual Debugging:**
Picotron cartridge visualization using `draw_locus()` for grid visualization.

**Pool Monitoring:**
```lua
-- Track memory usage in development
print("Pool size:", loc._pool())
print("Object count:", loc._obj_count())
```

**Strategy Inspection:**
```lua
-- Get strategy information
local info = strategy:get_info()
print("Strategy:", info.name)
print("Object count:", info.statistics.object_count)
```

## Performance Considerations

### Strategy Selection Guidelines

| Scenario | Recommended Strategy | Rationale |
|----------|---------------------|-----------|
| Small bounded world, uniform objects | Fixed Grid | Simple, minimal overhead |

**Planned Strategies:**
- **Quadtree**: Good for clustered objects, dynamic (adaptive subdivision)
- **Hash Grid**: Excellent for large/infinite worlds (sparse allocation)
- **BSP Tree**: Good for complex spatial relationships (hierarchical partitioning)
- **BVH**: Excellent for dynamic objects, ray casting (bounding volume trees)

### Memory Management

- **Picotron**: Userdata arrays with 10,000 object limit
- **Pool Recycling**: Automatic table reuse to minimize GC pressure
- **Sparse Allocation**: Cells created only when containing objects

### Performance Optimization

- **Query Size**: Smaller query regions perform better
- **Object Updates**: Minimize position changes across cell boundaries
- **Filter Functions**: Use lightweight filters to reduce processing
- **Strategy Matching**: Choose strategy matching your object distribution pattern

## Integration Patterns

### Game Engine Integration

```lua
-- Entity Component System integration
local SpatialSystem = {}

function SpatialSystem.new(strategy_config)
   local self = {
      spatial = locustron.create_strategy(strategy_config),
      entities = {}
   }
   return self
end

function SpatialSystem:add_entity(entity, x, y, w, h)
   self.spatial:add_object(entity, x, y, w, h)
   self.entities[entity] = true
end

function SpatialSystem:update_entity(entity, x, y, w, h)
   self.spatial:update_object(entity, x, y, w, h)
end

function SpatialSystem:query_nearby(x, y, radius, filter)
   return self.spatial:query_region(
      x - radius, y - radius,
      radius * 2, radius * 2,
      filter
   )
end
```

### Yotta Package Distribution

**Installation:**
```bash
# In Picotron console
> yotta add #locustron
> yotta apply
```

**Usage in Projects:**
```lua
include("lib/locustron/require.lua")
local locustron = require("lib/locustron/locustron")
```

This ensures Locustron integrates seamlessly with the Picotron ecosystem while maintaining the flexibility of multiple spatial partitioning strategies.