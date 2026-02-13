# std.process.Args

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating command-line argument handling.

## Quick Start

### Iterating through arguments

In Zig 0.16, the idiomatic way to access command-line arguments is via the `Init` or `Init.Minimal` parameter passed to `main`.

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Initialize the iterator using the process-wide allocator
    var args = try init.minimal.args.iterateAllocator(init.gpa);
    defer args.deinit();

    // Skip the program name (first argument)
    _ = args.skip();

    // Iterate through remaining arguments
    while (args.next()) |arg| {
  std.debug.print("Argument: {s}\n", .{arg});
    }
}
```

### Collecting arguments into a slice

```zig
pub fn main(init: std.process.Init) !void {
    // Allocate a slice containing all arguments in an arena
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    for (args, 0..) |arg, i| {
  std.debug.print("arg[{}]: {s}\n", .{i, arg});
    }
}
```

---

## Overview

`std.process.Args` represents the command-line arguments passed to the process. In Zig 0.16, an instance of this type is automatically provided to the `main` function as part of the `std.process.Init` or `std.process.Init.Minimal` structs.

**Key Characteristics:**
- **Platform-Agnostic**: Abstracted via a common interface for Windows, POSIX, and WASI.
- **Memory Efficient**: Supports both lazy iteration and bulk allocation.
- **UTF-8 Ready**: On Windows, arguments are automatically converted from UTF-16 to WTF-8.

---

## Fields

`vector: Vector`
------
Internal representation of the arguments. The type of `Vector` depends on the target operating system.

---

## Types

### `Iterator`

A struct used to iterate over command-line arguments one by one.

**Key Methods:**
- `next() ?[:0]const u8`: Returns the next argument, or `null` if none remain.
- `skip() bool`: Skips the next argument. Returns `true` if an argument was skipped.
- `deinit() void`: Releases resources associated with the iterator.

---

## Functions

### `pub fn iterate(a: Args) Iterator`

Returns an iterator for the arguments.

**Note:** On some platforms (like Windows and WASI), this may fail to provide access to all arguments if they require runtime fetching/allocation. Use `iterateAllocator` for cross-platform code.

------

### `pub fn iterateAllocator(a: Args, gpa: Allocator) Iterator.InitError!Iterator`

Returns an iterator, using the provided allocator to fetch or convert arguments if necessary.

**Parameters:**
- `a`: The `Args` instance.
- `gpa`: Allocator for internal buffers.

**Returns:** An `Iterator`. You must call `deinit()` on the iterator when finished.

------

### `pub fn toSlice(a: Args, arena: Allocator) ToSliceError![]const [:0]const u8`

Allocates and returns all arguments as a slice of null-terminated strings.

**Parameters:**
- `a`: The `Args` instance.
- `arena`: An allocator (typically an `ArenaAllocator`) to hold the arguments.

---

## Debug Checklist

✅ **Use `iterateAllocator`** - It is the most robust way to handle arguments across all supported platforms.

✅ **Call `deinit()` on the iterator** - Essential if the iterator was created with an allocator.

✅ **Skip the first argument if only interested in parameters** - `args.next()` first returns the program name/path.

✅ **Use an ArenaAllocator for `toSlice`** - Since `toSlice` performs multiple allocations, an arena makes cleanup simple.

---

## Performance Tips

1. **Prefer `Iterator` over `toSlice`** - If you only need to process arguments once, iteration avoids allocating a full slice.
2. **Use the `main` provided allocator** - `init.gpa` or `init.arena.allocator()` are already set up for you.

---

## See Also

- **std.process.Init** - The structure containing the `Args` instance for `main`.
- **std.process.ArgExpansion** - Options for argument expansion on certain platforms.
