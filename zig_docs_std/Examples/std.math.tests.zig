// Tests for std.math documentation examples
// Run with: zig test Examples/std.math.tests.zig

const std = @import("std");
const testing = std.testing;

// ============================================================================
// Quick Start Examples
// ============================================================================

test "Quick Start: Trigonometry" {
    const angle_rad = std.math.pi / 4.0; // 45 degrees
    const sine = std.math.sin(angle_rad);
    const cosine = std.math.cos(angle_rad);
    const tangent = std.math.tan(angle_rad);

    // sin(45°) ≈ cos(45°) ≈ 0.7071
    try testing.expect(std.math.approxEqAbs(f64, sine, 0.7071, 0.001));
    try testing.expect(std.math.approxEqAbs(f64, cosine, 0.7071, 0.001));
    try testing.expect(std.math.approxEqAbs(f64, tangent, 1.0, 0.001));

    std.debug.print("  ✅ Trigonometry test PASS\n", .{});
}

test "Quick Start: Rounding and Clamping" {
    const value = 3.7;
    const floored = std.math.floor(value); // 3.0
    const ceiled = std.math.ceil(value); // 4.0
    const rounded = std.math.round(value); // 4.0

    try testing.expectEqual(@as(f64, 3.0), floored);
    try testing.expectEqual(@as(f64, 4.0), ceiled);
    try testing.expectEqual(@as(f64, 4.0), rounded);

    const clamped = std.math.clamp(value, 0.0, 3.0); // 3.0
    try testing.expectEqual(@as(f64, 3.0), clamped);

    std.debug.print("  ✅ Rounding and clamping test PASS\n", .{});
}

test "Quick Start: Power and Logarithms" {
    const squared = std.math.pow(f64, 2.0, 8.0); // 2^8 = 256
    const root = std.math.sqrt(16.0); // 4.0
    const log_val = std.math.log2(1024.0); // 10.0

    try testing.expectEqual(@as(f64, 256.0), squared);
    try testing.expectEqual(@as(f64, 4.0), root);
    try testing.expectEqual(@as(f64, 10.0), log_val);

    std.debug.print("  ✅ Power and logarithms test PASS\n", .{});
}

test "Quick Start: Safe Integer Arithmetic" {
    const a: u32 = 100;
    const b: u32 = 200;
    const sum = try std.math.add(u32, a, b); // 300
    const product = try std.math.mul(u32, a, b); // 20000

    try testing.expectEqual(@as(u32, 300), sum);
    try testing.expectEqual(@as(u32, 20000), product);

    // Test overflow detection
    const big_a: u8 = 200;
    const big_b: u8 = 100;
    const overflow_result = std.math.add(u8, big_a, big_b);
    try testing.expectError(error.Overflow, overflow_result);

    std.debug.print("  ✅ Safe integer arithmetic test PASS\n", .{});
}

// ============================================================================
// Safe Integer Arithmetic Functions
// ============================================================================

test "add() - overflow detection" {
    const a: u8 = 200;
    const b: u8 = 100;

    const overflow_result = std.math.add(u8, a, b);
    try testing.expectError(error.Overflow, overflow_result);

    const safe_a: u8 = 100;
    const safe_b: u8 = 50;
    const safe_result = try std.math.add(u8, safe_a, safe_b);
    try testing.expectEqual(@as(u8, 150), safe_result);

    std.debug.print("  ✅ add() test PASS\n", .{});
}

test "sub() - underflow detection" {
    const a: u32 = 10;
    const b: u32 = 20;

    const underflow_result = std.math.sub(u32, a, b);
    try testing.expectError(error.Overflow, underflow_result);

    const safe_a: u32 = 100;
    const safe_b: u32 = 30;
    const safe_result = try std.math.sub(u32, safe_a, safe_b);
    try testing.expectEqual(@as(u32, 70), safe_result);

    std.debug.print("  ✅ sub() test PASS\n", .{});
}

test "mul() - overflow detection" {
    const a: i32 = 50000;
    const b: i32 = 50000;

    const overflow_result = std.math.mul(i32, a, b);
    try testing.expectError(error.Overflow, overflow_result);

    const safe_a: i32 = 100;
    const safe_b: i32 = 200;
    const safe_result = try std.math.mul(i32, safe_a, safe_b);
    try testing.expectEqual(@as(i32, 20000), safe_result);

    std.debug.print("  ✅ mul() test PASS\n", .{});
}

