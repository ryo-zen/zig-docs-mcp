// Core slice examples for zig_docs/slices.md
// Run with:
//   zig test zig_docs_std/Examples/slices.tests.zig

const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;

test "basic slices" {
    var array = [_]i32{ 1, 2, 3, 4 };
    var start: usize = 0;
    _ = &start;
    const slice = array[start..array.len];

    const alt: []const i32 = &.{ 1, 2, 3, 4 };
    try testing.expectEqualSlices(i32, slice, alt);
    try testing.expect(@TypeOf(slice) == []i32);
    try testing.expect(slice.len == array.len);
    try testing.expect(&slice[0] == &array[0]);
}

test "compile-time vs runtime slicing types" {
    var array = [_]i32{ 1, 2, 3, 4 };

    const ptr_to_array = array[0..array.len];
    try testing.expect(@TypeOf(ptr_to_array) == *[array.len]i32);

    var runtime_start: usize = 1;
    _ = &runtime_start;
    const length = 2;
    const ptr_len = array[runtime_start..][0..length];
    try testing.expect(@TypeOf(ptr_len) == *[length]i32);
}

test "slice strings and formatting" {
    const hello: []const u8 = "hello";
    const world: []const u8 = "世界";

    var buf: [100]u8 = undefined;
    var start: usize = 0;
    _ = &start;
    const out = buf[start..];
    const joined = try fmt.bufPrint(out, "{s} {s}", .{ hello, world });

    try testing.expect(mem.eql(u8, joined, "hello 世界"));
}

test "slice pointer relationship" {
    var array = [_]i32{ 1, 2, 3, 4 };
    const slice = array[0..];

    try testing.expect(@TypeOf(slice.ptr) == [*]i32);
    try testing.expect(@TypeOf(&slice[0]) == *i32);
    try testing.expect(@intFromPtr(slice.ptr) == @intFromPtr(&slice[0]));
}

test "array pointers can be sliced into mutable slices" {
    var array: [10]u8 = .{0} ** 10;
    const ptr = &array;
    try testing.expectEqual(*[10]u8, @TypeOf(ptr));

    var start: usize = 0;
    var end: usize = 5;
    _ = .{ &start, &end };
    const slice = ptr[start..end];

    try testing.expectEqual([]u8, @TypeOf(slice));
    slice[2] = 3;
    try testing.expectEqual(@as(u8, 3), array[2]);

    const ptr2 = slice[2..3];
    try testing.expectEqual(@as(usize, 1), ptr2.len);
    try testing.expectEqual(@as(u8, 3), ptr2[0]);
    try testing.expectEqual(*[1]u8, @TypeOf(ptr2));
}

test "empty slice construction" {
    const empty1 = &[0]u8{};
    const empty2: []u8 = &.{};

    try testing.expectEqual(@as(usize, 0), empty1.len);
    try testing.expectEqual(@as(usize, 0), empty2.len);
}

test "sentinel-terminated slices" {
    const s: [:0]const u8 = "hello";
    try testing.expectEqual(@as(usize, 5), s.len);
    try testing.expectEqual(@as(u8, 0), s[5]);

    const early_sentinel: [:0]const u8 = "he\x00lo";
    try testing.expectEqual(@as(usize, 5), early_sentinel.len);
    try testing.expectEqual(@as(u8, 0), early_sentinel[2]);
    try testing.expectEqual(@as(u8, 0), early_sentinel[5]);
}

test "sentinel slicing syntax" {
    var array = [_]u8{ 3, 2, 1, 0, 3, 2, 1, 0 };
    var n: usize = 3;
    _ = &n;
    const s = array[0..n :0];

    try testing.expect(@TypeOf(s) == [:0]u8);
    try testing.expectEqual(@as(usize, 3), s.len);
}
