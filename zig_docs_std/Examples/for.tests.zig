// Comprehensive tests for zig_docs/for.md examples.
// Run with:
//   zig test zig_docs_std/Examples/for.tests.zig

const std = @import("std");
const testing = std.testing;

test "for basics" {
    const items = [_]i32{ 4, 5, 3, 4, 0 };
    var sum: i32 = 0;

    for (items) |value| {
        if (value == 0) {
            continue;
        }
        sum += value;
    }
    try testing.expectEqual(16, sum);

    for (items[0..1]) |value| {
        sum += value;
    }
    try testing.expectEqual(20, sum);

    var sum2: i32 = 0;
    for (items, 0..) |_, i| {
        try testing.expectEqual(usize, @TypeOf(i));
        sum2 += @as(i32, @intCast(i));
    }
    try testing.expectEqual(10, sum2);

    var sum3: usize = 0;
    for (0..5) |i| {
        sum3 += i;
    }
    try testing.expectEqual(10, sum3);
}

test "multi object for" {
    const items = [_]usize{ 1, 2, 3 };
    const items2 = [_]usize{ 4, 5, 6 };
    var count: usize = 0;

    for (items, items2) |i, j| {
        count += i + j;
    }

    try testing.expectEqual(21, count);
}

test "for reference" {
    var items = [_]i32{ 3, 4, 2 };

    for (&items) |*value| {
        value.* += 1;
    }

    try testing.expectEqual(4, items[0]);
    try testing.expectEqual(5, items[1]);
    try testing.expectEqual(3, items[2]);
}

test "for else" {
    const items = [_]?i32{ 3, 4, null, 5 };

    var sum: i32 = 0;
    const result = for (items) |value| {
        if (value != null) {
            sum += value.?;
        }
    } else blk: {
        try testing.expectEqual(12, sum);
        break :blk sum;
    };
    try testing.expectEqual(12, result);
}

test "nested break and continue" {
    var break_count: usize = 0;
    outer_break: for (1..6) |_| {
        for (1..6) |_| {
            break_count += 1;
            break :outer_break;
        }
    }
    try testing.expectEqual(1, break_count);

    var continue_count: usize = 0;
    outer_continue: for (1..9) |_| {
        for (1..6) |_| {
            continue_count += 1;
            continue :outer_continue;
        }
    }
    try testing.expectEqual(8, continue_count);
}

test "inline for loop" {
    const nums = [_]i32{ 2, 4, 6 };
    var sum: usize = 0;
    inline for (nums) |i| {
        const T = switch (i) {
            2 => f32,
            4 => i8,
            6 => bool,
            else => unreachable,
        };
        sum += typeNameLength(T);
    }
    try testing.expectEqual(9, sum);
}

fn typeNameLength(comptime T: type) usize {
    return @typeName(T).len;
}