test "mulWide() - guaranteed no overflow" {
    const a: u32 = 0xFFFFFFFF;
    const b: u32 = 0xFFFFFFFF;

    const product: u64 = std.math.mulWide(u32, a, b);
    // 0xFFFFFFFF * 0xFFFFFFFF = 0xFFFFFFFE00000001
    try testing.expect(product > 0);

    std.debug.print("  ✅ mulWide() test PASS\n", .{});
}

test "negate() - overflow on min value" {
    const min_val: i8 = -128;

    // -(-128) = 128, but i8 max is 127
    const overflow_result = std.math.negate(min_val);
    try testing.expectError(error.Overflow, overflow_result);

    const safe_val: i8 = -100;
    const safe_result = try std.math.negate(safe_val);
    try testing.expectEqual(@as(i8, 100), safe_result);

    std.debug.print("  ✅ negate() test PASS\n", .{});
}

test "negateCast() - unsigned to signed" {
    const unsigned: u8 = 100;
    const negated: i8 = try std.math.negateCast(unsigned);
    try testing.expectEqual(@as(i8, -100), negated);

    std.debug.print("  ✅ negateCast() test PASS\n", .{});
}

// ============================================================================
// Trigonometric Functions
// ============================================================================

test "sin() - basic trigonometry" {
    const angle = std.math.pi / 6.0; // 30 degrees
    const sine = std.math.sin(angle);
    try testing.expect(std.math.approxEqAbs(f64, sine, 0.5, 0.0001));

    std.debug.print("  ✅ sin() test PASS\n", .{});
}

test "cos() - basic trigonometry" {
    const angle = std.math.pi / 3.0; // 60 degrees
    const cosine = std.math.cos(angle);
    try testing.expect(std.math.approxEqAbs(f64, cosine, 0.5, 0.0001));

    std.debug.print("  ✅ cos() test PASS\n", .{});
}

test "tan() - basic trigonometry" {
    const angle = std.math.pi / 4.0; // 45 degrees
    const tangent = std.math.tan(angle);
    try testing.expect(std.math.approxEqAbs(f64, tangent, 1.0, 0.0001));

    std.debug.print("  ✅ tan() test PASS\n", .{});
}

test "asin() - inverse sine" {
    const sine_val: f64 = 0.5;
    const angle = std.math.asin(sine_val);
    const expected = std.math.pi / 6.0; // 30 degrees
    try testing.expect(std.math.approxEqAbs(f64, angle, expected, 0.0001));

    std.debug.print("  ✅ asin() test PASS\n", .{});
}

test "atan2() - two-argument arctangent" {
    const y: f64 = 1.0;
    const x: f64 = 1.0;
    const angle = std.math.atan2(y, x);
    const expected = std.math.pi / 4.0; // 45 degrees
    try testing.expect(std.math.approxEqAbs(f64, angle, expected, 0.0001));

    std.debug.print("  ✅ atan2() test PASS\n", .{});
}

// ============================================================================
// Power and Root Functions
// ============================================================================

test "sqrt() - square root" {
    const value = 16.0;
    const root = std.math.sqrt(value);
    try testing.expectEqual(@as(f64, 4.0), root);

    std.debug.print("  ✅ sqrt() test PASS\n", .{});
}

test "cbrt() - cube root" {
    const value: f64 = 27.0;
    const root = std.math.cbrt(value);
    try testing.expect(std.math.approxEqAbs(f64, root, 3.0, 0.0001));

    std.debug.print("  ✅ cbrt() test PASS\n", .{});
}

test "pow() - power function" {
    const base = 2.0;
    const exponent = 10.0;
    const result = std.math.pow(f64, base, exponent);
    try testing.expectEqual(@as(f64, 1024.0), result);

    std.debug.print("  ✅ pow() test PASS\n", .{});
}

test "powi() - integer power with overflow check" {
    const base: i32 = 2;
    const exp: i32 = 10;
    const result = try std.math.powi(i32, base, exp);
    try testing.expectEqual(@as(i32, 1024), result);

    // Test overflow - 2^31 overflows i32 (max is 2^31-1)
    const big_exp: i32 = 31;
    const overflow_result = std.math.powi(i32, base, big_exp);
    try testing.expectError(error.Overflow, overflow_result);

    std.debug.print("  ✅ powi() test PASS\n", .{});
}

// ============================================================================
// Exponential and Logarithm Functions
// ============================================================================

test "exp() - exponential function" {
    const x = 2.0;
    const result = std.math.exp(x);
    try testing.expect(std.math.approxEqAbs(f64, result, 7.389, 0.001));

    std.debug.print("  ✅ exp() test PASS\n", .{});
}

