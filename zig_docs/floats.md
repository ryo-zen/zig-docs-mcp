# Floats

📚 **[See Comprehensive Float Examples](../../Examples/test_float_patterns.zig)** - Complete working examples of all patterns, operations, and pitfalls discussed in this guide

Zig supports the following floating point types, adhering to IEEE-754 standards:

* `f16`: IEEE-754-2008 binary16 (half precision)
* `f32`: IEEE-754-2008 binary32 (single precision)
* `f64`: IEEE-754-2008 binary64 (double precision)
* `f80`: IEEE-754-2008 80-bit extended precision
* `f128`: IEEE-754-2008 binary128 (quad precision)
* `c_longdouble`: Matches `long double` for the target C ABI

## Quick Reference

| Type | Bits | Precision (decimal digits) | Range (approx) | Hardware Accelerated | Use Case |
|------|------|---------------------------|----------------|---------------------|----------|
| `f16` | 16 | ~3-4 | ±65,504 | GPU (modern) | ML/AI, graphics, memory-constrained |
| `f32` | 32 | ~7 | ±3.4×10³⁸ | ✅ CPU, GPU | General purpose, games, graphics |
| `f64` | 64 | ~15-16 | ±1.7×10³⁰⁸ | ✅ CPU | Scientific computing, high precision |
| `f80` | 80 | ~19 | ±1.1×10⁴⁹³² | ⚠️ x86 only | Extended precision (x87 FPU) |
| `f128` | 128 | ~34 | ±1.1×10⁴⁹³² | ❌ Software | Cryptography, extreme precision |
| `c_longdouble` | varies | varies | varies | Platform-dependent | C interop only |

**Note:** `f80` is x86-specific and may be slow on other architectures. `f128` is typically software-emulated and much slower than hardware types.

## When to Use Which Type

### Use `f32` when:
- Building games or real-time graphics
- Memory usage matters (arrays of millions of floats)
- GPU computation (most shaders use 32-bit floats)
- 7 decimal digits of precision is sufficient
- **This is the default choice for most applications**

### Use `f64` when:
- Scientific computing requiring high precision
- Financial calculations (though see "When NOT to Use Floats" below)
- Coordinate systems with large numbers (GPS, astronomy)
- Accumulating many small values (reduces rounding error)
- Working with time durations in seconds (nanosecond precision)

### Use `f16` when:
- Training neural networks (half-precision training)
- GPU memory is limited
- Storing large datasets where precision can be sacrificed
- Working with mobile/embedded GPUs

### Use `f128` when:
- Implementing cryptographic primitives
- Computing mathematical constants to extreme precision
- Intermediate calculations that need very high precision
- **Warning:** Very slow (software-emulated on most platforms)

### Avoid `f80` unless:
- You specifically need x87 FPU compatibility
- Working with legacy C code that uses `long double` on x86
- **Not portable** - behaves differently on ARM, RISC-V, etc.

## Float Literals

Float literals have the type `comptime_float`. This type has arbitrary precision at compile time and is guaranteed to have the same precision and operations as the largest other floating point type (`f128`).

Float literals coerce to:
* Any floating point type.
* Any integer type, provided there is no fractional component.

```zig
const std = @import("std");

test "float literals" {
    const floating_point = 123.0E+77;
    const another_float = 123.0;
    const yet_another = 123.0e+77;

    const hex_floating_point = 0x103.70p-5;
    const another_hex_float = 0x103.70;
    const yet_another_hex_float = 0x103.70P-5;

    // Underscores may be placed between two digits as a visual separator
    const lightspeed = 299_792_458.000_000;
    const nanosecond = 0.000_000_001;
    const more_hex = 0x1234_5678.9ABC_CDEFp-10;
    
    _ = floating_point; _ = another_float; _ = yet_another;
    _ = hex_floating_point; _ = another_hex_float; _ = yet_another_hex_float;
    _ = lightspeed; _ = nanosecond; _ = more_hex;
}
```

## Special Values

There is no dedicated syntax for `NaN`, `infinity`, or `negative infinity`. For these special values, use the standard library `std.math` functions.

```zig
const std = @import("std");

test "special values" {
    const inf = std.math.inf(f32);
    const negative_inf = -std.math.inf(f64);
    const nan = std.math.nan(f128);

    _ = inf; _ = negative_inf; _ = nan;
}
```

## Common Pitfalls

### ❌ Comparing floats with `==`
```zig
// BAD: Direct equality comparison
const a: f32 = 0.1 + 0.2;
const b: f32 = 0.3;
if (a == b) { // May be false due to rounding!
    // This might not execute
}
```

**Fix:** Use epsilon comparison with `std.math.approxEqAbs` or `std.math.approxEqRel`:
```zig
// GOOD: Epsilon comparison
const a: f32 = 0.1 + 0.2;
const b: f32 = 0.3;
if (std.math.approxEqAbs(f32, a, b, 0.0001)) {
    // This will execute
}
```

