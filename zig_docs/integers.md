# Integers

## [Integer Literals](#toc-Integer-Literals) §

      integer_literals.zig
```zig
const decimal_int = 98222;
const hex_int = 0xff;
const another_hex_int = 0xFF;
const octal_int = 0o755;
const binary_int = 0b11110000;

// underscores may be placed between two digits as a visual separator
const one_billion = 1_000_000_000;
const binary_mask = 0b1_1111_1111;
const permissions = 0o7_5_5;
const big_address = 0xFF80_0000_0000_0000;
```

      
      
## [Runtime Integer Values](#toc-Runtime-Integer-Values) §

      

      Integer literals have no size limitation, and if any Illegal Behavior occurs,
      the compiler catches it.
      

      

      However, once an integer value is no longer known at compile-time, it must have a
      known size, and is vulnerable to safety-checked [Illegal Behavior](#Illegal-Behavior).
      

      runtime_vs_comptime.zig
```zig
fn divide(a: i32, b: i32) i32 {
    return a / b;
}
```

      

      In this function, values `a` and `b` are known only at runtime,
      and thus this division operation is vulnerable to both [Integer Overflow](#Integer-Overflow) and
      [Division by Zero](#Division-by-Zero).
      

      

      Operators such as `+` and `-` cause [Illegal Behavior](#Illegal-Behavior) on
      integer overflow. Alternative operators are provided for wrapping and saturating arithmetic on all targets.
      `+%` and `-%` perform wrapping arithmetic
      while `+|` and `-|` perform saturating arithmetic.
      

      

      Zig supports arbitrary bit-width integers, referenced by using
      an identifier of `i` or `u` followed by digits. For example, the identifier
      `i7` refers to a signed 7-bit integer. The maximum allowed bit-width of an
      integer type is `65535`. For signed integer types, Zig uses a
      [two's complement](https://en.wikipedia.org/wiki/Two's_complement) representation.
      

      

See also:

- [Wrapping Operations](#Wrapping-Operations)
## [Integer Overflow Detection and Validation](#toc-Integer-Overflow-Detection) §

Zig provides comprehensive **runtime safety checking** and **compile-time validation** for integer overflow operations. This built-in overflow checking helps prevent security vulnerabilities and logic errors.

### Safety-Checked Overflow Detection

By default in Debug and ReleaseSafe modes, Zig automatically inserts runtime safety checks for integer overflow. When overflow is detected, the program panics with a clear error message:

      overflow_detection.zig
```zig
const std = @import("std");

pub fn main() void {
    var x: u8 = 255;
    x += 1; // Runtime panic: integer overflow
}
```

**Validation Modes:**
- **Debug mode** (default): All integer overflow checking enabled
- **ReleaseSafe**: Integer overflow checking enabled, optimized
- **ReleaseFast**: Overflow checking disabled for performance
- **ReleaseSmall**: Overflow checking disabled for size

### Compile-Time Overflow Validation

At compile-time, Zig can validate and catch integer overflow in comptime expressions:

      comptime_overflow_validation.zig
```zig
const value = @as(u8, 200) + 100; // Compile error: overflow of integer type 'u8' with value '300'
```

This compile-time validation ensures that overflow bugs are caught before the program runs.

### Wrapping Arithmetic (No Checking)

Use wrapping operators when you intentionally want overflow to wrap around without safety checks:

      wrapping_arithmetic.zig
```zig
const std = @import("std");

test "wrapping arithmetic" {
    var x: u8 = 255;
    x +%= 1; // Wraps to 0, no panic
    try std.testing.expect(x == 0);
}
```

**Wrapping operators:** `+%`, `-%`, `*%`, `+%=`, `-%=`, `*%=`

### Saturating Arithmetic (No Checking)

Use saturating operators when you want overflow to clamp at type limits:

      saturating_arithmetic.zig
```zig
const std = @import("std");

test "saturating arithmetic" {
    var x: u8 = 255;
    x +|= 1; // Saturates at 255, no panic
    try std.testing.expect(x == 255);
}
```

**Saturating operators:** `+|`, `-|`, `*|`, `+|=`, `-|=`, `*|=`

### Explicit Overflow Checking with Builtins

For fine-grained control, use builtin functions that return overflow status:

      explicit_overflow_checking.zig
```zig
const std = @import("std");

test "explicit overflow checking" {
    const a: u8 = 200;
    const b: u8 = 100;

    const result = @addWithOverflow(a, b);
    // result[0] = wrapped value (44)
    // result[1] = overflow bit (1 if overflow occurred)

    if (result[1] != 0) {
        std.debug.print("Overflow detected!\n", .{});
    }
}
```

**Overflow detection builtins:**
- `@addWithOverflow(a, b)` - Addition with overflow flag
- `@subWithOverflow(a, b)` - Subtraction with overflow flag
- `@mulWithOverflow(a, b)` - Multiplication with overflow flag
- `@shlWithOverflow(a, b)` - Left shift with overflow flag

### Controlling Runtime Safety Checks

Use `@setRuntimeSafety` to enable or disable overflow checking for specific code blocks:

      runtime_safety_control.zig
```zig
const std = @import("std");

test "controlling overflow checks" {
    // Overflow checking enabled (default in Debug)
    var x: u8 = 255;

    @setRuntimeSafety(false);
    x += 1; // No panic, wraps to 0
    @setRuntimeSafety(true);

    try std.testing.expect(x == 0);
}
```

### Best Practices for Integer Safety

1. **Default to safety checks**: Keep overflow checking enabled during development
2. **Use wrapping/saturating operators explicitly**: Make overflow behavior clear in code
3. **Validate inputs**: Check ranges before operations when possible
4. **Test edge cases**: Include tests with maximum/minimum integer values
5. **Profile before disabling**: Only disable safety checks after measuring performance impact

See also:

- [Illegal Behavior](#Illegal-Behavior)
- [Builtin Functions](#Builtin-Functions)
- [@setRuntimeSafety](#setRuntimeSafety)
- [@addWithOverflow](#addWithOverflow)
