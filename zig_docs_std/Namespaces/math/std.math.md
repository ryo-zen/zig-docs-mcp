# std.math

📚 **[See Comprehensive Examples & Tests](<repo>/zig_docs_std/Examples/std.math.tests.zig)** - Complete runnable code demonstrating all math features

**Run tests:** `zig test <repo>/zig_docs_std/Examples/std.math.tests.zig`

## Quick Start

### Most Common Patterns

**Trigonometry**
```zig
const angle_rad = std.math.pi / 4.0; // 45 degrees
const sine = std.math.sin(angle_rad);
const cosine = std.math.cos(angle_rad);
const tangent = std.math.tan(angle_rad);
```

**Rounding and Clamping**
```zig
const value = 3.7;
const floored = std.math.floor(value);  // 3.0
const ceiled = std.math.ceil(value);    // 4.0
const rounded = std.math.round(value);  // 4.0

const clamped = std.math.clamp(value, 0.0, 3.0); // 3.0
```

**Power and Logarithms**
```zig
const squared = std.math.pow(f64, 2.0, 8.0);      // 2^8 = 256
const root = std.math.sqrt(16.0);                  // 4.0
const log_val = std.math.log2(1024.0);            // 10.0
```

**Safe Integer Arithmetic**
```zig
const a: u32 = 100;
const b: u32 = 200;
const sum = try std.math.add(u32, a, b);          // 300, or error.Overflow
const product = try std.math.mul(u32, a, b);      // 20000, or error.Overflow
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Absolute value | N/A (use `@abs`) | `@abs(-5)` |
| Clamp to range | `clamp()` | `std.math.clamp(x, 0, 100)` |
| Power of two check | `isPowerOfTwo()` | `std.math.isPowerOfTwo(16)` |
| Round up to power of two | `ceilPowerOfTwo()` | `try std.math.ceilPowerOfTwo(u32, 10)` |
| GCD / LCM | `gcd()` / `lcm()` | `std.math.gcd(12, 8)` |
| Float comparison | `approxEqAbs/Rel()` | `std.math.approxEqAbs(f64, a, b, 0.001)` |

### ⚠️ Critical: Use Safe Arithmetic for Overflow Detection
```zig
// WRONG - Silent overflow, wraps around
const result = a +% b; // ❌ Will wrap on overflow

// CORRECT - Returns error on overflow
const result = try std.math.add(u32, a, b); // ✅ Returns error.Overflow
```

---

## Overview

`std.math` is Zig's comprehensive mathematics library, providing trigonometric functions, logarithms, power operations, safe integer arithmetic, floating-point utilities, and mathematical constants.

**Key Characteristics:**
- **Safe arithmetic** - Functions like `add()`, `mul()`, `sub()` return errors on overflow instead of wrapping
- **Generic operations** - Most functions work with any numeric type (`anytype` parameters)
- **Hardware acceleration** - Uses dedicated CPU instructions when available (sin, cos, sqrt, etc.)
- **Compile-time support** - Many functions work at `comptime` for constant evaluation
- **IEEE 754 compliance** - Full support for floating-point special values (NaN, infinity)

**When to use std.math:**
- Performing trigonometric calculations for graphics, physics, or signal processing
- Detecting overflow in integer arithmetic (financial calculations, resource limits)
- Working with floating-point values (comparison, rounding, special value handling)
- Converting between degrees and radians for angle calculations
- Finding greatest common divisors, least common multiples, or power-of-two alignments

**Related namespaces:**
- `std.math.big` - Arbitrary-precision integer arithmetic (bigint)
- `std.math.complex` - Complex number operations
- `@sin/@cos/@sqrt` - Direct builtin functions (std.math wraps these)

---

## Mathematical Constants

**`e: f64 = 2.718281828459045`**
Euler's number, base of natural logarithms.

**`pi: f64 = 3.141592653589793`**
Archimedes' constant (π), ratio of circle circumference to diameter.

**`tau: f64 = 6.283185307179586`**
Circle constant (τ = 2π), full turn in radians.

**`phi: f64 = 1.618033988749895`**
Golden ratio (Φ = (1 + √5) / 2).

**`sqrt2: f64 = 1.414213562373095`**
Square root of 2 (√2).

**`sqrt1_2: f64 = 0.7071067811865476`**
1 / √2 or √2 / 2.

**`ln2: f64 = 0.6931471805599453`**
Natural logarithm of 2.

**`ln10: f64 = 2.302585092994046`**
Natural logarithm of 10.

**`log2e: f64 = 1.4426950408889634`**
Base-2 logarithm of e.

**`log10e: f64 = 0.4342944819032518`**
Base-10 logarithm of e.

**`two_sqrtpi: f64 = 1.1283791670955126`**
2 / √π.

**`rad_per_deg: f64 = 0.017453292519943295`**
Radians per degree (π / 180).

**`deg_per_rad: f64 = 57.29577951308232`**
Degrees per radian (180 / π).

---

## Safe Integer Arithmetic Functions

These functions perform checked arithmetic and return errors instead of wrapping on overflow.

### `pub fn add(comptime T: type, a: T, b: T) error{Overflow}!T`

Returns the sum of `a` and `b`, returning `error.Overflow` if the result doesn't fit in type `T`.

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const a: u8 = 200;
    const b: u8 = 100;

    // This would overflow u8 (max 255)
    const sum = std.math.add(u8, a, b) catch |err| {
        std.debug.print("Overflow detected: {}\n", .{err});
        return err;
    };

    std.debug.print("Sum: {}\n", .{sum});
}
```