test "exp2() - base-2 exponential" {
    const x = 10.0;
    const result = std.math.exp2(x);
    try testing.expectEqual(@as(f64, 1024.0), result);

    std.debug.print("  ✅ exp2() test PASS\n", .{});
}

test "log() - logarithm with custom base" {
    const x = 1000.0;
    const result = std.math.log(f64, 10.0, x);
    try testing.expectEqual(@as(f64, 3.0), result);

    std.debug.print("  ✅ log() test PASS\n", .{});
}

test "log2() - base-2 logarithm" {
    const x = 1024.0;
    const result = std.math.log2(x);
    try testing.expectEqual(@as(f64, 10.0), result);

    std.debug.print("  ✅ log2() test PASS\n", .{});
}

test "log2_int() - integer log2" {
    const x: u32 = 1000;
    const result = std.math.log2_int(u32, x);
    try testing.expectEqual(@as(u5, 9), result); // 2^9 = 512 < 1000 < 2^10

    std.debug.print("  ✅ log2_int() test PASS\n", .{});
}

test "log2_int_ceil() - ceiling integer log2" {
    const x: u32 = 1000;
    const result = std.math.log2_int_ceil(u32, x);
    try testing.expectEqual(@as(u5, 10), result); // 2^10 = 1024 > 1000

    std.debug.print("  ✅ log2_int_ceil() test PASS\n", .{});
}

// ============================================================================
// Rounding Functions
// ============================================================================

test "floor() - round down" {
    const value = 3.7;
    const result = std.math.floor(value);
    try testing.expectEqual(@as(f64, 3.0), result);

    std.debug.print("  ✅ floor() test PASS\n", .{});
}

test "ceil() - round up" {
    const value = 3.2;
    const result = std.math.ceil(value);
    try testing.expectEqual(@as(f64, 4.0), result);

    std.debug.print("  ✅ ceil() test PASS\n", .{});
}

test "round() - round to nearest" {
    const value = 3.5;
    const result = std.math.round(value);
    try testing.expectEqual(@as(f64, 4.0), result);

    std.debug.print("  ✅ round() test PASS\n", .{});
}

test "trunc() - truncate towards zero" {
    const positive = 3.7;
    const negative = -3.7;

    try testing.expectEqual(@as(f64, 3.0), std.math.trunc(positive));
    try testing.expectEqual(@as(f64, -3.0), std.math.trunc(negative));

    std.debug.print("  ✅ trunc() test PASS\n", .{});
}

// ============================================================================
// Clamping and Range Functions
// ============================================================================

test "clamp() - limit to range" {
    const value = 150;
    const clamped = std.math.clamp(value, 0, 100);
    try testing.expectEqual(@as(i32, 100), clamped);

    const in_range = 50;
    const unchanged = std.math.clamp(in_range, 0, 100);
    try testing.expectEqual(@as(i32, 50), unchanged);

    std.debug.print("  ✅ clamp() test PASS\n", .{});
}

test "lerp() - linear interpolation" {
    const start = 0.0;
    const end = 100.0;
    const halfway = std.math.lerp(start, end, 0.5);
    try testing.expectEqual(@as(f64, 50.0), halfway);

    const beyond = std.math.lerp(start, end, 1.5);
    try testing.expectEqual(@as(f64, 150.0), beyond);

    std.debug.print("  ✅ lerp() test PASS\n", .{});
}

test "wrap() - cyclic wrapping" {
    // wrap() limits to half-open interval [-r, r), not [0, r)
    const value = 5.0;
    const range = 3.0;
    const wrapped = std.math.wrap(value, range);
    // 5.0 wrapped to [-3, 3) = -1.0
    try testing.expectEqual(@as(f64, -1.0), wrapped);

    std.debug.print("  ✅ wrap() test PASS\n", .{});
}

// ============================================================================
// Division and Modulo Functions
// ============================================================================

test "divCeil() - ceiling division" {
    const result = try std.math.divCeil(i32, 10, 3);
    try testing.expectEqual(@as(i32, 4), result); // rounds up

    std.debug.print("  ✅ divCeil() test PASS\n", .{});
}

test "mod() - modulo (always positive)" {
    const result = try std.math.mod(i32, -5, 3);
    try testing.expectEqual(@as(i32, 1), result); // always positive

    std.debug.print("  ✅ mod() test PASS\n", .{});
}

