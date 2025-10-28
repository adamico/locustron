# Phase 1: Core Abstraction & Fixed Grid Refactor (2 weeks)

## Overview
Phase 1 establishes the foundation for multi-strategy spatial partitioning by creating a clean abstraction layer and refactoring the current implementation to use linked lists instead of userdata. This enables vanilla Lua testing and prepares for multiple strategy implementations.

---

## Phase 1.1: Vanilla Lua Foundation & Testing Setup (3 days)

### BDD Feature Specifications

**Feature: Vanilla Lua Compatibility**
```gherkin
As a developer using Locustron
I want the library to run in standard Lua environments
So that I can develop and test without Picotron dependencies

Scenario: Library loads in vanilla Lua
  Given I have a standard Lua 5.4+ environment
  When I require the locustron library
  Then it should load without any Picotron-specific dependencies
  And it should not reference userdata functions
  And it should use only standard Lua language features
  And it should leverage Lua 5.4+ features like integer division and new string methods

Scenario: Basic spatial operations work in vanilla Lua
  Given a locustron instance created in vanilla Lua 5.4+
  When I add objects to the spatial hash
  And I query for objects in a region
  Then I should get correct spatial query results
  And the performance should be comparable to Picotron version
  And it should utilize Lua 5.4+ optimizations where applicable
```

**Feature: Comprehensive Testing Infrastructure**
```gherkin
As a developer contributing to Locustron
I want a comprehensive testing framework
So that I can validate changes with confidence

Scenario: BDD test suite execution
  Given a Busted testing framework setup
  When I run the complete test suite
  Then all tests should pass with >90% code coverage
  And test execution should complete in under 30 seconds
  And test results should include performance metrics

Scenario: Cross-platform Lua compatibility
  Given test configurations for multiple Lua versions
  When I run tests on Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT
  Then all tests should pass on each version
  And any version-specific behaviors should be documented
```

**Feature: Linked List Data Structures**
```gherkin
As a spatial partitioning algorithm
I want efficient doubly linked list operations
So that I can manage objects without fixed capacity limits

Scenario: Cell creation and management
  Given the need to store objects in spatial cells
  When I create a new cell
  Then it should have head and tail pointers set to nil
  And it should track object count efficiently
  And it should support unlimited object capacity

Scenario: Object node operations
  Given objects that need spatial indexing
  When I create object nodes with bounding boxes
  Then each node should store object reference, spatial data, and prev/next pointers
  And nodes should support O(1) insertion and removal operations
  And memory usage should be efficient for typical game scenarios

Scenario: Doubly linked list manipulation
  Given a cell with multiple objects
  When I add, remove, or traverse objects in either direction
  Then operations should be O(1) for insertion/deletion at any position
  And forward traversal should visit all objects in insertion order
  And backward traversal should visit all objects in reverse order
  And list integrity should be maintained during all operations
```

**Feature: Continuous Integration Pipeline**
```gherkin
As a project maintainer
I want automated testing on code changes
So that regressions are caught immediately

Scenario: Automated test execution
  Given a Git repository with CI configuration
  When I push code changes to any branch
  Then tests should run automatically on multiple Lua versions
  And I should receive immediate feedback on test results
  And coverage reports should be generated and tracked

Scenario: Performance regression detection
  Given baseline performance metrics
  When new code is tested in CI
  Then performance should not degrade by more than 10%
  And significant performance improvements should be highlighted
  And performance trends should be tracked over time
```

### Implementation Steps

