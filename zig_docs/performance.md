# Performance Methodology

A practical, measure-first workflow for optimizing Zig systems code without regressing correctness.

## Runnable Examples

- `zig test zig_docs_std/Examples/performance_methodology.tests.zig`
- `zig build-exe zig_docs_std/Examples/test_arraylist_aligned_performance.zig -O ReleaseSafe`
- `zig run zig_docs_std/Examples/mlkem_benchmark.zig -O ReleaseFast`
- `zig run zig_docs_std/Examples/mldsa_benchmark.zig -O ReleaseFast`

## Overview

Performance work should be treated as an engineering loop, not a one-way rewrite.
Always optimize based on measured bottlenecks, then re-measure after each change.

## Quick Start

1. Define a workload that matches production behavior.
2. Collect a baseline: latency percentiles, throughput, and allocation volume.
3. Identify the hottest path before changing code.
4. Optimize one bottleneck at a time.
5. Keep a correctness test for every optimization.

```zig
const std = @import("std");

fn work(iterations: usize) u64 {
    var acc: u64 = 0;
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        acc +%= @as(u64, @intCast(i));
    }
    return acc;
}

test "simple timer harness" {
    const io = std.testing.io;
    const start = std.Io.Clock.awake.now(io);
    const result = work(200_000);
    const elapsed_ns = start.durationTo(std.Io.Clock.awake.now(io)).toNanoseconds();

    // Guard against dead-code elimination while keeping the example tiny.
    try std.testing.expect(result != 0);
    try std.testing.expect(elapsed_ns > 0);
}
```

## Zig 0.16 Performance Notes

Zig 0.16.0 changes both application-level performance APIs and build-time
performance tradeoffs:

1. Prefer `std.Io.Clock` for timing and pass an explicit `std.Io` through code
   that can block or introduce nondeterminism. Tests should normally use
   `std.testing.io`.
2. For independent I/O operations, `std.Io.Batch` has lower task overhead than
   `Future`; start with the API that matches the workflow, then measure before
   rewriting.
3. `std.heap.ArenaAllocator` is now thread-safe and lock-free. It is comparable
   for single-threaded access and can be faster than the old
   `ThreadSafeAllocator` wrapper under concurrent access.
4. Incremental compilation is much faster and can be tried with
   `zig build -fincremental --watch`, but it is still disabled by default in
   0.16.0 because known bugs remain.
5. The self-hosted x86 backend remains the default in `Debug` mode and has
   significantly faster compilation than LLVM, but lower machine-code quality.
   Do not use `Debug` timings as evidence for optimized runtime performance.
6. The new ELF linker is the default with `-fincremental` on ELF targets and is
   materially faster for incremental relinking, but it is not yet feature
   complete.
7. LLVM 21 loop vectorization is disabled in Zig 0.16.0 to avoid
   miscompilations. This can reduce generated-code performance for some hot
   loops, so benchmark vector-heavy code on the actual target and compiler
   version.

## Measure-First Workflow

1. Pick a stable input size and fixed environment where possible.
2. Warm up once before collecting numbers.
3. Run multiple iterations and compare median and p95, not a single run.
4. Track allocation count/bytes for memory-sensitive paths.
5. Capture compiler mode (`Debug`, `ReleaseSafe`, `ReleaseFast`, `ReleaseSmall`) with each result.
6. Capture the Zig version and target triple with each result, because backend
   and linker behavior changed in Zig 0.16.0.

## Optimization Triage Order

Apply this order unless profiling proves otherwise:

1. Algorithm and data-structure complexity.
2. Allocation frequency and lifetime (reduce churn first).
3. Cache locality and memory layout.
4. Branch behavior and predictable hot paths.
5. Micro-optimizations and instruction-level tuning.

## Allocation Profiling Patterns

1. Wrap hot path tests with a counting allocator or failing allocator.
2. Record allocation count and total bytes before and after changes.
3. Move temporary allocations to caller-owned buffers or arenas when lifetimes allow.
4. Keep OOM behavior explicit while optimizing.

## Cache-Friendly Layout Guidance

1. Keep hot fields close together and avoid pointer-heavy indirection on hot paths.
2. Prefer contiguous storage (`[]T`, `ArrayList`) for scan-heavy loops.
3. Split rarely-used fields into separate cold structs.
4. Validate with end-to-end benchmarks, not intuition.

## Decision Guide

- Choose `ReleaseSafe` first for perf debugging when you still need runtime checks.
- Choose `ReleaseFast` for final throughput-sensitive binaries after correctness and fuzz coverage are stable.
- Use `ReleaseSmall` when binary size or distribution footprint is a hard constraint.
- Keep at least one correctness and one performance regression test for each critical path.

## Gotchas

1. Comparing results from different build modes invalidates conclusions.
2. Microbenchmarks that ignore I/O, allocation, or contention often mislead.
3. Removing safety checks can hide bugs that later dominate tail latency.
4. Optimizing cold paths increases complexity without practical gain.

## Related Docs

- [0.16.0 Release Notes](release_notes.md)
- [Build Mode](build_mode.md)
- [Release Checklist](release_checklist.md)
- [Memory Allocator Strategy](memory_allocator_strategy.md)
- [Result Location Semantics](result_location_semantics.md)
