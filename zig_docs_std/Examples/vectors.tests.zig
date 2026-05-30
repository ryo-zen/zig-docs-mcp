// Core vector examples for zig_docs/vectors.md
// Run with:
//   zig test zig_docs_std/Examples/vectors.tests.zig

const std = @import("std");
const testing = std.testing;

test "basic vector usage" {
    const a = @Vector(4, i32){ 1, 2, 3, 4 };
    const b = @Vector(4, i32){ 5, 6, 7, 8 };
    const c = a + b;

    try testing.expectEqual(@as(i32, 6), c[0]);
    try testing.expectEqual(@as(i32, 8), c[1]);
    try testing.expectEqual(@as(i32, 10), c[2]);
    try testing.expectEqual(@as(i32, 12), c[3]);
}

test "element-wise operators and scalar conversion helpers" {
    const a = @Vector(4, u8){ 1, 2, 3, 4 };
    const b: @Vector(4, u8) = @splat(2);

    const sum = a + b;
    const shifted = a << @Vector(4, u3){ 0, 1, 2, 3 };
    const lt = a < @Vector(4, u8){ 2, 2, 4, 4 };

    try testing.expectEqual(@Vector(4, u8){ 3, 4, 5, 6 }, sum);
    try testing.expectEqual(@Vector(4, u8){ 1, 4, 12, 32 }, shifted);
    try testing.expectEqual(@Vector(4, bool){ true, false, true, false }, lt);
    try testing.expectEqual(@Vector(4, bool){ false, true, false, true }, !lt);
    try testing.expectEqual(@as(u8, 10), @reduce(.Add, a));
}

test "conversion between vectors arrays and slices" {
    const arr1: [4]f32 = [_]f32{ 1.1, 3.2, 4.5, 5.6 };
    const vec: @Vector(4, f32) = arr1;
    const arr2: [4]f32 = vec;
    try testing.expectEqual(arr1, arr2);

    const vec2: @Vector(2, f32) = arr1[1..3].*;

    const slice: []const f32 = &arr1;
    var offset: u32 = 1;
    _ = &offset;
    const vec3: @Vector(2, f32) = slice[offset..][0..2].*;

    try testing.expectEqual(slice[offset], vec2[0]);
    try testing.expectEqual(slice[offset + 1], vec2[1]);
    try testing.expectEqual(vec2, vec3);
}

test "vectors and arrays support bit casts" {
    const bytes: [4]u8 = .{ 0x12, 0x34, 0x56, 0x78 };
    const vec: @Vector(4, u8) = @bitCast(bytes);
    const round_trip: [4]u8 = @bitCast(vec);

    try testing.expectEqual(bytes, round_trip);
    try testing.expectEqual(@as(u8, 0x56), vec[2]);
}

fn unpack(x: @Vector(4, f32), y: @Vector(4, f32)) @Vector(4, f32) {
    const a, const c, _, _ = x;
    const b, const d, _, _ = y;
    return .{ a, b, c, d };
}

test "destructuring vectors" {
    const x: @Vector(4, f32) = .{ 1.0, 2.0, 3.0, 4.0 };
    const y: @Vector(4, f32) = .{ 5.0, 6.0, 7.0, 8.0 };

    try testing.expectEqual(@Vector(4, f32){ 1.0, 5.0, 2.0, 6.0 }, unpack(x, y));
}
