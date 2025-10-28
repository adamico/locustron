--- @diagnostic disable: undefined-global different-require
-- Locustron Userdata Performance Benchmark
-- Focused testing of userdata implementation performance characteristics
-- Measures absolute performance metrics for the unified implementation
-- Run in Picotron console: include("benchmarks/picotron/benchmark_userdata_performance.lua")

include("../../src/picotron/require.lua")
local locustron = require("../../src/picotron/locustron")

-- Test Configuration
local OBJECT_COUNTS = { 100, 500, 1000, 2000 }
local GRID_SIZE = 32 -- Fixed grid for consistent comparison
local ITERATIONS = { add = 50, update = 30, query = 20, delete = 25 }

local function create_test_objects(count)
   local objects = {}
   for i = 1, count do
      objects[i] = {
         x = rnd(500),
         y = rnd(500),
         w = 8 + rnd(16),
         h = 8 + rnd(16),
         id = i,
         type = (i % 3 == 0) and "enemy" or "item",
      }
   end
   return objects
end

local function benchmark_add_operations(object_count)
   local loc = locustron(GRID_SIZE)
   local objects = create_test_objects(object_count)

   local start_time = time()
   local operations = 0

   for i = 1, min(ITERATIONS.add, #objects) do
      local obj = objects[i]
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
      operations = operations + 1
   end

   local elapsed = time() - start_time
   local ops_per_second = operations / max(elapsed, 0.001)
   local memory_bytes = stat(3)

   return ops_per_second, memory_bytes, operations
end

local function benchmark_update_operations(object_count)
   local loc = locustron(GRID_SIZE)
   local objects = create_test_objects(object_count)

   -- Pre-populate with objects
   for _, obj in pairs(objects) do
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   local start_time = time()
   local operations = 0

   for i = 1, min(ITERATIONS.update, #objects) do
      local obj = objects[i]
      local new_x = obj.x + rnd(40) - 20
      local new_y = obj.y + rnd(40) - 20
      loc.update(obj, new_x, new_y, obj.w, obj.h)
      operations = operations + 1
   end

   local elapsed = time() - start_time
   local ops_per_second = operations / max(elapsed, 0.001)

   return ops_per_second, operations
end

local function benchmark_query_operations(object_count)
   local loc = locustron(GRID_SIZE)
   local objects = create_test_objects(object_count)

   -- Pre-populate with objects
   for _, obj in pairs(objects) do
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   local start_time = time()
   local operations = 0
   local total_results = 0

   for i = 1, ITERATIONS.query do
      local qx = rnd(400)
      local qy = rnd(400)
      local results = loc.query(qx, qy, 64, 64)

      local count = 0
      for obj in pairs(results) do
         count = count + 1
      end
      total_results = total_results + count
      operations = operations + 1
   end

   local elapsed = time() - start_time
   local ops_per_second = operations / max(elapsed, 0.001)
   local avg_results = total_results / operations

   return ops_per_second, avg_results, operations
end

local function benchmark_filtered_query_operations(object_count)
   local loc = locustron(GRID_SIZE)
   local objects = create_test_objects(object_count)

   -- Pre-populate with objects
   for _, obj in pairs(objects) do
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   -- Filter function
   local function is_enemy(obj) return obj.type == "enemy" end

   local start_time = time()
   local operations = 0
   local total_results = 0

   for i = 1, ITERATIONS.query do
      local qx = rnd(400)
      local qy = rnd(400)
      local results = loc.query(qx, qy, 64, 64, is_enemy)

      local count = 0
      for obj in pairs(results) do
         count = count + 1
      end
      total_results = total_results + count
      operations = operations + 1
   end

   local elapsed = time() - start_time
   local ops_per_second = operations / max(elapsed, 0.001)
   local avg_results = total_results / operations

   return ops_per_second, avg_results, operations
end

local function benchmark_delete_operations(object_count)
   local loc = locustron(GRID_SIZE)
   local objects = create_test_objects(object_count)

   -- Pre-populate with objects
   for _, obj in pairs(objects) do
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   end

   local start_time = time()
   local operations = 0

   for i = 1, min(ITERATIONS.delete, #objects) do
      local obj = objects[i]
      loc.del(obj)
      operations = operations + 1
   end

   local elapsed = time() - start_time
   local ops_per_second = operations / max(elapsed, 0.001)

   return ops_per_second, operations
end

local function run_userdata_performance_benchmark()
   printh("\27[1m\27[36m=== LOCUSTRON USERDATA PERFORMANCE BENCHMARK ===\27[0m")
   printh("Measuring absolute performance of userdata implementation")
   printh("Grid size: " .. GRID_SIZE)
   printh("\n")

   printh("\27[1m\27[34m=== ADD OPERATIONS ===\27[0m")
   printh("Objects | Ops/Sec | Memory | Operations")
   printh("--------|---------|--------|----------")

   for _, count in pairs(OBJECT_COUNTS) do
      local ops_per_sec, memory_bytes, operations = benchmark_add_operations(count)
      printh(string.format("%7d | %7.0f | %6.1fK | %9d", count, ops_per_sec, memory_bytes / 1024, operations))
   end
   printh("\n")

   printh("\27[1m\27[34m=== UPDATE OPERATIONS ===\27[0m")
   printh("Objects | Ops/Sec | Operations")
   printh("--------|---------|----------")

   for _, count in pairs(OBJECT_COUNTS) do
      local ops_per_sec, operations = benchmark_update_operations(count)
      printh(string.format("%7d | %7.0f | %9d", count, ops_per_sec, operations))
   end
   printh("\n")

   printh("\27[1m\27[34m=== QUERY OPERATIONS ===\27[0m")
   printh("Objects | Ops/Sec | Avg Results | Operations")
   printh("--------|---------|-------------|----------")

   for _, count in pairs(OBJECT_COUNTS) do
      local ops_per_sec, avg_results, operations = benchmark_query_operations(count)
      printh(string.format("%7d | %7.0f | %11.1f | %9d", count, ops_per_sec, avg_results, operations))
   end
   printh("\n")

   printh("\27[1m\27[34m=== FILTERED QUERY OPERATIONS ===\27[0m")
   printh("Objects | Ops/Sec | Avg Results | Operations")
   printh("--------|---------|-------------|----------")

   for _, count in pairs(OBJECT_COUNTS) do
      local ops_per_sec, avg_results, operations = benchmark_filtered_query_operations(count)
      printh(string.format("%7d | %7.0f | %11.1f | %9d", count, ops_per_sec, avg_results, operations))
   end
   printh("\n")

   printh("\27[1m\27[34m=== DELETE OPERATIONS ===\27[0m")
   printh("Objects | Ops/Sec | Operations")
   printh("--------|---------|----------")

   for _, count in pairs(OBJECT_COUNTS) do
      local ops_per_sec, operations = benchmark_delete_operations(count)
      printh(string.format("%7d | %7.0f | %9d", count, ops_per_sec, operations))
   end
   printh("\n")

   printh("\27[1m\27[36m=== PERFORMANCE ANALYSIS ===\27[0m")
   printh("This benchmark measures the raw performance of userdata operations.")
   printh("Higher operations/second indicates better performance.")
   printh("Memory usage shows Picotron RAM consumption during operations.")
   printh("Results demonstrate userdata efficiency for spatial hash operations.")
   printh("\n")
   printh("TYPICAL PERFORMANCE EXPECTATIONS:")
   printh("- Add operations: 500-2000 ops/sec")
   printh("- Update operations: 300-1000 ops/sec")
   printh("- Query operations: 200-800 ops/sec")
   printh("- Delete operations: 400-1500 ops/sec")
   printh("- Filtered queries: 150-600 ops/sec (due to function calls)")
end

-- Auto-run when included
run_userdata_performance_benchmark()

return {
   run_userdata_performance_benchmark = run_userdata_performance_benchmark,
   benchmark_add_operations = benchmark_add_operations,
   benchmark_update_operations = benchmark_update_operations,
   benchmark_query_operations = benchmark_query_operations,
   benchmark_delete_operations = benchmark_delete_operations,
}
