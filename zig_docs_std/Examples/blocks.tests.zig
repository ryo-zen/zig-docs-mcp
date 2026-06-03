// Comprehensive tests for zig_docs/blocks.md examples.
// Run with:
//   zig test zig_docs_std/Examples/blocks.tests.zig

const std = @import("std");
const testing = std.testing;

test "labeled break from labeled block expression" {
    var y: i32 = 123;

    const x = blk: {
        y += 1;
        break :blk y;
    };
    try testing.expectEqual(124, x);
    try testing.expectEqual(124, y);
}

test "separate scopes can reuse a name" {
    {
        const pi = 3.14;
        _ = pi;
    }
    {
        var pi: bool = true;
        _ = &pi;
    }
}

test "empty block is equivalent to void literal" {
    const a = {};
    const b = void{};

    try testing.expectEqual(void, @TypeOf(a));
    try testing.expectEqual(void, @TypeOf(b));
    try testing.expectEqual(a, b);
}

test "block expressions can compute values" {
    const value = outer: {
        const base = inner: {
            break :inner @as(u8, 40);
        };
        break :outer base + 2;
    };

    try testing.expectEqual(42, value);
}
