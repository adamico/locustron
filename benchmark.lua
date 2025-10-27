#!/usr/bin/env lua
-- Locustron Benchmark Runner
-- Standalone script for running spatial partitioning benchmarks

-- Add src directory to package path
package.path = package.path .. ";./src/?.lua;./src/vanilla/?.lua"

local BenchmarkCLI = require("benchmark_cli")

-- Pass command line arguments to the CLI
BenchmarkCLI.main(arg)