------

### `pub fn sub(comptime T: type, a: T, b: T) error{Overflow}!T`

Returns `a - b`, returning `error.Overflow` on overflow (underflow for unsigned types).

**Example:**
```zig
const a: u32 = 10;
const b: u32 = 20;

// Would underflow for unsigned type
const result = try std.math.sub(u32, a, b); // Returns error.Overflow
```

------

### `pub fn mul(comptime T: type, a: T, b: T) error{Overflow}!T`

Returns the product of `a` and `b`, returning `error.Overflow` if the result doesn't fit.

**Example:**
```zig
const a: i32 = 50000;
const b: i32 = 50000;

const product = try std.math.mul(i32, a, b); // May overflow
```

------

### `pub fn mulWide(comptime T: type, a: T, b: T) std.meta.Int(@typeInfo(T).int.signedness, @typeInfo(T).int.bits * 2)`

Multiplies `a` and `b`, returning a result with twice the bit width to guarantee no overflow.

**Example:**
```zig
const a: u32 = 0xFFFFFFFF;
const b: u32 = 0xFFFFFFFF;

const product: u64 = std.math.mulWide(u32, a, b); // Returns u64, never overflows
```

------

### `pub fn negate(x: anytype) !@TypeOf(x)`

Returns the negation of `x`, returning an error if negating would overflow.

**Example:**
```zig
const min_val: i8 = -128;

// -(-128) = 128, but i8 max is 127
const result = try std.math.negate(min_val); // Returns error.Overflow
```

------

### `pub fn negateCast(x: anytype) !std.meta.Int(.signed, @bitSizeOf(@TypeOf(x)))`

Negates an integer and casts the result to a signed type of the same bit width.

**Example:**
```zig
const unsigned: u8 = 100;
const negated: i8 = try std.math.negateCast(unsigned); // -100
```

------

## Trigonometric Functions

### `pub inline fn sin(value: anytype) @TypeOf(value)`

Sine trigonometric function. Uses hardware instruction when available. Equivalent to `@sin(value)`.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const angle = std.math.pi / 6.0; // 30 degrees
    const sine = std.math.sin(angle);
    std.debug.print("sin(30°) = {d:.4}\n", .{sine}); // 0.5000
}
```

------

### `pub inline fn cos(value: anytype) @TypeOf(value)`

Cosine trigonometric function. Uses hardware instruction when available.

**Example:**
```zig
const angle = std.math.pi / 3.0; // 60 degrees
const cosine = std.math.cos(angle); // 0.5
```

------

### `pub inline fn tan(value: anytype) @TypeOf(value)`

Tangent trigonometric function. Uses hardware instruction when available.

**Example:**
```zig
const angle = std.math.pi / 4.0; // 45 degrees
const tangent = std.math.tan(angle); // 1.0
```

------

### `pub fn asin(x: anytype) @TypeOf(x)`

Returns the arc-sine of `x` (inverse sine). Input must be in range [-1, 1].

**Example:**
```zig
const sine_val: f64 = 0.5;
const angle = std.math.asin(sine_val); // π/6 radians (30 degrees)
```

------

### `pub fn acos(x: anytype) @TypeOf(x)`

Returns the arc-cosine of `x` (inverse cosine). Input must be in range [-1, 1].

------

### `pub fn atan(x: anytype) @TypeOf(x)`

Returns the arc-tangent of `x` (inverse tangent).

------

### `pub fn atan2(y: anytype, x: anytype) @TypeOf(x, y)`

Returns the arc-tangent of `y/x`, using the signs of both arguments to determine the correct quadrant.

**Example:**
```zig
const y: f64 = 1.0;
const x: f64 = 1.0;
const angle = std.math.atan2(y, x); // π/4 radians (45 degrees)
```

------

## Hyperbolic Functions

### `pub fn sinh(x: anytype) @TypeOf(x)`

Returns the hyperbolic sine of `x`.

------

### `pub fn cosh(x: anytype) @TypeOf(x)`

Returns the hyperbolic cosine of `x`.

------

### `pub fn tanh(x: anytype) @TypeOf(x)`

Returns the hyperbolic tangent of `x`.

------

### `pub fn asinh(x: anytype) @TypeOf(x)`

Returns the hyperbolic arc-sine of `x`.

------

### `pub fn acosh(x: anytype) @TypeOf(x)`

Returns the hyperbolic arc-cosine of `x`.

------

### `pub fn atanh(x: anytype) @TypeOf(x)`

Returns the hyperbolic arc-tangent of `x`.

------

## Power and Root Functions

### `pub fn sqrt(x: anytype) Sqrt(@TypeOf(x))`

Returns the square root of `x`.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const value = 16.0;
    const root = std.math.sqrt(value); // 4.0
    std.debug.print("sqrt({d}) = {d}\n", .{value, root});
}
```

