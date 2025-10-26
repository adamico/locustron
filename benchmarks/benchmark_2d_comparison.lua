--- @diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
-- A/B Performance Benchmark: 1D vs 2D Userdata Locustron
-- Tests identical workloads on both implementations to measure performance differences
-- 
-- NEW APPROACH: Single intensive operations designed for Picotron's 32MB RAM constraint.
-- Instead of many iterations, each test performs one complex operation that stresses
-- the differences between 1D array indexing vs 2D userdata method calls.
-- 
-- HOW TO RUN FROM PICOTRON CONSOLE:
-- 1. cd("/desktop/projects/locustron")  -- or wherever your project is
-- 2. include("benchmarks/benchmark_2d_comparison.lua")
-- 
-- OR drag and drop this file into the Picotron console

include("../src/lib/require.lua")
local locustron_1d = require("../src/lib/locustron")
local locustron_2d = require("../src/lib/locustron_2d")

printh("=== Locustron 1D vs 2D Performance Benchmark ===")
printh("Comparing performance between 1D and 2D userdata implementations...")
printh("")

-- Benchmark configuration - Single intensive operations for 32MB RAM constraint
local TESTS = {
   {name = "1k objects", object_count = 1000},
   {name = "5k objects", object_count = 5000},
   {name = "10k objects", object_count = 10000}
}

-- Intensive single-iteration operations that stress 1D vs 2D userdata differences
local OPERATIONS = {
   "bulk_add", "intensive_query", "grid_sweep", "bulk_delete"
}

-- Test data generation
local function generate_test_objects(count)
   local objects = {}
   for i = 1, count do
      objects[i] = {
         id = i,
         x = rnd(1000),
         y = rnd(1000),
         w = 8 + rnd(16),
         h = 8 + rnd(16)
      }
   end
   return objects
end

-- Timing utility - Operation counting for relative performance measurement
local operation_counter = 0

local function start_timing()
   operation_counter = 0
   return time()  -- Use Picotron's time() as baseline
end

local function count_operation()
   operation_counter = operation_counter + 1
end

local function end_timing(start_time)
   local elapsed_time = time() - start_time
   local ops_per_second = operation_counter / max(elapsed_time, 0.001)  -- Avoid division by zero
   return ops_per_second
end

-- Benchmark runner
local function benchmark_operation(loc, operation, objects)
   -- Memory check before starting
   local initial_memory = stat(3)
   printh(string.format("  Starting %s operation (memory: %.1fKB)", 
          operation, initial_memory))
   
   local start_time = start_timing()
   
   if operation == "bulk_add" then
      -- Single intensive operation: Add all objects at once
      for _, obj in ipairs(objects) do
         loc.add(obj, obj.x, obj.y, obj.w, obj.h)
         count_operation()  -- Count each add operation
      end
      
   elseif operation == "intensive_query" then
      -- Single intensive operation: Query entire grid systematically
      local grid_size = 32  -- Match locustron grid size
      local query_results = {}
      for x = 0, 1000, grid_size do
         for y = 0, 1000, grid_size do
            local result = loc.query(x, y, grid_size, grid_size)
            count_operation()  -- Count each query operation
            -- Process results to ensure work is done
            for obj in pairs(result) do
               query_results[obj] = true
            end
         end
      end
      
   elseif operation == "grid_sweep" then
      -- Single intensive operation: Update all objects in sweeping pattern
      for i, obj in ipairs(objects) do
         local offset = (i % 100) - 50  -- -50 to +49 offset
         local new_x = max(0, min(1000, obj.x + offset))
         local new_y = max(0, min(1000, obj.y + offset))
         obj.x = new_x
         obj.y = new_y
         loc.update(obj, new_x, new_y, obj.w, obj.h)
         count_operation()  -- Count each update operation
      end
      
   elseif operation == "bulk_delete" then
      -- Single intensive operation: Delete all objects
      for _, obj in ipairs(objects) do
         if loc.get_bbox then
            local x, y, w, h = loc.get_bbox(obj)
            if x then  -- Object exists in spatial hash
               loc.del(obj)
               count_operation()  -- Count each delete operation
            end
         end
      end
   end
   
   local ops_per_second = end_timing(start_time)
   local final_memory = stat(3)
   printh(string.format("  Completed %s operation (memory: %.1fKB)", operation, final_memory))
   
   return ops_per_second  -- Return operations per second as performance metric
end

-- Single benchmark test with intensive operations
local function run_benchmark_test(implementation_name, loc_factory, test_config)
   local results = {}
   
   printh(string.format("Testing %s with %s:", implementation_name, test_config.name))
   
   for _, operation in ipairs(OPERATIONS) do
      printh(string.format("  Starting %s test...", operation))
      
      local objects = generate_test_objects(test_config.object_count)
      local loc = loc_factory(32)
      
      -- For operations that need pre-populated data
      if operation ~= "bulk_add" then
         -- Pre-populate with bulk_add operation
         for _, obj in ipairs(objects) do
            loc.add(obj, obj.x, obj.y, obj.w, obj.h)
         end
      end
      
      local test_start = time()
      local duration = benchmark_operation(loc, operation, objects)
      local elapsed = time() - test_start
      
      -- Check for reasonable completion time
      if elapsed > 30 then
         printh(string.format("  %s: TIMEOUT (>30s)", operation))
         results[operation] = -1
      else
         results[operation] = duration
         printh(string.format("  %s: %.0f ops/sec", operation, duration))
      end
   end
   
   return results
