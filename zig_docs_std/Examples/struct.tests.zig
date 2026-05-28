// Core struct examples for zig_docs/struct.md
// Run with:
//   zig test zig_docs_std/Examples/struct.tests.zig

const std = @import("std");
const testing = std.testing;

test "default field value example categorizes thresholds" {
    const Threshold = struct {
        minimum: f32 = 0.25,
        maximum: f32 = 0.75,

        const Category = enum { low, medium, high };

        fn categorize(t: @This(), value: f32) !Category {
            try testing.expect(t.maximum >= t.minimum);
            if (value < t.minimum) return .low;
            if (value > t.maximum) return .high;
            return .medium;
        }
    };

    const threshold: Threshold = .{};

    try testing.expectEqual(Threshold.Category.low, try threshold.categorize(0.10));
    try testing.expectEqual(Threshold.Category.medium, try threshold.categorize(0.50));
    try testing.expectEqual(Threshold.Category.high, try threshold.categorize(0.90));
}

test "tuple destructuring can return multiple values from a block" {
    const digits = [_]i8{ 3, 8, 9, 0, 7, 4, 1 };

    const min, const max = blk: {
        var min: i8 = 127;
        var max: i8 = -128;

        for (digits) |digit| {
            if (digit < min) min = digit;
            if (digit > max) max = digit;
        }

        break :blk .{ min, max };
    };

    try testing.expectEqual(@as(i8, 0), min);
    try testing.expectEqual(@as(i8, 9), max);
}

test "packed struct equality compares backing integer" {
    const S = packed struct {
        a: u4,
        b: u4,
    };

    const x: S = .{ .a = 1, .b = 2 };
    const y: S = .{ .b = 2, .a = 1 };

    try testing.expectEqual(x, y);
}