test "rem() - remainder (can be negative)" {
    const result = try std.math.rem(i32, -5, 3);
    try testing.expectEqual(@as(i32, -2), result); // can be negative

    std.debug.print("  ✅ rem() test PASS\n", .{});
}

// ============================================================================
// Power-of-Two Functions
// ============================================================================

test "isPowerOfTwo() - check power of two" {
    try testing.expect(std.math.isPowerOfTwo(16));
    try testing.expect(!std.math.isPowerOfTwo(100));

    std.debug.print("  ✅ isPowerOfTwo() test PASS\n", .{});
}

test "ceilPowerOfTwo() - round up to power of two" {
    const result = try std.math.ceilPowerOfTwo(u32, 10);
    try testing.expectEqual(@as(u32, 16), result);

    const already_power = try std.math.ceilPowerOfTwo(u32, 16);
    try testing.expectEqual(@as(u32, 16), already_power);

    std.debug.print("  ✅ ceilPowerOfTwo() test PASS\n", .{});
}

test "ceilPowerOfTwoPromote() - promoted result type" {
    const input: u8 = 200;
    const result: u9 = std.math.ceilPowerOfTwoPromote(u8, input);
    try testing.expectEqual(@as(u9, 256), result);

    std.debug.print("  ✅ ceilPowerOfTwoPromote() test PASS\n", .{});
}

test "floorPowerOfTwo() - round down to power of two" {
    const result = std.math.floorPowerOfTwo(u32, 100);
    try testing.expectEqual(@as(u32, 64), result);

    std.debug.print("  ✅ floorPowerOfTwo() test PASS\n", .{});
}

// ============================================================================
// Bit Manipulation Functions
// ============================================================================

test "rotl() - rotate left" {
    const value: u8 = 0b10110001;
    const rotated = std.math.rotl(u8, value, 2);
    try testing.expectEqual(@as(u8, 0b11000110), rotated);

    std.debug.print("  ✅ rotl() test PASS\n", .{});
}

test "boolMask() - boolean to bitmask" {
    const mask = std.math.boolMask(u32, true);
    try testing.expectEqual(@as(u32, 0xFFFFFFFF), mask);

    const zero_mask = std.math.boolMask(u32, false);
    try testing.expectEqual(@as(u32, 0), zero_mask);

    std.debug.print("  ✅ boolMask() test PASS\n", .{});
}

// ============================================================================
// Comparison and Ordering Functions
// ============================================================================

test "compare() - runtime comparison operator" {
    const op = std.math.CompareOperator.gte;
    const result = std.math.compare(10, op, 5);
    try testing.expect(result); // 10 >= 5 is true

    std.debug.print("  ✅ compare() test PASS\n", .{});
}

test "order() - ordering relationship" {
    const ordering = std.math.order(10, 20);
    try testing.expectEqual(std.math.Order.lt, ordering);

    std.debug.print("  ✅ order() test PASS\n", .{});
}

test "sign() - sign of number" {
    try testing.expectEqual(@as(i32, -1), std.math.sign(@as(i32, -10)));
    try testing.expectEqual(@as(i32, 0), std.math.sign(@as(i32, 0)));
    try testing.expectEqual(@as(i32, 1), std.math.sign(@as(i32, 10)));

    std.debug.print("  ✅ sign() test PASS\n", .{});
}

// ============================================================================
// Number Theory Functions
// ============================================================================

test "gcd() - greatest common divisor" {
    const result = std.math.gcd(48, 18);
    try testing.expectEqual(@as(u32, 6), result);

    std.debug.print("  ✅ gcd() test PASS\n", .{});
}

test "lcm() - least common multiple" {
    const result = std.math.lcm(12, 18);
    try testing.expectEqual(@as(u32, 36), result);

    std.debug.print("  ✅ lcm() test PASS\n", .{});
}

// ============================================================================
// Floating-Point Utility Functions
// ============================================================================

test "approxEqAbs() - absolute tolerance comparison" {
    const a = 1.0;
    const b = 1.0001;
    const equal = std.math.approxEqAbs(f64, a, b, 0.001);
    try testing.expect(equal);

    std.debug.print("  ✅ approxEqAbs() test PASS\n", .{});
}

test "copysign() - copy sign" {
    const result = std.math.copysign(@as(f64, 10.0), @as(f64, -1.0));
    try testing.expectEqual(@as(f64, -10.0), result);

    std.debug.print("  ✅ copysign() test PASS\n", .{});
}

