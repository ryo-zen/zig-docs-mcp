# Targets

A Zig target describes where your binary will run: architecture, OS, ABI, and CPU feature assumptions.

## Overview

If target selection is implicit, binaries often become host-specific by accident. Explicit target configuration is required for portable and reproducible releases.

## Runnable Examples

- `zig_docs_std/Examples/build_release_modes.tests.zig`
- `zig_docs_std/Examples/test_io_threaded.zig`
- `zig_docs_std/Examples/test_socket_basic.zig`

## Quick Start

1. Use host target defaults only for local development.
2. Set explicit target requirements for deployable artifacts.
3. Validate runtime behavior on each promised platform.
4. Record target and toolchain version in release metadata.

## What a Target Includes

A target captures:

- CPU architecture.
- Enabled/required CPU features.
- Operating system and version constraints.
- ABI and ABI version.

Use `zig targets` to inspect available target metadata.

## Host Target vs Explicit Target

Without `-target`, Zig builds for the host machine. That is convenient for local iteration, but unsuitable for cross-machine deployment.

Use explicit target configuration when you need portability:

Shell$ `zig build-exe app.zig -target x86_64-linux-gnu`

## Build Script Pattern

build.zig
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);
}
```

## Portability Guidance

- Keep platform-specific paths behind explicit conditional compilation.
- Avoid over-specializing CPU features unless deployment hardware is tightly controlled.
- Treat libc/non-libc linkage as part of the target policy, not an afterthought.
- Confirm filesystem, networking, and process behavior on real target environments.

## Decision Guide

- Use host target for local development and quick experiments.
- Use explicit target triples for CI artifacts and release binaries.
- Use conservative CPU baselines when binaries must run across mixed hardware fleets.
- Narrow target assumptions only when you can enforce deployment environment constraints.

## Gotchas

1. Host defaults can silently produce non-portable binaries.
2. CPU feature assumptions can cause runtime failures on older systems.
3. Successful cross-compilation does not guarantee runtime compatibility.
4. ABI mismatches can appear as link-time or runtime errors far from the root cause.

## Related Docs

- [Build Mode](build_mode.md)
- [Compilation Model](compilation_model.md)
- [Release Checklist](release_checklist.md)
- [C Interop](c.md)
