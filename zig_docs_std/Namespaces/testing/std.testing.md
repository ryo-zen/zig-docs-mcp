# std.testing

📚 **[See Comprehensive Examples & Tests](../../../Examples/testing.tests.zig)** - Complete runnable code demonstrating all testing features

## Quick Start

### Most Common Patterns

**Basic Assertion**
```zig
const std = @import("std");

test "basic assertion" {
    const result = 2 + 2;
    try std.testing.expect(result == 4);
}
```

**Leak Detection with testing.allocator**
```zig
test "memory leak detection" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data);

    // Test passes only if all allocations are freed
}
```

**Equality Assertions**
```zig
test "equality checks" {
    try std.testing.expectEqual(42, 40 + 2);
    try std.testing.expectEqualStrings("hello", "hello");

    const expected = [_]i32{1, 2, 3};
    const actual = [_]i32{1, 2, 3};
    try std.testing.expectEqualSlices(i32, &expected, &actual);
}
```

**Error Testing**
```zig
test "error handling" {
    const result = failingFunction();
    try std.testing.expectError(error.OutOfMemory, result);
}

fn failingFunction() !void {
    return error.OutOfMemory;
}
```

**Floating-Point Precision**
```zig
test "approximate equality" {
    const pi: f64 = 3.14159;
    const approximate: f64 = 3.14;

    // Within absolute tolerance
    try std.testing.expectApproxEqAbs(pi, approximate, 0.01);
}
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Boolean assertion | `expect(bool)` | `try expect(x > 0)` |
| Exact equality | `expectEqual(a, b)` | `try expectEqual(42, result)` |
| Deep equality | `expectEqualDeep(a, b)` | `try expectEqualDeep(struct1, struct2)` |
| String comparison | `expectEqualStrings(a, b)` | `try expectEqualStrings("hi", str)` |
| Slice comparison | `expectEqualSlices(T, a, b)` | `try expectEqualSlices(u8, &exp, &act)` |
| Error checking | `expectError(err, result)` | `try expectError(error.BadInput, result)` |
| Float precision | `expectApproxEqAbs(a, b, tol)` | `try expectApproxEqAbs(3.14, pi, 0.01)` |

### ⚠️ Critical: Always Use `try` with Assertions

```zig
// ❌ WRONG - Test failure won't propagate!
test "bad assertion" {
    std.testing.expect(false); // Does nothing - assertion error ignored!
}

// ✅ CORRECT - Always use `try`
test "good assertion" {
    try std.testing.expect(true); // Properly handles test failure
}
```

---

## Overview

`std.testing` is Zig's built-in testing framework, providing assertion functions, testing allocators, and utilities for writing robust unit tests. It's designed to catch bugs early with automatic leak detection and type-safe assertions.

**Key Characteristics:**
- **Automatic leak detection** - `std.testing.allocator` catches memory leaks without manual tracking
- **Type-safe assertions** - Compile-time validation of assertion arguments
- **Informative failures** - Failed assertions print detailed diagnostics showing exactly what went wrong
- **No dependencies** - Built into the Zig standard library, works everywhere
- **Test isolation** - Each `test` block runs independently
- **Deterministic randomness** - `random_seed` provides reproducible test behavior

**When to use std.testing:**
- Unit testing individual functions and data structures
- Integration testing with memory leak detection
- Testing error paths and edge cases
- Verifying allocator behavior and OOM handling
- Property-based testing with fuzzing utilities

**Related namespaces:**
- `std.debug` - Debug printing and panic utilities
- `std.heap` - Allocator implementations for production use
- `std.mem` - Memory comparison and manipulation

---

## Assertion Functions

### Basic Assertions

#### `pub fn expect(ok: bool) !void`

The fundamental assertion function. Fails the test if the boolean condition is false.

**Parameters:**
- `ok` - Boolean expression to evaluate

**Returns:** `error.TestUnexpectedResult` if `ok` is false

**Example:**
```zig
const std = @import("std");

