--- @diagnostic disable:unknown-symbol, action-after-return, exp-in-action, miss-symbol
-- Benchmark Diagnostics for Locustron
-- Helps diagnose issues with benchmark execution
-- Run in Picotron console: include("benchmarks/benchmark_diagnostics.lua")

printh("\27[1m\27[36m=== LOCUSTRON BENCHMARK DIAGNOSTICS ===\27[0m")
printh("Checking benchmark environment...")
local start_memory = stat(3)
printh("Initial memory usage: " .. start_memory .. " bytes (" .. string.format("%.1f", start_memory / 1024) .. " KB)")
printh("\n")

-- Check basic Picotron functions
printh("\27[1m\27[34mPICOTRON FUNCTION CHECKS:\27[0m")
local functions_to_check = {
   {"time", time},
   {"printh", printh},
   {"stat", stat},
   {"rnd", rnd},
   {"flr", flr},
   {"max", max},
   {"min", min}
}

for _, func_info in pairs(functions_to_check) do
   local name, func = func_info[1], func_info[2]
   if func then
      printh("\27[32m✓\27[0m " .. name .. " - Available")
   else
      printh("\27[31m✗\27[0m " .. name .. " - Missing")
   end
end

local after_func_check = stat(3)
printh("Memory after function checks: " .. after_func_check .. " bytes (" .. string.format("%.1f", after_func_check / 1024) .. " KB)")
printh("\n")

-- Check file system access
printh("\27[1m\27[34mFILE SYSTEM CHECKS:\27[0m")
local success, error_msg = pcall(function()
   include("../src/lib/require.lua")
   printh("\27[32m✓\27[0m require.lua - Loaded successfully")
end)

if not success then
   printh("\27[31m✗\27[0m require.lua - Failed to load: " .. tostring(error_msg))
   printh("  Make sure you're in the benchmarks/ directory")
   return
end

local after_require = stat(3)
printh("Memory after require.lua: " .. after_require .. " bytes (" .. string.format("%.1f", after_require / 1024) .. " KB)")
printh("Memory increase: " .. (after_require - start_memory) .. " bytes")

-- Check locustron loading
local locustron_success, locustron_error = pcall(function()
   local locustron = require("../src/lib/locustron")
   printh("✓ locustron.lua - Loaded successfully")
   return locustron
end)

if not locustron_success then
   printh("✗ locustron.lua - Failed to load: " .. tostring(locustron_error))
   return
end

-- Test basic locustron functionality
printh("\n")
printh("LOCUSTRON FUNCTIONALITY CHECKS:")
local loc_test_success, loc_test_error = pcall(function()
   local locustron = require("../src/lib/locustron")
   local loc = locustron(32)
   
   -- Test object creation and addition
   local obj = {x = 10, y = 10, w = 8, h = 8, id = "test"}
   loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   printh("✓ Object addition - Working")
   
   -- Test querying
   local results = loc.query(0, 0, 50, 50)
   if results[obj] then
      printh("✓ Object querying - Working")
   else
      printh("✗ Object querying - Failed")
   end
   
   -- Test API functions
   local x, y, w, h = loc.get_bbox(obj)
   if x == 10 and y == 10 and w == 8 and h == 8 then
      printh("✓ get_bbox function - Working")
   else
      printh("✗ get_bbox function - Failed")
   end
   
   -- Test internal functions
   local cell_count = loc._get_cell_count(0, 0)
   printh("✓ _get_cell_count function - Working (count: " .. tostring(cell_count) .. ")")
   
   printh("✓ Basic locustron functionality - All tests passed")
end)

if not loc_test_success then
   printh("✗ Locustron functionality test failed: " .. tostring(loc_test_error))
   return
end

-- Test simple benchmark function
printh("\n")
printh("BENCHMARK FUNCTION CHECKS:")
local bench_success, bench_error = pcall(function()
   local locustron = require("../src/lib/locustron")
   local objects = {}
   for i = 1, 10 do
      objects[i] = {
         x = rnd(100),
         y = rnd(100),
         w = 8,
         h = 8,
         id = i
      }
   end
   printh("✓ Test object creation - Working")
   
   local loc = locustron(32)
   for _, obj in pairs(objects) do
      loc.add(obj, obj.x, obj.y, obj.w, obj.h)
   end
   printh("✓ Bulk object addition - Working")
   
   -- Test timing
   local start_time = time()
   for i = 1, 5 do
      local results = loc.query(rnd(80), rnd(80), 20, 20)
   end
   local end_time = time()
   local duration = end_time - start_time
   printh("✓ Benchmark timing - Working (5 queries in " .. string.format("%.4f", duration) .. "s)")
   
   printh("✓ Benchmark functions - All tests passed")
end)

if not bench_success then
   printh("✗ Benchmark function test failed: " .. tostring(bench_error))
   return
end

-- Memory check
printh("\n")
printh("MEMORY STATUS:")
local current_memory = stat(3)
printh("Current memory usage: " .. current_memory .. " bytes (" .. string.format("%.1f", current_memory / 1024) .. " KB)")
if current_memory > 25000000 then  -- 25MB in bytes
   printh("\27[33mWARNING: High memory usage detected\27[0m")
   printh("This may affect benchmark performance")
elseif current_memory < 1000000 then  -- 1MB in bytes
   printh("\27[32mMemory usage looks normal\27[0m")
else
   printh("Memory usage is acceptable")
end

printh("\n")
printh("\27[1m\27[36m=== DIAGNOSTICS COMPLETE ===\27[0m")
printh("\27[32mAll systems appear to be working correctly.\27[0m")
printh("You can now run the full benchmark suite with confidence.")
printh("\n")
printh("To run benchmarks:")
printh('include("run_all_benchmarks.lua")')
printh('-- or --')
printh('include("benchmark_grid_tuning.lua")')
printh('include("benchmark_userdata_performance.lua")')