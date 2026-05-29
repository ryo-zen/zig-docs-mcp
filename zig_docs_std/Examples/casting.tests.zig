// Core casting examples for zig_docs/casting.md.
// Run with:
//   zig test zig_docs_std/Examples/casting.tests.zig

const std = @import("std");
const testing = std.testing;

test "safe coercions preserve value and representation" {
    var value: i32 = 1234;
    const const_ptr: *const i32 = &value;
    try testing.expectEqual(@as(i32, 1234), const_ptr.*);

    const small: u8 = 250;
    const wide: u16 = small;
    const signed: i16 = small;
    try testing.expectEqual(@as(u16, 250), wide);
    try testing.expectEqual(@as(i16, 250), signed);

    var int: u8 = 123;
    _ = &int;
    const float: f32 = int;
    const int_from_float: u8 = @intFromFloat(float);
    try testing.expectEqual(int, int_from_float);
}

test "array pointer, slice, optional, and error-union coercions" {
    var buf: [5]u8 = "hello".*;

    const slice: []u8 = &buf;
    try testing.expectEqualStrings("hello", slice);

    const many_ptr: [*]u8 = &buf;
    try testing.expectEqual('o', many_ptr[4]);

    const optional_many_ptr: ?[*]u8 = &buf;
    try testing.expectEqual('o', optional_many_ptr.?[4]);

    const maybe_slice: ?[]const u8 = "hello";
    try testing.expectEqualStrings("hello", maybe_slice.?);

    const error_slice: anyerror![]const u8 = "hello";
    try testing.expectEqualStrings("hello", try error_slice);

    const sentinel_slice: [:0]const u8 = "hello";
    const sentinel_ptr: [*:0]const u8 = sentinel_slice;
    try testing.expectEqual('o', sentinel_ptr[4]);
}

test "union, enum, tuple, and undefined coercions" {
    const Tag = enum { one, two, three };
    const Tagged = union(Tag) {
        one: i32,
        two: f32,
        three,
    };

    const union_value = Tagged{ .two = 12.34 };
    const tag: Tag = union_value;
    try testing.expectEqual(Tag.two, tag);

    const enum_value = Tag.three;
    const coerced_union: Tagged = enum_value;
    try testing.expectEqual(Tag.three, coerced_union);

    const Tuple = struct { u8, u8 };
    const tuple: Tuple = .{ 5, 6 };
    const array: [2]u8 = tuple;
    try testing.expectEqual([2]u8{ 5, 6 }, array);

    const initialized: u32 = undefined;
    _ = initialized;
}

test "explicit casts document runtime assertions and representation changes" {
    const byte: u8 = @intCast(@as(u16, 255));
    try testing.expectEqual(@as(u8, 255), byte);

    const truncated: u8 = @truncate(@as(u16, 0x12ff));
    try testing.expectEqual(@as(u8, 0xff), truncated);

    const as_float: f32 = @floatFromInt(@as(u16, 42));
    try testing.expectEqual(@as(f32, 42.0), as_float);

    const smaller_float: f32 = @floatCast(@as(f64, 3.5));
    try testing.expectEqual(@as(f32, 3.5), smaller_float);

    const from_bool = @intFromBool(true);
    try testing.expectEqual(@as(u1, 1), from_bool);

    const E = enum(u8) { a = 1, b = 2 };
    const enum_value: E = @enumFromInt(2);
    try testing.expectEqual(E.b, enum_value);
    try testing.expectEqual(@as(u8, 2), @intFromEnum(enum_value));

    const err: anyerror = error.FileNotFound;
    const narrowed: error{FileNotFound} = @errorCast(err);
    try testing.expectEqual(error.FileNotFound, narrowed);
    try testing.expect(@intFromError(err) != 0);

    const one_bits: u32 = 0x3f800000;
    const one: f32 = @bitCast(one_bits);
    try testing.expectEqual(@as(f32, 1.0), one);
}

test "pointer explicit casts keep address and enforce alignment" {
    var bytes align(4) = [_]u8{ 0x78, 0x56, 0x34, 0x12 };
    const raw: []u8 = bytes[0..];
    const aligned: []align(4) u8 = @alignCast(raw);
    const ints = std.mem.bytesAsSlice(u32, aligned);
    try testing.expectEqual(@as(usize, 1), ints.len);
    try testing.expectEqual(@as(u32, 0x12345678), ints[0]);

    const bytes_ptr: *align(4) [4]u8 = &bytes;
    const int_ptr: *align(4) u32 = @ptrCast(bytes_ptr);
    try testing.expectEqual(@intFromPtr(bytes_ptr), @intFromPtr(int_ptr));
}

test "peer type resolution chooses a common coercible type" {
    const a: i8 = 12;
    const b: i16 = 34;
    const c = a + b;
    try testing.expectEqual(@as(i16, 46), c);
    try testing.expectEqual(i16, @TypeOf(c));

    var i: u8 = 12;
    var f: f32 = 34;
    _ = .{ &i, &f };
    const x = i + f;
    try testing.expectEqual(@as(f32, 46.0), x);
    try testing.expectEqual(f32, @TypeOf(x));

    var choose_value = true;
    _ = &choose_value;
    const maybe = if (choose_value) @as(usize, 0) else null;
    try testing.expectEqual(?usize, @TypeOf(maybe));
    try testing.expectEqual(@as(usize, 0), maybe.?);

    var choose_text = true;
    _ = &choose_text;
    const text = if (choose_text) "true" else @as([]const u8, "false");
    try testing.expectEqualStrings("true", text);
    try testing.expectEqual([]const u8, @TypeOf(text));
}