test "expect - basic boolean assertions" {
    try std.testing.expect(true);
    try std.testing.expect(2 + 2 == 4);
    try std.testing.expect("hello".len == 5);

    const value = 42;
    try std.testing.expect(value > 0);
    try std.testing.expect(value < 100);
}
```

**When to use:** Simple boolean conditions, range checks, basic invariants.

------

### Equality Assertions

#### `pub fn expectEqual(expected: anytype, actual: anytype) !void`

Asserts that two values are exactly equal. Provides detailed diagnostics on failure showing both values.

**Parameters:**
- `expected` - The expected value
- `actual` - The actual value to check

**Returns:** `error.TestExpectedEqual` if values differ

**Behavior:** Uses peer type resolution to coerce `expected` and `actual` to a common type.

**Example:**
```zig
const std = @import("std");

test "expectEqual - exact value comparison" {
    try std.testing.expectEqual(42, 42);
    try std.testing.expectEqual(@as(u32, 100), @as(u32, 100));

    const Point = struct { x: i32, y: i32 };
    try std.testing.expectEqual(Point{.x = 10, .y = 20}, Point{.x = 10, .y = 20});

    // Works with enums
    const Color = enum { red, green, blue };
    try std.testing.expectEqual(Color.red, Color.red);
}
```

**Note:** For deep structural equality (pointers, nested structs), use `expectEqualDeep`.

------

#### `pub fn expectEqualDeep(expected: anytype, actual: anytype) !void`

Recursively compares two values for deep structural equality. Follows pointers and compares pointed-to values.

**Parameters:**
- `expected` - Expected value
- `actual` - Actual value

**Returns:** `error.TestExpectedEqual` if values differ at any level

**Example:**
```zig
const std = @import("std");

test "expectEqualDeep - recursive comparison" {
    const allocator = std.testing.allocator;

    const a = try allocator.create(i32);
    defer allocator.destroy(a);
    a.* = 42;

    const b = try allocator.create(i32);
    defer allocator.destroy(b);
    b.* = 42;

    // Compares pointed-to values, not pointer addresses
    try std.testing.expectEqualDeep(a.*, b.*);

    // Works with nested structures
    const Inner = struct { value: i32 };
    const Outer = struct { inner: Inner, count: usize };

    const expected = Outer{ .inner = Inner{.value = 10}, .count = 5 };
    const actual = Outer{ .inner = Inner{.value = 10}, .count = 5 };

    try std.testing.expectEqualDeep(expected, actual);
}
```

------

#### `pub fn expectEqualSlices(comptime T: type, expected: []const T, actual: []const T) !void`

Compares two slices element-by-element. On failure, highlights differences in red.

**Parameters:**
- `T` - Element type
- `expected` - Expected slice
- `actual` - Actual slice

**Returns:** `error.TestExpectedEqual` if lengths differ or any elements differ

**Example:**
```zig
const std = @import("std");

test "expectEqualSlices - slice comparison" {
    const expected = [_]u8{1, 2, 3, 4, 5};
    const actual = [_]u8{1, 2, 3, 4, 5};

    try std.testing.expectEqualSlices(u8, &expected, &actual);

    // Works with string slices
    const str1: []const u8 = "hello";
    const str2: []const u8 = "hello";
    try std.testing.expectEqualSlices(u8, str1, str2);

    // Fails if lengths differ
    const short = [_]u8{1, 2};
    const long = [_]u8{1, 2, 3};
    // try std.testing.expectEqualSlices(u8, &short, &long); // Would fail
}
```

------

#### `pub fn expectEqualSentinel(comptime T: type, comptime sentinel: T, expected: [:sentinel]const T, actual: [:sentinel]const T) !void`

Compares two sentinel-terminated slices, including verifying the sentinel value.

**Parameters:**
- `T` - Element type
- `sentinel` - Sentinel value (e.g., `0` for null-terminated strings)
- `expected` - Expected sentinel-terminated slice
- `actual` - Actual sentinel-terminated slice

**Example:**
```zig
const std = @import("std");

test "expectEqualSentinel - null-terminated comparison" {
    const str1: [:0]const u8 = "hello";
    const str2: [:0]const u8 = "hello";

    try std.testing.expectEqualSentinel(u8, 0, str1, str2);

    // Custom sentinel
    const data1: [4:255]u8 = [_:255]u8{1, 2, 3, 4};
    const data2: [4:255]u8 = [_:255]u8{1, 2, 3, 4};
    try std.testing.expectEqualSentinel(u8, 255, &data1, &data2);
}
```

------

#### `pub fn expectEqualStrings(expected: []const u8, actual: []const u8) !void`

Specialized string comparison with helpful diagnostics for string mismatches.

**Parameters:**
- `expected` - Expected string
- `actual` - Actual string

**Returns:** `error.TestExpectedEqual` if strings differ

**Example:**
```zig
const std = @import("std");

