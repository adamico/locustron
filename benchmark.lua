#!/usr/bin/env lua
-- Locustron Benchmark Runner
-- Standalone script for running spatial partitioning benchmarks from terminal

---@diagnostic disable: undefined-global, inject-field

-- Add src and benchmarks directories to package path
package.path = package.path .. ";./src/?.lua;./benchmarks/?.lua"

local BenchmarkCLI = require("benchmarks.benchmark_cli")

-- Pass command line arguments to the CLI
BenchmarkCLI.main(arg)
