#!/usr/bin/env lua

-- Load the refactored locus library
local locus = require("src.lib.locus")

-- Simple test to verify the refactoring works
print("Testing refactored locus library...")

-- Create a locus instance
local loc = locus(32)

-- Test basic operations
local obj1 = {id = 1}
local obj2 = {id = 2}
local obj3 = {id = 3}

-- Add objects
print("Adding objects...")
loc.add(obj1, 10, 10, 8, 8)
loc.add(obj2, 50, 50, 8, 8)
loc.add(obj3, 15, 15, 8, 8)

-- Query objects
print("Querying objects...")
local results = loc.query(0, 0, 64, 64)
local count = 0
for obj in pairs(results) do
    count = count + 1
    print("Found object:", obj.id)
end
print("Total objects found:", count)

-- Update an object
print("Updating object...")
loc.update(obj1, 100, 100, 8, 8)

-- Query again
print("Querying after update...")
local results2 = loc.query(0, 0, 64, 64)
local count2 = 0
for obj in pairs(results2) do
    count2 = count2 + 1
    print("Found object:", obj.id)
end
print("Total objects found after update:", count2)

-- Test with filter
print("Testing with filter...")
local function is_obj1(obj)
    return obj.id == 1
end

local filtered = loc.query(0, 0, 200, 200, is_obj1)
local filtered_count = 0
for obj in pairs(filtered) do
    filtered_count = filtered_count + 1
    print("Filtered result:", obj.id)
end
print("Filtered objects found:", filtered_count)

-- Delete objects
print("Deleting objects...")
loc.del(obj1)
loc.del(obj2)
loc.del(obj3)

print("Test completed successfully!")