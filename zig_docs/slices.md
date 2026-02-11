# Slices

A slice in Zig has type `[]T` and represents two pieces of data:

- pointer (`[*]T`)
- length (`len`)

Unlike arrays, slice length is runtime-known. Arrays encode length in the type.

📚 **Runnable Examples:** `zig_docs_std/Examples/slices.tests.zig`

📘 **Related Guide:** [Memory Allocator Strategy](memory_allocator_strategy.md)

## Overview

Use slices for most API boundaries where you pass buffers, strings, or variable-size views.

- Arrays: fixed-size data (`[N]T`)
- Slices: runtime views over contiguous data (`[]T`)
- Sentinel slices: runtime view with guaranteed sentinel at `len` (`[:x]T`)

## Quick Reference

| Operation | Syntax | Notes |
|---|---|---|
| Full runtime slice | `array[start..end]` | Produces `[]T` if bounds are runtime-known |
| Compile-time range | `array[0..N]` | May produce `*[N]T` |
| Access length | `slice.len` | Runtime length |
| Access raw pointer | `slice.ptr` | Many-item pointer (`[*]T`) |
| Empty slice | `const s: []u8 = &.{}` | Common zero-length literal |
| Sentinel slice | `[:0]const u8` | Allows `slice[slice.len]` |

## Basic Slices

```zig
const std = @import("std");
const expect = std.testing.expect;
const expectEqualSlices = std.testing.expectEqualSlices;

test "basic slices" {
    var array = [_]i32{ 1, 2, 3, 4 };
    var start: usize = 0;
    _ = &start;
    const slice = array[start..array.len];

    const alt: []const i32 = &.{ 1, 2, 3, 4 };
    try expectEqualSlices(i32, slice, alt);

    try expect(@TypeOf(slice) == []i32);
    try expect(slice.len == array.len);
    try expect(&slice[0] == &array[0]);
}
```

## Compile-Time vs Runtime Slicing

If both bounds are comptime-known, slicing may produce a pointer-to-array (`*[N]T`) instead of `[]T`.

```zig
const std = @import("std");
const expect = std.testing.expect;

test "slicing result type" {
    var array = [_]i32{ 1, 2, 3, 4 };

    const ptr_to_array = array[0..array.len];
    try expect(@TypeOf(ptr_to_array) == *[array.len]i32);

    var runtime_start: usize = 1;
    _ = &runtime_start;
    const length = 2;
    const ptr_len = array[runtime_start..][0..length];
    try expect(@TypeOf(ptr_len) == *[length]i32);
}
```

## Slices and Strings

Zig has no dedicated string type. By convention, strings are UTF-8 byte slices (`[]const u8`).

```zig
const std = @import("std");
const expect = std.testing.expect;
const mem = std.mem;
const fmt = std.fmt;

test "slice strings" {
    const hello: []const u8 = "hello";
    const world: []const u8 = "世界";

    var buf: [100]u8 = undefined;
    var start: usize = 0;
    _ = &start;
    const out = buf[start..];
    const joined = try fmt.bufPrint(out, "{s} {s}", .{ hello, world });

    try expect(mem.eql(u8, joined, "hello 世界"));
}
```

## Pointer and Slice Relationship

```zig
const std = @import("std");
const expect = std.testing.expect;

test "slice pointer fields" {
    var array = [_]i32{ 1, 2, 3, 4 };
    const slice = array[0..];

    try expect(@TypeOf(slice.ptr) == [*]i32);
    try expect(@TypeOf(&slice[0]) == *i32);
    try expect(@intFromPtr(slice.ptr) == @intFromPtr(&slice[0]));
}
```

## Sentinel-Terminated Slices

`[:x]T` is a slice with runtime length and a guaranteed sentinel value at index `len`.

```zig
const std = @import("std");
const expect = std.testing.expect;

test "sentinel slices" {
    const s: [:0]const u8 = "hello";
    try expect(s.len == 5);
    try expect(s[5] == 0);
}

test "sentinel slicing syntax" {
    var array = [_]u8{ 3, 2, 1, 0, 3, 2, 1, 0 };
    var n: usize = 3;
    _ = &n;
    const s = array[0..n :0];
    try expect(@TypeOf(s) == [:0]u8);
    try expect(s.len == 3);
}
```

## Common Gotchas

- Bounds checks apply to `slice[i]`, but not raw pointer arithmetic on `slice.ptr`.
- Mutating `slice.ptr` directly without updating `len` can create invalid slice state.
- `&slice[0]` requires `slice.len > 0`; handle empty slices safely.
- Sentinel slice creation (`data[start..end :x]`) checks sentinel at runtime in safety modes.

## Safety Patterns

1. Validate index/range before access in boundary-heavy code.
2. Prefer passing slices over raw pointers to preserve bounds.
3. Use `[:x]T` only when sentinel contracts are real and enforced.
4. Keep empty-slice behavior explicit (`&.{}` or `[0..0]` style).

## See Also

- [Pointers](pointers.md)
- [Arrays](arrays.md)
- [for](for.md)
- [Illegal Behavior](illegal_behavior.md)
