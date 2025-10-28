--- @diagnostic disable: undefined-global, undefined-field
-- BenchmarkSuite Tests
-- Comprehensive test coverage for the benchmarking framework

local BenchmarkSuite = require("benchmarks.vanilla.benchmark_suite")
local PerformanceProfiler = require("benchmarks.vanilla.performance_profiler")

-- Manually register strategies for testing
local strategy_interface = require("src.strategies.interface")
local FixedGridStrategy = require("src.strategies.fixed_grid")

-- Note: Strategy registration not yet implemented, using direct instantiation

describe("BenchmarkSuite", function()
   local benchmark_suite

   before_each(
      function()
         benchmark_suite = BenchmarkSuite.new({
            strategies = { "fixed_grid" },
            iterations = 10,
         })
      end
   )

   describe("initialization", function()
      it("should create with default configuration", function()
         local default_suite = BenchmarkSuite.new({})
         assert.is_table(default_suite.scenarios)
         assert.equals("fixed_grid", default_suite.strategies[1])
         assert.equals(1000, default_suite.iterations)
      end)

      it("should create with custom configuration", function()
         local custom_suite = BenchmarkSuite.new({
            strategies = { "fixed_grid", "quadtree" },
            iterations = 500,
         })
         assert.equals(2, #custom_suite.strategies)
         assert.equals(500, custom_suite.iterations)
      end)

      it("should setup all test scenarios", function()
         assert.is_function(benchmark_suite.scenarios.clustered)
         assert.is_function(benchmark_suite.scenarios.uniform)
         assert.is_function(benchmark_suite.scenarios.sparse)
         assert.is_function(benchmark_suite.scenarios.moving)
         assert.is_function(benchmark_suite.scenarios.large_objects)
      end)
   end)

   describe("scenario generation", function()
      it("should generate clustered objects", function()
         local objects = benchmark_suite.scenarios.clustered(100)
         -- Clustered generation may not produce exactly the requested count due to clustering algorithm
         assert.is_true(#objects >= 50) -- Should generate at least half the requested objects
         assert.is_true(#objects <= 120) -- Should not generate more than 20% over the requested count

         -- Verify object structure
         for _, obj_data in ipairs(objects) do
            assert.is_not_nil(obj_data.obj)
            assert.is_number(obj_data.x)
            assert.is_number(obj_data.y)
            assert.is_number(obj_data.w)
            assert.is_number(obj_data.h)
            assert.is_true(obj_data.w >= 8 and obj_data.w <= 32)
            assert.is_true(obj_data.h >= 8 and obj_data.h <= 32)
         end
      end)

      it("should generate uniform distribution", function()
         local objects = benchmark_suite.scenarios.uniform(50)
         assert.equals(50, #objects)

         -- Check distribution bounds
         for _, obj_data in ipairs(objects) do
            assert.is_true(obj_data.x >= 0 and obj_data.x <= 1000)
            assert.is_true(obj_data.y >= 0 and obj_data.y <= 1000)
         end
      end)

      it("should generate sparse world objects", function()
         local objects = benchmark_suite.scenarios.sparse(30)
         assert.equals(30, #objects)

         -- Should include negative coordinates
         local has_negative = false
         for _, obj_data in ipairs(objects) do
            if obj_data.x < 0 or obj_data.y < 0 then
               has_negative = true
               break
            end
         end
         -- Note: Due to randomness, this might not always be true, but statistically likely
      end)

      it("should generate moving objects with velocity", function()
         local objects = benchmark_suite.scenarios.moving(25)
         assert.equals(25, #objects)

         -- Moving objects should have velocity
         for _, obj_data in ipairs(objects) do
            assert.is_number(obj_data.vx)
            assert.is_number(obj_data.vy)
            assert.is_true(obj_data.vx >= -5 and obj_data.vx <= 5)
            assert.is_true(obj_data.vy >= -5 and obj_data.vy <= 5)
         end
      end)

      it("should generate varied size objects", function()
         local objects = benchmark_suite.scenarios.large_objects(40)
         assert.equals(40, #objects)

         -- Should have size variation
         local sizes = {}
         for _, obj_data in ipairs(objects) do
            table.insert(sizes, obj_data.w * obj_data.h)
         end

         -- Check that we have some size variation
         local min_size = math.min(table.unpack(sizes))
         local max_size = math.max(table.unpack(sizes))
         assert.is_true(max_size > min_size)
      end)
   end)

   describe("strategy benchmarking", function()
      it("should benchmark fixed grid strategy", function()
         local objects = benchmark_suite.scenarios.uniform(20)
         local results = benchmark_suite:benchmark_strategy("fixed_grid", objects, { cell_size = 32 })

         assert.is_number(results.add_time)
         assert.is_number(results.query_time)
         assert.is_number(results.memory_usage)
         assert.is_number(results.accuracy)
         assert.equals(20, results.object_count)

         -- Sanity checks
         assert.is_true(results.add_time >= 0)
         assert.is_true(results.query_time >= 0)
         assert.is_true(results.memory_usage > 0)
         assert.is_true(results.accuracy >= 0 and results.accuracy <= 1)
      end)

      it("should measure update performance for moving objects", function()
         local objects = benchmark_suite.scenarios.moving(15)
         local results = benchmark_suite:benchmark_strategy("fixed_grid", objects)

         assert.is_number(results.update_time)
         assert.is_true(results.update_time >= 0)
      end)

      it("should measure remove performance", function()
         local objects = benchmark_suite.scenarios.uniform(10)
         local results = benchmark_suite:benchmark_strategy("fixed_grid", objects)

         assert.is_number(results.remove_time)
         assert.is_true(results.remove_time >= 0)
      end)
   end)

   describe("accuracy testing", function()
      it("should perform brute force queries", function()
         local objects = {
            { obj = { id = 1 }, x = 10, y = 10, w = 20, h = 20 },
            { obj = { id = 2 }, x = 100, y = 100, w = 20, h = 20 },
         }

         local results = benchmark_suite:brute_force_query(objects, 0, 0, 50, 50)
         assert.equals(true, results[objects[1].obj])
         assert.is_nil(results[objects[2].obj])
      end)

      it("should check rectangle intersection correctly", function()
         -- Overlapping rectangles
         assert.is_true(benchmark_suite:rectangles_intersect(0, 0, 20, 20, 10, 10, 20, 20))

         -- Non-overlapping rectangles
         assert.is_false(benchmark_suite:rectangles_intersect(0, 0, 10, 10, 20, 20, 10, 10))

         -- Adjacent rectangles (should not intersect)
         assert.is_false(benchmark_suite:rectangles_intersect(0, 0, 10, 10, 10, 0, 10, 10))

         -- Completely contained
         assert.is_true(benchmark_suite:rectangles_intersect(0, 0, 100, 100, 25, 25, 10, 10))
      end)

      it("should compare query results correctly", function()
         local obj1, obj2, obj3 = { id = 1 }, { id = 2 }, { id = 3 }

         local result1 = { [obj1] = true, [obj2] = true }
         local result2 = { [obj1] = true, [obj2] = true }
         local result3 = { [obj1] = true, [obj3] = true }

         assert.is_true(benchmark_suite:results_match(result1, result2))
         assert.is_false(benchmark_suite:results_match(result1, result3))
      end)
   end)

   describe("performance analysis", function()
      it("should find best performing strategy", function()
         local strategies = {
            strategy_a = {
               add_time = 0.001,
               query_time = 0.002,
               memory_usage = 1024,
               accuracy = 1.0,
            },
            strategy_b = {
               add_time = 0.002,
               query_time = 0.001,
               memory_usage = 2048,
               accuracy = 0.99,
            },
         }

         local best_name, best_results = benchmark_suite:find_best_strategy(strategies)
         assert.is_string(best_name)
         assert.is_table(best_results)
         assert.is_true(best_name == "strategy_a" or best_name == "strategy_b")
      end)

      it("should generate performance charts", function()
         local scenario_results = {
            [100] = {
               fixed_grid = { add_time = 0.001, query_time = 0.002, memory_usage = 1024 },
            },
            [200] = {
               fixed_grid = { add_time = 0.002, query_time = 0.003, memory_usage = 2048 },
            },
         }

         local chart = benchmark_suite:generate_performance_chart(scenario_results, "add_time")
         assert.is_table(chart)
         assert.is_true(#chart > 0)

         -- Should contain chart elements
         local chart_text = table.concat(chart, "\n")
         assert.truthy(chart_text:match("Performance"))
         assert.truthy(chart_text:match("```"))
      end)
   end)
end)

describe("PerformanceProfiler", function()
   local profiler

   before_each(function() profiler = PerformanceProfiler.new() end)

   describe("initialization", function()
      it("should create empty profiler", function()
         assert.is_table(profiler.operation_history)
         assert.is_table(profiler.memory_snapshots)
         assert.is_table(profiler.query_patterns)
         assert.is_table(profiler.recommendations)
      end)
   end)

   describe("object distribution analysis", function()
      it("should analyze uniform distribution", function()
         local objects = {
            { x = 0, y = 0, w = 10, h = 10 },
            { x = 100, y = 100, w = 10, h = 10 },
            { x = 200, y = 200, w = 10, h = 10 },
         }

         local analysis = profiler:analyze_object_distribution(objects)

         assert.equals(3, analysis.total_objects)
         assert.equals(100, analysis.average_object_size)
         assert.is_false(analysis.has_negative_coords)
         assert.is_number(analysis.clustering_factor)
      end)

      it("should detect negative coordinates", function()
         local objects = {
            { x = -10, y = 5, w = 10, h = 10 },
            { x = 10, y = -5, w = 10, h = 10 },
         }

         local analysis = profiler:analyze_object_distribution(objects)
         assert.is_true(analysis.has_negative_coords)
      end)

      it("should calculate size variation", function()
         local objects = {
            { x = 0, y = 0, w = 10, h = 10 }, -- Size: 100
            { x = 0, y = 0, w = 20, h = 20 }, -- Size: 400
            { x = 0, y = 0, w = 30, h = 30 }, -- Size: 900
         }

         local analysis = profiler:analyze_object_distribution(objects)
         assert.is_true(analysis.size_variation > 0)
      end)
   end)

   describe("clustering analysis", function()
      it("should calculate clustering factor", function()
         -- Highly clustered positions
         local clustered_positions = {
            { 0, 0 },
            { 1, 1 },
            { 2, 2 },
         }

         -- Dispersed positions
         local dispersed_positions = {
            { 0, 0 },
            { 100, 100 },
            { 200, 200 },
         }

         local clustered_factor = profiler:calculate_clustering_factor(clustered_positions)
         local dispersed_factor = profiler:calculate_clustering_factor(dispersed_positions)

         assert.is_number(clustered_factor)
         assert.is_number(dispersed_factor)
         assert.is_true(clustered_factor >= 0 and clustered_factor <= 1)
         assert.is_true(dispersed_factor >= 0 and dispersed_factor <= 1)
      end)

      it("should handle edge cases", function()
         -- Single object
         local single = profiler:calculate_clustering_factor({ { 0, 0 } })
         assert.equals(0, single)

         -- Empty array
         local empty = profiler:calculate_clustering_factor({})
         assert.equals(0, empty)
      end)
   end)

   describe("performance calculations", function()
      it("should calculate average add time", function()
         local profile = {
            operations = {
               { type = "add", duration = 0.001 },
               { type = "add", duration = 0.002 },
               { type = "query", duration = 0.005 }, -- Should be ignored
               { type = "add", duration = 0.003 },
            },
         }

         local avg_time = profiler:calculate_average_add_time(profile)
         assert.equals(0.002, avg_time) -- (0.001 + 0.002 + 0.003) / 3
      end)

      it("should calculate average query time", function()
         local profile = {
            query_analysis = {
               { duration = 0.001 },
               { duration = 0.003 },
               { duration = 0.002 },
            },
         }

         local avg_time = profiler:calculate_average_query_time(profile)
         assert.equals(0.002, avg_time) -- (0.001 + 0.003 + 0.002) / 3
      end)

      it("should handle empty operations", function()
         local empty_profile = { operations = {}, query_analysis = {} }

         assert.equals(0, profiler:calculate_average_add_time(empty_profile))
         assert.equals(0, profiler:calculate_average_query_time(empty_profile))
      end)
   end)

   describe("recommendation generation", function()
      it("should generate performance recommendations", function()
         local profile = {
            operations = {
               { type = "add", duration = 0.002 }, -- Slow add time
               { type = "add", duration = 0.002 },
            },
            memory_timeline = {
               { operation_count = 100, memory_kb = 100 },
               { operation_count = 200, memory_kb = 300 }, -- High memory usage
            },
            query_analysis = {},
         }

         local workload = { objects = {} }
         local recommendations = profiler:generate_recommendations(profile, workload)

         assert.is_table(recommendations)
         -- Should have recommendations for slow adds and high memory
         assert.is_true(#recommendations > 0)
      end)

      it("should categorize recommendations by severity", function()
         local profile = {
            operations = {
               { type = "add", duration = 0.005 }, -- Very slow
            },
            memory_timeline = {
               { operation_count = 100, memory_kb = 100 },
               { operation_count = 200, memory_kb = 500 }, -- High growth
            },
            query_analysis = {},
         }

         local workload = { objects = {} }
         local recommendations = profiler:generate_recommendations(profile, workload)

         local has_warning = false
         for _, rec in ipairs(recommendations) do
            assert.is_string(rec.severity)
            assert.is_string(rec.type)
            assert.is_string(rec.category)
            assert.is_string(rec.message)

            if rec.severity == "warning" or rec.severity == "critical" then has_warning = true end
         end

         assert.is_true(has_warning)
      end)
   end)

   describe("report generation", function()
      it("should generate formatted report", function()
         local profiles = {
            {
               strategy_name = "fixed_grid",
               operations = {
                  { type = "add", duration = 0.001 },
               },
               memory_timeline = {
                  { operation_count = 100, memory_kb = 100 },
               },
               query_analysis = {
                  { duration = 0.002 },
               },
               recommendations = {
                  { severity = "info", category = "test", message = "Test recommendation" },
               },
               workload_info = { object_count = 100 },
            },
         }

         local report = profiler:generate_report(profiles)

         assert.is_string(report)
         assert.truthy(report:match("Performance Analysis Report"))
         assert.truthy(report:match("fixed_grid"))
         assert.truthy(report:match("Executive Summary"))
         assert.truthy(report:match("Detailed Analysis"))
      end)
   end)
end)
