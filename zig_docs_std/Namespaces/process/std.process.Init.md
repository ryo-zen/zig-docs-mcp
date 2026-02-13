# std.process.Init

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Quick Start

### The Modern Zig Entry Point

In Zig 0.16, the standard way to write a `main` function is to accept `std.process.Init`.

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // 1. Use the provided General Purpose Allocator
    const list = try init.gpa.alloc(u8, 10);
    defer init.gpa.free(list);

    // 2. Use the provided Arena for data that lives until exit
    const persistent_data = try init.arena.allocator().dupe(u8, "I live forever");
    _ = persistent_data;

    // 3. Use the provided Io interface
    var child = try std.process.spawn(init.io, .{
  .argv = &[_][]const u8{"ls"},
    });
    _ = try child.wait(init.io);

    // 4. Access pre-parsed environment variables
    if (init.environ_map.get("USER")) |user| {
  std.debug.print("Hello, {s}!\n", .{user});
    }
}
```

---

## Overview

`std.process.Init` is a structure provided by the Zig runtime to your `main` function. It encapsulates the most common resources a program needs, pre-initialized and ready for use.

This pattern replaces the manual initialization of allocators and fetching of arguments/environment variables that was common in previous Zig versions.

**Key Benefits:**
- **Zero Boilerplate**: No need to manually set up a `GeneralPurposeAllocator` or `ArenaAllocator`.
- **Platform Optimized**: The `io` and `gpa` fields are automatically selected to be the best options for your target platform and build mode.
- **Safety**: In debug builds, the provided `gpa` automatically includes leak detection.
- **WASI Support**: Includes `preopens` for seamless file system access on WASI.

---

## Fields

`minimal: Minimal`
------
A subset of `Init` containing only `args` and `environ`. Use `Init.Minimal` as your `main` parameter if you want to manage your own allocators and I/O.

`arena: *std.heap.ArenaAllocator`
------
An arena allocator that persists for the entire lifetime of the process. It is automatically deinitialized after `main` returns. This is ideal for configuration data, command-line arguments, or any other data that needs to live until the program terminates.

`gpa: Allocator`
------
A thread-safe `std.mem.Allocator`. In Debug and ReleaseSafe modes, this is typically a `GeneralPurposeAllocator` with leak detection enabled. In ReleaseFast and ReleaseSmall, it is optimized for performance/size.

`io: std.Io`
------
The standard I/O interface for the current platform. This is used for spawning processes, performing non-blocking I/O, and other system interactions.

`environ_map: *Environ.Map`
------
A mutable hash map containing all environment variables. This is initialized using `gpa`.

`preopens: Preopens`
------
Named files provided by the parent process. Primarily used in WASI for capability-based security, but available on all platforms to provide a consistent interface for passed file descriptors.

---

## Types

### `Minimal`

A smaller version of `Init` for programs that require more control.

**Fields:**
- `environ: Environ` - Raw environment variable access.
- `args: Args` - Command-line argument access.

---

## Debug Checklist

✅ **Use `init.gpa` for most allocations** - It's safe and performs leak checking in debug builds.

✅ **Use `init.arena.allocator()` for "global" data** - Saves you from having to track and free every single long-lived allocation.

✅ **Pass `init.io` to process functions** - `std.process.spawn`, `std.process.run`, and `child.wait` all require it.

✅ **Prefer `Init` over `Init.Minimal`** - Unless you have a specific reason to avoid the standard allocators or I/O setup.

---

## See Also

- **std.process.Args** - For details on how to use the arguments provided in `init.minimal.args`.
- **std.process.Environ** - For details on environment variable access.
- **std.Io** - The interface used by `init.io`.
- **std.heap.GeneralPurposeAllocator** - The underlying allocator typically used for `init.gpa`.
