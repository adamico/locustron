-- Grid Size Tuning Benchmark for Locustron (Userdata Implementation)
-- Tests memory allocation vs query optimization trade-offs
-- Optimized for userdata-based spatial hash with comprehensive performance metrics
-- Run in Picotron console: include("benchmarks/benchmark_grid_tuning.lua")

include("../lib/locustron/require.lua")
local locustron = require("../lib/locustron/locustron")

-- Benchmark Configuration
local GRID_SIZES = {16, 32, 64, 128}
local OBJECT_SIZES = {
   {name = "tiny", w = 4, h = 4},
   {name = "small", w = 8, h = 8},
   {name = "medium", w = 16, h = 16},
   {name = "large", w = 32, h = 32}
}
local OBJECT_COUNT = 100
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
   local max_objects_per_cell = 0
   
   -- Use our unified API to count cells and objects efficiently
   local grid_size = loc._size
   local sample_area = 300 -- Sample a 300x300 area
   
   for y = 0, sample_area, grid_size do
      for x = 0, sample_area, grid_size do
         local gx, gy = flr(x / grid_size), flr(y / grid_size)
         local count = loc._get_cell_count(gx, gy)
         if count > 0 then
            cell_count = cell_count + 1
            total_objects = total_objects + count
            max_objects_per_cell = max(max_objects_per_cell, count)
         end
      end
   end

   return cell_count, total_objects, max_objects_per_cell
end

function measure_query_precision(loc, objects, query_size)
   local total_candidates = 0
   local total_actual = 0
   local tests = 8

   for i = 1, tests do
      local qx = rnd(200 - query_size)
      local qy = rnd(200 - query_size)

      local candidates = loc.query(qx, qy, query_size, query_size)
      local candidate_count = 0
      for obj in pairs(candidates) do
         candidate_count = candidate_count + 1
      end
      total_candidates = total_candidates + candidate_count

      -- Count actual intersections using bbox data
      local actual_hits = 0
      for obj in pairs(candidates) do
         local ox, oy, ow, oh = loc.get_bbox(obj)
         if ox and oy and ow and oh then
            if ox + ow >= qx and ox <= qx + query_size and
               oy + oh >= qy and oy <= qy + query_size then
               actual_hits = actual_hits + 1
            end
         end
      end
      total_actual = total_actual + actual_hits
   end

   local avg_candidates = total_candidates / tests
   local avg_actual = total_actual / tests
   local precision = avg_candidates > 0 and (avg_actual / avg_candidates) * 100 or 0

   return avg_candidates, avg_actual, precision
end

function measure_operation_performance(loc, objects)
   local operations = 0
   local start_time = time()
   
   -- Test update operations  
   for i = 1, min(15, #objects) do
      local obj = objects[i]
      local new_x = obj.x + rnd(20) - 10
      local new_y = obj.y + rnd(20) - 10
      loc.update(obj, new_x, new_y, obj.w, obj.h)
      operations = operations + 1
   end
   
   -- Test query operations
   for i = 1, 10 do
      local qx = rnd(150)
      local qy = rnd(150)
      local results = loc.query(qx, qy, 32, 32)
      operations = operations + 1
   end
   
   local total_time = time() - start_time
   local ops_per_second = operations / max(total_time, 0.001)
   
   return ops_per_second
end

function run_compact_benchmark()
   printh("\27[1m\27[36m=== LOCUSTRON USERDATA BENCHMARK ===\27[0m")
   printh("Testing grid vs object size trade-offs with performance metrics")
   printh("\n")

   for _, obj_size in pairs(OBJECT_SIZES) do
      printh("OBJECT SIZE: "..obj_size.name.." ("..obj_size.w.."x"..obj_size.h..")")
      printh("Grid | Cells | Obj/Cell | MaxCell | Precision | Ops/Sec | Rating")
      printh("-----|-------|----------|---------|-----------|---------|--------")

      local objects = create_test_objects(OBJECT_COUNT, obj_size)

      for _, grid_size in pairs(GRID_SIZES) do
         
         local loc_success, loc_error = pcall(function()
            local loc = locustron(grid_size)

            -- Add all objects
            for _, obj in pairs(objects) do
               loc.add(obj, obj.x, obj.y, obj.w, obj.h)
            end

            -- Measure memory efficiency
            local cells, total_objs, max_per_cell = count_cells_and_objects(loc)
            local obj_per_cell = cells > 0 and (total_objs / cells) or 0

            -- Measure query precision
            local avg_candidates, avg_actual, precision = measure_query_precision(loc, objects, QUERY_SIZE)
            
            -- Measure operation performance
            local ops_per_second = measure_operation_performance(loc, objects)

            -- Determine rating
            local rating = ""
            local score = 0
            
            -- Precision score (50% weight)
            if precision > 80 then score = score + 50
            elseif precision > 60 then score = score + 35
            elseif precision > 40 then score = score + 25
            else score = score + 10 end
            
            -- Memory efficiency score (30% weight)
            if cells < 15 and obj_per_cell > 2 then score = score + 30
            elseif cells < 25 and obj_per_cell > 1.5 then score = score + 20
            elseif cells < 35 then score = score + 15
            else score = score + 5 end
            
            -- Performance score (20% weight)
            if ops_per_second > 500 then score = score + 20
            elseif ops_per_second > 200 then score = score + 15
            elseif ops_per_second > 100 then score = score + 10
            else score = score + 5 end
            
            if score >= 85 then rating = "EXCELLENT"
            elseif score >= 70 then rating = "VERY GOOD"
            elseif score >= 55 then rating = "GOOD"
            elseif score >= 40 then rating = "OK"
            else rating = "POOR" end

            printh(string.format("%4d | %5d | %8.1f | %7d | %8.1f%% | %7.0f | %s",
               grid_size, cells, obj_per_cell, max_per_cell, precision, ops_per_second, rating))
         end)
         
         if not loc_success then
            printh("\27[31mERROR testing grid size " .. grid_size .. ": " .. tostring(loc_error) .. "\27[0m")
         end
      end
      printh("\n")
   end

   printh("\27[1m\27[34m=== PERFORMANCE METRICS ===\27[0m")
   printh("Grid: Grid cell size | Obj: Object size | Memory: KB used")
   printh("Ops/Sec: Combined update/query operations per second")
   printh("MaxCell: Maximum objects in any single cell")
   printh("\n")
   printh("\27[1m\27[34m=== RECOMMENDATIONS ===\27[0m")
   printh("\27[32mEXCELLENT: Optimal balance of precision, performance, and memory\27[0m")
   printh("\27[33mVERY GOOD: Good performance with minor trade-offs\27[0m")
   printh("GOOD: Acceptable performance for most use cases")
   printh("\n")
   printh("GUIDELINES:")
   printh("- Grid ≈ object size = best precision")
   printh("- Grid > object size = fewer cells, more false positives")
   printh("- Grid < object size = more cells, better precision, higher memory")
   printh("- Choose based on query frequency vs memory constraints")
end

-- Auto-run when included
run_compact_benchmark()

return {
   run_compact_benchmark = run_compact_benchmark,
   measure_query_precision = measure_query_precision,
   measure_operation_performance = measure_operation_performance
}