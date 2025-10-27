-- Benchmark Runner for Locustron
-- Runs all available benchmarks with timing information
-- Run in Picotron console: include("benchmarks/run_all_benchmarks.lua")

printh("\27[1m\27[36m=== LOCUSTRON BENCHMARK SUITE ===\27[0m")
printh("Running comprehensive performance analysis...")
printh("Start time: " .. time())
printh("\n")

-- Helper function to run benchmarks safely
function run_benchmark_safely(name, filename)
   local start_time = time()
   
   local success, error_msg = pcall(function()
      include(filename)
   end)
   
   local end_time = time()
   local duration = end_time - start_time
   
   if success then
      printh(name .. " (" .. string.format("%.3f", duration) .. "s)")
   else
      printh("\27[31mERROR in " .. name .. ": " .. tostring(error_msg) .. "\27[0m")
      printh("Duration: " .. string.format("%.3f", duration) .. " seconds")
   end
   printh("\n")
   
   return success, duration
end

-- Run benchmarks
local start_total = time()
local grid_success, grid_time = run_benchmark_safely("GRID TUNING BENCHMARK", "benchmark_grid_tuning.lua")
local perf_success, perf_time = run_benchmark_safely("USERDATA PERFORMANCE BENCHMARK", "benchmark_userdata_performance.lua")
local total_time = time() - start_total

-- Summary
printh("\27[1m\27[36m=== BENCHMARK SUITE COMPLETE ===\27[0m")
printh("Total execution time: " .. string.format("%.3f", total_time) .. " seconds")
printh("Grid tuning: " .. (grid_success and "\27[32mSUCCESS\27[0m" or "\27[31mFAILED\27[0m") .. " (" .. string.format("%.3f", grid_time) .. "s)")
printh("Performance: " .. (perf_success and "\27[32mSUCCESS\27[0m" or "\27[31mFAILED\27[0m") .. " (" .. string.format("%.3f", perf_time) .. "s)")

local memory_bytes = stat(3)
local memory_kb = memory_bytes / 1024
if memory_kb > 32768 then
   printh("Memory usage: " .. string.format("%.1f", memory_kb / 1024) .. " MB \27[33m(WARNING: High usage)\27[0m")
else
   printh("Memory usage: " .. string.format("%.1f", memory_kb) .. " KB")
end

printh("\n")
printh("NEXT STEPS:")
printh("1. Review grid size recommendations for your object sizes")
printh("2. Consider performance trade-offs based on your game's needs")
printh("3. Test with your actual game objects and query patterns")
printh("4. Monitor memory usage during development")

if not grid_success or not perf_success then
   printh("\n")
   printh("TROUBLESHOOTING:")
   printh("- Ensure you're running from the src/picotron/benchmarks/ directory")
   printh("- Check that all required files exist in src/picotron/")
   printh("- Try running individual benchmarks to isolate issues")
end