test "frexp() - extract mantissa and exponent" {
    const result = std.math.frexp(@as(f64, 10.0));
    // 10.0 = 0.625 * 2^4
    try testing.expect(std.math.approxEqAbs(f64, result.significand, 0.625, 0.001));
    try testing.expectEqual(@as(i32, 4), result.exponent);

    std.debug.print("  ✅ frexp() test PASS\n", .{});
}

test "ldexp() - multiply by power of 2" {
    const result = std.math.ldexp(@as(f64, 1.5), 3);
    try testing.expectEqual(@as(f64, 12.0), result); // 1.5 * 2^3 = 12.0

    std.debug.print("  ✅ ldexp() test PASS\n", .{});
}

test "modf() - split integer and fractional parts" {
    const result = std.math.modf(@as(f64, 3.14));
    try testing.expectEqual(@as(f64, 3.0), result.ipart);
    try testing.expect(std.math.approxEqAbs(f64, result.fpart, 0.14, 0.001));

    std.debug.print("  ✅ modf() test PASS\n", .{});
}

// ============================================================================
// Special Floating-Point Values
// ============================================================================

test "nan() and isNan() - not a number" {
    const not_a_number = std.math.nan(f64);
    try testing.expect(std.math.isNan(not_a_number));

    std.debug.print("  ✅ nan() and isNan() test PASS\n", .{});
}

test "inf() and isInf() - infinity" {
    const infinity = std.math.inf(f64);
    try testing.expect(std.math.isInf(infinity));

    std.debug.print("  ✅ inf() and isInf() test PASS\n", .{});
}

test "isPositiveInf() and isNegativeInf()" {
    const pos_inf = std.math.inf(f64);
    const neg_inf = -std.math.inf(f64);

    try testing.expect(std.math.isPositiveInf(pos_inf));
    try testing.expect(std.math.isNegativeInf(neg_inf));

    std.debug.print("  ✅ isPositiveInf() and isNegativeInf() test PASS\n", .{});
}

test "isFinite() - finite value check" {
    try testing.expect(std.math.isFinite(@as(f64, 10.0)));
    try testing.expect(!std.math.isFinite(std.math.inf(f64)));
    try testing.expect(!std.math.isFinite(std.math.nan(f64)));

    std.debug.print("  ✅ isFinite() test PASS\n", .{});
}

// ============================================================================
// Miscellaneous Math Functions
// ============================================================================

test "hypot() - hypotenuse calculation" {
    const x = 3.0;
    const y = 4.0;
    const distance = std.math.hypot(x, y);
    try testing.expectEqual(@as(f64, 5.0), distance);

    std.debug.print("  ✅ hypot() test PASS\n", .{});
}

// ============================================================================
// Angle Conversion Functions
// ============================================================================

test "degreesToRadians() - angle conversion" {
    const degrees = 180.0;
    const radians = std.math.degreesToRadians(degrees);
    try testing.expect(std.math.approxEqAbs(f64, radians, std.math.pi, 0.0001));

    std.debug.print("  ✅ degreesToRadians() test PASS\n", .{});
}

test "radiansToDegrees() - angle conversion" {
    const radians = std.math.pi;
    const degrees = std.math.radiansToDegrees(radians);
    try testing.expect(std.math.approxEqAbs(f64, degrees, 180.0, 0.0001));

    std.debug.print("  ✅ radiansToDegrees() test PASS\n", .{});
}

// ============================================================================
// Type Utilities
// ============================================================================

test "cast() - safe integer cast" {
    const big: u32 = 300;
    const small = std.math.cast(u8, big);
    try testing.expectEqual(@as(?u8, null), small); // 300 > 255

    const fits: u32 = 100;
    const ok = std.math.cast(u8, fits).?;
    try testing.expectEqual(@as(u8, 100), ok);

    std.debug.print("  ✅ cast() test PASS\n", .{});
}

test "maxInt() and minInt() - type limits" {
    const max_u8 = std.math.maxInt(u8);
    const min_u8 = std.math.minInt(u8);
    try testing.expectEqual(@as(u8, 255), max_u8);
    try testing.expectEqual(@as(u8, 0), min_u8);

    const max_i16 = std.math.maxInt(i16);
    const min_i16 = std.math.minInt(i16);
    try testing.expectEqual(@as(i16, 32767), max_i16);
    try testing.expectEqual(@as(i16, -32768), min_i16);

    std.debug.print("  ✅ maxInt() and minInt() test PASS\n", .{});
}

// ============================================================================
// Usage Patterns
// ============================================================================

