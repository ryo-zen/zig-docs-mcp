# Arrays

Arrays in Zig have type `[N]T`, where `N` is the length and `T` is the element type.

📚 **Runnable Examples:** `zig_docs_std/Examples/arrays.tests.zig`

- Length is part of the type.
- Length is known at compile time.
- Arrays support indexing, iteration, slicing, and compile-time composition.

## Quick Reference

| Operation | Syntax | Notes |
|---|---|---|
| Array literal | `[_]u8{ 'h', 'i' }` | Length inferred |
| Explicit type | `const a: [2]u8 = .{ 'h', 'i' };` | Length fixed in type |
| Length | `a.len` | Compile-time-known for arrays |
| Concatenation | `a ++ b` | Both operands must be comptime-known |
| Repetition | `x ** n` | Repeats pattern `n` times |
| Slice view | `a[start..end]` | Produces an array pointer for comptime-known bounds, or a slice for runtime-known bounds |

## Basic Arrays

```zig
const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const alt_message: [5]u8 = .{ 'h', 'e', 'l', 'l', 'o' };

comptime {
    assert(mem.eql(u8, &message, &alt_message));
    assert(message.len == 5);
}

// A string literal is a single-item pointer to a sentinel-terminated array.
const same_message = "hello";

comptime {
    assert(mem.eql(u8, &message, same_message));
}
```

## Iteration and Mutation

```zig
const std = @import("std");
const expectEqual = std.testing.expectEqual;

const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
var some_integers: [100]i32 = undefined;

test "iterate array" {
    var sum: usize = 0;
    for (message) |byte| {
        sum += byte;
    }
    try expectEqual('h' + 'e' + 'l' * 2 + 'o', sum);
}

test "mutate array in place" {
    for (&some_integers, 0..) |*item, i| {
        item.* = @intCast(i);
    }
    try expectEqual(10, some_integers[10]);
    try expectEqual(99, some_integers[99]);
}
```

## Compile-Time Array Composition

```zig
const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

const part_one = [_]i32{ 1, 2, 3, 4 };
const part_two = [_]i32{ 5, 6, 7, 8 };
const all_of_it = part_one ++ part_two;

comptime {
    assert(mem.eql(i32, &all_of_it, &[_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }));
}

const hello = "hello";
const world = "world";
const hello_world = hello ++ " " ++ world;
comptime {
    assert(mem.eql(u8, hello_world, "hello world"));
}

const pattern = "ab" ** 3;
comptime {
    assert(mem.eql(u8, pattern, "ababab"));
}

const all_zero = [_]u16{0} ** 10;
comptime {
    assert(all_zero.len == 10);
    assert(all_zero[5] == 0);
}
```

## Initializing Complex Arrays

```zig
const std = @import("std");
const expectEqual = std.testing.expectEqual;

const Point = struct {
    x: i32,
    y: i32,
};

var fancy_array = init: {
    var initial_value: [10]Point = undefined;
    for (&initial_value, 0..) |*pt, i| {
        pt.* = Point{
            .x = @intCast(i),
            .y = @intCast(i * 2),
        };
    }
    break :init initial_value;
};

fn makePoint(x: i32) Point {
    return Point{
        .x = x,
        .y = x * 2,
    };
}
var more_points = [_]Point{makePoint(3)} ** 10;

test "array initialization patterns" {
    try expectEqual(4, fancy_array[4].x);
    try expectEqual(8, fancy_array[4].y);
    try expectEqual(3, more_points[4].x);
    try expectEqual(6, more_points[4].y);
    try expectEqual(10, more_points.len);
}
```

## Multidimensional Arrays

```zig
const std = @import("std");
const expectEqual = std.testing.expectEqual;

const mat4x5 = [4][5]f32{
    [_]f32{ 1.0, 0.0, 0.0, 0.0, 0.0 },
    [_]f32{ 0.0, 1.0, 0.0, 1.0, 0.0 },
    [_]f32{ 0.0, 0.0, 1.0, 0.0, 0.0 },
    [_]f32{ 0.0, 0.0, 0.0, 1.0, 9.9 },
};

test "multidimensional arrays" {
    try expectEqual(mat4x5[1], [_]f32{ 0.0, 1.0, 0.0, 1.0, 0.0 });
    try expectEqual(9.9, mat4x5[3][4]);

    for (mat4x5, 0..) |row, row_index| {
        for (row, 0..) |cell, column_index| {
            if (row_index == column_index) {
                try expectEqual(1.0, cell);
            }
        }
    }

    const all_zero: [4][5]f32 = .{.{0} ** 5} ** 4;
    try expectEqual(0, all_zero[0][0]);
}
```

## Sentinel-Terminated Arrays

`[N:x]T` means an array with compile-time length `N` and sentinel `x` at index `N`.

```zig
const std = @import("std");
const expectEqual = std.testing.expectEqual;

test "sentinel array basics" {
    const array = [_:0]u8{ 1, 2, 3, 4 };
    try expectEqual([4:0]u8, @TypeOf(array));
    try expectEqual(4, array.len);
    try expectEqual(0, array[4]);
}

test "sentinel can appear before len" {
    // The sentinel value may appear earlier, but does not influence the compile-time 'len'.
    const array = [_:0]u8{ 1, 0, 0, 4 };
    try expectEqual([4:0]u8, @TypeOf(array));
    try expectEqual(4, array.len);
    try expectEqual(0, array[4]);
}
```

## Destructuring Arrays

```zig
const std = @import("std");
const print = std.debug.print;

fn swizzleRgbaToBgra(rgba: [4]u8) [4]u8 {
    // Readable swizzling by destructuring.
    const r, const g, const b, const a = rgba;
    return .{ b, g, r, a };
}

pub fn main() void {
    const pos = [_]i32{ 1, 2 };
    const x, const y = pos;
    print("x = {}, y = {}\n", .{x, y});

    const orange: [4]u8 = .{ 255, 165, 0, 255 };
    print("{any}\n", .{swizzleRgbaToBgra(orange)});
}
```

## Common Gotchas

- `++` and `**` are compile-time composition tools; they require comptime-known operands.
- Array length is part of the type: `[4]u8` and `[5]u8` are different types.
- Arrays and slices are different: arrays have compile-time-known length, slices store runtime `ptr + len`.
- In sentinel arrays, `len` is still `N`; the sentinel lives at index `N`.

## See Also

- [for](for.md)
- [Slices](slices.md)
- [Pointers](pointers.md)
- [Vectors](vectors.md)
