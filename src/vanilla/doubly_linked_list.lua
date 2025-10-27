-- Doubly Linked List Implementation for Spatial Cells
-- Optimized for spatial partitioning use cases

--- @class SpatialNode
--- @field data table Object data with spatial properties
--- @field next SpatialNode | nil
--- @field prev SpatialNode | nil
local SpatialNode = {}
SpatialNode.__index = SpatialNode

--- Create a new spatial node
--- @param obj any Object reference
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return SpatialNode
function SpatialNode:new(obj, x, y, w, h)
   return setmetatable({
      data = {
         obj = obj,
         x = x,
         y = y,
         w = w,
         h = h
      },
      next = nil,
      prev = nil,
   }, self)
end

--- @class SpatialCell
--- @field private firstNode SpatialNode | nil
--- @field private lastNode SpatialNode | nil
--- @field private count number
local SpatialCell = {}
SpatialCell.__index = SpatialCell

--- Create a new spatial cell
--- @return SpatialCell
function SpatialCell:new()
   return setmetatable({
      firstNode = nil,
      lastNode = nil,
      count = 0,
   }, self)
end

-- Standard doubly linked list insertion operations

--- Insert at beginning of list (O(1) operation)
--- @param obj any Object to insert
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return SpatialNode The created node
function SpatialCell:insertBeginning(obj, x, y, w, h)
   local newNode = SpatialNode:new(obj, x, y, w, h)

   if self.firstNode == nil then
      -- Empty list case
      self.firstNode = newNode
      self.lastNode = newNode
      newNode.prev = nil
      newNode.next = nil
   else
      -- Insert before first node
      self:insertBefore(self.firstNode, newNode)
   end

   self.count = self.count + 1
   return newNode
end

--- Insert at end of list (O(1) operation)
--- @param obj any Object to insert
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return SpatialNode The created node
function SpatialCell:insertEnd(obj, x, y, w, h)
   local newNode = SpatialNode:new(obj, x, y, w, h)

   if self.lastNode == nil then
      -- Empty list case
      self.firstNode = newNode
      self.lastNode = newNode
      newNode.prev = nil
      newNode.next = nil
   else
      -- Insert after last node
      self:insertAfter(self.lastNode, newNode)
   end

   self.count = self.count + 1
   return newNode
end

--- Insert before a given node
--- @param node SpatialNode Reference node
--- @param newNode SpatialNode Node to insert
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

--- Insert after a given node
--- @param node SpatialNode Reference node
--- @param newNode SpatialNode Node to insert
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

--- Remove a node
--- @param node SpatialNode Node to remove
--- @return SpatialNode | nil The removed node
function SpatialCell:remove(node)
   if not node then return nil end

   -- Remove node from doubly linked list
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

   -- Clean up the removed node
   node.next = nil
   node.prev = nil

   return node
end

--- Traverse forwards through the list
--- @param fn fun(node: SpatialNode): boolean | nil Callback function, return false to stop early
function SpatialCell:traverseForwards(fn)
   local node = self.firstNode
   while node ~= nil do
      local continue = fn(node)
      if continue == false then
         break
      end
      node = node.next
   end
end

--- Traverse backwards through the list
--- @param fn fun(node: SpatialNode): boolean | nil Callback function, return false to stop early
function SpatialCell:traverseBackwards(fn)
   local node = self.lastNode
   while node ~= nil do
      local continue = fn(node)
      if continue == false then
         break
      end
      node = node.prev
   end
end

--- Find a node by object reference
--- @param obj any Object to find
--- @return SpatialNode | nil The node containing the object
function SpatialCell:find(obj)
   local found_node = nil

   self:traverseForwards(function(node)
      if node.data.obj == obj then
         found_node = node
         return false -- Stop traversal
      end
      return true  -- Continue traversal
   end)

   return found_node
end

--- Query objects in cell with optional filter
--- @param filter_fn function | nil Optional filter function
--- @return table Results hash {[obj] = true}
function SpatialCell:query(filter_fn)
   local results = {}

   self:traverseForwards(function(node)
      local obj = node.data.obj
      if not filter_fn or filter_fn(obj) then
         results[obj] = true
      end
      return true -- Continue traversal
   end)

   return results
end

--- Get the number of objects in this cell
--- @return number Object count
function SpatialCell:getCount()
   return self.count
end

--- Check if the cell is empty
--- @return boolean True if empty
function SpatialCell:isEmpty()
   return self.count == 0
end

--- Clear all objects from the cell
function SpatialCell:clear()
   self.firstNode = nil
   self.lastNode = nil
   self.count = 0
end

-- Factory functions for external use
local M = {}

--- Create a new spatial cell
--- @return SpatialCell
function M.createCell()
   return SpatialCell:new()
end

--- Create a new spatial node
--- @param obj any Object reference
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param w number Width
--- @param h number Height
--- @return SpatialNode
function M.createNode(obj, x, y, w, h)
   return SpatialNode:new(obj, x, y, w, h)
end

-- Export classes for testing
M.SpatialCell = SpatialCell
M.SpatialNode = SpatialNode

return M
