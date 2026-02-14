# Release Checklist

A production-oriented checklist for shipping Zig binaries with clear safety, performance, and operability guarantees.

## Runnable Examples

- `zig_docs_std/Examples/build_release_modes.tests.zig`
- `zig_docs_std/Examples/std.process.tests.zig`
- `zig_docs_std/Examples/testing.tests.zig`

## Overview

Release quality is not just about compile success.
A good release verifies behavior under the selected optimization mode, validates target assumptions, and confirms operational failure handling.

## Quick Start

1. Freeze toolchain version and target triple.
2. Run tests in `Debug` and release mode intended for deployment.
3. Verify logging, error reporting, and exit behavior.
4. Produce reproducible artifacts with recorded build flags.
5. Validate startup and shutdown paths on each supported target.

## Pre-Release Checklist

1. Build Mode
   Use the intended mode (`ReleaseSafe`, `ReleaseFast`, or `ReleaseSmall`) for final verification.
2. Test Matrix
   Run core tests on host and at least one non-host target if cross-platform support is promised.
3. Targeting
   Confirm `-target` and CPU feature assumptions are explicit, not implicit host defaults.
4. Error Policy
   Verify recoverable errors return typed values and fatal invariants fail loudly.
5. Resource Safety
   Validate cleanup paths for files, sockets, locks, and child processes.
6. Observability
   Confirm logs include operation context required for incident triage.
7. Packaging
   Store exact build command, Zig version, and artifact checksums.

## Build Artifact Checklist

1. Record `zig version` output in release metadata.
2. Record compile command or `build.zig` options used.
3. Keep symbol/debug strategy explicit per environment.
4. Verify binary size and startup regression budgets.

## Rollout Checklist

1. Canary deploy with explicit rollback criteria.
2. Watch error rates, latency percentiles, and memory growth.
3. Confirm shutdown and restart are clean.
4. Keep previous known-good artifact available for immediate rollback.

## Decision Guide

- Choose `ReleaseSafe` when operational correctness diagnostics are still high priority.
- Choose `ReleaseFast` for stable, benchmarked hot paths with mature coverage.
- Choose `ReleaseSmall` when binary footprint is a strict delivery constraint.
- Keep one release policy per artifact; avoid mixing undocumented mode choices.

## Gotchas

1. Validating only `Debug` mode can miss release-only behavior differences.
2. Shipping host-target binaries by accident breaks cross-machine deployment.
3. Missing reproducibility metadata makes incident forensics difficult.
4. Unbounded retries can look healthy in tests but fail in production saturation.

## Related Docs

- [Build Mode](build_mode.md)
- [Compilation Model](compilation_model.md)
- [Targets](targets.md)
- [Performance Methodology](performance.md)
- [Error Handling Playbook](error_handling.md)