------

### ❌ Precision loss with large numbers
```zig
// BAD: f32 can't represent all integers above 2^24
const x: f32 = 16777216.0; // 2^24, last exact integer
const y: f32 = x + 1.0;
// y == x (the +1.0 is lost!)
```

**Fix:** Use `f64` for large integer ranges or use actual integer types:
```zig
// GOOD: Use f64 for larger range
const x: f64 = 16777216.0;
const y: f64 = x + 1.0; // Now y == 16777217.0

// BETTER: Use integer types for exact integers
const x: i64 = 16777216;
const y: i64 = x + 1; // Always exact
```

------

### ❌ NaN propagation
```zig
// BAD: Not checking for NaN
const result = std.math.sqrt(-1.0); // NaN (can't sqrt negative)
const final = result + 10.0; // Still NaN!
// Any operation with NaN produces NaN
```

**Fix:** Check for NaN explicitly:
```zig
// GOOD: Validate inputs
const value: f32 = -1.0;
if (value < 0.0) {
    // Handle negative input
    return error.InvalidInput;
}
const result = std.math.sqrt(value);
```

------

### ❌ Using floats for currency
```zig
// BAD: Floats for money - rounding errors accumulate
var balance: f64 = 0.0;
balance += 0.1; // $0.10
balance += 0.1; // $0.10
balance += 0.1; // $0.10
// balance might be 0.30000000000000004, not 0.30!
```

**Fix:** Use integer cents or a decimal library:
```zig
// GOOD: Integer cents (no rounding errors)
var balance_cents: i64 = 0;
balance_cents += 10; // 10 cents
balance_cents += 10; // 10 cents
balance_cents += 10; // 10 cents
// balance_cents == 30 (always exact)
const dollars = @as(f64, @floatFromInt(balance_cents)) / 100.0;
```

------

### ❌ Ignoring signed zero
```zig
// BAD: Assuming 0.0 == -0.0
const pos_zero: f32 = 0.0;
const neg_zero: f32 = -0.0;
// pos_zero == neg_zero is TRUE
// But they have different bit representations
```

**Important:** Signed zero exists in IEEE-754. It matters for:
- `1.0 / 0.0 = +inf`
- `1.0 / -0.0 = -inf`
- Branch cuts in complex functions

------

### ❌ Forgetting overflow produces infinity
```zig
// BAD: No overflow check
const huge: f32 = 1.0e38;
const result = huge * huge; // +inf (overflow)
// No error, just infinity!
```

**Fix:** Check for infinity after operations:
```zig
// GOOD: Validate result
const huge: f32 = 1.0e38;
const result = huge * huge;
if (std.math.isInf(result)) {
    return error.Overflow;
}
```

## Floating Point Operations

By default, floating point operations use **Strict** mode. In this mode, operations are strictly IEEE-754 compliant.

You can switch to **Optimized** mode on a per-block basis using `@setFloatMode(.optimized)`. This allows the compiler to re-associate operations (e.g., `(a + b) - c` might become `a + (b - c)`), which can improve performance but may result in different rounding behavior.

### Example: Strict vs Optimized Mode

To observe the difference between Strict and Optimized modes, the compiler must perform actual runtime arithmetic rather than resolving constants at compile-time. In the example below, we use `volatile` to force runtime execution.

**Note:** While the logic holds in Debug builds, floating point re-association optimizations are typically most aggressive in Release builds.
Run with: `zig run float_mode.zig -O ReleaseFast`

```zig
const std = @import("std");
const print = std.debug.print;

// Large value that causes precision loss for small additions in Strict mode
const big = 1.0e20; 

// Strict Mode (Default)
// Operations executed strictly left-to-right.
// (x + big) - big
// 1. (0.001 + 1e20) -> 1e20 (0.001 lost due to precision)
// 2. 1e20 - 1e20 -> 0.0
fn foo_strict(x: f64) f64 {
    return x + big - big;
}

// Optimized Mode
// Compiler may reassociate: x + (big - big)
// 1. (1e20 - 1e20) -> 0.0
// 2. x + 0.0 -> x
fn foo_optimized(x: f64) f64 {
    @setFloatMode(.optimized);
    return x + big - big;
}

pub fn main() void {
    // Use volatile to prevent compile-time constant folding for this demonstration
    var x: f64 = 0.001;
    const v_x = @as(*volatile f64, &x).*;

    print("Optimized = {d}\n", .{foo_optimized(v_x)});
    print("Strict    = {d}\n", .{foo_strict(v_x)});
}
```

## Common Operations

The `std.math` module provides comprehensive floating point operations:

