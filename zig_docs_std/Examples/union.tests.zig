// Core union examples for zig_docs/union.md
// Run with:
//   zig test zig_docs_std/Examples/union.tests.zig

const std = @import("std");
const testing = std.testing;

test "tagged union switch captures payload and tag" {
    const ComplexTypeTag = enum {
        ok,
        not_ok,
    };
    const ComplexType = union(ComplexTypeTag) {
        ok: u8,
        not_ok: void,
    };

    const c = ComplexType{ .ok = 42 };

    try testing.expectEqual(ComplexTypeTag.ok, @as(ComplexTypeTag, c));
    try testing.expectEqual(ComplexTypeTag, std.meta.Tag(ComplexType));

    switch (c) {
        .ok => |value| try testing.expectEqual(42, value),
        .not_ok => unreachable,
    }

    switch (c) {
        .ok => |_, tag| comptime std.debug.assert(tag == .ok),
        .not_ok => unreachable,
    }
}

test "tagged union payload can be modified through switch pointer capture" {
    const ComplexTypeTag = enum {
        ok,
        not_ok,
    };
    const ComplexType = union(ComplexTypeTag) {
        ok: u8,
        not_ok: void,
    };

    var c = ComplexType{ .ok = 42 };

    switch (c) {
        ComplexTypeTag.ok => |*value| value.* += 1,
        ComplexTypeTag.not_ok => unreachable,
    }

    try testing.expectEqual(43, c.ok);
}

test "inferred tag union exposes tag values and tag names" {
    const Tagged = union(enum(u32)) {
        int: i64 = 123,
        boolean: bool = 67,
    };

    const int: Tagged = .{ .int = -40 };
    const boolean: Tagged = .{ .boolean = false };

    try testing.expectEqual(123, @intFromEnum(int));
    try testing.expectEqual(67, @intFromEnum(boolean));
    try testing.expectEqualSlices(u8, "int", @tagName(Tagged.int));
}

test "packed union equality compares backing integer" {
    const U = packed union {
        a: u4,
        b: i4,
    };

    const x: U = .{ .a = 3 };
    const y: U = .{ .b = 3 };

    try testing.expectEqual(x, y);
}

test "anonymous union literal syntax initializes union values" {
    const Number = union {
        int: i32,
        float: f64,
    };

    const helpers = struct {
        fn makeNumber() Number {
            return .{ .float = 12.34 };
        }
    };

    const i: Number = .{ .int = 42 };
    const f = helpers.makeNumber();

    try testing.expectEqual(42, i.int);
    try testing.expectEqual(12.34, f.float);
}
