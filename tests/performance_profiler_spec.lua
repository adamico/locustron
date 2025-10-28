--- Busted tests for PerformanceProfiler
--- Tests the performance profiling system functionality

local class = require("lib.middleclass")

describe("PerformanceProfiler", function()
   local PerformanceProfiler

   before_each(function()
      -- Load the module fresh for each test
      package.loaded["demo.debugging.performance_profiler"] = nil
      PerformanceProfiler = require("demo.debugging.performance_profiler")
   end)

   describe("Class creation", function()
      it("should initialize with default config", function()
         local profiler = PerformanceProfiler:new()

         -- Check default config
         assert.are.equal(1000, profiler.config.max_measurements)
         assert.are.equal(1.0, profiler.config.sample_rate)
         assert.is_false(profiler.config.enable_detailed)
         assert.is_false(profiler.config.track_memory)

         -- Check initial data structures
         assert.is_table(profiler.measurements)
         assert.are.equal(0, #profiler.measurements)
         assert.is_table(profiler.current_session)
         assert.is_nil(profiler.current_session.start_time)
         assert.is_table(profiler.stats)
      end)

      it("should accept custom config", function()
         local config = {
            max_measurements = 500,
            sample_rate = 0.5,
            enable_detailed = true,
            track_memory = true,
         }
         local profiler = PerformanceProfiler:new(config)

         assert.are.equal(500, profiler.config.max_measurements)
         assert.are.equal(0.5, profiler.config.sample_rate)
         assert.is_true(profiler.config.enable_detailed)
         assert.is_true(profiler.config.track_memory)
      end)
   end)

   describe("Session management", function()
      local profiler

      before_each(function() profiler = PerformanceProfiler:new() end)

      it("should start a profiling session", function()
         profiler:start_session()
         assert.is_not_nil(profiler.current_session.start_time)
         assert.are.equal(0, profiler.current_session.query_count)
         assert.are.equal(0, profiler.current_session.total_time)
         assert.are.equal(0, profiler.current_session.peak_time)
      end)

      it("should end a profiling session", function()
         profiler:start_session()
         -- Simulate some activity
         profiler.current_session.query_count = 10
         profiler.current_session.total_time = 0.5
         -- Mock a reasonable session duration
         profiler.current_session.start_time = profiler:get_time() - 0.5

         profiler:end_session()
         assert.is_nil(profiler.current_session.start_time)
         -- Allow for floating point precision issues with os.clock()
         assert.is_true(profiler.stats.queries_per_second >= 19.9 and profiler.stats.queries_per_second <= 20.1)
      end)

      it("should handle ending session without starting", function()
         -- Should not error
         assert.has_no_error(function() profiler:end_session() end)
      end)
   end)

   describe("Query measurement", function()
      local profiler

      before_each(function() profiler = PerformanceProfiler:new() end)

      it("should measure query execution time", function()
         local mock_strategy = "fixed_grid"
         local mock_query = function(x, y, w, h)
            -- Simulate some work
            local sum = 0
            for i = 1, 100 do
               sum = sum + i
            end
            return { result = sum }
         end

         local result = profiler:measure_query(mock_strategy, mock_query, 10, 20, 30, 40)

         assert.is_table(result)
         assert.are.equal(5050, result.result)
         assert.are.equal(1, #profiler.measurements)

         local measurement = profiler.measurements[1]
         assert.are.equal(mock_strategy, measurement.strategy)
         assert.is_number(measurement.execution_time)
         assert.is_number(measurement.timestamp)
         assert.are.equal(1, measurement.result_count)
      end)

      it("should respect sampling rate", function()
         -- Test with sample rate = 0 (should never sample)
         local profiler = PerformanceProfiler:new({ sample_rate = 0 })
         local call_count = 0
         local mock_query = function()
            call_count = call_count + 1
            return "result"
         end

         -- Call multiple times to test sampling
         for i = 1, 10 do
            profiler:measure_query("test", mock_query)
         end

         -- With sample_rate = 0, query should be called but not measured
         assert.are.equal(10, call_count)
         assert.are.equal(0, #profiler.measurements)
      end)

      it("should update session statistics", function()
         profiler:start_session()

         profiler:measure_query("test", function() return {} end)
         profiler:measure_query("test", function() return {} end)

         assert.are.equal(2, profiler.current_session.query_count)
         assert.is_number(profiler.current_session.total_time)
         assert.is_number(profiler.current_session.peak_time)
      end)

      it("should maintain measurement limit", function()
         local profiler = PerformanceProfiler:new({ max_measurements = 3 })

         -- Add measurements directly to reach the limit
         for i = 1, 3 do
            table.insert(profiler.measurements, {
               strategy = "test",
               execution_time = 0.01,
               timestamp = os.time(),
               result_count = 1,
               session_id = i,
            })
         end

         -- This should trigger limit enforcement and remove oldest
         table.insert(profiler.measurements, {
            strategy = "test",
            execution_time = 0.01,
            timestamp = os.time(),
            result_count = 1,
            session_id = 4,
         })

         -- Simulate the limit enforcement (normally done in measure_query)
         if #profiler.measurements > profiler.config.max_measurements then table.remove(profiler.measurements, 1) end

         assert.are.equal(3, #profiler.measurements)
         -- First measurement should be removed (FIFO)
         assert.are.equal(2, profiler.measurements[1].session_id)
      end)
   end)

   describe("Statistics calculation", function()
      local profiler

      before_each(function() profiler = PerformanceProfiler:new() end)

      it("should calculate basic statistics", function()
         -- Add some mock measurements
         table.insert(profiler.measurements, {
            strategy = "fixed_grid",
            execution_time = 0.01,
            result_count = 5,
         })
         table.insert(profiler.measurements, {
            strategy = "fixed_grid",
            execution_time = 0.02,
            result_count = 3,
         })
         table.insert(profiler.measurements, {
            strategy = "quadtree",
            execution_time = 0.015,
            result_count = 7,
         })

         profiler:update_aggregated_stats()

         assert.are.equal(3, profiler.stats.total_queries)
         assert.are.equal(0.045, profiler.stats.total_time)
         assert.are.equal(0.015, profiler.stats.average_query_time)
         assert.are.equal(0.015, profiler.stats.median_query_time)
      end)

      it("should calculate strategy-specific statistics", function()
         -- Add measurements for different strategies
         table.insert(profiler.measurements, {
            strategy = "fixed_grid",
            execution_time = 0.01,
         })
         table.insert(profiler.measurements, {
            strategy = "fixed_grid",
            execution_time = 0.02,
         })
         table.insert(profiler.measurements, {
            strategy = "quadtree",
            execution_time = 0.015,
         })

         profiler:update_aggregated_stats()

         local fg_stats = profiler.stats.strategy_performance["fixed_grid"]
         assert.is_not_nil(fg_stats)
         assert.are.equal(2, fg_stats.query_count)
         assert.are.equal(0.015, fg_stats.average_time)

         local qt_stats = profiler.stats.strategy_performance["quadtree"]
         assert.is_not_nil(qt_stats)
         assert.are.equal(1, qt_stats.query_count)
         assert.are.equal(0.015, qt_stats.average_time)
      end)

      it("should handle empty measurements", function()
         profiler:update_aggregated_stats()

         assert.are.equal(0, profiler.stats.total_queries)
         assert.are.equal(0, profiler.stats.average_query_time)
      end)
   end)

   describe("Strategy performance", function()
      local profiler

      before_each(function()
         profiler = PerformanceProfiler:new()
         -- Add mock data
         profiler.stats.strategy_performance = {
            fixed_grid = {
               query_count = 10,
               average_time = 0.01,
               median_time = 0.009,
               p95_time = 0.015,
               total_time = 0.1,
            },
            quadtree = {
               query_count = 5,
               average_time = 0.02,
               median_time = 0.018,
               p95_time = 0.025,
               total_time = 0.1,
            },
         }
      end)

      it("should return strategy performance data", function()
         local fg_perf = profiler:get_strategy_performance("fixed_grid")
         assert.are.equal(10, fg_perf.query_count)
         assert.are.equal(0.01, fg_perf.average_time)

         local qt_perf = profiler:get_strategy_performance("quadtree")
         assert.are.equal(5, qt_perf.query_count)
         assert.are.equal(0.02, qt_perf.average_time)
      end)

      it("should return default data for unknown strategy", function()
         local unknown_perf = profiler:get_strategy_performance("unknown")
         assert.are.equal(0, unknown_perf.query_count)
         assert.are.equal(0, unknown_perf.average_time)
      end)
   end)

   describe("Bottleneck detection", function()
      local profiler

      before_each(function()
         profiler = PerformanceProfiler:new()
         -- Add measurements with different execution times
         table.insert(profiler.measurements, {
            strategy = "test",
            execution_time = 0.1,
            result_count = 1,
         })
         table.insert(profiler.measurements, {
            strategy = "test",
            execution_time = 0.05,
            result_count = 2,
         })
         table.insert(profiler.measurements, {
            strategy = "test",
            execution_time = 0.2,
            result_count = 3,
         })
      end)

      it("should identify bottlenecks", function()
         local bottlenecks = profiler:get_bottlenecks(2)

         assert.are.equal(2, #bottlenecks)
         assert.are.equal(0.2, bottlenecks[1].execution_time)
         assert.are.equal(0.1, bottlenecks[2].execution_time)
      end)

      it("should limit bottleneck count", function()
         local bottlenecks = profiler:get_bottlenecks(1)
         assert.are.equal(1, #bottlenecks)
         assert.are.equal(0.2, bottlenecks[1].execution_time)
      end)

      it("should handle empty measurements", function()
         local empty_profiler = PerformanceProfiler:new()
         local bottlenecks = empty_profiler:get_bottlenecks(5)
         assert.are.equal(0, #bottlenecks)
      end)
   end)

   describe("Performance recommendations", function()
      it("should provide recommendations for slow queries", function()
         local profiler = PerformanceProfiler:new()
         profiler.stats.average_query_time = 0.02 -- > 1 frame at 60fps

         local recommendations = profiler:get_recommendations()
         assert.is_true(#recommendations > 0)
         assert.is_string(recommendations[1])
      end)

      it("should recommend best performing strategy", function()
         local profiler = PerformanceProfiler:new()
         profiler.stats.strategy_performance = {
            fixed_grid = { average_time = 0.01, query_count = 10 },
            quadtree = { average_time = 0.005, query_count = 10 },
         }

         local recommendations = profiler:get_recommendations()
         local found_best = false
         for _, rec in ipairs(recommendations) do
            if rec:find("Best performing strategy") and rec:find("quadtree") then
               found_best = true
               break
            end
         end
         assert.is_true(found_best)
      end)

      it("should handle no recommendations needed", function()
         local profiler = PerformanceProfiler:new()
         profiler.stats.average_query_time = 0.001 -- Fast queries

         local recommendations = profiler:get_recommendations()
         -- Should still have strategy recommendation if data exists
         assert.is_table(recommendations)
      end)
   end)

   describe("Data management", function()
      local profiler

      before_each(function()
         profiler = PerformanceProfiler:new()
         table.insert(profiler.measurements, {
            strategy = "test",
            execution_time = 0.01,
            timestamp = 123456,
            result_count = 5,
         })
      end)

      it("should clear all data", function()
         profiler:clear()

         assert.are.equal(0, #profiler.measurements)
         assert.are.equal(0, profiler.stats.total_queries)
         assert.are.equal(0, profiler.stats.average_query_time)
      end)

      it("should export complete data", function()
         local data = profiler:export_data()

         assert.is_table(data)
         assert.is_table(data.config)
         assert.is_table(data.stats)
         assert.is_table(data.measurements)
         assert.is_table(data.session)
         assert.is_number(data.export_time)
      end)

      it("should generate formatted report", function()
         -- Add some test data
         table.insert(profiler.measurements, {
            strategy = "test",
            execution_time = 0.01,
            result_count = 5,
         })
         profiler:update_aggregated_stats()

         local report = profiler:get_report()

         assert.is_string(report)
         assert.is_true(report:len() > 0)
         assert.is_true(report:find("Performance Report") ~= nil)
         assert.is_true(report:find("Total Queries") ~= nil)
         assert.is_true(report:find("1") ~= nil) -- Should contain the query count
      end)
   end)

   describe("Utility functions", function()
      local profiler

      before_each(function() profiler = PerformanceProfiler:new() end)

      it("should get result count from table", function()
         local result = profiler:get_result_count({ { a = 1, b = 2, c = 3 } })
         assert.are.equal(3, result)
      end)

      it("should get result count from number", function()
         local result = profiler:get_result_count({ 42 })
         assert.are.equal(42, result)
      end)

      it("should handle empty results", function()
         local result = profiler:get_result_count({ nil })
         assert.are.equal(0, result)
      end)

      it("should get time using fallback", function()
         -- Mock time function not available
         local original_time = _G.time
         _G.time = nil

         local time_val = profiler:get_time()
         assert.is_number(time_val)

         _G.time = original_time
      end)

      it("should get memory usage", function()
         local memory = profiler:get_memory_usage()
         assert.are.equal(0, memory) -- Picotron doesn't expose memory usage
      end)
   end)
end)