------

### `pub fn cbrt(x: anytype) @TypeOf(x)`

Returns the cube root of `x`.

**Example:**
```zig
const value: f64 = 27.0;
const root = std.math.cbrt(value); // 3.0
```

------

### `pub fn pow(comptime T: type, x: T, y: T) T`

Returns `x` raised to the power of `y` (x^y).

**Example:**
```zig
const base = 2.0;
const exponent = 10.0;
const result = std.math.pow(f64, base, exponent); // 1024.0
```

------

### `pub fn powi(comptime T: type, x: T, y: T) error{Overflow, Underflow}!T`

Returns `x` raised to the integer power `y`. Returns error on overflow/underflow.

**Example:**
```zig
const base: i32 = 2;
const exp: i32 = 30;
const result = try std.math.powi(i32, base, exp);
```

------

## Exponential and Logarithm Functions

### `pub inline fn exp(value: anytype) @TypeOf(value)`

Base-e exponential function (e^x). Uses hardware instruction when available. Equivalent to `@exp(value)`.

**Example:**
```zig
const x = 2.0;
const result = std.math.exp(x); // e^2 ≈ 7.389
```

------

### `pub inline fn exp2(value: anytype) @TypeOf(value)`

Base-2 exponential function (2^x). Uses hardware instruction when available.

**Example:**
```zig
const x = 10.0;
const result = std.math.exp2(x); // 2^10 = 1024.0
```

------

### `pub fn expm1(x: anytype) @TypeOf(x)`

Returns `e^x - 1`. More accurate than `exp(x) - 1` when `x` is near zero.

------

### `pub fn log(comptime T: type, base: T, x: T) T`

Returns the logarithm of `x` for the provided `base`.

**Example:**
```zig
const x = 1000.0;
const result = std.math.log(f64, 10.0, x); // log₁₀(1000) = 3.0
```

------

### `pub fn log2(x: anytype) @TypeOf(x)`

Returns the base-2 logarithm of `x`.

**Example:**
```zig
const x = 1024.0;
const result = std.math.log2(x); // 10.0
```

------

### `pub fn log10(x: anytype) @TypeOf(x)`

Returns the base-10 logarithm of `x`.

------

### `pub fn log1p(x: anytype) @TypeOf(x)`

Returns the natural logarithm of `1 + x`. More accurate than `log(1 + x)` when `x` is near zero.

------

### `pub fn log2_int(comptime T: type, x: T) Log2Int(T)`

Returns the base-2 logarithm of integer `x`, rounding down to the nearest integer.

**Example:**
```zig
const x: u32 = 1000;
const result = std.math.log2_int(u32, x); // 9 (since 2^9 = 512 < 1000 < 2^10)
```

------

### `pub fn log2_int_ceil(comptime T: type, x: T) Log2IntCeil(T)`

Returns the base-2 logarithm of integer `x`, rounding up to the nearest integer.

**Example:**
```zig
const x: u32 = 1000;
const result = std.math.log2_int_ceil(u32, x); // 10 (since 2^10 = 1024 > 1000)
```

------

### `pub fn log10_int(x: anytype) std.math.Log2Int(@TypeOf(x))`

Returns the base-10 logarithm of integer `x`, rounding down to the nearest integer.

------

### `pub fn log_int(comptime T: type, base: T, x: T) Log2Int(T)`

Returns the logarithm of `x` for the provided `base`, rounding down to the nearest integer. Asserts `base > 1` and `x > 0`.

------

## Rounding Functions

### `pub inline fn floor(value: anytype) @TypeOf(value)`

Returns the largest integral value not greater than the given floating point number. Uses hardware instruction when available. Equivalent to `@floor(value)`.

**Example:**
```zig
const value = 3.7;
const result = std.math.floor(value); // 3.0
```

------

### `pub inline fn ceil(value: anytype) @TypeOf(value)`

Returns the smallest integral value not less than the given floating point number. Uses hardware instruction when available. Equivalent to `@ceil(value)`.

**Example:**
```zig
const value = 3.2;
const result = std.math.ceil(value); // 4.0
```

------

### `pub inline fn round(value: anytype) @TypeOf(value)`

Rounds to the nearest integer. If two integers are equally close, rounds away from zero. Uses hardware instruction when available. Equivalent to `@round(value)`.

**Example:**
```zig
const value = 3.5;
const result = std.math.round(value); // 4.0
```

------

### `pub inline fn trunc(value: anytype) @TypeOf(value)`

Rounds towards zero (removes fractional part). Uses hardware instruction when available. Equivalent to `@trunc(value)`.