### Rounding and Truncation
```zig
const std = @import("std");

test "rounding operations" {
    const x: f32 = 3.7;

    // Round to nearest integer
    try std.testing.expect(std.math.round(x) == 4.0);

    // Round down (floor)
    try std.testing.expect(std.math.floor(x) == 3.0);

    // Round up (ceil)
    try std.testing.expect(std.math.ceil(x) == 4.0);

    // Truncate toward zero
    try std.testing.expect(std.math.trunc(x) == 3.0);
}
```

------

### Comparison Functions
```zig
test "float comparison" {
    const a: f64 = 0.1 + 0.2;
    const b: f64 = 0.3;

    // Absolute difference comparison (tolerance-based)
    try std.testing.expect(std.math.approxEqAbs(f64, a, b, 0.0001));

    // Relative difference comparison (percentage-based)
    try std.testing.expect(std.math.approxEqRel(f64, a, b, 0.0001));

    // Get minimum/maximum (use @min/@max builtins)
    try std.testing.expect(@min(a, b) <= a);
    try std.testing.expect(@max(a, b) >= b);
}
```

------

### Mathematical Functions
```zig
test "math functions" {
    const x: f64 = 2.0;

    // Power and roots
    try std.testing.expect(std.math.pow(f64, x, 3.0) == 8.0);
    try std.testing.expect(std.math.sqrt(x) > 1.4);
    try std.testing.expect(std.math.cbrt(x) > 1.2); // Cube root

    // Exponential and logarithms
    const e_to_x = std.math.exp(x);
    _ = e_to_x;
    const ln_x = std.math.log(f64, std.math.e, x);
    _ = ln_x;
    const log10_x = std.math.log10(x);
    _ = log10_x;

    // Trigonometry (radians)
    const sine = std.math.sin(x);
    const cosine = std.math.cos(x);
    const tangent = std.math.tan(x);
    _ = sine; _ = cosine; _ = tangent;

    // Absolute value (use @abs builtin)
    try std.testing.expect(@abs(-3.14) == 3.14);
}
```

------

### Classification Functions
```zig
test "float classification" {
    // Check for special values
    try std.testing.expect(std.math.isNan(std.math.nan(f32)));
    try std.testing.expect(std.math.isInf(std.math.inf(f64)));

    const finite_val: f32 = 42.0;
    try std.testing.expect(std.math.isFinite(finite_val));

    const normal_val: f32 = 1.0;
    try std.testing.expect(std.math.isNormal(normal_val)); // Not zero, inf, or NaN

    // Sign operations
    const neg_zero: f32 = -0.0;
    try std.testing.expect(std.math.signbit(neg_zero)); // True for negative zero

    const magnitude: f32 = 5.0;
    const sign: f32 = -1.0;
    try std.testing.expect(std.math.copysign(magnitude, sign) == -5.0);
}
```

## Real-World Patterns

### Physics Simulation (f32 for performance)
```zig
const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn length(self: Vec2) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn normalize(self: Vec2) Vec2 {
        const len = self.length();
        if (len < 0.0001) return Vec2{ .x = 0, .y = 0 };
        return Vec2{ .x = self.x / len, .y = self.y / len };
    }
};

test "physics vector" {
    const v = Vec2{ .x = 3.0, .y = 4.0 };
    try std.testing.expect(std.math.approxEqAbs(f32, v.length(), 5.0, 0.0001));

    const normalized = v.normalize();
    try std.testing.expect(std.math.approxEqAbs(f32, normalized.length(), 1.0, 0.0001));
}
```

------

### GPS Coordinates (f64 for precision)
```zig
const Coordinate = struct {
    latitude: f64,  // -90 to +90 degrees
    longitude: f64, // -180 to +180 degrees

    // Haversine formula for distance between two points on Earth
    pub fn distanceTo(self: Coordinate, other: Coordinate) f64 {
        const earth_radius_km = 6371.0;
        const lat1 = self.latitude * std.math.pi / 180.0;
        const lat2 = other.latitude * std.math.pi / 180.0;
        const delta_lat = (other.latitude - self.latitude) * std.math.pi / 180.0;
        const delta_lon = (other.longitude - self.longitude) * std.math.pi / 180.0;

        const a = std.math.sin(delta_lat / 2.0) * std.math.sin(delta_lat / 2.0) +
            std.math.cos(lat1) * std.math.cos(lat2) *
            std.math.sin(delta_lon / 2.0) * std.math.sin(delta_lon / 2.0);
        const c = 2.0 * std.math.atan2(std.math.sqrt(a), std.math.sqrt(1.0 - a));

        return earth_radius_km * c;
    }
};

test "GPS distance calculation" {
    const new_york = Coordinate{ .latitude = 40.7128, .longitude = -74.0060 };
    const london = Coordinate{ .latitude = 51.5074, .longitude = -0.1278 };

    const distance = new_york.distanceTo(london);
    // Should be approximately 5570 km
    try std.testing.expect(distance > 5500.0 and distance < 5600.0);
}
```