test "expectEqualStrings - string comparison" {
    try std.testing.expectEqualStrings("hello", "hello");

    const allocator = std.testing.allocator;
    const dynamic = try allocator.dupe(u8, "world");
    defer allocator.free(dynamic);

    try std.testing.expectEqualStrings("world", dynamic);

    // Empty strings
    try std.testing.expectEqualStrings("", "");
}
```

**Note:** Prefer this over `expectEqualSlices(u8, ...)` for strings - provides better error messages.

------

### Error Assertions

#### `pub fn expectError(expected_error: anyerror, actual_error_union: anytype) !void`

Asserts that an error union contains a specific error. Fails if the error union is a success value or contains a different error.

**Parameters:**
- `expected_error` - The error expected
- `actual_error_union` - Error union to check (e.g., result of a function call)

**Returns:** `error.TestUnexpectedResult` if the error doesn't match

**Example:**
```zig
const std = @import("std");

fn dividePositive(a: i32, b: i32) !i32 {
    if (b == 0) return error.DivisionByZero;
    if (a < 0 or b < 0) return error.NegativeInput;
    return @divTrunc(a, b);
}

test "expectError - error path testing" {
    // Verify specific errors are returned
    try std.testing.expectError(error.DivisionByZero, dividePositive(10, 0));
    try std.testing.expectError(error.NegativeInput, dividePositive(-5, 2));

    // Success case (no error)
    const result = try dividePositive(10, 2);
    try std.testing.expectEqual(5, result);
}
```

**Common use:** Testing error handling paths, validating input validation.

------

### Numeric Assertions

#### `pub fn expectApproxEqAbs(expected: anytype, actual: anytype, tolerance: anytype) !void`

Asserts that two floating-point numbers are equal within an absolute tolerance.

**Parameters:**
- `expected` - Expected value (float type)
- `actual` - Actual value (float type)
- `tolerance` - Maximum absolute difference allowed

**Formula:** `|expected - actual| <= tolerance`

**Example:**
```zig
const std = @import("std");

test "expectApproxEqAbs - absolute tolerance" {
    const pi: f64 = 3.14159;
    const approximate: f64 = 3.14;

    // Within 0.01 absolute difference
    try std.testing.expectApproxEqAbs(pi, approximate, 0.01);

    // Scientific calculations
    const e: f64 = 2.71828;
    const measured: f64 = 2.72;
    try std.testing.expectApproxEqAbs(e, measured, 0.01);

    // Works with f32, f64, f16, f128
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), @as(f32, 1.0001), @as(f32, 0.001));
}
```

**When to use:** Physics simulations, geometry calculations, when absolute error is meaningful.

------

#### `pub fn expectApproxEqRel(expected: anytype, actual: anytype, tolerance: anytype) !void`

Asserts that two floating-point numbers are equal within a relative tolerance (percentage).

**Parameters:**
- `expected` - Expected value (float type)
- `actual` - Actual value (float type)
- `tolerance` - Maximum relative difference (as a fraction, e.g., 0.01 for 1%)

**Formula:** `|expected - actual| / |expected| <= tolerance`

**Example:**
```zig
const std = @import("std");

test "expectApproxEqRel - relative tolerance" {
    // 1% relative tolerance
    try std.testing.expectApproxEqRel(@as(f64, 100.0), @as(f64, 101.0), @as(f64, 0.02));

    // Good for large numbers
    const big: f64 = 1_000_000.0;
    const measured: f64 = 1_000_500.0;
    try std.testing.expectApproxEqRel(big, measured, 0.001); // 0.1% tolerance

    // Small numbers
    const small: f64 = 0.001;
    const measured_small: f64 = 0.00101;
    try std.testing.expectApproxEqRel(small, measured_small, 0.02);
}
```

**When to use:** When precision requirements scale with magnitude (financial calculations, scientific data).

------

### String Assertions

#### `pub fn expectStringStartsWith(actual: []const u8, expected_starts_with: []const u8) !void`

Asserts that a string starts with a specific prefix.

**Parameters:**
- `actual` - String to check
- `expected_starts_with` - Expected prefix

**Example:**
```zig
const std = @import("std");