**Example:**
```zig
const positive = 3.7;
const negative = -3.7;
std.debug.print("{d}, {d}\n", .{
    std.math.trunc(positive), // 3.0
    std.math.trunc(negative), // -3.0
});
```

------

## Clamping and Range Functions

### `pub fn clamp(val: anytype, lower: anytype, upper: anytype) @TypeOf(val, lower, upper)`

Limits `val` to the inclusive range [lower, upper].

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const value = 150;
    const clamped = std.math.clamp(value, 0, 100); // 100
    std.debug.print("Clamped: {}\n", .{clamped});
}
```

------

### `pub fn lerp(a: anytype, b: anytype, t: anytype) @TypeOf(a, b, t)`

Performs linear interpolation between `a` and `b` based on `t`. `t` ranges from 0.0 to 1.0, but may exceed these bounds.

**Example:**
```zig
const start = 0.0;
const end = 100.0;
const halfway = std.math.lerp(start, end, 0.5); // 50.0
const beyond = std.math.lerp(start, end, 1.5); // 150.0
```

------

### `pub fn wrap(x: anytype, r: anytype) @TypeOf(x)`

Limits `x` to the half-open interval [-r, r). Useful for wrapping angles or cyclic values.

**Example:**
```zig
const value = 5.0;
const range = 3.0;
const wrapped = std.math.wrap(value, range); // -1.0 (wraps to [-3, 3))
```

------

## Division and Modulo Functions

### `pub fn divTrunc(comptime T: type, numerator: T, denominator: T) !T`

Divides `numerator` by `denominator`, rounding toward zero. Returns error on overflow or when denominator is zero.

------

### `pub fn divFloor(comptime T: type, numerator: T, denominator: T) !T`

Divides `numerator` by `denominator`, rounding toward negative infinity. Returns error on overflow or when denominator is zero.

------

### `pub fn divCeil(comptime T: type, numerator: T, denominator: T) !T`

Divides `numerator` by `denominator`, rounding toward positive infinity. Returns error on overflow or when denominator is zero.

**Example:**
```zig
const result = try std.math.divCeil(i32, 10, 3); // 4 (rounds up)
```

------

### `pub fn divExact(comptime T: type, numerator: T, denominator: T) !T`

Divides `numerator` by `denominator`. Returns error if quotient is not an integer, denominator is zero, or on overflow.

------

### `pub fn mod(comptime T: type, numerator: T, denominator: T) !T`

Returns `numerator` modulo `denominator`. Returns error if denominator is zero or negative. Negative numerators never result in negative return values.

**Example:**
```zig
const result = try std.math.mod(i32, -5, 3); // 1 (always positive)
```

------

### `pub fn rem(comptime T: type, numerator: T, denominator: T) !T`

Returns the remainder when `numerator` is divided by `denominator`. Returns error if denominator is zero or negative. Negative numerators can give negative results.

**Example:**
```zig
const result = try std.math.rem(i32, -5, 3); // -2 (can be negative)
```

------

### `pub fn comptimeMod(num: anytype, comptime denom: comptime_int) IntFittingRange(0, denom - 1)`

Returns the modulo of `num` with the smallest integer type that can represent the result.

------

## Power-of-Two Functions

### `pub fn isPowerOfTwo(int: anytype) bool`

Returns whether `int` is a power of two. Asserts `int > 0`.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("{}\n", .{std.math.isPowerOfTwo(16)});  // true
    std.debug.print("{}\n", .{std.math.isPowerOfTwo(100)}); // false
}
```

------

### `pub fn ceilPowerOfTwo(comptime T: type, value: T) error{Overflow}!T`

Returns the next power of two (or the value itself if already a power of two). Only unsigned integers. Zero is not allowed. Returns error if the result doesn't fit.

**Example:**
```zig
const result = try std.math.ceilPowerOfTwo(u32, 10); // 16
```

------

### `pub fn ceilPowerOfTwoAssert(comptime T: type, value: T) T`

