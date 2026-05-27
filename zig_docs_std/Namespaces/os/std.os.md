# std.os

## Overview

`std.os` exposes OS-specific namespaces. It is a thin root namespace that groups per-platform low-level declarations.

Source: `/path/to/zig-0.16.0/lib/std/os.zig`

## Public API

- `std.os.linux` - Linux-specific constants, syscall wrappers, and OS declarations.
- `std.os.plan9` - Plan 9-specific declarations.
- `std.os.uefi` - UEFI-specific declarations.
- `std.os.wasi` - WASI-specific declarations.
- `std.os.emscripten` - Emscripten-specific declarations.
- `std.os.windows` - Windows-specific declarations.

## Relationship to std.posix

Use `std.posix` for cross-platform POSIX-style wrappers and translated error sets. Use `std.os.<platform>` when code intentionally targets one platform namespace and needs platform-native constants or declarations.
