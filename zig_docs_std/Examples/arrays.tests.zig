// Comprehensive tests for zig_docs/arrays.md examples
// Target: Zig 0.16+
//
// Run with:
//   zig test zig_docs_std/Examples/arrays.tests.zig

const std = @import("std");
const testing = std.testing;
const mem = std.mem;

test "basic arrays: literals, length, and string-literal compatibility" {
    const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
    const alt_message: [5]u8 = .{ 'h', 'e', 'l', 'l', 'o' };
    const same_message = "hello";

    try testing.expect(message.len == 5);
    try testing.expect(mem.eql(u8, &message, &alt_message));
    try testing.expect(mem.eql(u8, &message, same_message));
}

test "iteration and mutation" {
    const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };

    var sum: usize = 0;
    for (message) |byte| sum += byte;
    try testing.expect(sum == 'h' + 'e' + 'l' * 2 + 'o');

    var some_integers: [100]i32 = undefined;
    for (&some_integers, 0..) |*item, i| {
        item.* = @intCast(i);
    }
    try testing.expect(some_integers[10] == 10);
    try testing.expect(some_integers[99] == 99);
}

test "compile-time array composition" {
    const part_one = [_]i32{ 1, 2, 3, 4 };
    const part_two = [_]i32{ 5, 6, 7, 8 };
    const all_of_it = part_one ++ part_two;
    const pattern = "ab" ** 3;
    const all_zero = [_]u16{0} ** 10;

    try testing.expect(mem.eql(i32, &all_of_it, &[_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }));
    try testing.expect(mem.eql(u8, pattern, "ababab"));
    try testing.expect(all_zero.len == 10);
    try testing.expect(all_zero[5] == 0);
}

test "complex initialization patterns" {
    const Point = struct {
        x: i32,
        y: i32,
    };

    const fancy_array = init: {
        var initial_value: [10]Point = undefined;
        for (&initial_value, 0..) |*pt, i| {
            pt.* = .{ .x = @intCast(i), .y = @intCast(i * 2) };
        }
        break :init initial_value;
    };

    const makePoint = struct {
        fn call(x: i32) Point {
            return .{ .x = x, .y = x * 2 };
        }
    }.call;

    const more_points = [_]Point{makePoint(3)} ** 10;

    try testing.expect(fancy_array[4].x == 4);
    try testing.expect(fancy_array[4].y == 8);
    try testing.expect(more_points[4].x == 3);
    try testing.expect(more_points[4].y == 6);
}

test "multidimensional arrays" {
    const mat4x5 = [4][5]f32{
        [_]f32{ 1.0, 0.0, 0.0, 0.0, 0.0 },
        [_]f32{ 0.0, 1.0, 0.0, 1.0, 0.0 },
        [_]f32{ 0.0, 0.0, 1.0, 0.0, 0.0 },
        [_]f32{ 0.0, 0.0, 0.0, 1.0, 9.9 },
    };

    try testing.expectEqual(mat4x5[1], [_]f32{ 0.0, 1.0, 0.0, 1.0, 0.0 });
    try testing.expect(mat4x5[3][4] == 9.9);

    for (mat4x5, 0..) |row, row_index| {
        for (row, 0..) |cell, col_index| {
            if (row_index == col_index) try testing.expect(cell == 1.0);
        }
    }

    const all_zero: [4][5]f32 = .{.{0} ** 5} ** 4;
    try testing.expect(all_zero[0][0] == 0.0);
}

test "sentinel-terminated arrays" {
    const array = [_:0]u8{ 1, 2, 3, 4 };
    const array_with_early_zero = [_:0]u8{ 1, 0, 0, 4 };

    try testing.expect(@TypeOf(array) == [4:0]u8);
    try testing.expect(array.len == 4);
    try testing.expect(array[4] == 0);

    try testing.expect(@TypeOf(array_with_early_zero) == [4:0]u8);
    try testing.expect(array_with_early_zero.len == 4);
    try testing.expect(array_with_early_zero[4] == 0);
}

fn swizzleRgbaToBgra(rgba: [4]u8) [4]u8 {
    const r, const g, const b, const a = rgba;
    return .{ b, g, r, a };
}

test "destructuring arrays" {
    const pos = [_]i32{ 1, 2 };
    const x, const y = pos;
    try testing.expectEqual(@as(i32, 1), x);
    try testing.expectEqual(@as(i32, 2), y);

    const orange: [4]u8 = .{ 255, 165, 0, 255 };
    const bgra = swizzleRgbaToBgra(orange);
    try testing.expectEqual([4]u8{ 0, 165, 255, 255 }, bgra);
}