Returns the next power of two. Asserts that the value fits (doesn't overflow).

------

### `pub fn ceilPowerOfTwoPromote(comptime T: type, value: T) std.meta.Int(@typeInfo(T).int.signedness, @typeInfo(T).int.bits + 1)`

Returns the next power of two. Result type has 1 more bit than input type, guaranteeing no overflow.

**Example:**
```zig
const input: u8 = 200;
const result: u9 = std.math.ceilPowerOfTwoPromote(u8, input); // 256
```

------

### `pub fn floorPowerOfTwo(comptime T: type, value: T) T`

Returns the nearest power of two less than or equal to `value`, or zero if `value <= 0`.

**Example:**
```zig
const result = std.math.floorPowerOfTwo(u32, 100); // 64
```

------

## Bit Manipulation Functions

### `pub fn shl(comptime T: type, a: T, shift_amt: anytype) T`

Shifts left. Overflowed bits are truncated. Negative shift amounts result in right shift.

------

### `pub fn shlExact(comptime T: type, a: T, shift_amt: Log2Int(T)) !T`

Shifts `a` left by `shift_amt`. Returns error on overflow. `shift_amt` is unsigned.

------

### `pub fn shr(comptime T: type, a: T, shift_amt: anytype) T`

Shifts right. Overflowed bits are truncated. Negative shift amounts result in left shift.

------

### `pub fn rotl(comptime T: type, x: T, r: anytype) T`

Rotates left. Only unsigned values can be rotated. Negative shift values result in shift modulo the bit count.

**Example:**
```zig
const value: u8 = 0b10110001;
const rotated = std.math.rotl(u8, value, 2); // 0b11000110
```

------

### `pub fn rotr(comptime T: type, x: T, r: anytype) T`

Rotates right. Only unsigned values can be rotated. Negative shift values result in shift modulo the bit count.

------

### `pub inline fn boolMask(comptime MaskInt: type, value: bool) MaskInt`

Returns a mask of all ones if `value` is true, and all zeroes if false. Compiles to one instruction for register-sized integers.

**Example:**
```zig
const mask = std.math.boolMask(u32, true); // 0xFFFFFFFF
const zero_mask = std.math.boolMask(u32, false); // 0x00000000
```

------

## Comparison and Ordering Functions

### `pub fn compare(a: anytype, op: CompareOperator, b: anytype) bool`

Performs comparison using a runtime-known operator enum value. Works on any operands that support comparison operators.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const op = std.math.CompareOperator.gte;
    const result = std.math.compare(10, op, 5); // true (10 >= 5)
    std.debug.print("Result: {}\n", .{result});
}
```

------

### `pub fn order(a: anytype, b: anytype) Order`

Returns the order of two numbers with respect to each other.

**Example:**
```zig
const ordering = std.math.order(10, 20); // .lt (less than)
```

------

### `pub inline fn sign(i: anytype) @TypeOf(i)`

Returns -1, 0, or 1. Supports integers, floats, and vectors. Unsigned integers always return 0 or 1. Branchless implementation.

**Example:**
```zig
std.debug.print("{}, {}, {}\n", .{
    std.math.sign(-10), // -1
    std.math.sign(0),   // 0
    std.math.sign(10),  // 1
});
```

------

## Number Theory Functions

### `pub fn gcd(a: anytype, b: anytype) @TypeOf(a, b)`

Returns the greatest common divisor (GCD) of two unsigned integers.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const result = std.math.gcd(48, 18); // 6
    std.debug.print("GCD(48, 18) = {}\n", .{result});
}
```

------

### `pub fn lcm(a: anytype, b: anytype) @TypeOf(a, b)`

Returns the least common multiple (LCM) of two integers. If either argument is zero, returns 0.

**Example:**
```zig
const result = std.math.lcm(12, 18); // 36
```

------

## Floating-Point Utility Functions

### `pub fn approxEqAbs(comptime T: type, x: T, y: T, tolerance: T) bool`

