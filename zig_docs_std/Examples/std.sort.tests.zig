// Runnable examples for std.sort.
// Run with: zig test zig_docs_std/Examples/std.sort.tests.zig

const std = @import("std");
const testing = std.testing;

fn orderU32(target: u32, item: u32) std.math.Order {
    return std.math.order(target, item);
}

test "sort integers ascending and descending" {
    var values = [_]u32{ 9, 1, 5, 2, 5 };

    std.sort.heap(u32, &values, {}, std.sort.asc(u32));
    try testing.expectEqualSlices(u32, &.{ 1, 2, 5, 5, 9 }, &values);

    std.sort.heap(u32, &values, {}, std.sort.desc(u32));
    try testing.expectEqualSlices(u32, &.{ 9, 5, 5, 2, 1 }, &values);
}

test "sort structs with a custom comparator" {
    const User = struct {
        name: []const u8,
        score: u32,

        fn lessThan(_: void, lhs: @This(), rhs: @This()) bool {
            return lhs.score < rhs.score;
        }
    };

    var users = [_]User{
        .{ .name = "maya", .score = 30 },
        .{ .name = "kai", .score = 10 },
        .{ .name = "noa", .score = 20 },
    };

    std.sort.insertion(User, &users, {}, User.lessThan);

    try testing.expectEqualStrings("kai", users[0].name);
    try testing.expectEqualStrings("noa", users[1].name);
    try testing.expectEqualStrings("maya", users[2].name);
}

test "binary search and insertion bounds" {
    const values = [_]u32{ 2, 4, 8, 8, 8, 16 };

    const found = std.sort.binarySearch(u32, &values, @as(u32, 8), orderU32).?;
    try testing.expect(values[found] == 8);

    try testing.expectEqual(@as(usize, 2), std.sort.lowerBound(u32, &values, @as(u32, 8), orderU32));
    try testing.expectEqual(@as(usize, 5), std.sort.upperBound(u32, &values, @as(u32, 8), orderU32));

    const range = std.sort.equalRange(u32, &values, @as(u32, 8), orderU32);
    try testing.expectEqual(@as(usize, 2), range[0]);
    try testing.expectEqual(@as(usize, 5), range[1]);
}

test "min max and sorted checks" {
    const values = [_]i32{ -3, 10, 4, -8 };

    try testing.expectEqual(@as(i32, -8), std.sort.min(i32, &values, {}, std.sort.asc(i32)).?);
    try testing.expectEqual(@as(i32, 10), std.sort.max(i32, &values, {}, std.sort.asc(i32)).?);

    const sorted = [_]i32{ -8, -3, 4, 10 };
    try testing.expect(std.sort.isSorted(i32, &sorted, {}, std.sort.asc(i32)));
    try testing.expect(!std.sort.isSorted(i32, &values, {}, std.sort.asc(i32)));
}
