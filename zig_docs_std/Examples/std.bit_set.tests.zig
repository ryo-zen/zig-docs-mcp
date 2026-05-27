// Runnable examples for std.bit_set.
// Run with: zig test zig_docs_std/Examples/std.bit_set.tests.zig

const std = @import("std");
const testing = std.testing;

test "StaticBitSet membership and iteration" {
    var set = std.bit_set.StaticBitSet(16).empty;

    set.set(2);
    set.set(5);
    set.set(9);
    set.unset(5);
    set.toggle(7);

    try testing.expect(set.isSet(2));
    try testing.expect(!set.isSet(5));
    try testing.expect(set.isSet(7));
    try testing.expectEqual(@as(usize, 3), set.count());

    var seen = [_]usize{ 0, 0, 0 };
    var i: usize = 0;
    var it = set.iterator(.{});
    while (it.next()) |index| : (i += 1) {
        seen[i] = index;
    }

    try testing.expectEqualSlices(usize, &.{ 2, 7, 9 }, &seen);
}

test "StaticBitSet union and intersection" {
    var a = std.bit_set.StaticBitSet(8).empty;
    a.set(1);
    a.set(3);

    var b = std.bit_set.StaticBitSet(8).empty;
    b.set(3);
    b.set(4);

    var union_set = a;
    union_set.setUnion(b);
    try testing.expect(union_set.isSet(1));
    try testing.expect(union_set.isSet(3));
    try testing.expect(union_set.isSet(4));

    var intersection = a;
    intersection.setIntersection(b);
    try testing.expect(!intersection.isSet(1));
    try testing.expect(intersection.isSet(3));
    try testing.expect(!intersection.isSet(4));
}

test "DynamicBitSet runtime-sized set" {
    const allocator = testing.allocator;

    var set = try std.bit_set.DynamicBitSet.initEmpty(allocator, 100);
    defer set.deinit();

    set.set(10);
    set.set(64);
    set.setRangeValue(.{ .start = 20, .end = 25 }, true);

    try testing.expect(set.isSet(10));
    try testing.expect(set.isSet(64));
    try testing.expect(set.isSet(20));
    try testing.expect(set.isSet(24));
    try testing.expect(!set.isSet(25));
    try testing.expectEqual(@as(usize, 7), set.count());
}