**Day 1: Vanilla Lua Foundation**
```lua
-- Step 1: Create doubly linked list primitives (based on whoop.ee implementation)
describe("Doubly Linked List Foundation", function()
  context("when creating object nodes", function()
    it("should store all required spatial data", function()
      local obj = {id = "test"}
      local node = create_object_node(obj, 10, 20, 8, 16)
      
      assert.equals(obj, node.data.obj)
      assert.equals(10, node.data.x)
      assert.equals(20, node.data.y)
      assert.equals(8, node.data.w)
      assert.equals(16, node.data.h)
      assert.is_nil(node.next)
      assert.is_nil(node.prev)
    end)
  end)
  
  context("when creating cells with doubly linked lists", function()
    it("should initialize empty cells correctly", function()
      local cell = create_cell()
      assert.is_nil(cell.firstNode)
      assert.is_nil(cell.lastNode)
      assert.equals(0, cell.count)
    end)
    
    it("should support O(1) insertion at beginning", function()
      local cell = create_cell()
      local obj1 = {id = "obj1"}
      local obj2 = {id = "obj2"}
      
      cell:insertBeginning(obj1, 10, 10, 8, 8)
      cell:insertBeginning(obj2, 20, 20, 8, 8)
      
      assert.equals(2, cell.count)
      assert.equals(obj2, cell.firstNode.data.obj)
      assert.equals(obj1, cell.lastNode.data.obj)
    end)
    
    it("should support O(1) removal using standard algorithm", function()
      local cell = create_cell()
      local obj = {id = "test"}
      local node = cell:insertBeginning(obj, 10, 10, 8, 8)
      
      cell:remove(node)
      assert.equals(0, cell.count)
      assert.is_nil(cell.firstNode)
      assert.is_nil(cell.lastNode)
    end)
    
    it("should support bidirectional traversal", function()
      local cell = create_cell()
      local objects = {}
      
      -- Insert objects
      for i = 1, 3 do
        local obj = {id = string.format("obj_%d", i)}
        cell:insertBeginning(obj, i*10, i*10, 8, 8)
        table.insert(objects, 1, obj)  -- Insert at beginning to match order
      end
      
      -- Test forward traversal
      local forward_order = {}
      cell:traverseForwards(function(node)
        table.insert(forward_order, node.data.obj.id)
      end)
      assert.same({"obj_3", "obj_2", "obj_1"}, forward_order)
      
      -- Test backward traversal  
      local backward_order = {}
      cell:traverseBackwards(function(node)
        table.insert(backward_order, node.data.obj.id)
      end)
      assert.same({"obj_1", "obj_2", "obj_3"}, backward_order)
    end)
  end)
end)
```

**Day 2: Testing Infrastructure**
```lua
-- Step 2: Set up comprehensive test framework
describe("Testing Infrastructure", function()
  context("when running in different Lua versions", function()
    it("should provide version compatibility", function()
      assert.truthy(_VERSION)
      assert.truthy(string.match(_VERSION, "Lua 5%.%d+"))
    end)
  end)
  
  context("when measuring performance", function()
    it("should establish baseline metrics", function()
      local start_time = os.clock()
      -- Perform standard operations
      local duration = os.clock() - start_time
      assert.truthy(duration >= 0)
    end)
  end)
end)
```

**Day 3: CI Pipeline & Integration**
```yaml
# .github/workflows/test.yml
name: Vanilla Lua Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        lua-version: ['5.1', '5.2', '5.3', '5.4', 'luajit']
    steps:
      - uses: actions/checkout@v3
      - uses: leafo/gh-actions-lua@v9
        with:
          luaVersion: ${{ matrix.lua-version }}
      - uses: leafo/gh-actions-luarocks@v4
      - run: luarocks install busted
      - run: luarocks install luacov
      - run: busted --coverage
      - run: luacov
```

### Acceptance Criteria (BDD Style)

**Given** the Phase 1.1 implementation is complete
**When** I run the validation suite
**Then** the following scenarios should pass:

- ✅ **Vanilla Lua Compatibility**: Library loads and runs in all target Lua versions
- ✅ **Test Coverage**: >90% code coverage with comprehensive BDD scenarios
- ✅ **CI Pipeline**: Automated testing passes on all supported platforms
- ✅ **Performance Baseline**: Benchmarks establish measurable performance targets
- ✅ **Linked List Operations**: All data structure operations work correctly and efficiently

---

## Phase 1.2: Strategy Interface Design (2 days)

### Objectives
- Define comprehensive strategy interface
- Create strategy factory system
- Establish configuration patterns
- Design strategy lifecycle management

### Deliverables
- **Strategy Interface**: Abstract contract for all spatial partitioning strategies
- **Strategy Factory**: Dynamic strategy creation and configuration
- **Configuration System**: Flexible parameter management
- **Lifecycle Management**: Strategy initialization, cleanup, and state management

### Key Components
```lua
-- Core strategy interface contract
local SpatialStrategy = {
  -- Object lifecycle
  add_object = function(self, obj, x, y, w, h) end,
  remove_object = function(self, obj) end,
  update_object = function(self, obj, x, y, w, h) end,
  
  -- Spatial queries
  query_region = function(self, x, y, w, h, filter_fn) end,
  query_point = function(self, x, y, filter_fn) end,
  query_nearest = function(self, x, y, count, filter_fn) end,
  
  -- Strategy management
  get_info = function(self) end,
  get_statistics = function(self) end,
  clear = function(self) end,
  
  -- Debug and visualization
  get_debug_info = function(self) end,
  visualize_structure = function(self) end
}

-- Strategy factory
local function create_strategy(strategy_name, config)
  local strategies = {
    fixed_grid = require("strategies.fixed_grid"),
    quadtree = require("strategies.quadtree"),
    hash_grid = require("strategies.hash_grid"),
    auto = require("strategies.auto_select")
  }
  
  local strategy_class = strategies[strategy_name]
  if not strategy_class then
    error("Unknown strategy: " .. tostring(strategy_name))
  end
  
  return strategy_class.new(config or {})
end

-- Enhanced configuration system
local loc = locustron({
  strategy = "fixed_grid",
  config = {
    cell_size = 32,
    initial_capacity = 100,
    growth_factor = 1.5,
    debug_mode = false
  }
})
```