test "expectStringStartsWith - prefix checking" {
    try std.testing.expectStringStartsWith("hello world", "hello");
    try std.testing.expectStringStartsWith("README.md", "README");

    const path = "/usr/local/bin/zig";
    try std.testing.expectStringStartsWith(path, "/usr");
}
```

------

#### `pub fn expectStringEndsWith(actual: []const u8, expected_ends_with: []const u8) !void`

Asserts that a string ends with a specific suffix.

**Parameters:**
- `actual` - String to check
- `expected_ends_with` - Expected suffix

**Example:**
```zig
const std = @import("std");

test "expectStringEndsWith - suffix checking" {
    try std.testing.expectStringEndsWith("hello world", "world");
    try std.testing.expectStringEndsWith("test.zig", ".zig");

    const filename = "document.pdf";
    try std.testing.expectStringEndsWith(filename, ".pdf");
}
```

------

#### `pub fn expectFmt(expected: []const u8, comptime template: []const u8, args: anytype) !void`

Asserts that formatting a template with arguments produces an expected string.

**Parameters:**
- `expected` - Expected formatted result
- `template` - Format string (comptime)
- `args` - Tuple of arguments

**Example:**
```zig
const std = @import("std");

test "expectFmt - formatted string testing" {
    try std.testing.expectFmt("Value: 42", "Value: {d}", .{42});
    try std.testing.expectFmt("Hello, Alice!", "Hello, {s}!", .{"Alice"});

    const Point = struct { x: i32, y: i32 };
    const p = Point{ .x = 10, .y = 20 };
    // In Zig 0.16, {any} format changed to use .{ } notation
    try std.testing.expectFmt(".{ .x = 10, .y = 20 }", "{any}", .{p});
}
```

------

## Testing Resources

### `allocator` - General Purpose Allocator with Leak Detection

A `GeneralPurposeAllocator` instance configured for testing with automatic leak detection and safety checks.

**Type:** `std.mem.Allocator`

**Features:**
- **Automatic leak detection** - Detects memory leaks at program exit
- **Double-free detection** - Catches attempts to free memory twice
- **Use-after-free detection** - Can catch some use-after-free bugs
- **Stack traces** - Shows allocation stack traces on leak (when available)

**Example:**
```zig
const std = @import("std");

test "testing.allocator - automatic leak detection" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(u8, 1024);
    defer allocator.free(data); // Test fails if this is removed!

    data[0] = 42;
    try std.testing.expectEqual(@as(u8, 42), data[0]);
}

test "testing.allocator - create and destroy" {
    const allocator = std.testing.allocator;

    const Point = struct { x: i32, y: i32 };
    const p = try allocator.create(Point);
    defer allocator.destroy(p);

    p.* = Point{.x = 10, .y = 20};
    try std.testing.expectEqual(@as(i32, 10), p.x);
}
```

**Critical:** This is the *recommended allocator for all tests*. It catches memory management bugs automatically.

------

### `failing_allocator` - Simulated OOM Allocator

An allocator that *always* returns `error.OutOfMemory`. Used for testing error paths without exhausting system memory.

**Type:** `std.mem.Allocator`

**Use case:** Verify that your code handles allocation failures gracefully.

**Example:**
```zig
const std = @import("std");

fn processData(allocator: std.mem.Allocator) ![]u8 {
    const buffer = try allocator.alloc(u8, 100);
    // ... process ...
    return buffer;
}

test "failing_allocator - OOM handling" {
    const result = processData(std.testing.failing_allocator);

    // Should return OutOfMemory error
    try std.testing.expectError(error.OutOfMemory, result);
}
```

**Warning:** Never actually *use* this allocator for real allocations - it always fails!

------

### `io` - Testing IO Interface

A `std.Io.Threaded` instance for testing IO operations.

**Type:** `std.Io.Threaded`

**Use case:** Testing code that requires IO operations in a controlled environment.

**Example:**
```zig
const std = @import("std");