Performs approximate comparison of two floating-point values. Returns true if the absolute difference is less than or equal to the specified tolerance.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const a = 1.0;
    const b = 1.0001;
    const equal = std.math.approxEqAbs(f64, a, b, 0.001); // true
    std.debug.print("Approximately equal: {}\n", .{equal});
}
```

------

### `pub fn approxEqRel(comptime T: type, x: T, y: T, tolerance: T) bool`

Performs approximate comparison using relative tolerance. Returns true if the absolute difference is less than or equal to `max(|x|, |y|) * tolerance`.

------

### `pub fn copysign(magnitude: anytype, sign: @TypeOf(magnitude)) @TypeOf(magnitude)`

Returns a value with the magnitude of `magnitude` and the sign of `sign`.

**Example:**
```zig
const result = std.math.copysign(@as(f64, 10.0), @as(f64, -1.0)); // -10.0
```

------

### `pub fn signbit(x: anytype) bool`

Returns whether `x` is negative or negative zero.

------

### `pub fn frexp(x: anytype) Frexp(@TypeOf(x))`

Breaks `x` into a normalized fraction and an integral power of two: `x == frac * 2^exp`, with |frac| in the interval [0.5, 1).

**Example:**
```zig
const result = std.math.frexp(@as(f64, 10.0));
// result.significand ≈ 0.625, result.exponent = 4
// (0.625 * 2^4 = 10.0)
```

------

### `pub fn ldexp(x: anytype, n: i32) @TypeOf(x)`

Returns `x * 2^n`.

**Example:**
```zig
const result = std.math.ldexp(@as(f64, 1.5), 3); // 1.5 * 2^3 = 12.0
```

------

### `pub fn modf(x: anytype) Modf(@TypeOf(x))`

Returns the integer and fractional parts of `x`. Both parts have the same sign as `x`.

**Example:**
```zig
const result = std.math.modf(@as(f64, 3.14));
// result.ipart = 3.0, result.fpart = 0.14
```

------

### `pub fn nextAfter(comptime T: type, x: T, y: T) T`

Returns the next representable value after `x` in the direction of `y`.

------

## Floating-Point Type Inspection

### `pub inline fn floatEps(comptime T: type) T`

Returns the machine epsilon of floating-point type `T` (the smallest value where `1.0 + eps != 1.0`).

------

### `pub inline fn floatEpsAt(comptime T: type, x: T) T`

Returns the local epsilon at value `x` (the smallest value where `x + eps != x`).

------

### `pub inline fn floatMantissaBits(comptime T: type) comptime_int`

Returns the number of bits in the mantissa of floating-point type `T`.

------

### `pub inline fn floatExponentBits(comptime T: type) comptime_int`

Returns the number of bits in the exponent of floating-point type `T`.

------

### `pub inline fn floatExponentMin(comptime T: type) comptime_int`

Returns the minimum exponent that can represent a normalized value in floating-point type `T`.

------

### `pub inline fn floatExponentMax(comptime T: type) comptime_int`

Returns the maximum exponent that can represent a normalized value in floating-point type `T`.

------

### `pub inline fn floatMin(comptime T: type) T`

Returns the smallest normal number representable in floating-point type `T`.

------

### `pub inline fn floatMax(comptime T: type) T`

Returns the largest normal number representable in floating-point type `T`.

------

### `pub inline fn floatTrueMin(comptime T: type) T`

Returns the smallest subnormal number representable in floating-point type `T`.

------

## Special Floating-Point Values

### `pub inline fn nan(comptime Type: type) Type`

Returns the canonical quiet NaN representation for a floating-point `Type`.

**Example:**
```zig
const not_a_number = std.math.nan(f64);
std.debug.print("Is NaN: {}\n", .{std.math.isNan(not_a_number)}); // true
```

------

### `pub inline fn snan(comptime Type: type) Type`

Returns a signalling NaN representation for a floating-point `Type`.

------

### `pub inline fn inf(comptime Type: type) Type`

Returns the positive infinity value for a floating-point `Type`.

**Example:**
```zig
const infinity = std.math.inf(f64);
std.debug.print("Is inf: {}\n", .{std.math.isInf(infinity)}); // true
```

------

### `pub fn isNan(x: anytype) bool`

Returns whether `x` is NaN (quiet or signalling).

------

### `pub fn isSignalNan(x: anytype) bool`

Returns whether `x` is a signalling NaN.

------

### `pub inline fn isInf(x: anytype) bool`

Returns whether `x` is infinity (positive or negative).

------

### `pub inline fn isPositiveInf(x: anytype) bool`

Returns whether `x` is positive infinity.

------

### `pub inline fn isNegativeInf(x: anytype) bool`

Returns whether `x` is negative infinity.

------

### `pub fn isFinite(x: anytype) bool`

Returns whether `x` is a finite value (not NaN or infinity).

------

### `pub fn isNormal(x: anytype) bool`

Returns whether `x` is neither zero, subnormal, infinity, nor NaN.

------

### `pub inline fn isPositiveZero(x: anytype) bool`

Returns whether `x` is positive zero.

------

### `pub inline fn isNegativeZero(x: anytype) bool`

Returns whether `x` is negative zero.

------

## Miscellaneous Math Functions

### `pub fn hypot(x: anytype, y: anytype) @TypeOf(x, y)`

Returns `sqrt(x*x + y*y)`, avoiding unnecessary overflow and underflow.

**Example:**
```zig
const x = 3.0;
const y = 4.0;
const distance = std.math.hypot(x, y); // 5.0
```

------

### `pub fn ilogb(x: anytype) i32`

Returns the binary exponent of `x` as an integer.

------

### `pub fn gamma(comptime T: type, x: T) T`

Returns the gamma function of `x`. For integer `x`, `gamma(x) = factorial(x - 1)`.

------

### `pub fn lgamma(comptime T: type, x: T) T`

Returns the natural logarithm of the absolute value of the gamma function.

------

## Angle Conversion Functions

### `pub fn degreesToRadians(ang: anytype) if (@TypeOf(ang) == comptime_int) comptime_float else @TypeOf(ang)`

Converts an angle in degrees to radians.

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const degrees = 180.0;
    const radians = std.math.degreesToRadians(degrees); // π
    std.debug.print("{d} degrees = {d} radians\n", .{degrees, radians});
}
```

------

### `pub fn radiansToDegrees(ang: anytype) if (@TypeOf(ang) == comptime_int) comptime_float else @TypeOf(ang)`

Converts an angle in radians to degrees.

**Example:**
```zig
const radians = std.math.pi;
const degrees = std.math.radiansToDegrees(radians); // 180.0
```

------

## Type Utilities

### `pub fn cast(comptime T: type, x: anytype) ?T`

Casts an integer to a different integer type. If the value doesn't fit, returns `null`.

**Example:**
```zig
const big: u32 = 300;
const small = std.math.cast(u8, big); // null (300 > 255)

const fits: u32 = 100;
const ok = std.math.cast(u8, fits).?; // 100
```

------

### `pub fn lossyCast(comptime T: type, value: anytype) T`

Casts a value to a different type. If the value doesn't fit or can't be perfectly represented, it will be converted to the closest possible representation.

------

### `pub fn maxInt(comptime T: type) comptime_int`