### Success Criteria
- ✅ Well-defined strategy interface with clear contracts
- ✅ Factory pattern enables dynamic strategy selection
- ✅ Configuration system supports all strategy parameters
- ✅ Interface design accommodates future strategy implementations

---

## Phase 1.3: Fixed Grid Strategy Refactor (4 days)

### Objectives
- Refactor current userdata implementation to linked lists
- Implement strategy interface for Fixed Grid
- Maintain exact API compatibility
- Achieve performance parity or better

### Deliverables
- **Fixed Grid Strategy**: Complete linked list implementation
- **API Compatibility Layer**: Seamless transition from legacy API
- **Performance Optimization**: Efficient linked list operations
- **Comprehensive Testing**: Full test coverage for refactored implementation

### Key Implementation Details
```lua
-- Fixed Grid strategy using standardized doubly linked lists
local FixedGridStrategy = {}
FixedGridStrategy.__index = FixedGridStrategy

function FixedGridStrategy.new(config)
  local self = setmetatable({}, FixedGridStrategy)
  
  self.cell_size = config.cell_size or 32
  self.grid = {}  -- Sparse grid of cells
  self.objects = {}  -- Object to node mapping
  self.object_count = 0
  
  return self
end

function FixedGridStrategy:add_object(obj, x, y, w, h)
  -- Calculate grid bounds using Lua 5.4+ integer division
  local gx0 = x // self.cell_size
  local gy0 = y // self.cell_size
  local gx1 = (x + w - 1) // self.cell_size
  local gy1 = (y + h - 1) // self.cell_size
  
  -- Store nodes for each cell this object spans
  local object_nodes = {}
  
  -- Add to all overlapping cells
  for gy = gy0, gy1 do
    if not self.grid[gy] then self.grid[gy] = {} end
    for gx = gx0, gx1 do
      if not self.grid[gy][gx] then 
        self.grid[gy][gx] = create_cell() 
      end
      
      -- Insert at beginning using standard algorithm
      local node = self.grid[gy][gx]:insertBeginning(obj, x, y, w, h)
      table.insert(object_nodes, {cell = self.grid[gy][gx], node = node})
    end
  end
  
  -- Store mapping for removal/updates
  self.objects[obj] = object_nodes
  self.object_count = self.object_count + 1
  return obj
end

function FixedGridStrategy:remove_object(obj)
  local object_nodes = self.objects[obj]
  if not object_nodes then
    error("unknown object")
  end
  
  -- Remove from all cells using standard removal algorithm
  for _, entry in ipairs(object_nodes) do
    entry.cell:remove(entry.node)
  end
  
  self.objects[obj] = nil
  self.object_count = self.object_count - 1
  return obj
end

function FixedGridStrategy:query_region(x, y, w, h, filter_fn)
  local results = {}
  local visited = {}  -- Prevent duplicates
  
  -- Calculate query bounds using Lua 5.4+ integer division
  local gx0 = x // self.cell_size
  local gy0 = y // self.cell_size
  local gx1 = (x + w - 1) // self.cell_size
  local gy1 = (y + h - 1) // self.cell_size
  
  -- Query all overlapping cells
  for gy = gy0, gy1 do
    local row = self.grid[gy]
    if row then
      for gx = gx0, gx1 do
        local cell = row[gx]
        if cell then
          -- Use standard forward traversal
          cell:traverseForwards(function(node)
            local obj = node.data.obj
            if not visited[obj] then
              visited[obj] = true
              if not filter_fn or filter_fn(obj) then
                results[obj] = true
              end
            end
          end)
        end
      end
    end
  end
  
  return results
end

function FixedGridStrategy:update_object(obj, x, y, w, h)
  -- Simple implementation: remove and re-add
  self:remove_object(obj)
  return self:add_object(obj, x, y, w, h)
end
```