end

-- Compare results (now using operations per second)
local function calculate_speedup(ops_1d, ops_2d)
   -- Handle timeout cases
   if ops_1d == -1 and ops_2d == -1 then
      return "both timed out"
   elseif ops_1d == -1 then
      return "1D timed out, 2D completed"
   elseif ops_2d == -1 then
      return "2D timed out, 1D completed"
   end
   
   if ops_2d <= 1 and ops_1d <= 1 then 
      return "both too slow to measure"
   end
   if ops_2d <= 1 then 
      return "2D too slow"
   end
   if ops_1d <= 1 then 
      return "1D too slow"
   end
   
   local speedup = ops_2d / ops_1d  -- Higher ops/sec is better
   local percent_change = ((ops_2d - ops_1d) / ops_1d) * 100
   
   if speedup > 1.05 then  -- More than 5% faster
      return string.format("2D %.1f%% faster (%.2fx)", percent_change, speedup)
   elseif speedup < 0.95 then  -- More than 5% slower
      return string.format("2D %.1f%% slower (%.2fx)", -percent_change, 1/speedup)
   else
      return string.format("no significant difference (%.1f%%)", percent_change)
   end
end

-- Main benchmark runner
local function run_performance_comparison()
   printh("=== Locustron Performance Comparison: 1D vs 2D Userdata ===")
   printh("Testing with high iteration counts and microsecond precision...")
   printh("")
   
   local all_results = {}
   
   for _, test_config in ipairs(TESTS) do
      printh(string.format("--- %s ---", test_config.name))
      
      -- Test 1D implementation
      local results_1d = run_benchmark_test("1D Userdata", locustron_1d, test_config)
      
      -- Test 2D implementation  
      local results_2d = run_benchmark_test("2D Userdata", locustron_2d, test_config)
      
      -- Calculate and display comparison
      printh("")
      printh("Performance Comparison:")
      for _, operation in ipairs(OPERATIONS) do
         local speedup = calculate_speedup(results_1d[operation], results_2d[operation])
         printh(string.format("  %s: %s", operation, speedup))
      end
      
      -- Store results
      all_results[test_config.name] = {
         ["1d"] = results_1d,
         ["2d"] = results_2d
      }
      
      printh("")
   end
   
   -- Overall summary
   printh("=== SUMMARY ===")
   local total_1d, total_2d = 0, 0
   local timeouts_1d, timeouts_2d = 0, 0
   
   for test_name, results in pairs(all_results) do
      local test_total_1d, test_total_2d = 0, 0
      local test_timeouts_1d, test_timeouts_2d = 0, 0
      
      for _, operation in ipairs(OPERATIONS) do
         local val_1d = results["1d"][operation]
         local val_2d = results["2d"][operation]
         
         if val_1d == -1 then
            test_timeouts_1d = test_timeouts_1d + 1
         else
            test_total_1d = test_total_1d + val_1d
         end
         
         if val_2d == -1 then
            test_timeouts_2d = test_timeouts_2d + 1
         else
            test_total_2d = test_total_2d + val_2d
         end
      end
      
      total_1d = total_1d + test_total_1d
      total_2d = total_2d + test_total_2d
      timeouts_1d = timeouts_1d + test_timeouts_1d
      timeouts_2d = timeouts_2d + test_timeouts_2d
      
      local test_speedup = calculate_speedup(test_total_1d, test_total_2d)
      printh(string.format("%s overall: %s", test_name, test_speedup))
   end
   
   if timeouts_1d > 0 or timeouts_2d > 0 then
      printh(string.format("Timeouts: 1D=%d, 2D=%d", timeouts_1d, timeouts_2d))
   end
   
   local overall_speedup = calculate_speedup(total_1d, total_2d)
   printh(string.format("OVERALL: %s", overall_speedup))
   
   return all_results
end

-- Export for use in other contexts
local benchmark = {
   run_comparison = run_performance_comparison,
   generate_test_objects = generate_test_objects,
   benchmark_operation = benchmark_operation,
   run_benchmark_test = run_benchmark_test
}

-- Auto-run if executed directly
if not ... then
   -- Running as main script
   printh("Starting benchmark in 3 seconds...")
   -- Small delay to let console settle
   for i = 3, 1, -1 do
      printh("Starting in " .. i .. "...")
      -- Add small delay here if needed
   end
   printh("")
   
   run_performance_comparison()
   
   printh("")
   printh("=== BENCHMARK COMPLETE ===")
   printh("Results show performance comparison between 1D and 2D implementations.")
   printh("Reduced iteration counts to prevent memory exhaustion.")
   printh("Positive percentages indicate 2D implementation is faster.")
   printh("Target was 5-15% improvement for 2D implementation.")
   printh("If timeouts occurred, consider further reducing object counts.")
end

return benchmark