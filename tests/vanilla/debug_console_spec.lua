--- Busted tests for DebugConsole
--- Tests the debug console functionality

describe("DebugConsole", function()
   local DebugConsole

   before_each(function()
      -- Load the module fresh for each test
      package.loaded["src.debugging.debug_console"] = nil
      DebugConsole = require("src.debugging.debug_console")
   end)

   describe("Class creation", function()
      it("should initialize with default config", function()
         local console = DebugConsole:new()

         -- Check default config
         assert.are.equal(100, console.config.max_history)
         assert.are.equal(50, console.config.max_output_lines)
         assert.is_true(console.config.enable_echo)
         assert.is_false(console.config.case_sensitive)

         -- Check initial data structures
         assert.is_table(console.commands)
         assert.is_table(console.history)
         assert.is_table(console.output_buffer)
         assert.are.equal("", console.current_command)
         assert.are.equal(0, console.cursor_pos)
      end)

      it("should accept custom config", function()
         local config = {
            max_history = 50,
            max_output_lines = 25,
            enable_echo = false,
            case_sensitive = true
         }
         local console = DebugConsole:new(config)

         assert.are.equal(50, console.config.max_history)
         assert.are.equal(25, console.config.max_output_lines)
         assert.are.equal(false, console.config.enable_echo)
         assert.are.equal(true, console.config.case_sensitive)
      end)
   end)

   describe("Command registration", function()
      local console

      before_each(function()
         console = DebugConsole:new()
      end)

      it("should register built-in commands", function()
         assert.is_not_nil(console.commands["help"])
         assert.is_not_nil(console.commands["info"])
         assert.is_not_nil(console.commands["stats"])
         assert.is_not_nil(console.commands["clear"])
         assert.is_not_nil(console.commands["echo"])
      end)

      it("should register custom commands", function()
         local called = false
         console:register_command("test", function() called = true return "ok" end, "Test command")

         assert.is_not_nil(console.commands["test"])
         assert.are.equal("Test command", console.commands["test"].description)

         -- Execute custom command
         local result = console:execute_command("test")
         assert.is_true(called)
         assert.are.equal("ok", result)
      end)
   end)

   describe("Command execution", function()
      local console

      before_each(function()
         console = DebugConsole:new()
      end)

      it("should execute simple commands", function()
         local result = console:execute_command("echo hello world")
         assert.are.equal("hello world", result)
      end)

      it("should handle quoted arguments", function()
         local result = console:execute_command('echo "hello world" test')
         assert.are.equal("hello world test", result)
      end)

      it("should handle unknown commands", function()
         local result = console:execute_command("unknown_command")
         assert.is_string(result)
         assert.is_true(string.find(result, "Unknown command") ~= nil)
      end)

      it("should handle empty commands", function()
         local result = console:execute_command("")
         assert.are.equal("", result)
      end)

      it("should handle command errors", function()
         console:register_command("error_cmd", function() error("test error") end)
         local result = console:execute_command("error_cmd")
         assert.is_string(result)
         assert.is_true(string.find(result, "Error executing command") ~= nil)
      end)

      it("should maintain command history", function()
         console:execute_command("echo test1")
         console:execute_command("echo test2")

         assert.are.equal(2, #console.history)
         assert.are.equal("echo test1", console.history[1].command)
         assert.are.equal("echo test2", console.history[2].command)
      end)

      it("should limit command history", function()
         local console = DebugConsole:new({max_history = 3})

         for i = 1, 5 do
            console:execute_command("echo " .. i)
         end

         assert.are.equal(3, #console.history)
         assert.are.equal("echo 3", console.history[1].command) -- FIFO
      end)
   end)

   describe("Command parsing", function()
      local console

      before_each(function()
         console = DebugConsole:new()
      end)

      it("should parse simple arguments", function()
         local args = console:parse_command_line("cmd arg1 arg2 arg3")
         assert.are.equal(4, #args)
         assert.are.equal("cmd", args[1])
         assert.are.equal("arg1", args[2])
         assert.are.equal("arg2", args[3])
         assert.are.equal("arg3", args[4])
      end)

      it("should handle quoted strings", function()
         local args = console:parse_command_line('cmd "arg with spaces" normal_arg')
         assert.are.equal(3, #args)
         assert.are.equal("cmd", args[1])
         assert.are.equal("arg with spaces", args[2])
         assert.are.equal("normal_arg", args[3])
      end)

      it("should handle empty input", function()
         local args = console:parse_command_line("")
         assert.are.equal(0, #args)
      end)

      it("should handle multiple spaces", function()
         local args = console:parse_command_line("cmd    arg1    arg2")
         assert.are.equal(3, #args)
         assert.are.equal("cmd", args[1])
         assert.are.equal("arg1", args[2])
         assert.are.equal("arg2", args[3])
      end)
   end)

   describe("Output buffer", function()
      local console

      before_each(function()
         console = DebugConsole:new()
      end)

      it("should add output to buffer", function()
         console:add_output("line 1")
         console:add_output("line 2")

         assert.are.equal(2, #console.output_buffer)
         assert.are.equal("line 1", console.output_buffer[1])
         assert.are.equal("line 2", console.output_buffer[2])
      end)

      it("should limit output buffer", function()
         local console = DebugConsole:new({max_output_lines = 3})

         for i = 1, 5 do
            console:add_output("line " .. i)
         end

         assert.are.equal(3, #console.output_buffer)
         assert.are.equal("line 3", console.output_buffer[1]) -- FIFO
      end)

      it("should clear output buffer", function()
         console:add_output("test")
         assert.are.equal(1, #console.output_buffer)

         console:clear_output()
         assert.are.equal(0, #console.output_buffer)
      end)

      it("should populate output buffer during command execution", function()
         console:execute_command("echo hello world")

         -- Should have command echo and result
         assert.is_true(#console.output_buffer >= 1)
         assert.is_true(string.find(console.output_buffer[#console.output_buffer], "hello world") ~= nil)
      end)
   end)

   describe("Built-in commands", function()
      local console

      before_each(function()
         console = DebugConsole:new()
      end)

      it("should provide help text", function()
         local result = console:execute_command("help")
         assert.is_string(result)
         assert.is_true(string.find(result, "Available commands") ~= nil)
         assert.is_true(string.find(result, "help") ~= nil)
         assert.is_true(string.find(result, "echo") ~= nil)
      end)

      it("should show system info", function()
         local result = console:execute_command("info")
         assert.is_string(result)
         assert.is_true(string.find(result, "System Information") ~= nil)
      end)

      it("should show strategy stats", function()
         local result = console:execute_command("stats")
         assert.is_string(result)
         assert.is_true(string.find(result, "No strategy loaded") ~= nil)
      end)

      it("should handle clear command", function()
         console:add_output("test")
         assert.are.equal(1, #console.output_buffer)

         local result = console:execute_command("clear")
         assert.are.equal("Output cleared", result)
         -- execute_command adds to output buffer, so it should have the command and result
         assert.are.equal(2, #console.output_buffer)
      end)

      it("should show command history", function()
         console:execute_command("echo test1")
         console:execute_command("echo test2")

         local result = console:execute_command("history")
         assert.is_string(result)
         assert.is_true(string.find(result, "Command History") ~= nil)
         assert.is_true(string.find(result, "echo test1") ~= nil)
         assert.is_true(string.find(result, "echo test2") ~= nil)
      end)

      it("should show config", function()
         local result = console:execute_command("config")
         assert.is_string(result)
         assert.is_true(string.find(result, "Console Configuration") ~= nil)
         assert.is_true(string.find(result, "max_history") ~= nil)
      end)

      it("should set config values", function()
         local result = console:execute_command("set max_history 50")
         assert.are.equal("Set max_history = 50", result)
         assert.are.equal(50, console.config.max_history)
      end)

      it("should handle invalid config keys", function()
         local result = console:execute_command("set invalid_key value")
         assert.is_string(result)
         assert.is_true(string.find(result, "Unknown configuration key") ~= nil)
      end)
   end)

   describe("Strategy integration", function()
      local console
      local mock_strategy

      before_each(function()
         console = DebugConsole:new()
         mock_strategy = {
            objects = {
               obj1 = {x = 10, y = 20, w = 16, h = 16},
               obj2 = {x = 30, y = 40, w = 8, h = 8}
            },
            cell_size = 32,
            max_objects = 8,
            query_region = function(self, x, y, w, h)
               return {obj1 = true} -- Mock result
            end
         }
         console:set_strategy(mock_strategy, "fixed_grid")
      end)

      it("should show strategy stats", function()
         local result = console:execute_command("stats")
         assert.is_string(result)
         assert.is_true(string.find(result, "Strategy Statistics") ~= nil)
         assert.is_true(string.find(result, "Total Objects: 2") ~= nil)
         assert.is_true(string.find(result, "Cell Size: 32") ~= nil)
      end)

      it("should list objects", function()
         local result = console:execute_command("objects")
         assert.is_string(result)
         assert.is_true(string.find(result, "Objects in strategy") ~= nil)
         assert.is_true(string.find(result, "obj1") ~= nil)
         assert.is_true(string.find(result, "obj2") ~= nil)
      end)

      it("should filter objects", function()
         local result = console:execute_command("objects obj1")
         assert.is_string(result)
         assert.is_true(string.find(result, "obj1") ~= nil)
         assert.is_false(string.find(result, "obj2") ~= nil)
      end)

      it("should execute queries", function()
         local result = console:execute_command("query 0 0 100 100")
         assert.is_string(result)
         assert.is_true(string.find(result, "returned 1 results") ~= nil)
      end)

      it("should handle invalid query arguments", function()
         local result = console:execute_command("query invalid args")
         assert.is_string(result)
         assert.is_true(string.find(result, "Usage: query") ~= nil)
      end)
   end)

   describe("Visualization integration", function()
      local console
      local mock_vis

      before_each(function()
         console = DebugConsole:new()
         mock_vis = {
            show_structure = true,
            show_objects = false,
            show_queries = true,
            show_performance = false,
            viewport = {scale = 1.0},
            add_query = function() end
         }
         console:set_visualization_system(mock_vis)
      end)

      it("should toggle visualization options", function()
         local result = console:execute_command("show structure")
         assert.are.equal("Structure visualization: OFF", result)
         assert.is_false(mock_vis.show_structure)

         result = console:execute_command("show objects")
         assert.are.equal("Object visualization: ON", result)
         assert.is_true(mock_vis.show_objects)
      end)

      it("should handle invalid visualization options", function()
         local result = console:execute_command("show invalid")
         assert.is_string(result)
         assert.is_true(string.find(result, "Usage: show") ~= nil)
      end)

      it("should set zoom level", function()
         local result = console:execute_command("zoom 2.5")
         assert.are.equal("Zoom level set to 2.50", result)
         assert.are.equal(2.5, mock_vis.viewport.scale)
      end)

      it("should handle invalid zoom levels", function()
         local result = console:execute_command("zoom invalid")
         assert.is_string(result)
         assert.is_true(string.find(result, "Invalid zoom level") ~= nil)
      end)
   end)

   describe("Performance integration", function()
      local console
      local mock_profiler

      before_each(function()
         console = DebugConsole:new()
         mock_profiler = {
            stats = {
               total_queries = 100,
               average_query_time = 0.005,
               queries_per_second = 200
            },
            get_report = function()
               return "Mock performance report"
            end,
            get_bottlenecks = function(count)
               return {
                  {strategy = "test", execution_time = 0.1},
                  {strategy = "test", execution_time = 0.05}
               }
            end,
            start_session = function() end,
            end_session = function() end,
            measure_query = function() end
         }
         console:set_performance_profiler(mock_profiler)
      end)

      it("should show performance report", function()
         local result = console:execute_command("perf")
         assert.are.equal("Mock performance report", result)
      end)

      it("should show bottlenecks", function()
         local result = console:execute_command("bottlenecks")
         assert.is_string(result)
         assert.is_true(string.find(result, "Performance Bottlenecks") ~= nil)
         assert.is_true(string.find(result, "100.000ms") ~= nil)
         assert.is_true(string.find(result, "50.000ms") ~= nil)
      end)

      it("should run benchmarks", function()
         -- Set up a mock strategy for the benchmark
         local mock_strategy = {
            _strategy_name = "test",
            query_region = function() return {} end
         }
         console:set_strategy(mock_strategy, "test")
         
         local result = console:execute_command("benchmark 10")
         assert.is_string(result)
         assert.is_true(string.find(result, "Benchmark completed") ~= nil)
      end)
   end)

   describe("Error handling", function()
      local console

      before_each(function()
         console = DebugConsole:new()
      end)

      it("should handle missing visualization system", function()
         local result = console:execute_command("show structure")
         assert.are.equal("Visualization system not available", result)
      end)

      it("should handle missing performance profiler", function()
         local result = console:execute_command("perf")
         assert.are.equal("Performance profiler not available", result)
      end)

      it("should handle missing strategy", function()
         local result = console:execute_command("query 0 0 10 10")
         assert.are.equal("No queryable strategy loaded", result)
      end)
   end)

   describe("Utility functions", function()
      local console

      before_each(function()
         console = DebugConsole:new()
      end)

      it("should get object count", function()
         assert.are.equal(0, console:get_object_count())

         console:set_strategy({objects = {a = {}, b = {}, c = {}}})
         assert.are.equal(3, console:get_object_count())
      end)

      it("should get time", function()
         local time_val = console:get_time()
         assert.is_number(time_val)
      end)

      it("should set strategy", function()
         local strategy = {test = true}
         console:set_strategy(strategy, "test_strategy")

         assert.are.equal(strategy, console.current_strategy)
         assert.are.equal("test_strategy", strategy._strategy_name)
      end)

      it("should integrate with systems", function()
         local vis = {test = "vis"}
         local perf = {test = "perf"}

         console:set_visualization_system(vis)
         console:set_performance_profiler(perf)

         assert.are.equal(vis, console.visualization_system)
         assert.are.equal(perf, console.performance_profiler)
      end)
   end)
end)