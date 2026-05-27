# std.start

## Overview

`std.start` contains executable startup glue. It is imported by `std.zig` root initialization logic so the appropriate entry symbols are exported and eventually call the root `main` when required.

Source: `/path/to/zig-0.16.0/lib/std/start.zig`

## Behavior

At comptime, this file inspects the target, output mode, libc linkage, and root declarations to decide whether to export startup symbols for:

- normal executables
- dynamic libraries on Windows
- Windows GUI entry points
- UEFI applications
- WASI command or reactor entry points
- freestanding WebAssembly
- OS-specific `_start` entry points

## Notes

This namespace does not expose public functions in the locked source; importing it triggers startup-selection comptime logic. Application code normally interacts with this behavior by defining the appropriate root `main` or target-specific entry point.