### Performance Targets
- **Add/Remove Operations**: <0.001ms per operation for typical game objects
- **Query Operations**: <0.01ms for viewport-sized queries
- **Memory Usage**: <10MB for 10,000 objects
- **API Compatibility**: 100% backward compatibility with existing Locustron API

### Doubly Linked List Implementation
Based on standard algorithms from [Wikipedia](https://en.wikipedia.org/wiki/Doubly_linked_list) and proven pattern from [whoop.ee](https://www.whoop.ee/post/doubly-linked-list.html):

```lua
-- Core doubly linked list implementation for spatial cells
-- Follows standard nomenclature: firstNode/lastNode, next/prev links

---@class SpatialNode
---@field data table Object data with spatial properties  
---@field next SpatialNode | nil
---@field prev SpatialNode | nil
local SpatialNode = {}
SpatialNode.__index = SpatialNode

---@param obj any Object reference
---@param x number X coordinate
---@param y number Y coordinate  
---@param w number Width
---@param h number Height
---@return SpatialNode
function SpatialNode:new(obj, x, y, w, h)
  return setmetatable({
    data = {
      obj = obj,
      x = x, y = y, w = w, h = h
    },
    next = nil,
    prev = nil,
  }, self)
end

---@class SpatialCell
---@field private firstNode SpatialNode | nil
---@field private lastNode SpatialNode | nil
---@field private count number
local SpatialCell = {}
SpatialCell.__index = SpatialCell

---@return SpatialCell
function SpatialCell:new()
  return setmetatable({
    firstNode = nil,
    lastNode = nil,
    count = 0,
  }, self)
end

-- Standard insertion algorithms from Wikipedia

---Insert at beginning of list
---@param obj any
---@param x number
---@param y number
---@param w number  
---@param h number
---@return SpatialNode
function SpatialCell:insertBeginning(obj, x, y, w, h)
  local newNode = SpatialNode:new(obj, x, y, w, h)
  
  if self.firstNode == nil then
    self.firstNode = newNode
    self.lastNode = newNode
    newNode.prev = nil
    newNode.next = nil
  else
    self:insertBefore(self.firstNode, newNode)
  end
  
  self.count = self.count + 1
  return newNode
end

---Insert before a given node (Wikipedia algorithm)
---@param node SpatialNode
---@param newNode SpatialNode
function SpatialCell:insertBefore(node, newNode)
  newNode.next = node
  if node.prev == nil then
    newNode.prev = nil
    self.firstNode = newNode
  else
    newNode.prev = node.prev
    node.prev.next = newNode
  end
  node.prev = newNode
end

---Insert after a given node (Wikipedia algorithm)
---@param node SpatialNode  
---@param newNode SpatialNode
function SpatialCell:insertAfter(node, newNode)
  newNode.prev = node
  if node.next == nil then
    newNode.next = nil
    self.lastNode = newNode
  else
    newNode.next = node.next
    node.next.prev = newNode
  end
  node.next = newNode
end

---Remove a node (Wikipedia algorithm) 
---@param node SpatialNode
---@return SpatialNode | nil
function SpatialCell:remove(node)
  if not node then return nil end
  
  -- Standard doubly linked list removal
  if node.prev == nil then
    self.firstNode = node.next
  else
    node.prev.next = node.next
  end
  
  if node.next == nil then
    self.lastNode = node.prev
  else
    node.next.prev = node.prev
  end
  
  self.count = self.count - 1
  return node
end

-- Traversal algorithms from Wikipedia

---Traverse forwards through the list
---@param fn fun(node: SpatialNode)
function SpatialCell:traverseForwards(fn)
  local node = self.firstNode
  while node ~= nil do
    fn(node)
    node = node.next
  end
end

---Traverse backwards through the list  
---@param fn fun(node: SpatialNode)
function SpatialCell:traverseBackwards(fn)
  local node = self.lastNode
  while node ~= nil do
    fn(node)
    node = node.prev
  end
end

---Query objects in cell with optional filter
---@param filter_fn function | nil
---@return table Results hash {[obj] = true}
function SpatialCell:query(filter_fn)
  local results = {}
  
  self:traverseForwards(function(node)
    local obj = node.data.obj
    if not filter_fn or filter_fn(obj) then
      results[obj] = true
    end
  end)
  
  return results
end

-- Factory functions
function create_cell()
  return SpatialCell:new()
end

function create_object_node(obj, x, y, w, h)
  return SpatialNode:new(obj, x, y, w, h)
end
```

### Success Criteria
- ✅ Fixed Grid strategy fully implements strategy interface
- ✅ All existing Locustron functionality preserved
- ✅ Performance meets or exceeds current userdata implementation
- ✅ Comprehensive test coverage validates all operations

---

## Phase 1.4: Integration & Validation (3 days)

### Objectives
- Integrate all Phase 1 components
- Validate complete API compatibility
- Establish performance benchmarks
- Create migration documentation

### Deliverables
- **Integrated Locustron**: Complete multi-strategy foundation
- **Migration Guide**: Step-by-step upgrade instructions
- **Performance Report**: Comprehensive benchmarking results
- **API Documentation**: Updated documentation reflecting new capabilities

### Integration Testing
```lua
-- Comprehensive integration test suite
describe("Phase 1 Integration", function()
  context("when using the legacy API", function()
    it("should work exactly as before", function()
      local loc = locustron()
      local obj = {id = "test"}
      
      loc.add(obj, 10, 20, 8, 16)
      local results = loc.query(5, 15, 20, 20)
      
      assert.truthy(results[obj])
      assert.equals(1, count_objects(results))
    end)
  end)
  
  context("when using the new strategy API", function()
    it("should provide enhanced functionality", function()
      local loc = locustron({
        strategy = "fixed_grid",
        config = {cell_size = 64}
      })
      
      local obj = {id = "test"}
      loc.add(obj, 10, 20, 8, 16)
      
      local info = loc.get_strategy_info()
      assert.equals("fixed_grid", info.name)
      assert.equals(64, info.config.cell_size)
    end)
  end)
  
  context("when using multiple strategies", function()
    it("should maintain consistent behavior across strategies", function()
      local strategies = {"fixed_grid", "quadtree", "hash_grid"}
      
      for _, strategy_name in ipairs(strategies) do
        local loc = locustron({
          strategy = strategy_name,
          config = {cell_size = 32}
        })
        
        -- Add test objects
        local obj1 = {id = "obj1"}
        local obj2 = {id = "obj2"}
        
        loc.add(obj1, 10, 10, 8, 8)
        loc.add(obj2, 50, 50, 8, 8)
        
        -- Test basic operations
        local results = loc.query(5, 5, 20, 20)
        assert.truthy(results[obj1])
        assert.falsy(results[obj2])
        
        -- Test updates
        loc.update(obj1, 45, 45, 8, 8)
        local updated_results = loc.query(40, 40, 20, 20)
        assert.truthy(updated_results[obj1])
        
        -- Test removal
        loc.del(obj1)
        local final_results = loc.query(0, 0, 100, 100)
        assert.falsy(final_results[obj1])
        assert.truthy(final_results[obj2])
      end
    end)
  end)
  
  context("when performing stress tests", function()
    it("should handle large numbers of objects efficiently", function()
      local loc = locustron({strategy = "fixed_grid"})
      local objects = {}
      
      -- Add 1000 objects
      for i = 1, 1000 do
        local obj = {id = string.format("obj_%d", i)}
        local x = math.random(0, 500)
        local y = math.random(0, 500)
        
        loc.add(obj, x, y, 8, 8)
        objects[i] = {obj = obj, x = x, y = y}
      end
      
      -- Test query performance
      local start_time = os.clock()
      for i = 1, 100 do
        local results = loc.query(i * 5, i * 5, 50, 50)
        -- Verify results contain expected objects
        assert.truthy(type(results) == "table")
      end
      local duration = os.clock() - start_time
      
      -- Should complete 100 queries in reasonable time
      assert.truthy(duration < 1.0)  -- Less than 1 second
      
      -- Test update performance
      start_time = os.clock()
      for i = 1, 100 do
        local obj_data = objects[i]
        local new_x = obj_data.x + 10
        local new_y = obj_data.y + 10
        loc.update(obj_data.obj, new_x, new_y, 8, 8)
      end
      duration = os.clock() - start_time
      
      -- Should complete 100 updates quickly
      assert.truthy(duration < 0.1)  -- Less than 100ms
    end)
  end)
end)
```

### Success Criteria
- ✅ Complete API compatibility with existing code
- ✅ New strategy interface fully functional
- ✅ Performance benchmarks meet targets
- ✅ Documentation updated and comprehensive
- ✅ Migration path clear and well-documented

## Phase 1 Summary

**Duration**: 2 weeks (12 days)
**Key Achievement**: Foundation for multi-strategy spatial partitioning
**Backward Compatibility**: 100% preserved
**New Capabilities**: Strategy abstraction, vanilla Lua support, enhanced testing

**Ready for Phase 2**: Benchmarking framework implementation with established foundation for performance analysis.