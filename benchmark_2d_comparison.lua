-- A/B Performance Benchmark: 1D vs 2D Userdata Locustron
-- Tests identical workloads on both implementations to measure performance differences

local require = include and include or require
local locustron_1d = require("lib/locustron")
local locustron_2d = require("lib/locustron_2d")

-- Benchmark configuration
local TESTS = {
   {name = "1k objects", object_count = 1000},
   {name = "5k objects", object_count = 5000},
   {name = "10k objects", object_count = 10000}
}

local OPERATIONS = {
   "add", "query", "update", "delete"
}

-- Test data generation
local function generate_test_objects(count)
   local objects = {}
   for i = 1, count do
      objects[i] = {
         id = i,
         x = rnd and rnd(1000) or math.random(1000),
         y = rnd and rnd(1000) or math.random(1000),
         w = 8 + (rnd and rnd(16) or math.random(16)),
         h = 8 + (rnd and rnd(16) or math.random(16))
      }
   end
   return objects
end

-- Timing utility
local function time_ms()
   if time then
      return time() * 1000  -- Picotron time() returns seconds
   else
      return 0  -- Fallback for testing without os.clock
   end
end

-- Benchmark runner
local function benchmark_operation(loc, operation, objects, iterations)
   iterations = iterations or 1
   
   local start_time = time_ms()
   
   for iter = 1, iterations do
      if operation == "add" then
         for _, obj in ipairs(objects) do
            loc.add(obj, obj.x, obj.y, obj.w, obj.h)
         end
         
      elseif operation == "query" then
         -- Query random regions
         local query_count = math.max(1, math.floor(#objects / 10)) -- Query 10% as many times as objects
         for i = 1, query_count do
            local x = rnd and rnd(900) or math.random(900)
            local y = rnd and rnd(900) or math.random(900)
            local result = loc.query(x, y, 100, 100)
            -- Process results to avoid optimization
            local count = 0
            for _ in pairs(result) do count = count + 1 end
         end
         
      elseif operation == "update" then
         for _, obj in ipairs(objects) do
            obj.x = obj.x + (rnd and rnd(20) - 10 or math.random(20) - 10)
            obj.y = obj.y + (rnd and rnd(20) - 10 or math.random(20) - 10)
            loc.update(obj, obj.x, obj.y, obj.w, obj.h)
         end
         
      elseif operation == "delete" then
         for _, obj in ipairs(objects) do
            loc.del(obj)
         end
      end
   end
   
   local end_time = time_ms()
   return end_time - start_time
end

-- Single benchmark test
local function run_benchmark_test(implementation_name, loc_factory, test_config)
   local results = {}
   
   -- Warm up
   local warmup_objects = generate_test_objects(100)
   local warmup_loc = loc_factory(32)
   benchmark_operation(warmup_loc, "add", warmup_objects)
   
   printh(string.format("Testing %s with %s:", implementation_name, test_config.name))
   
   for _, operation in ipairs(OPERATIONS) do
      local objects = generate_test_objects(test_config.object_count)
      local loc = loc_factory(32)
      
      -- For operations that need pre-populated data
      if operation ~= "add" then
         benchmark_operation(loc, "add", objects)
      end
      
      local duration = benchmark_operation(loc, operation, objects)
      results[operation] = duration
      
      printh(string.format("  %s: %.2f ms", operation, duration))
   end
   
   return results
end

-- Compare results
local function calculate_speedup(time_1d, time_2d)
   if time_2d == 0 then return "inf" end
   local speedup = time_1d / time_2d
   if speedup > 1 then
      return string.format("%.1fx faster", speedup)
   else
      return string.format("%.1fx slower", 1 / speedup)
   end
end

-- Main benchmark runner
local function run_performance_comparison()
   printh("=== Locustron Performance Comparison: 1D vs 2D Userdata ===")
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
   
   for test_name, results in pairs(all_results) do
      local test_total_1d, test_total_2d = 0, 0
      for _, operation in ipairs(OPERATIONS) do
         test_total_1d = test_total_1d + results["1d"][operation]
         test_total_2d = test_total_2d + results["2d"][operation]
      end
      total_1d = total_1d + test_total_1d
      total_2d = total_2d + test_total_2d
      
      local test_speedup = calculate_speedup(test_total_1d, test_total_2d)
      printh(string.format("%s overall: %s", test_name, test_speedup))
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
   run_performance_comparison()
end

return benchmark