test "testing.io - basic usage" {
    const io = std.testing.io;
    // Use for socket, file, and stream testing
}
```

------

### `environ` - Testing Environment Variables

A test environment variable container.

**Type:** `Environ`

**Use case:** Isolated environment for testing code that reads environment variables.

------

### `random_seed` - Deterministic Random Seed

A fixed random seed for reproducible randomness in tests.

**Type:** `u32`

**Use case:** Ensure tests are deterministic and reproducible across runs.

**Example:**
```zig
const std = @import("std");

test "random_seed - deterministic randomness" {
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    const random = prng.random();

    const value = random.int(u32);
    // Same seed produces same sequence across test runs
}
```

------

### `backend_can_print` - Print Capability Detection

Boolean indicating whether the test backend supports printing.

**Type:** `bool`

**Use case:** Conditionally enable verbose logging in tests.

------

## Utility Functions

### `pub fn checkAllAllocationFailures(backing_allocator: std.mem.Allocator, comptime test_fn: anytype, extra_args: anytype) !void`

Exhaustively tests a function under all possible allocation failure scenarios. Runs `test_fn` repeatedly, failing one allocation at a time, ensuring no memory leaks occur.

**Parameters:**
- `backing_allocator` - Allocator to track (typically `std.testing.allocator`)
- `test_fn` - Function to test (must accept `Allocator` as first parameter)
- `extra_args` - Additional arguments to pass to `test_fn`

**Example:**
```zig
const std = @import("std");

fn createAndFill(allocator: std.mem.Allocator, size: usize) ![]u8 {
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    for (buffer, 0..) |*byte, i| {
  byte.* = @intCast(i % 256);
    }

    return buffer;
}

test "checkAllAllocationFailures - exhaustive OOM testing" {
    try std.testing.checkAllAllocationFailures(
  std.testing.allocator,
  createAndFill,
  .{10}
    );
}
```

**Use case:** Critical codepaths where allocation failure must not leak memory.

------

### `pub fn fuzz(context: anytype, comptime testOne: fn(@TypeOf(context), []const u8) anyerror!void, options: FuzzInputOptions) !void`

Inline fuzzing utility for property-based testing with random inputs.

**Parameters:**
- `context` - Context passed to each test iteration
- `testOne` - Function to run for each fuzz input
- `options` - Fuzzing options (seed, iteration count, etc.)

**Example:**
```zig
const std = @import("std");

fn parseNonNegative(input: []const u8) !u32 {
    const value = try std.fmt.parseInt(i32, input, 10);
    if (value < 0) return error.NegativeValue;
    return @intCast(value);
}

test "fuzz - property-based testing" {
    const Context = struct {};

    try std.testing.fuzz(Context{}, struct {
  fn testOne(ctx: Context, input: []const u8) !void {
      _ = ctx;
      // Test that parsing never crashes
      _ = parseNonNegative(input) catch {};
  }
    }.testOne, .{});
}
```

------

### `pub fn tmpDir(opts: std.Io.Dir.OpenOptions) TmpDir`

Creates a temporary directory for testing. Automatically cleaned up.

**Parameters:**
- `opts` - Directory opening options

**Returns:** `TmpDir` handle with `dir` field and `cleanup()` method

**Example:**
```zig
const std = @import("std");

test "tmpDir - temporary file testing" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const io = std.testing.io;

    // Create file in temp directory
    var file = try tmp.dir.createFile(io, "test.txt", .{});
    defer file.close(io);

    var buffer: [1024]u8 = undefined;
    var writer = file.writer(io, &buffer);
    try writer.interface.writeAll("Hello, test!");
    try writer.interface.flush();

    // Temp dir is automatically deleted on cleanup
}
```

------

### `pub fn refAllDecls(comptime T: type) void`

Forces the semantic analyzer to process all declarations in a type. Used to ensure APIs are complete and error-free.

**Parameters:**
- `T` - Type to reference

**Example:**
```zig
const std = @import("std");

const MyLib = struct {
    pub fn foo() void {}
    pub fn bar() void {}
    // ... many functions
};

test "refAllDecls - API completeness check" {
    // Ensures all functions in MyLib compile
    std.testing.refAllDecls(MyLib);
}
```

**Use case:** Library testing - ensure public API compiles even if not directly called.

------

## Usage Patterns

### Pattern 1: Basic Unit Test with Assertions

```zig
const std = @import("std");

fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

test "arithmetic functions" {
    // Basic equality
    try std.testing.expectEqual(@as(i32, 5), add(2, 3));
    try std.testing.expectEqual(@as(i32, 6), multiply(2, 3));

    // Boolean conditions
    try std.testing.expect(add(10, 20) > 0);
    try std.testing.expect(multiply(-2, 3) < 0);

    // Edge cases
    try std.testing.expectEqual(@as(i32, 0), add(0, 0));
    try std.testing.expectEqual(@as(i32, 0), multiply(100, 0));
}
```

------

### Pattern 2: Testing Memory Management with Leak Detection

```zig
const std = @import("std");

const Buffer = struct {
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize) !Buffer {
  const data = try allocator.alloc(u8, size);
  return Buffer{
      .data = data,
      .allocator = allocator,
  };
    }

    pub fn deinit(self: *Buffer) void {
  self.allocator.free(self.data);
    }
};

test "Buffer - memory management" {
    const allocator = std.testing.allocator;

    var buffer = try Buffer.init(allocator, 1024);
    defer buffer.deinit();

    // Use buffer
    buffer.data[0] = 42;
    try std.testing.expectEqual(@as(u8, 42), buffer.data[0]);

    // Test passes only if deinit() frees all memory
}
```

------

### Pattern 3: Testing Error Paths with OOM Simulation

```zig
const std = @import("std");

const ArrayList = struct {
    items: []i32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize) !ArrayList {
  const items = try allocator.alloc(i32, size);
  return ArrayList{
      .items = items,
      .allocator = allocator,
  };
    }

    pub fn deinit(self: *ArrayList) void {
  self.allocator.free(self.items);
    }
};

test "ArrayList - OOM handling" {
    // Verify allocation failure is handled gracefully
    const result = ArrayList.init(std.testing.failing_allocator, 10);
    try std.testing.expectError(error.OutOfMemory, result);

    // Verify success case works
    const allocator = std.testing.allocator;
    var list = try ArrayList.init(allocator, 10);
    defer list.deinit();

    try std.testing.expectEqual(@as(usize, 10), list.items.len);
}
```

------

### Pattern 4: Testing with Temporary Files

```zig
const std = @import("std");

fn writeConfig(dir: std.Io.Dir, io: std.Io, filename: []const u8, content: []const u8) !void {
    var file = try dir.createFile(io, filename, .{});
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var writer = file.writer(io, &buffer);
    try writer.interface.writeAll(content);
    try writer.interface.flush();
}

fn readConfig(dir: std.Io.Dir, io: std.Io, filename: []const u8, buffer: []u8) ![]u8 {
    var file = try dir.openFile(io, filename, .{});
    defer file.close(io);

    var read_buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &read_buffer);

    // Read entire file content
    const content = try reader.interface.allocRemaining(std.testing.allocator, .unlimited);
    defer std.testing.allocator.free(content);

    @memcpy(buffer[0..content.len], content);
    return buffer[0..content.len];
}

test "config file I/O" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const io = std.testing.io;

    // Write config
    const config = "setting=value";
    try writeConfig(tmp.dir, io, "config.txt", config);

    // Read config
    var buffer: [1024]u8 = undefined;
    const read_data = try readConfig(tmp.dir, io, "config.txt", &buffer);

    try std.testing.expectEqualStrings(config, read_data);
}
```

------

### Pattern 5: Exhaustive Allocation Failure Testing

```zig
const std = @import("std");

fn buildMessage(allocator: std.mem.Allocator, name: []const u8, count: usize) ![]u8 {
    return std.fmt.allocPrint(allocator, "Hello, {s}! Count: {d}", .{name, count});
}

fn testBuildMessage(allocator: std.mem.Allocator, name: []const u8, count: usize) !void {
    const msg = try buildMessage(allocator, name, count);
    defer allocator.free(msg);

    // Verify format
    try std.testing.expect(msg.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, msg, name) != null);
}