------

### Currency Handling (integers, NOT floats)
```zig
const Money = struct {
    cents: i64, // Store as integer cents

    pub fn fromDollars(dollars: f64) Money {
        return Money{ .cents = @intFromFloat(dollars * 100.0) };
    }

    pub fn toDollars(self: Money) f64 {
        return @as(f64, @floatFromInt(self.cents)) / 100.0;
    }

    pub fn add(self: Money, other: Money) Money {
        return Money{ .cents = self.cents + other.cents };
    }
};

test "currency handling" {
    var balance = Money{ .cents = 0 };
    balance = balance.add(Money{ .cents = 10 }); // $0.10
    balance = balance.add(Money{ .cents = 10 }); // $0.10
    balance = balance.add(Money{ .cents = 10 }); // $0.10

    try std.testing.expect(balance.cents == 30); // Exactly 30 cents
    try std.testing.expect(balance.toDollars() == 0.30);
}
```

------

### Scientific Computing (f64 for accuracy)
```zig
// Numerical integration using Simpson's rule
fn integrate(comptime f: fn (f64) f64, a: f64, b: f64, n: usize) f64 {
    const h = (b - a) / @as(f64, @floatFromInt(n));
    var sum: f64 = f(a) + f(b);

    var i: usize = 1;
    while (i < n) : (i += 2) {
        sum += 4.0 * f(a + @as(f64, @floatFromInt(i)) * h);
    }

    i = 2;
    while (i < n) : (i += 2) {
        sum += 2.0 * f(a + @as(f64, @floatFromInt(i)) * h);
    }

    return sum * h / 3.0;
}

fn square(x: f64) f64 {
    return x * x;
}

test "numerical integration" {
    // Integrate x^2 from 0 to 1 (should be 1/3)
    const result = integrate(square, 0.0, 1.0, 1000);
    try std.testing.expect(std.math.approxEqAbs(f64, result, 1.0 / 3.0, 0.0001));
}
```

## Performance Tips

1. **Use `f32` by default** - Twice as fast as `f64` on most hardware, uses half the memory
2. **Enable `@setFloatMode(.optimized)` in hot loops** - Allows compiler optimizations
3. **Avoid `f128`** - Software-emulated, 10-100x slower than hardware floats
4. **Use SIMD for arrays** - Process multiple floats at once with `@Vector`
5. **Minimize conversions** - Converting between `f32` and `f64` has a cost
6. **Fused multiply-add** - `@mulAdd(T, a, b, c)` computes `a*b+c` in one operation (faster and more accurate)

```zig
test "fused multiply-add" {
    const a: f64 = 2.0;
    const b: f64 = 3.0;
    const c: f64 = 4.0;

    // Fused operation (one rounding, potentially one instruction)
    const result_fma = @mulAdd(f64, a, b, c); // a*b + c

    // Separate operations (two roundings, two instructions)
    const result_normal = a * b + c;

    // Results may differ slightly due to rounding
    _ = result_fma;
    _ = result_normal;
}
```

## Debug Checklist

When debugging float issues, check:

1. ✅ **Are you comparing with `==`?** Use `approxEqAbs` or `approxEqRel` instead
2. ✅ **Is the result NaN?** Check with `std.math.isNan()` and validate inputs
3. ✅ **Is the result infinity?** Check with `std.math.isInf()` for overflow
4. ✅ **Are you losing precision?** Use `f64` instead of `f32` for large numbers
5. ✅ **Are you using floats for money?** Switch to integer cents
6. ✅ **Are you in optimized mode unintentionally?** Check for `@setFloatMode(.optimized)`
7. ✅ **Is your platform emulating the type?** `f80` on ARM, `f128` everywhere

## When NOT to Use Floats

### ❌ Currency and Financial Calculations
**Problem:** Rounding errors accumulate, leading to incorrect balances
**Solution:** Use integer cents or a decimal library

### ❌ Exact Counters
**Problem:** Floats can't represent all integers above 2²⁴ (f32) or 2⁵³ (f64)
**Solution:** Use integer types (`i32`, `i64`, `u64`, etc.)

### ❌ Hash Table Keys
**Problem:** NaN != NaN, -0.0 and +0.0 have different bits but compare equal
**Solution:** Use integers or strings as keys

### ❌ Security-Sensitive Timing
**Problem:** Float operations can take different times based on values (timing attacks)
**Solution:** Use constant-time integer operations

### ❌ Exact Decimal Representation
**Problem:** 0.1 cannot be exactly represented in binary floating point
**Solution:** Use rational numbers (numerator/denominator) or decimal libraries

## See also

* [@setFloatMode](builtin_functions.md#setFloatMode)
* [Integers](integers.md)