Returns the maximum value of integer type `T`.

**Example:**
```zig
const max_u8 = std.math.maxInt(u8); // 255
const max_i16 = std.math.maxInt(i16); // 32767
```

------

### `pub fn minInt(comptime T: type) comptime_int`

Returns the minimum value of integer type `T`.

**Example:**
```zig
const min_u8 = std.math.minInt(u8); // 0
const min_i16 = std.math.minInt(i16); // -32768
```

------

### `pub fn alignCast(comptime alignment: Alignment, ptr: anytype) AlignCastError!AlignCastResult(alignment, @TypeOf(ptr))`

Align-casts a pointer but returns an error if it has the wrong alignment.

------

## Floating-Point Exception Functions

These functions raise floating-point exceptions for debugging purposes.

### `pub fn raiseDivByZero() void`

Raises a divide-by-zero exception.

------

### `pub fn raiseInvalid() void`

Raises an invalid operation exception.

------

### `pub fn raiseOverflow() void`

Raises an overflow exception.

------

### `pub fn raiseUnderflow() void`

Raises an underflow exception.

------

### `pub fn raiseInexact() void`

Raises an inexact result exception.

------

---

## Types and Constants

### User-Facing Types

**`CompareOperator` (enum)**
```zig
pub const CompareOperator = enum { eq, neq, lt, lte, gt, gte };
```
Used with `compare()` for runtime-determined comparison operations.

**Example:**
```zig
const op = std.math.CompareOperator.gte;
const result = std.math.compare(10, op, 5); // true
```

------

**`Order` (enum)**
```zig
pub const Order = enum { lt, eq, gt };
```
Represents the ordering relationship between two values.

------

**`Sign` (enum)**
```zig
pub const Sign = enum { negative, zero, positive };
```
Represents the sign of a number.

------

**`Frexp(T)` (struct)**

Return type of `frexp()` containing:
- `significand: T` - The normalized fraction part
- `exponent: i32` - The power of two exponent

------

**`Modf(T)` (struct)**

Return type of `modf()` containing:
- `ipart: T` - The integer part
- `fpart: T` - The fractional part

------

### Type Functions

**`Log2Int(T)` (type function)**

Returns the smallest integer type that can hold `log2(T.max)`.

------

**`Log2IntCeil(T)` (type function)**

Returns the smallest integer type that can hold `ceil(log2(T.max))`.

------

**`IntFittingRange(comptime_int min, comptime_int max)` (type function)**

Returns the smallest integer type that can hold values in the range [min, max].

------

**`ByteAlignedInt(comptime T: type)` (type function)**

Returns an integer type aligned to byte boundaries.

------

**`Min(comptime T: type, a: T, b: T)` (type function)**

Comptime function that returns the minimum of two values.

------

### Complex Numbers

**`Complex` (type)**

See `std.math.complex` namespace for complex number operations.

------

**`F80` (type)**

Extended precision 80-bit floating-point type.

------

### Namespaces

**`std.math.big`**

Arbitrary-precision integer arithmetic (bigint operations).

------

**`std.math.complex`**

Complex number operations and utilities.

------

## Usage Patterns

### Pattern 1: Safe Integer Arithmetic in Financial Calculations

```zig
const std = @import("std");

pub fn calculateTotal(price: u64, quantity: u32) !u64 {
    // Use safe multiplication to detect overflow
    const subtotal = try std.math.mul(u64, price, quantity);

    // Calculate tax (15%)
    const tax_amount = try std.math.mul(u64, subtotal, 15);
    const tax = try std.math.divCeil(u64, tax_amount, 100);

    // Add tax to subtotal
    const total = try std.math.add(u64, subtotal, tax);

    return total;
}

pub fn main() !void {
    const price: u64 = 1_000_000;
    const quantity: u32 = 5000;

    const total = calculateTotal(price, quantity) catch |err| {
        std.debug.print("Overflow error: {}\n", .{err});
        return err;
    };

    std.debug.print("Total: ${}\n", .{total});
}
```

**Explanation:**
Demonstrates how to use safe arithmetic functions to detect overflow in calculations where wrapping would be incorrect and dangerous.

------

### Pattern 2: Angle Calculations for Graphics

```zig
const std = @import("std");

pub fn rotatePoint(x: f64, y: f64, degrees: f64) struct { x: f64, y: f64 } {
    const radians = std.math.degreesToRadians(degrees);
    const cos_angle = std.math.cos(radians);
    const sin_angle = std.math.sin(radians);

    return .{
        .x = x * cos_angle - y * sin_angle,
        .y = x * sin_angle + y * cos_angle,
    };
}

pub fn main() void {
    const point = rotatePoint(1.0, 0.0, 90.0);
    std.debug.print("Rotated point: ({d:.4}, {d:.4})\n", .{ point.x, point.y });
}
```

------

### Pattern 3: Floating-Point Comparison in Tests

