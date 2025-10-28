--- @diagnostic disable: undefined-global undefined-field
-- BDD Tests for Doubly Linked List Implementation
-- Following Phase 1.1 specifications

local dll = require("src.strategies.doubly_linked_list")

describe("Doubly Linked List Foundation", function()
   describe("SpatialNode creation", function()
      it("should store all required spatial data", function()
         local obj = { id = "test" }
         local node = dll.createNode(obj, 10, 20, 8, 16)

         assert.equals(obj, node.data.obj)
         assert.equals(10, node.data.x)
         assert.equals(20, node.data.y)
         assert.equals(8, node.data.w)
         assert.equals(16, node.data.h)
         assert.falsy(node.next)
         assert.falsy(node.prev)
      end)

      it("should create isolated nodes", function()
         local obj1 = { id = "obj1" }
         local obj2 = { id = "obj2" }
         local node1 = dll.createNode(obj1, 0, 0, 8, 8)
         local node2 = dll.createNode(obj2, 10, 10, 8, 8)

         assert.falsy(node1.next)
         assert.falsy(node1.prev)
         assert.falsy(node2.next)
         assert.falsy(node2.prev)
         assert.not_equals(node1, node2)
      end)
   end)

   describe("SpatialCell creation and basic operations", function()
      local cell

      before_each(function() cell = dll.createCell() end)

      it("should initialize empty cells correctly", function()
         assert.falsy(cell.firstNode)
         assert.falsy(cell.lastNode)
         assert.equals(0, cell:getCount())
         assert.truthy(cell:isEmpty())
      end)

      it("should support O(1) insertion at beginning", function()
         local obj1 = { id = "obj1" }
         local obj2 = { id = "obj2" }

         local node1 = cell:insertBeginning(obj1, 10, 10, 8, 8)
         assert.equals(1, cell:getCount())
         assert.equals(obj1, cell.firstNode.data.obj)
         assert.equals(obj1, cell.lastNode.data.obj)

         local node2 = cell:insertBeginning(obj2, 20, 20, 8, 8)
         assert.equals(2, cell:getCount())
         assert.equals(obj2, cell.firstNode.data.obj)
         assert.equals(obj1, cell.lastNode.data.obj)

         -- Check links are correct
         assert.equals(node1, node2.next)
         assert.equals(node2, node1.prev)
      end)

      it("should support O(1) insertion at end", function()
         local obj1 = { id = "obj1" }
         local obj2 = { id = "obj2" }

         local node1 = cell:insertEnd(obj1, 10, 10, 8, 8)
         assert.equals(1, cell:getCount())
         assert.equals(obj1, cell.firstNode.data.obj)
         assert.equals(obj1, cell.lastNode.data.obj)

         local node2 = cell:insertEnd(obj2, 20, 20, 8, 8)
         assert.equals(2, cell:getCount())
         assert.equals(obj1, cell.firstNode.data.obj)
         assert.equals(obj2, cell.lastNode.data.obj)

         -- Check links are correct
         assert.equals(node2, node1.next)
         assert.equals(node1, node2.prev)
      end)

      it("should support O(1) removal operations", function()
         local obj = { id = "test" }
         local node = cell:insertBeginning(obj, 10, 10, 8, 8)

         assert.equals(1, cell:getCount())

         local removed = cell:remove(node)
         assert.equals(obj, removed.data.obj)
         assert.equals(0, cell:getCount())
         assert.falsy(cell.firstNode)
         assert.falsy(cell.lastNode)
         assert.truthy(cell:isEmpty())

         -- Check that removed node is cleaned up
         assert.falsy(removed.next)
         assert.falsy(removed.prev)
      end)

      it("should handle removal from middle of list", function()
         local obj1 = { id = "obj1" }
         local obj2 = { id = "obj2" }
         local obj3 = { id = "obj3" }

         local node1 = cell:insertEnd(obj1, 10, 10, 8, 8)
         local node2 = cell:insertEnd(obj2, 20, 20, 8, 8)
         local node3 = cell:insertEnd(obj3, 30, 30, 8, 8)

         assert.equals(3, cell:getCount())

         -- Remove middle node
         cell:remove(node2)
         assert.equals(2, cell:getCount())
         assert.equals(obj1, cell.firstNode.data.obj)
         assert.equals(obj3, cell.lastNode.data.obj)

         -- Check that links are correct
         assert.equals(node3, node1.next)
         assert.equals(node1, node3.prev)
      end)
   end)

   describe("bidirectional traversal", function()
      local cell

      before_each(function()
         cell = dll.createCell()

         -- Insert objects in order: obj1, obj2, obj3
         cell:insertEnd({ id = "obj1" }, 10, 10, 8, 8)
         cell:insertEnd({ id = "obj2" }, 20, 20, 8, 8)
         cell:insertEnd({ id = "obj3" }, 30, 30, 8, 8)
      end)

      it("should support forward traversal", function()
         local visited = {}

         cell:traverseForwards(function(node)
            table.insert(visited, node.data.obj.id)
            return true -- Continue traversal
         end)

         assert.same({ "obj1", "obj2", "obj3" }, visited)
      end)

      it("should support backward traversal", function()
         local visited = {}

         cell:traverseBackwards(function(node)
            table.insert(visited, node.data.obj.id)
            return true -- Continue traversal
         end)

         assert.same({ "obj3", "obj2", "obj1" }, visited)
      end)

      it("should support early termination in forward traversal", function()
         local visited = {}

         cell:traverseForwards(function(node)
            table.insert(visited, node.data.obj.id)
            if node.data.obj.id == "obj2" then
               return false -- Stop traversal
            end
            return true -- Continue traversal
         end)

         assert.same({ "obj1", "obj2" }, visited)
      end)

      it("should support early termination in backward traversal", function()
         local visited = {}

         cell:traverseBackwards(function(node)
            table.insert(visited, node.data.obj.id)
            if node.data.obj.id == "obj2" then
               return false -- Stop traversal
            end
            return true -- Continue traversal
         end)

         assert.same({ "obj3", "obj2" }, visited)
      end)
   end)

   describe("object finding and querying", function()
      local cell
      local obj1, obj2, obj3

      before_each(function()
         cell = dll.createCell()
         obj1 = { id = "obj1", type = "enemy" }
         obj2 = { id = "obj2", type = "pickup" }
         obj3 = { id = "obj3", type = "enemy" }

         cell:insertEnd(obj1, 10, 10, 8, 8)
         cell:insertEnd(obj2, 20, 20, 4, 4)
         cell:insertEnd(obj3, 30, 30, 8, 8)
      end)

      it("should find objects by reference", function()
         local node1 = cell:find(obj1)
         assert.truthy(node1)
         assert.equals(obj1, node1.data.obj)

         local node2 = cell:find(obj2)
         assert.truthy(node2)
         assert.equals(obj2, node2.data.obj)

         local node_not_found = cell:find({ id = "not_exists" })
         assert.falsy(node_not_found)
      end)

      it("should query all objects without filter", function()
         local results = cell:query()

         assert.truthy(results[obj1])
         assert.truthy(results[obj2])
         assert.truthy(results[obj3])

         -- Count results
         local count = 0
         for _ in pairs(results) do
            count = count + 1
         end
         assert.equals(3, count)
      end)

      it("should query objects with filter function", function()
         local enemy_filter = function(obj) return obj.type == "enemy" end

         local results = cell:query(enemy_filter)

         assert.truthy(results[obj1])
         assert.falsy(results[obj2]) -- obj2 is pickup, not enemy
         assert.truthy(results[obj3])

         -- Count results
         local count = 0
         for _ in pairs(results) do
            count = count + 1
         end
         assert.equals(2, count)
      end)
   end)

   describe("cell management operations", function()
      local cell

      before_each(function() cell = dll.createCell() end)

      it("should clear all objects from cell", function()
         cell:insertEnd({ id = "obj1" }, 10, 10, 8, 8)
         cell:insertEnd({ id = "obj2" }, 20, 20, 8, 8)

         assert.equals(2, cell:getCount())
         assert.falsy(cell:isEmpty())

         cell:clear()

         assert.equals(0, cell:getCount())
         assert.truthy(cell:isEmpty())
         assert.falsy(cell.firstNode)
         assert.falsy(cell.lastNode)
      end)

      it("should handle operations on empty cell gracefully", function()
         assert.truthy(cell:isEmpty())
         assert.equals(0, cell:getCount())

         -- Query empty cell
         local results = cell:query()
         local count = 0
         for _ in pairs(results) do
            count = count + 1
         end
         assert.equals(0, count)

         -- Find in empty cell
         local node = cell:find({ id = "test" })
         assert.falsy(node)

         -- Traverse empty cell
         local visited = 0
         cell:traverseForwards(function(node)
            visited = visited + 1
            return true
         end)
         assert.equals(0, visited)
      end)
   end)

   describe("Lua 5.4+ compatibility", function()
      it("should work with integer division operator", function()
         -- Test that we can use // operator in spatial calculations
         local grid_size = 32
         local x = 75
         local grid_x = x // grid_size -- Should be 2

         assert.equals(2, grid_x)

         -- Test with negative coordinates
         local neg_x = -10
         local neg_grid_x = neg_x // grid_size -- Should be -1

         assert.equals(-1, neg_grid_x)
      end)

      it("should handle large object counts efficiently", function()
         local cell = dll.createCell()
         local objects = {}

         -- Insert 100 objects
         for i = 1, 100 do
            local obj = { id = string.format("obj_%d", i) }
            objects[i] = obj
            cell:insertEnd(obj, i, i, 8, 8)
         end

         assert.equals(100, cell:getCount())

         -- Query all objects
         local results = cell:query()
         local count = 0
         for _ in pairs(results) do
            count = count + 1
         end
         assert.equals(100, count)

         -- Remove all objects
         for i = 1, 100 do
            local node = cell:find(objects[i])
            assert.truthy(node)
---@diagnostic disable-next-line: param-type-mismatch
            cell:remove(node)
         end

         assert.equals(0, cell:getCount())
         assert.truthy(cell:isEmpty())
      end)
   end)
end)
