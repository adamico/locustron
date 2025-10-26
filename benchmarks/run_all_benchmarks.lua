-- Benchmark Runner for Locustron
-- Runs all available benchmarks with timing information
-- Run in Picotron console: include("benchmarks/run_all_benchmarks.lua")

printh("=== LOCUSTRON BENCHMARK SUITE ===")
printh("Running comprehensive performance analysis...")
printh("Start time: " .. time())
printh()

-- Run Grid Tuning Benchmark
printh(">>> STARTING GRID TUNING BENCHMARK <<<")
local start_grid = time()
include("benchmark_grid_tuning.lua")
local end_grid = time()
printh("Grid tuning benchmark completed in " .. string.format("%.2f", end_grid - start_grid) .. " seconds")
printh()

-- Run Userdata Performance Benchmark  
printh(">>> STARTING USERDATA PERFORMANCE BENCHMARK <<<")
local start_userdata = time()
include("benchmark_userdata_performance.lua")
local end_userdata = time()
printh("Userdata performance benchmark completed in " .. string.format("%.2f", end_userdata - start_userdata) .. " seconds")
printh()

-- Summary
local total_time = time() - start_grid
printh("=== BENCHMARK SUITE COMPLETE ===")
printh("Total execution time: " .. string.format("%.2f", total_time) .. " seconds")
printh("Memory usage: " .. string.format("%.1f", stat(3)) .. " KB")
printh()
printh("NEXT STEPS:")
printh("1. Review grid size recommendations for your object sizes")
printh("2. Consider performance trade-offs based on your game's needs")
printh("3. Test with your actual game objects and query patterns")
printh("4. Monitor memory usage during development")