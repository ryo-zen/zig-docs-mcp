// Core union examples for zig_docs/union.md
// Run with:
//   zig test zig_docs_std/Examples/union.tests.zig

const std = @import("std");
const testing = std.testing;

test "packed union equality compares backing integer" {
    const U = packed union {
        a: u4,
        b: i4,
    };

    const x: U = .{ .a = 3 };
    const y: U = .{ .b = 3 };

    try testing.expectEqual(x, y);
}
