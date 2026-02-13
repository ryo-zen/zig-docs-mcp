# std.process.Environ

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating environment variable handling.

## Quick Start

### Basic Environment Access

In Zig 0.16, the most common way to access environment variables is via the `Init` struct provided to `main`.

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // 1. Check for existence (case-insensitive on Windows)
    if (init.environ_map.contains("PATH")) {
  // ...
    }

    // 2. Get a value (returns ?[]const u8)
    if (init.environ_map.get("HOME")) |home| {
  std.debug.print("Home: {s}\n", .{home});
    }

    // 3. Iterate through all variables
    var it = init.environ_map.iterator();
    while (it.next()) |entry| {
  std.debug.print("{s}={s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
    }
}
```

### Low-level Access (Environ)

If you use `Init.Minimal`, you get a raw `Environ` handle.

```zig
pub fn main(minimal: std.process.Init.Minimal) !void {
    // raw environment access (less convenient than Map)
    const env = minimal.environ;
    _ = env;
}
```

---

## Overview

`std.process.Environ` represents the environment variables of a process as a raw, unmodified block of data provided by the operating system. While `Environ` provides low-level access, most applications should use `std.process.Environ.Map` for a more convenient, searchable hash map representation.

In Zig 0.16, `std.process.Init` automatically provides a pre-initialized `environ_map` (of type `*Map`) that is populated from the process's environment.

**Key Characteristics:**
- **Platform-Aware**: Handles Windows WTF-16 to WTF-8 conversion and case-insensitivity automatically.
- **Resource Management**: The `Map` type manages the memory for keys and values.
- **WASI Compatible**: Properly handles environment queries in WASI environments.

---

## Fields

`block: Block`
------
The raw environment data provided by the OS. On POSIX systems, this is a slice of null-terminated strings (`[:null]const ?[*:0]const u8`). On Windows and WASI (without libc), this is `void` as the environment must be queried at runtime.

---

## Nested Types

### `Map`
A high-level hash map for environment variables. It is the recommended way to read and modify environment variables.
See [std.process.Environ.Map](std.process.Environ.Map.md) for detailed documentation.

---

## Functions

### `pub fn createMap(env: Environ, allocator: Allocator) !Map`
Allocates a new `Map` and populates it by parsing the raw `Environ` block.

**Example:**
```zig
const env_map = try minimal.environ.createMap(allocator);
defer env_map.deinit();
```

------

### `pub fn getAlloc(environ: Environ, gpa: Allocator, key: []const u8) ![]u8`
A convenience function that creates a temporary map, looks up a key, and returns an owned copy of the value.
**Note:** This is less efficient than using a persistent `Map`.

------

### `pub fn getPosix(environ: Environ, key: []const u8) ?[:0]const u8`
Directly searches the POSIX environment block for a key. Returns a null-terminated slice pointing into the environment block.
**Note:** Only available on POSIX-like systems where `Block` is not `void`.

------

### `pub fn getWindows(environ: Environ, key: [*:0]const u16) ?[:0]const u16`
**Windows-only.** Directly searches the Windows environment block using a UTF-16 key.

---

## Error Sets

### `ContainsError`
- `OutOfMemory`
- `InvalidWtf8` (Windows only)

### `CreateMapError`
- `OutOfMemory`
- `InvalidWtf8` (Windows only)

---

## Debug Checklist

✅ **Use `init.environ_map`** - It's pre-parsed and ready for use in `main`.

✅ **Remember Case-Insensitivity on Windows** - `Environ.Map` handles this automatically by using a special hash context on Windows.

✅ **Call `deinit()` on custom Maps** - If you create a `Map` manually via `createMap`, you must free it.

✅ **Check for `null`** - Environment variables may not be set; always handle the optional return from `get()`.

---

## Performance Tips

1. **Reuse the `Map`** - Don't call `createMap` or `getAlloc` repeatedly. Use the `environ_map` provided in `Init`.
2. **Use `init.arena` for new Maps** - If you need a modified version of the environment for a child process, using an arena allocator simplifies cleanup.
3. **Prefer `contains()` over `get() != null`** - If you only need to know if a variable exists, `contains` is more explicit.

---

## See Also

- **std.process.Init** - The structure that provides the default environment map.
- **std.process.Environ.Map** - The primary type for environment manipulation.
- **std.process.Child** - Uses `Environ.Map` to set environment variables for new processes.