test "buildMessage - exhaustive OOM testing" {
    // Tests all allocation failure points
    try std.testing.checkAllAllocationFailures(
  std.testing.allocator,
  testBuildMessage,
  .{"Alice", 42}
    );
}
```

------

## Types

### `FailingAllocator`

An allocator implementation that always fails with `error.OutOfMemory`. Used via `std.testing.failing_allocator`.

**Methods:**
- All standard `Allocator` methods (always return `error.OutOfMemory`)

**Use case:** Testing OOM error paths.

------

### `FuzzInputOptions`

Configuration for fuzzing operations.

**Fields:**
- `seed: ?u32` - Random seed (null for default)
- `max_iterations: ?usize` - Maximum fuzz iterations

------

### `TmpDir`

Handle to a temporary directory created by `tmpDir()`.

**Fields:**
- `dir: std.fs.Dir` - Directory handle

**Methods:**
- `cleanup() void` - Removes the temporary directory

------

### `Reader` / `ReaderIndirect`

Testing reader types for IO testing.

------

## Error Sets

### `TestUnexpectedResult`
- `error.TestUnexpectedResult` - Generic test failure (from `expect`)

### `TestExpectedEqual`
- `error.TestExpectedEqual` - Values are not equal (from `expectEqual`, `expectEqualStrings`, etc.)

------

## Debug Checklist

✅ **Always use `try` with assertions** - Without `try`, assertion failures are silently ignored

✅ **Free all allocations when using `testing.allocator`** - Tests fail automatically on memory leaks

✅ **Don't use `failing_allocator` for real allocations** - It always returns `error.OutOfMemory`

✅ **Use `defer` immediately after allocation** - Ensures cleanup even if test fails early

✅ **Prefer `expectEqual` over `expect(a == b)`** - Better error messages showing both values

✅ **Use `expectEqualStrings` for strings** - More informative than generic slice comparison

✅ **Test both success and error paths** - Use `expectError` to verify error conditions

✅ **Use `expectApproxEqAbs/Rel` for floats** - Never use exact equality for floating-point

✅ **Isolate tests with scoped blocks** - Prevent variable name collisions in test files

✅ **Use `tmpDir` for file I/O tests** - Automatic cleanup prevents leftover test files

------

## Performance Tips

1. **Prefer `testing.allocator` in all tests** - The overhead is negligible and catches critical bugs. Don't optimize away safety in tests.

2. **Use `FixedBufferAllocator` for performance-critical test benchmarks** - When measuring performance, eliminate allocator variance:
   ```zig
   var buffer: [4096]u8 = undefined;
   var fba = std.heap.FixedBufferAllocator.init(&buffer);
   const allocator = fba.allocator();
   ```

3. **Batch related tests** - Group setup/teardown for related tests to amortize initialization cost:
   ```zig
   test "batch operations" {
 const allocator = std.testing.allocator;

 // Test 1
 {
     const data = try allocator.alloc(u8, 100);
     defer allocator.free(data);
     // ... test ...
 }

 // Test 2
 {
     const data = try allocator.alloc(u8, 200);
     defer allocator.free(data);
     // ... test ...
 }
   }
   ```

4. **Use `refAllDecls` once per module** - Don't call it in every test - one test per module is sufficient:
   ```zig
   test "API completeness" {
 std.testing.refAllDecls(@This());
   }
   ```

5. **Limit `checkAllAllocationFailures` to critical paths** - Exhaustive OOM testing is thorough but slow. Use it for security-critical or frequently-used allocating functions, not every function.

6. **Avoid `expectEqualDeep` when `expectEqual` suffices** - Deep comparison has overhead for pointer-chasing. Use it only when comparing nested/pointer-containing structures.

7. **Reuse `tmpDir` across multiple file operations** - Creating temp directories has filesystem overhead:
   ```zig
   var tmp = std.testing.tmpDir(.{});
   defer tmp.cleanup();

   // Multiple file operations in same temp dir
   try tmp.dir.createFile("file1.txt", .{});
   try tmp.dir.createFile("file2.txt", .{});
   ```

------

## See Also

- **std.debug** - Debug printing (`std.debug.print`), panic handling, assertion utilities
- **std.heap** - Production allocators (GeneralPurposeAllocator, ArenaAllocator, etc.)
- **std.mem** - Memory comparison (`eql`, `eqlBytes`), utilities for working with slices
- **std.fmt** - String formatting used by assertion diagnostics
- **std.Random** - Random number generation (use with `testing.random_seed` for determinism)
