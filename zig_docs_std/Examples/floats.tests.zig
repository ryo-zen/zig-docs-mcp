// Core float examples for zig_docs/floats.md
// Run with:
//   zig test zig_docs_std/Examples/floats.tests.zig

const std = @import("std");
const testing = std.testing;

test "floating point types are available" {
    try testing.expectEqual(@as(usize, 16), @bitSizeOf(f16));
    try testing.expectEqual(@as(usize, 32), @bitSizeOf(f32));
    try testing.expectEqual(@as(usize, 64), @bitSizeOf(f64));
    try testing.expectEqual(@as(usize, 80), @bitSizeOf(f80));
    try testing.expectEqual(@as(usize, 128), @bitSizeOf(f128));
    try testing.expect(@bitSizeOf(c_longdouble) >= 64);
}

test "float literals and separators" {
    const floating_point = 123.0E+77;
    const another_float = 123.0;
    const yet_another = 123.0e+77;

    const hex_floating_point = 0x103.70p-5;
    const another_hex_float = 0x103.70;
    const yet_another_hex_float = 0x103.70P-5;

    const lightspeed = 299_792_458.000_000;
    const nanosecond = 0.000_000_001;
    const more_hex = 0x1234_5678.9ABC_CDEFp-10;

    try testing.expectEqual(@as(f128, floating_point), @as(f128, yet_another));
    try testing.expectEqual(@as(f64, 123.0), another_float);
    try testing.expectEqual(@as(f64, hex_floating_point), @as(f64, yet_another_hex_float));
    try testing.expect(another_hex_float > hex_floating_point);
    try testing.expectEqual(@as(f64, 299792458.0), lightspeed);
    try testing.expect(nanosecond < 0.000_001);
    try testing.expect(more_hex > 0);
}

test "float literals coerce to floats and whole integers" {
    const as_float: f32 = 123.0;
    const as_int: u8 = 123.0;

    try testing.expectEqual(@as(f32, 123.0), as_float);
    try testing.expectEqual(@as(u8, 123), as_int);
}

test "special values come from std.math" {
    const inf = std.math.inf(f32);
    const negative_inf = -std.math.inf(f64);
    const nan = std.math.nan(f128);

    try testing.expect(std.math.isPositiveInf(inf));
    try testing.expect(std.math.isNegativeInf(negative_inf));
    try testing.expect(std.math.isNan(nan));
}

test "epsilon comparison and precision loss" {
    const a: f32 = 0.1 + 0.2;
    const b: f32 = 0.3;
    try testing.expect(std.math.approxEqAbs(f32, a, b, 0.0001));

    const x: f32 = 16777216.0;
    const y: f32 = x + 1.0;
    try testing.expectEqual(x, y);

    const x64: f64 = 16777216.0;
    const y64: f64 = x64 + 1.0;
    try testing.expect(y64 > x64);
}

test "nan infinity and signed zero behavior" {
    const nan = std.math.sqrt(@as(f32, -1.0));
    try testing.expect(std.math.isNan(nan + 10.0));

    const huge: f32 = 1.0e38;
    try testing.expect(std.math.isPositiveInf(huge * huge));

    var pos_zero: f32 = 0.0;
    var neg_zero: f32 = -0.0;
    _ = .{ &pos_zero, &neg_zero };

    try testing.expect(pos_zero == neg_zero);
    try testing.expect(!std.math.signbit(pos_zero));
    try testing.expect(std.math.signbit(neg_zero));
    try testing.expect(std.math.isPositiveInf(1.0 / pos_zero));
    try testing.expect(std.math.isNegativeInf(1.0 / neg_zero));
}

test "rounding comparison and math functions" {
    const x: f32 = 3.7;
    try testing.expectEqual(@as(f32, 4.0), std.math.round(x));
    try testing.expectEqual(@as(f32, 3.0), std.math.floor(x));
    try testing.expectEqual(@as(f32, 4.0), std.math.ceil(x));
    try testing.expectEqual(@as(f32, 3.0), std.math.trunc(x));

    const a: f64 = 0.1 + 0.2;
    const b: f64 = 0.3;
    try testing.expect(std.math.approxEqRel(f64, a, b, 0.0001));
    try testing.expect(@min(a, b) <= a);
    try testing.expect(@max(a, b) >= b);

    try testing.expectEqual(@as(f64, 8.0), std.math.pow(f64, 2.0, 3.0));
    try testing.expect(std.math.sqrt(@as(f64, 2.0)) > 1.4);
    try testing.expect(std.math.cbrt(@as(f64, 2.0)) > 1.2);
    try testing.expect(@abs(@as(f64, -3.14)) == 3.14);
}

fn strictFloatMode(x: f64) f64 {
    return x + 0.0;
}

fn optimizedFloatMode(x: f64) f64 {
    @setFloatMode(.optimized);
    return x + 0.0;
}

test "float mode syntax compiles" {
    var x: f64 = 0.001;
    _ = &x;

    try testing.expectEqual(x, strictFloatMode(x));
    try testing.expectEqual(x, optimizedFloatMode(x));
}

test "integer cents avoid decimal accumulation error" {
    var balance_cents: i64 = 0;
    balance_cents += 10;
    balance_cents += 10;
    balance_cents += 10;

    try testing.expectEqual(@as(i64, 30), balance_cents);
    try testing.expectEqual(@as(f64, 0.30), @as(f64, @floatFromInt(balance_cents)) / 100.0);
}

test "fused multiply add returns the expected arithmetic result" {
    const a: f64 = 2.0;
    const b: f64 = 3.0;
    const c: f64 = 4.0;

    try testing.expectEqual(@as(f64, 10.0), @mulAdd(f64, a, b, c));
}
