// Core integer examples for zig_docs/integers.md
// Run with:
//   zig test zig_docs_std/Examples/integers.tests.zig

const std = @import("std");
const testing = std.testing;

fn divide(a: i32, b: i32) i32 {
    return @divTrunc(a, b);
}

fn divideUnsigned(a: u32, b: u32) u32 {
    return a / b;
}

test "integer literals and separators" {
    const decimal_int = 98222;
    const hex_int = 0xff;
    const another_hex_int = 0xFF;
    const octal_int = 0o755;
    const binary_int = 0b11110000;

    const one_billion = 1_000_000_000;
    const binary_mask = 0b1_1111_1111;
    const permissions = 0o7_5_5;
    const big_address = 0xFF80_0000_0000_0000;

    try testing.expectEqual(98222, decimal_int);
    try testing.expectEqual(255, hex_int);
    try testing.expectEqual(hex_int, another_hex_int);
    try testing.expectEqual(493, octal_int);
    try testing.expectEqual(240, binary_int);
    try testing.expectEqual(1_000_000_000, one_billion);
    try testing.expectEqual(511, binary_mask);
    try testing.expectEqual(493, permissions);
    try testing.expectEqual(0xFF80_0000_0000_0000, big_address);
}

test "runtime integer values have fixed size" {
    var a: i32 = 10;
    var b: i32 = 2;
    _ = .{ &a, &b };

    try testing.expectEqual(@as(i32, 5), divide(a, b));
    try testing.expectEqual(@as(usize, 32), @bitSizeOf(@TypeOf(a)));

    var unsigned_a: u32 = 10;
    var unsigned_b: u32 = 2;
    _ = .{ &unsigned_a, &unsigned_b };
    try testing.expectEqual(@as(u32, 5), divideUnsigned(unsigned_a, unsigned_b));
}

test "arbitrary bit width integers" {
    const signed_min: i7 = -64;
    const signed_max: i7 = 63;
    const unsigned_max: u9 = 511;

    try testing.expectEqual(@as(usize, 7), @bitSizeOf(i7));
    try testing.expectEqual(@as(usize, 9), @bitSizeOf(u9));
    try testing.expectEqual(@as(i7, -1), signed_min +| signed_max);
    try testing.expectEqual(@as(u9, 511), unsigned_max);
}

test "wrapping arithmetic is explicit" {
    var x: u8 = 255;
    x +%= 1;
    try testing.expectEqual(@as(u8, 0), x);

    var y: u8 = 0;
    y -%= 1;
    try testing.expectEqual(@as(u8, 255), y);

    var z: u8 = 200;
    z *%= 2;
    try testing.expectEqual(@as(u8, 144), z);
}

test "saturating arithmetic clamps at integer limits" {
    var high: u8 = 255;
    high +|= 1;
    try testing.expectEqual(@as(u8, 255), high);

    var low: u8 = 0;
    low -|= 1;
    try testing.expectEqual(@as(u8, 0), low);

    var product: u8 = 200;
    product *|= 2;
    try testing.expectEqual(@as(u8, 255), product);
}

test "overflow builtins return wrapped value and overflow bit" {
    const add = @addWithOverflow(@as(u8, 200), @as(u8, 100));
    try testing.expectEqual(@as(u8, 44), add[0]);
    try testing.expectEqual(1, add[1]);

    const sub = @subWithOverflow(@as(u8, 0), @as(u8, 1));
    try testing.expectEqual(@as(u8, 255), sub[0]);
    try testing.expectEqual(1, sub[1]);

    const mul = @mulWithOverflow(@as(u8, 200), @as(u8, 2));
    try testing.expectEqual(@as(u8, 144), mul[0]);
    try testing.expectEqual(1, mul[1]);

    const shl = @shlWithOverflow(@as(u8, 0b1000_0000), 1);
    try testing.expectEqual(@as(u8, 0), shl[0]);
    try testing.expectEqual(1, shl[1]);
}

test "runtime safety control is not a wrapping operator" {
    var x: u8 = 1;

    @setRuntimeSafety(false);
    x += 1;
    @setRuntimeSafety(true);

    try testing.expectEqual(@as(u8, 2), x);
}