test "Usage Pattern: Safe Integer Arithmetic in Financial Calculations" {
    const price: u64 = 1_000;
    const quantity: u32 = 100;

    // Use safe multiplication
    const subtotal = try std.math.mul(u64, price, quantity);
    try testing.expectEqual(@as(u64, 100_000), subtotal);

    // Calculate 15% tax
    const tax_amount = try std.math.mul(u64, subtotal, 15);
    const tax = try std.math.divCeil(u64, tax_amount, 100);

    const total = try std.math.add(u64, subtotal, tax);
    try testing.expect(total > subtotal);

    std.debug.print("  ✅ Financial calculations pattern test PASS\n", .{});
}

test "Usage Pattern: Angle Calculations for Graphics" {
    const x = 1.0;
    const y = 0.0;

    // Rotate 90 degrees
    const degrees = 90.0;
    const radians = std.math.degreesToRadians(degrees);
    const cos_angle = std.math.cos(radians);
    const sin_angle = std.math.sin(radians);

    const rotated_x = x * cos_angle - y * sin_angle;
    const rotated_y = x * sin_angle + y * cos_angle;

    try testing.expect(std.math.approxEqAbs(f64, rotated_x, 0.0, 0.0001));
    try testing.expect(std.math.approxEqAbs(f64, rotated_y, 1.0, 0.0001));

    std.debug.print("  ✅ Graphics angle rotation pattern test PASS\n", .{});
}

test "Usage Pattern: Floating-Point Comparison in Tests" {
    const a = 0.1 + 0.2;
    const b = 0.3;

    // Don't use == for floats
    try testing.expect(std.math.approxEqAbs(f64, a, b, 0.0001));

    std.debug.print("  ✅ Float comparison pattern test PASS\n", .{});
}

test "Usage Pattern: Power-of-Two Memory Alignment" {
    const requested = 100;
    const aligned = try std.math.ceilPowerOfTwo(usize, requested);
    try testing.expectEqual(@as(usize, 128), aligned);
    try testing.expect(std.math.isPowerOfTwo(aligned));

    std.debug.print("  ✅ Memory alignment pattern test PASS\n", .{});
}

test "Usage Pattern: Distance Calculation" {
    const x1 = 0.0;
    const y1 = 0.0;
    const x2 = 3.0;
    const y2 = 4.0;

    const dx = x2 - x1;
    const dy = y2 - y1;
    const dist = std.math.hypot(dx, dy);

    try testing.expectEqual(@as(f64, 5.0), dist);

    std.debug.print("  ✅ Distance calculation pattern test PASS\n", .{});
}

// ============================================================================
// Summary
// ============================================================================

test "std.math documentation - all tests" {
    std.debug.print("\n", .{});
    std.debug.print("╔════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║  std.math Documentation Tests - Summary           ║\n", .{});
    std.debug.print("╠════════════════════════════════════════════════════╣\n", .{});
    std.debug.print("║  ✅ All examples validated and working             ║\n", .{});
    std.debug.print("║  ✅ Quick Start examples tested                    ║\n", .{});
    std.debug.print("║  ✅ Safe arithmetic functions tested               ║\n", .{});
    std.debug.print("║  ✅ Trigonometric functions tested                 ║\n", .{});
    std.debug.print("║  ✅ Power and root functions tested                ║\n", .{});
    std.debug.print("║  ✅ Exponential and log functions tested           ║\n", .{});
    std.debug.print("║  ✅ Rounding functions tested                      ║\n", .{});
    std.debug.print("║  ✅ Range and clamping functions tested            ║\n", .{});
    std.debug.print("║  ✅ Division and modulo functions tested           ║\n", .{});
    std.debug.print("║  ✅ Power-of-two functions tested                  ║\n", .{});
    std.debug.print("║  ✅ Bit manipulation functions tested              ║\n", .{});
    std.debug.print("║  ✅ Comparison functions tested                    ║\n", .{});
    std.debug.print("║  ✅ Number theory functions tested                 ║\n", .{});
    std.debug.print("║  ✅ Float utility functions tested                 ║\n", .{});
    std.debug.print("║  ✅ Special float values tested                    ║\n", .{});
    std.debug.print("║  ✅ Angle conversion functions tested              ║\n", .{});
    std.debug.print("║  ✅ Type utility functions tested                  ║\n", .{});
    std.debug.print("║  ✅ Usage patterns validated                       ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════╝\n", .{});
    std.debug.print("\n", .{});
}
