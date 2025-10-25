-- Simple benchmark integration for test_locustron.lua
-- Add this to your test file to run benchmarks with a keypress

local benchmark = require("lib/benchmark_compact")
local benchmark_running = false
local benchmark_complete = false

function run_benchmark_if_requested()
   -- Press 'b' to run benchmark
   if keyp("b") and not benchmark_running and not benchmark_complete then -- X/Square button
      benchmark_running = true
      benchmark_complete = false

      -- Run in next frame to avoid blocking
      cocreate(function()
         benchmark.run_benchmark()
         benchmark_running = false
         benchmark_complete = true
      end)
   end

   -- Press 'r' to reset benchmark
   if keyp("r") and benchmark_complete then -- O/Circle button
      benchmark_complete = false
   end
end

function draw_benchmark_status()
   -- Draw benchmark controls at bottom of screen
   local y = 240 - 16
   if not benchmark_complete then
      if benchmark_running then
         print("Running benchmark...", 8, y, 6)
      else
         print("Press B to run benchmark", 8, y, 7)
      end
   else
      print("Benchmark complete! Press R to reset", 8, y, 11)
   end
end

-- Add these to your _update() and _draw() functions:
-- In _update(): run_benchmark_if_requested()
-- In _draw(): draw_benchmark_status()

return {
   run_benchmark_if_requested = run_benchmark_if_requested,
   draw_benchmark_status = draw_benchmark_status
}
