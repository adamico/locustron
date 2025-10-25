#!/usr/bin/env lua

-- Performance benchmark for refactored locus library
local locus = require("src.lib.locus")

local function benchmark(name, func)
    print(string.format("Benchmarking %s...", name))
    local start_time = os.clock()
    func()
    local end_time = os.clock()
    print(string.format("%s completed in %.4f seconds", name, end_time - start_time))
end

-- Test with thousands of objects
print("=== Performance Benchmark with 10,000 objects ===")

local loc = locus(64) -- Larger grid size for better performance with many objects
local objects = {}

-- Generate objects
for i = 1, 10000 do
    objects[i] = {
        id = i,
        x = math.random(0, 2000),
        y = math.random(0, 2000),
        w = math.random(8, 32),
        h = math.random(8, 32)
    }
end

-- Benchmark adding objects
benchmark("Adding 10,000 objects", function()
    for i, obj in ipairs(objects) do
        loc.add(obj, obj.x, obj.y, obj.w, obj.h)
    end
end)

-- Benchmark queries
benchmark("1,000 queries (64x64 area)", function()
    for i = 1, 1000 do
        local x, y = math.random(0, 1936), math.random(0, 1936) -- 2000 - 64
        local results = loc.query(x, y, 64, 64)
        -- Count results to ensure query actually executes
        local count = 0
        for _ in pairs(results) do count = count + 1 end
    end
end)

-- Benchmark updates
benchmark("Updating 1,000 random objects", function()
    for i = 1, 1000 do
        local obj = objects[math.random(1, #objects)]
        obj.x = math.random(0, 2000)
        obj.y = math.random(0, 2000)
        loc.update(obj, obj.x, obj.y, obj.w, obj.h)
    end
end)

-- Benchmark filtered queries
benchmark("500 filtered queries", function()
    local function filter_small(obj)
        return obj.w < 20 and obj.h < 20
    end
    
    for i = 1, 500 do
        local x, y = math.random(0, 1936), math.random(0, 1936)
        local results = loc.query(x, y, 64, 64, filter_small)
        local count = 0
        for _ in pairs(results) do count = count + 1 end
    end
end)

-- Check memory usage (pool size)
local pool_size = 0
for _ in pairs(loc._pool) do pool_size = pool_size + 1 end
print(string.format("Pool size after operations: %d tables", pool_size))

print("=== Benchmark completed ===")