```zig
const std = @import("std");
const testing = std.testing;

test "approximate equality" {
    const a = 0.1 + 0.2; // May not exactly equal 0.3 due to floating-point error
    const b = 0.3;

    // Absolute tolerance comparison
    try testing.expect(std.math.approxEqAbs(f64, a, b, 0.0001));

    // Relative tolerance comparison (better for large numbers)
    const large_a = 1000000.0001;
    const large_b = 1000000.0002;
    try testing.expect(std.math.approxEqRel(f64, large_a, large_b, 0.00001));
}
```

------

### Pattern 4: Power-of-Two Memory Alignment

```zig
const std = @import("std");

pub fn alignBufferSize(requested_size: usize) !usize {
    // Round up to the next power of two for efficient memory allocation
    if (requested_size == 0) return 0;

    const aligned = try std.math.ceilPowerOfTwo(usize, requested_size);
    return aligned;
}

pub fn main() !void {
    const sizes = [_]usize{ 100, 1000, 2047, 2048, 5000 };

    for (sizes) |size| {
        const aligned = try alignBufferSize(size);
        std.debug.print("Request: {d:5} -> Aligned: {d:5}\n", .{ size, aligned });
    }
}
```

------

### Pattern 5: Distance Calculation (Avoiding Overflow)

```zig
const std = @import("std");

pub fn distance2D(x1: f64, y1: f64, x2: f64, y2: f64) f64 {
    const dx = x2 - x1;
    const dy = y2 - y1;

    // Use hypot to avoid overflow for large values
    return std.math.hypot(dx, dy);
}

pub fn main() void {
    const dist = distance2D(0.0, 0.0, 3.0, 4.0);
    std.debug.print("Distance: {d}\n", .{dist}); // 5.0
}
```

------

## Error Sets

### Overflow Errors
- `error.Overflow` - Result exceeds the maximum value representable in the target type
- `error.Underflow` - Result is less than the minimum value representable in the target type (or too close to zero for floating-point)

### Alignment Errors
- `error.Misaligned` - Pointer does not have the required alignment (from `alignCast`)

------

## Debug Checklist

✅ **Use safe arithmetic for overflow detection** - Prefer `add()`, `mul()`, `sub()` over `+%`, `*%`, `-%` when overflow is an error condition

✅ **Check for division by zero** - Use `divTrunc()`, `divFloor()`, `divCeil()` which return errors, or validate denominators before division

✅ **Use appropriate tolerance for float comparison** - Never use `==` for floating-point comparison; use `approxEqAbs()` or `approxEqRel()`

✅ **Validate input ranges for trigonometric functions** - `asin()` and `acos()` require inputs in [-1, 1]

✅ **Handle special floating-point values** - Check for NaN, infinity, and negative zero using `isNan()`, `isInf()`, `isNegativeZero()`

✅ **Ensure power-of-two inputs are non-zero** - Functions like `isPowerOfTwo()` and `ceilPowerOfTwo()` assert or error on zero

✅ **Use correct modulo function** - `mod()` always returns positive values, `rem()` can return negative; choose based on semantics

✅ **Convert angles correctly** - Remember: radians for math functions, degrees for human-readable values

------

## Performance Tips

1. **Prefer builtin functions for basic operations** - `@sqrt()`, `@sin()`, `@cos()`, `@exp()`, `@log()` compile to single hardware instructions when available. Using `std.math` wrappers adds function call overhead.

2. **Use integer logarithms for powers of two** - When working with sizes, alignments, or bit operations:
   ```zig
   // Fast integer log2
   const power = std.math.log2_int(u32, size);

   // Check if power of two (branchless)
   const is_power = std.math.isPowerOfTwo(value);
   ```

3. **Avoid unnecessary overflow checks** - If you know values cannot overflow (e.g., small constants), use standard operators `+`, `-`, `*` instead of `add()`, `sub()`, `mul()`.

4. **Use `clamp()` instead of min/max chains** - Single `clamp()` call is more efficient than nested `@min()` and `@max()`.
   ```zig
   // Good
   const clamped = std.math.clamp(value, 0, 100);

   // Less efficient
   const clamped = @max(0, @min(value, 100));
   ```

5. **Use `mulWide()` when overflow is expected** - Instead of checking for overflow, promote to a wider type:
   ```zig
   const result: u64 = std.math.mulWide(u32, a, b); // Never overflows
   ```

6. **Leverage comptime for constant calculations** - Math operations on `comptime` values are evaluated at compile time:
   ```zig
   const rad_90 = comptime std.math.degreesToRadians(90.0);
   ```

7. **Use `approxEqAbs()` for small numbers, `approxEqRel()` for large** - Absolute tolerance works well near zero; relative tolerance scales with magnitude.

------

## See Also

- **std.math.big** - Arbitrary-precision integer arithmetic for numbers beyond fixed-width types
- **std.math.complex** - Complex number operations (imaginary numbers)
- **@sqrt/@sin/@cos/@tan** - Direct builtin functions (std.math wraps these for consistency)
- **std.mem** - Memory comparison and manipulation utilities
- **std.meta.Int** - Type function for creating integer types of specific sizes
