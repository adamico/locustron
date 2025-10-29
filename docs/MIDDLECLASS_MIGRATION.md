# Middleclass Migration Guide

## Overview

Locustron has migrated from manual metatable-based OOP to the [middleclass](https://github.com/kikito/middleclass) library (v4.1.1) for consistent, maintainable object-oriented programming patterns across the entire codebase.

## What Changed

### Before: Manual Metatables

```lua
local MyClass = {}
MyClass.__index = MyClass

function MyClass.new(config)
  local self = setmetatable({}, MyClass)
  self.property = config.property or "default"
  return self
end

function MyClass:method()
  return self.property
end

-- Instantiation
local instance = MyClass.new({property = "value"})
```

### After: Middleclass

```lua
local class = require("lib.middleclass")

local MyClass = class("MyClass")

function MyClass:initialize(config)
  config = config or {}
  self.property = config.property or "default"
end

function MyClass:method()
  return self.property
end

-- Instantiation (note colon notation)
local instance = MyClass:new({property = "value"})
```

## Key Differences

### 1. Constructor Syntax

**Before:** `Class.new()` with dot notation  
**After:** `Class:new()` with colon notation

```lua
-- Old
local strategy = FixedGridStrategy.new({cell_size = 32})

-- New
local strategy = FixedGridStrategy:new({cell_size = 32})
```

### 2. Class Definition

**Before:** Manual metatable setup  
**After:** `class()` function

```lua
-- Old
local MyClass = {}
MyClass.__index = MyClass
setmetatable(MyClass, {__index = ParentClass})

-- New
local class = require("lib.middleclass")
local MyClass = class("MyClass", ParentClass)
```

### 3. Constructor Method

**Before:** `.new()` returns `self`  
**After:** `:initialize()` sets up instance

```lua
-- Old
function MyClass.new(config)
  local self = setmetatable({}, MyClass)
  self.config = config
  return self
end

-- New
function MyClass:initialize(config)
  self.config = config
end
```

### 4. Inheritance

**Before:** Manual parent constructor call  
**After:** Direct parent method call

```lua
-- Old
function ChildClass.new(config)
  local self = ParentClass.new(config)
  setmetatable(self, ChildClass)
  return self
end

-- New
function ChildClass:initialize(config)
  ParentClass.initialize(self, config)
  -- or: ParentClass.initialize(self, config)
end
```

### 5. Static Methods

**Before:** Direct table assignment  
**After:** `.static` table

```lua
-- Old
function MyClass.static_method()
  return "result"
end

-- New
function MyClass.static.static_method()
  return "result"
end
```

## Migration Checklist

If you're updating code that uses Locustron classes:

- [ ] Change all `Class.new()` calls to `Class:new()`
- [ ] Update any manual metatable patterns to use middleclass
- [ ] Replace `.new()` constructors with `:initialize()` methods
- [ ] Update parent class calls in inheritance
- [ ] Move static methods to `.static` table
- [ ] Test all functionality after migration

## Benefits

### 1. Consistency

All classes in Locustron now follow the same OOP pattern, making the codebase more predictable and easier to learn.

### 2. Less Boilerplate

Middleclass eliminates repetitive metatable setup code:

```lua
-- Before: 3 lines of boilerplate
local MyClass = {}
MyClass.__index = MyClass
setmetatable(MyClass, {__index = ParentClass})

-- After: 1 line
local MyClass = class("MyClass", ParentClass)
```

### 3. Better Inheritance

Middleclass provides clean inheritance with proper method resolution:

```lua
-- Inheritance is simple and clear
local ChildClass = class("ChildClass", ParentClass)

-- Parent methods are automatically available
function ChildClass:initialize(config)
  ParentClass.initialize(self, config)  -- Call parent
  self.child_property = config.child_property
end
```

### 4. Type Checking

Middleclass provides `isInstanceOf()` and `isSubclassOf()` for runtime type checking:

```lua
local strategy = FixedGridStrategy:new()

-- Check instance type
if strategy:isInstanceOf(SpatialStrategy) then
  print("Is a spatial strategy")
end

-- Check class hierarchy
if ChildClass:isSubclassOf(ParentClass) then
  print("ChildClass extends ParentClass")
end
```

### 5. Mixins

Middleclass supports mixins for shared functionality:

```lua
local Serializable = {
  serialize = function(self)
    return tostring(self)
  end
}

local MyClass = class("MyClass")
MyClass:include(Serializable)  -- Add mixin methods
```

## Migrated Classes

All the following classes now use middleclass:

### Strategy Pattern
- `SpatialStrategy` (interface)
- `FixedGridStrategy`
- `SpatialNode`
- `SpatialCell`

### Main API
- `Locustron`

### Integration Utilities
- `ViewportCulling`

### Benchmarking & Testing
- `BenchmarkSuite`
- `PerformanceProfiler`

### Demo Infrastructure
- `DebugConsole`
- `VisualizationSystem`
- `SceneManager` and all scene classes

## Backward Compatibility

### Factory Methods

For public APIs, static factory methods maintain compatibility:

```lua
-- Locustron.create() still works
function Locustron.static.create(config)
  return Locustron:new(config)
end

-- Usage
local loc = Locustron.create(32)  -- Still works!
```

### Legacy API Methods

Strategy classes maintain legacy method names:

```lua
-- FixedGridStrategy provides both APIs
strategy:add_object(obj, x, y, w, h)  -- New API
strategy:add(obj, x, y, w, h)         -- Legacy API (alias)
```

## Testing

All 188 tests pass with the middleclass implementation:

```bash
$ busted tests/
188 successes / 0 failures / 0 errors
```

Test files updated to use `:new()` syntax:
- `tests/fixed_grid_strategy_spec.lua`
- `tests/strategy_interface_spec.lua`
- `tests/viewport_culling_spec.lua`
- `tests/benchmark_suite_spec.lua`
- `tests/performance_profiler_spec.lua`
- `tests/debug_console_spec.lua`
- `tests/visualization_system_spec.lua`

## Common Errors

### 1. Using Dot Notation for Constructor

**Error:** `attempt to call field 'new' (a nil value)`

**Cause:** Using `Class.new()` instead of `Class:new()`

**Fix:**
```lua
-- Wrong
local instance = MyClass.new()

-- Correct
local instance = MyClass:new()
```

### 2. Returning Self from Initialize

**Error:** Constructor returns unexpected value

**Cause:** Returning `self` from `initialize()` method

**Fix:**
```lua
-- Wrong
function MyClass:initialize()
  self.value = 1
  return self  -- Don't do this
end

-- Correct
function MyClass:initialize()
  self.value = 1
  -- No return needed
end
```

### 3. Forgetting to Call Parent Constructor

**Error:** Parent properties not initialized

**Cause:** Not calling parent `initialize()` in child class

**Fix:**
```lua
-- Wrong
function ChildClass:initialize(config)
  self.child_prop = config.child_prop
end

-- Correct
function ChildClass:initialize(config)
  ParentClass.initialize(self, config)  -- Call parent
  self.child_prop = config.child_prop
end
```

## Additional Resources

- [Middleclass GitHub Repository](https://github.com/kikito/middleclass)
- [Middleclass Documentation](https://github.com/kikito/middleclass/wiki)
- [Locustron Copilot Instructions](.github/copilot-instructions.md) - OOP section
- [Locustron Test Suite](tests/) - Examples of proper usage

## Questions?

If you encounter issues with the migration:

1. Check this guide for common patterns
2. Review the test files for examples
3. See the copilot instructions for conventions
4. Open an issue on GitHub for help
