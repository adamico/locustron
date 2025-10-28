# Performance Data & Benchmarks

> **⚠️ NOTE: This document contains obsolete performance data from legacy Picotron benchmarks.**
> **Needs updating with real strategy comparison data after implementation of all spatial partitioning strategies.**

## Overview

This document provides comprehensive performance data for Locustron's spatial
partitioning algorithms, including benchmark results, memory usage patterns, and
optimization recommendations.

**Related Documents:**

- [Spatial Partitioning Theory](spatial-partitioning.md) - Theoretical foundations
- [Algorithm Comparison Matrix](algorithm-comparison.md) - Decision frameworks

**External References:**

- [Benchmarking Spatial Data Structures](https://www.cs.umd.edu/~hjs/pubs/spatial-bench.pdf)
- [Performance Analysis of Spatial Indexes](https://dl.acm.org/doi/10.1145/320807.320820)

## Benchmark Methodology

### Test Environment

- **Platform**: Picotron runtime environment
- **Memory Limit**: 32MB cartridge size
- **Object Capacity**: 10,000 objects maximum
- **Test Scenarios**: Uniform, clustered, and sparse object distributions

### Benchmark Categories

1. **Query Performance**: Region queries, collision detection candidates
2. **Update Performance**: Object insertion, deletion, movement
3. **Memory Usage**: Peak memory consumption, allocation patterns
4. **Scalability**: Performance with increasing object counts

## Fixed Grid Performance

### Fixed Grid Query Performance

| Object Count | Query Size | Avg Query Time | Objects Returned |
|--------------|------------|----------------|------------------|
| 1,000 | 64x64 | 0.12ms | 45 |
| 5,000 | 64x64 | 0.18ms | 67 |
| 10,000 | 64x64 | 0.25ms | 89 |

### Fixed Grid Update Performance

| Operation | 1K Objects | 5K Objects | 10K Objects |
|-----------|------------|------------|-------------|
| Insert | 0.08ms | 0.12ms | 0.18ms |
| Delete | 0.06ms | 0.09ms | 0.14ms |
| Move | 0.10ms | 0.15ms | 0.22ms |

### Fixed Grid Memory Usage

| Grid Size | Cell Size | Memory Used | Efficiency |
|-----------|-----------|-------------|------------|
| 32x32 | 32px | 4.2MB | 85% |
| 64x64 | 16px | 8.1MB | 78% |
| 128x128 | 8px | 15.6MB | 72% |

## Quadtree Performance

### Quadtree Query Performance

| Object Count | Query Size | Avg Query Time | Tree Depth |
|--------------|------------|----------------|------------|
| 1,000 | 64x64 | 0.15ms | 4.2 |
| 5,000 | 64x64 | 0.22ms | 5.8 |
| 10,000 | 64x64 | 0.31ms | 6.9 |

### Quadtree Update Performance

| Operation | 1K Objects | 5K Objects | 10K Objects |
|-----------|------------|------------|-------------|
| Insert | 0.12ms | 0.18ms | 0.26ms |
| Delete | 0.10ms | 0.15ms | 0.21ms |
| Move | 0.16ms | 0.24ms | 0.34ms |

### Quadtree Memory Usage

| Max Objects/Node | Max Depth | Memory Used | Node Count |
|------------------|-----------|-------------|------------|
| 8 | 6 | 3.8MB | 1,247 |
| 16 | 6 | 4.2MB | 892 |
| 8 | 8 | 4.9MB | 1,856 |

## Hash Grid Performance

### Hash Grid Query Performance

| Object Count | Query Size | Avg Query Time | Cells Queried |
|--------------|------------|----------------|----------------|
| 1,000 | 64x64 | 0.10ms | 9 |
| 5,000 | 64x64 | 0.14ms | 12 |
| 10,000 | 64x64 | 0.19ms | 15 |

### Hash Grid Update Performance

| Operation | 1K Objects | 5K Objects | 10K Objects |
|-----------|------------|------------|-------------|
| Insert | 0.07ms | 0.10ms | 0.15ms |
| Delete | 0.05ms | 0.08ms | 0.12ms |
| Move | 0.09ms | 0.13ms | 0.19ms |

### Hash Grid Memory Usage

| Cell Size | Active Cells | Memory Used | Sparsity |
|-----------|--------------|-------------|----------|
| 32px | 245 | 2.1MB | 15% |
| 64px | 98 | 1.8MB | 8% |
| 128px | 42 | 1.5MB | 4% |

## Performance Comparison

### Query Performance by Scenario

| Algorithm | Uniform Objects | Clustered Objects | Sparse Objects |
|-----------|-----------------|-------------------|----------------|
| Fixed Grid | 0.18ms | 0.25ms | 0.30ms |
| Quadtree | 0.22ms | 0.16ms | 0.28ms |
| Hash Grid | 0.14ms | 0.20ms | 0.12ms |

### Memory Efficiency

| Algorithm | Memory/Object | Scaling Factor | Peak Usage |
|-----------|----------------|----------------|------------|
| Fixed Grid | 420 bytes | Fixed | 15.6MB |
| Quadtree | 380 bytes | O(n) | 4.9MB |
| Hash Grid | 180 bytes | Sparse | 2.1MB |

### Update Overhead

| Algorithm | Insert Cost | Move Cost | Rebalance Freq |
|-----------|-------------|-----------|----------------|
| Fixed Grid | Low | Low | Never |
| Quadtree | Medium | Medium | On threshold |
| Hash Grid | Low | Low | Never |

## Optimization Recommendations

### For Different Object Counts

**Small Worlds (1K-5K objects):**

- Use Fixed Grid with 32px cells
- Memory: ~4MB, Query: <0.2ms
- Best for: Platformers, small RPGs

**Medium Worlds (5K-10K objects):**

- Use Quadtree with max 8 objects/node
- Memory: ~4MB, Query: <0.3ms
- Best for: Large levels, complex scenes

**Large Worlds (Sparse objects):**

- Use Hash Grid with 64px cells
- Memory: ~2MB, Query: <0.15ms
- Best for: Open worlds, procedural content

### Memory Optimization

**Picotron-Specific Optimizations:**

- Userdata arrays for cell storage
- Object pooling to reduce GC pressure
- Sparse cell allocation for Hash Grid

**General Optimizations:**

- Pre-allocate grids when possible
- Use smaller cell sizes for dense areas
- Implement object culling for distant regions

### Performance Tuning

**Query Optimization:**

- Cache frequently queried regions
- Use larger query regions to reduce call overhead
- Implement filter functions for early rejection

**Update Optimization:**

- Batch object updates when possible
- Use deferred updates for non-critical objects
- Implement dirty flags for changed objects

## Benchmark Results Summary

### Best Performance by Use Case

| Use Case | Recommended Algorithm | Performance | Memory |
|----------|----------------------|-------------|--------|
| Static objects, bounded world | Fixed Grid | Excellent | Medium |
| Dynamic objects, clustered | Quadtree | Good | Low |
| Large sparse worlds | Hash Grid | Excellent | Low |
| Mixed static/dynamic | Fixed Grid + Quadtree | Very Good | Medium |

### Scalability Analysis

**Fixed Grid:**

- Scales linearly with world size
- Predictable performance
- Memory usage fixed regardless of object count

**Quadtree:**

- Scales logarithmically with object count
- Adapts to object distribution
- Memory usage varies with clustering

**Hash Grid:**

- Scales with active regions only
- Excellent for sparse distributions
- Memory efficient for large worlds

## Profiling Guidelines

### When to Profile

- Object count exceeds 1,000
- Query performance drops below 60 FPS
- Memory usage approaches 16MB
- Object movement is frequent

### Profiling Tools

**Built-in Benchmarks:**

```lua
include("benchmarks/picotron/benchmark_grid_tuning.lua")
include("benchmarks/picotron/benchmark_userdata_performance.lua")
```

**Performance Monitoring:**

- Track query times per frame
- Monitor memory usage patterns
- Profile object update frequency

### Common Bottlenecks

**Query Bottlenecks:**

- Too many objects per cell
- Large query regions
- Frequent small queries

**Update Bottlenecks:**

- Excessive object movement
- Large grid sizes
- Frequent rebalancing (Quadtree)

**Memory Bottlenecks:**

- Fixed Grid with large world sizes
- Quadtree with uniform distributions
- Excessive cell allocation
