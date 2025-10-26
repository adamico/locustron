-- Grid Size Tuning Benchmark for Locustron
-- Tests memory allocation vs query optimization trade-offs
-- Run in Picotron console: include("benchmarks/benchmark_grid_tuning.lua")

include("../src/lib/require.lua")
local locustron = require("../src/lib/locustron")

-- Benchmark Configuration
local GRID_SIZES = {16, 32, 64, 128}
local OBJECT_SIZES = {
   {name = "tiny", w = 4, h = 4},
   {name = "small", w = 8, h = 8},
   {name = "medium", w = 16, h = 16},
   {name = "large", w = 32, h = 32}
}
local OBJECT_COUNT = 50 -- Reduced for Picotron performance
local QUERY_SIZE = 64

-- Utility functions
function create_test_objects(count, obj_size)
   local objects = {}
   for i = 1, count do
      objects[i] = {
         x = rnd(200 - obj_size.w),
         y = rnd(200 - obj_size.h),
         w = obj_size.w,
         h = obj_size.h,
         id = i
      }
   end
   return objects
end

function count_cells_and_objects(loc)
   local cell_count = 0
   local total_objects = 0

   -- Access internal structure safely
   if loc._rows then
      for cy, row in pairs(loc._rows) do
         for cx, cell in pairs(row) do
            cell_count += 1
            local objects_in_cell = 0
            for obj in pairs(cell) do
               objects_in_cell += 1
            end
            total_objects += objects_in_cell
         end
      end
   end

   return cell_count, total_objects
end

function measure_query_precision(loc, objects, query_size)
   local total_candidates = 0
   local total_actual = 0
   local tests = 5 -- Reduced iterations for Picotron

   for i = 1, tests do
      local qx = rnd(200 - query_size)
      local qy = rnd(200 - query_size)

      -- Get candidates from spatial hash
      local candidates = loc.query(qx, qy, query_size, query_size)
      local candidate_count = 0
      for obj in pairs(candidates) do
         candidate_count += 1
      end
      total_candidates += candidate_count

      -- Count actual intersections
      local actual_hits = 0
      for obj in pairs(candidates) do
         if obj.x + obj.w >= qx and obj.x <= qx + query_size and
            obj.y + obj.h >= qy and obj.y <= qy + query_size then
            actual_hits += 1
         end
      end
      total_actual += actual_hits
   end

   local avg_candidates = total_candidates / tests
   local avg_actual = total_actual / tests
   local precision = avg_candidates > 0 and (avg_actual / avg_candidates) * 100 or 0

   return avg_candidates, avg_actual, precision
end

function run_compact_benchmark()
   print("=== LOCUSTRON BENCHMARK ===")
   print("Testing grid vs object size trade-offs")
   print()

   for _, obj_size in pairs(OBJECT_SIZES) do
      print("OBJECT SIZE: "..obj_size.name.." ("..obj_size.w.."x"..obj_size.h..")")
      print("Grid | Cells | Obj/Cell | Precision | Recommendation")
      print("-----|-------|----------|-----------|---------------")

      local objects = create_test_objects(OBJECT_COUNT, obj_size)

      for _, grid_size in pairs(GRID_SIZES) do
         local loc = locustron(grid_size)

         -- Add all objects
         for _, obj in pairs(objects) do
            loc.add(obj, obj.x, obj.y, obj.w, obj.h)
         end

         -- Measure memory efficiency
         local cells, total_objs = count_cells_and_objects(loc)
         local obj_per_cell = cells > 0 and total_objs / cells or 0

         -- Measure query precision
         local avg_candidates, avg_actual, precision = measure_query_precision(loc, objects, QUERY_SIZE)

         -- Determine recommendation
         local recommendation = ""
         if precision > 80 then
            recommendation = "EXCELLENT"
         elseif precision > 60 then
            recommendation = "GOOD"
         elseif precision > 40 then
            recommendation = "OK"
         else
            recommendation = "POOR"
         end

         -- Add memory efficiency note
         if cells < 10 then
            recommendation = recommendation.."/MEM+"
         elseif cells > 30 then
            recommendation = recommendation.."/MEM-"
         end

         print(string.format("%4d | %5d | %8.1f | %8.1f%% | %s",
            grid_size, cells, obj_per_cell, precision, recommendation))
      end
      print()
   end

   print("=== GUIDELINES ===")
   print("EXCELLENT: High precision, good spatial filtering")
   print("MEM+: Memory efficient (few cells)")
   print("MEM-: Memory heavy (many cells)")
   print()
   print("RULE OF THUMB:")
   print("- Grid ≈ object size = best precision")
   print("- Grid > object size = fewer cells, more false positives")
   print("- Choose based on your game's query frequency")
end

-- Auto-run when included
run_compact_benchmark()

return {
   run_compact_benchmark = run_compact_benchmark
}
