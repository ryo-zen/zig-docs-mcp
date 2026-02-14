# Build Mode

Zig supports four optimization/safety modes. Mode selection directly affects runtime safety checks, performance characteristics, and binary size.

## Overview

Build mode is a policy decision, not just a compiler flag. Choose the mode based on deployment goals, then test and benchmark in that same mode.

## Runnable Examples

- `zig_docs_std/Examples/build_release_modes.tests.zig`
- `zig_docs_std/Examples/testing.tests.zig`

## Quick Start

1. Use `Debug` for day-to-day development and diagnostics.
2. Use `ReleaseSafe` for production when safety checks are still valuable.
3. Use `ReleaseFast` for performance-focused production binaries with mature test coverage.
4. Use `ReleaseSmall` when artifact size is a hard requirement.

## Standard `build.zig` Pattern

build.zig
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.default_step.dependOn(&exe.step);
}
```

This enables standard CLI options:

- `-Doptimize=Debug`
- `-Doptimize=ReleaseSafe`
- `-Doptimize=ReleaseFast`
- `-Doptimize=ReleaseSmall`

## Mode Summary

### [Debug](#toc-Debug) §

Shell$ `zig build-exe example.zig`

- Fastest compile times.
- Safety checks enabled.
- Slowest runtime among the four modes.
- Usually larger binaries.

### [ReleaseFast](#toc-ReleaseFast) §

Shell$ `zig build-exe example.zig -O ReleaseFast`

- Highest runtime optimization focus.
- Most safety checks disabled.
- Slower compile time than `Debug`.
- Good default for performance-critical, well-tested services.

### [ReleaseSafe](#toc-ReleaseSafe) §

Shell$ `zig build-exe example.zig -O ReleaseSafe`

- High optimization with runtime safety checks retained.
- Strong option for production rollouts where diagnostics still matter.
- Slower compile time than `Debug`.

### [ReleaseSmall](#toc-ReleaseSmall) §

Shell$ `zig build-exe example.zig -O ReleaseSmall`

- Optimizes for smaller binary size.
- Most safety checks disabled.
- Useful for constrained deployment environments.

## Decision Guide

- Choose `Debug` for development workflows and bug investigation.
- Choose `ReleaseSafe` for first production deployments or reliability-sensitive systems.
- Choose `ReleaseFast` for throughput/latency-sensitive binaries after correctness confidence is high.
- Choose `ReleaseSmall` when distribution footprint is the primary requirement.

## Gotchas

1. Benchmarking in `Debug` gives non-representative production numbers.
2. Switching to unsafe release modes can expose latent undefined behavior.
3. Mixing mode assumptions across docs, CI, and deployment causes hard-to-debug regressions.
4. Late mode changes in a release cycle can invalidate prior verification.

## Related Docs

- [Compilation Model](compilation_model.md)
- [Targets](targets.md)
- [Release Checklist](release_checklist.md)
- [Performance Methodology](performance.md)
- [Illegal Behavior](illegal_behavior.md)
