// Comprehensive tests for std.testing namespace documentation
// This file validates all examples from zig_docs_std/Namespaces/testing/std.testing.md
//
// Run with: zig test Examples/testing.tests.zig
//
// Organization: Tests follow documentation order
// - Quick Start examples
// - Assertion function examples
// - Testing resource examples
// - Utility function examples
// - Usage pattern examples

const std = @import("std");

// ============================================================================
// Quick Start Examples
// ============================================================================

test "Quick Start - basic assertion" {
    const result = 2 + 2;
    try std.testing.expect(result == 4);
}

test "Quick Start - leak detection with testing.allocator" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data);

    // Test passes only if all allocations are freed
}

test "Quick Start - equality checks" {
    try std.testing.expectEqual(42, 40 + 2);
    try std.testing.expectEqualStrings("hello", "hello");

    const expected = [_]i32{ 1, 2, 3 };
    const actual = [_]i32{ 1, 2, 3 };
    try std.testing.expectEqualSlices(i32, &expected, &actual);
}

fn failingFunction() !void {
    return error.OutOfMemory;
}

test "Quick Start - error handling" {
    const result = failingFunction();
    try std.testing.expectError(error.OutOfMemory, result);
}

test "Quick Start - floating-point precision" {
    const pi: f64 = 3.14159;
    const approximate: f64 = 3.14;

    // Within absolute tolerance
    try std.testing.expectApproxEqAbs(pi, approximate, 0.01);
}

// ============================================================================
// Basic Assertions - expect
// ============================================================================

test "expect - basic boolean assertions" {
    try std.testing.expect(true);
    try std.testing.expect(2 + 2 == 4);
    try std.testing.expect("hello".len == 5);

    const value = 42;
    try std.testing.expect(value > 0);
    try std.testing.expect(value < 100);
}

// ============================================================================
// Equality Assertions
// ============================================================================

test "expectEqual - exact value comparison" {
    try std.testing.expectEqual(42, 42);
    try std.testing.expectEqual(@as(u32, 100), @as(u32, 100));

    const Point = struct { x: i32, y: i32 };
    try std.testing.expectEqual(Point{ .x = 10, .y = 20 }, Point{ .x = 10, .y = 20 });

    // Works with enums
    const Color = enum { red, green, blue };
    try std.testing.expectEqual(Color.red, Color.red);
}

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

    const expected = Outer{ .inner = Inner{ .value = 10 }, .count = 5 };
    const actual = Outer{ .inner = Inner{ .value = 10 }, .count = 5 };

    try std.testing.expectEqualDeep(expected, actual);
}

test "expectEqualSlices - slice comparison" {
    const expected = [_]u8{ 1, 2, 3, 4, 5 };
    const actual = [_]u8{ 1, 2, 3, 4, 5 };

    try std.testing.expectEqualSlices(u8, &expected, &actual);

    // Works with string slices
    const str1: []const u8 = "hello";
    const str2: []const u8 = "hello";
    try std.testing.expectEqualSlices(u8, str1, str2);
}

test "expectEqualSentinel - null-terminated comparison" {
    const str1: [:0]const u8 = "hello";
    const str2: [:0]const u8 = "hello";

    try std.testing.expectEqualSentinel(u8, 0, str1, str2);

    // Custom sentinel
    const data1: [4:255]u8 = [_:255]u8{ 1, 2, 3, 4 };
    const data2: [4:255]u8 = [_:255]u8{ 1, 2, 3, 4 };
    try std.testing.expectEqualSentinel(u8, 255, &data1, &data2);
}

test "expectEqualStrings - string comparison" {
    try std.testing.expectEqualStrings("hello", "hello");

    const allocator = std.testing.allocator;
    const dynamic = try allocator.dupe(u8, "world");
    defer allocator.free(dynamic);

    try std.testing.expectEqualStrings("world", dynamic);

    // Empty strings
    try std.testing.expectEqualStrings("", "");
}

// ============================================================================
// Error Assertions
// ============================================================================

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

// ============================================================================
// Numeric Assertions
// ============================================================================

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

// ============================================================================
// String Assertions
// ============================================================================

test "expectStringStartsWith - prefix checking" {
    try std.testing.expectStringStartsWith("hello world", "hello");
    try std.testing.expectStringStartsWith("README.md", "README");

    const path = "/usr/local/bin/zig";
    try std.testing.expectStringStartsWith(path, "/usr");
}

test "expectStringEndsWith - suffix checking" {
    try std.testing.expectStringEndsWith("hello world", "world");
    try std.testing.expectStringEndsWith("test.zig", ".zig");

    const filename = "document.pdf";
    try std.testing.expectStringEndsWith(filename, ".pdf");
}

test "expectFmt - formatted string testing" {
    try std.testing.expectFmt("Value: 42", "Value: {d}", .{42});
    try std.testing.expectFmt("Hello, Alice!", "Hello, {s}!", .{"Alice"});

    const Point = struct { x: i32, y: i32 };
    const p = Point{ .x = 10, .y = 20 };
    // In Zig 0.16, {any} format changed to use .{ } notation
    try std.testing.expectFmt(".{ .x = 10, .y = 20 }", "{any}", .{p});
}

// ============================================================================
// Testing Resources
// ============================================================================

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

    p.* = Point{ .x = 10, .y = 20 };
    try std.testing.expectEqual(@as(i32, 10), p.x);
}

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

test "random_seed - deterministic randomness" {
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    const random = prng.random();

    const value = random.int(u32);
    // Same seed produces same sequence across test runs
    _ = value;
}

// ============================================================================
// Utility Functions
// ============================================================================

fn createAndFill(allocator: std.mem.Allocator, size: usize) ![]u8 {
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    for (buffer, 0..) |*byte, i| {
        byte.* = @intCast(i % 256);
    }

    return buffer;
}

test "checkAllAllocationFailures - exhaustive OOM testing" {
    // Helper wrapper that frees the result
    const TestWrapper = struct {
        fn testCreateAndFill(allocator: std.mem.Allocator, size: usize) !void {
            const buffer = try createAndFill(allocator, size);
            defer allocator.free(buffer);

            // Verify buffer was filled correctly
            if (buffer.len > 0) {
                try std.testing.expectEqual(@as(u8, 0), buffer[0]);
            }
        }
    };

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        TestWrapper.testCreateAndFill,
        .{10},
    );
}

fn parseNonNegative(input: []const u8) !u32 {
    const value = try std.fmt.parseInt(i32, input, 10);
    if (value < 0) return error.NegativeValue;
    return @intCast(value);
}

test "fuzz - property-based testing" {
    const Context = struct {};

    try std.testing.fuzz(Context{}, struct {
        fn testOne(ctx: Context, smith: *std.testing.Smith) !void {
            _ = ctx;
            var buffer: [64]u8 = undefined;
            const input = buffer[0..smith.slice(&buffer)];
            // Test that parsing never crashes
            _ = parseNonNegative(input) catch {};
        }
    }.testOne, .{});
}

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

test "refAllDecls - API completeness check" {
    const MyLib = struct {
        pub fn foo() void {}
        pub fn bar() void {}
        // ... many functions
    };

    // Ensures all functions in MyLib compile
    std.testing.refAllDecls(MyLib);
}

// ============================================================================
// Usage Patterns
// ============================================================================

// Pattern 1: Basic Unit Test with Assertions

fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

test "Usage Pattern 1 - arithmetic functions" {
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

// Pattern 2: Testing Memory Management with Leak Detection

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

test "Usage Pattern 2 - Buffer memory management" {
    const allocator = std.testing.allocator;

    var buffer = try Buffer.init(allocator, 1024);
    defer buffer.deinit();

    // Use buffer
    buffer.data[0] = 42;
    try std.testing.expectEqual(@as(u8, 42), buffer.data[0]);

    // Test passes only if deinit() frees all memory
}

// Pattern 3: Testing Error Paths with OOM Simulation

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

test "Usage Pattern 3 - ArrayList OOM handling" {
    // Verify allocation failure is handled gracefully
    const result = ArrayList.init(std.testing.failing_allocator, 10);
    try std.testing.expectError(error.OutOfMemory, result);

    // Verify success case works
    const allocator = std.testing.allocator;
    var list = try ArrayList.init(allocator, 10);
    defer list.deinit();

    try std.testing.expectEqual(@as(usize, 10), list.items.len);
}

// Pattern 4: Testing with Temporary Files

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

test "Usage Pattern 4 - config file I/O" {
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

// Pattern 5: Exhaustive Allocation Failure Testing

fn buildMessage(allocator: std.mem.Allocator, name: []const u8, count: usize) ![]u8 {
    return std.fmt.allocPrint(allocator, "Hello, {s}! Count: {d}", .{ name, count });
}

fn testBuildMessage(allocator: std.mem.Allocator, name: []const u8, count: usize) !void {
    const msg = try buildMessage(allocator, name, count);
    defer allocator.free(msg);

    // Verify format
    try std.testing.expect(msg.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, msg, name) != null);
}

test "Usage Pattern 5 - buildMessage exhaustive OOM testing" {
    // Tests all allocation failure points
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testBuildMessage,
        .{ "Alice", 42 },
    );
}

// ============================================================================
// Additional Coverage Tests
// ============================================================================

test "testing.allocator - multiple allocations" {
    const allocator = std.testing.allocator;

    const data1 = try allocator.alloc(u8, 100);
    defer allocator.free(data1);

    const data2 = try allocator.alloc(u8, 200);
    defer allocator.free(data2);

    const data3 = try allocator.alloc(u8, 50);
    defer allocator.free(data3);

    // All must be freed or test fails
}

test "expectEqual - various numeric types" {
    try std.testing.expectEqual(@as(u8, 255), @as(u8, 255));
    try std.testing.expectEqual(@as(i8, -128), @as(i8, -128));
    try std.testing.expectEqual(@as(u16, 65535), @as(u16, 65535));
    try std.testing.expectEqual(@as(i32, -42), @as(i32, -42));
    try std.testing.expectEqual(@as(usize, 1000), @as(usize, 1000));
}

test "expectEqualSlices - different element types" {
    // u8 slices
    const u8_exp = [_]u8{ 10, 20, 30 };
    const u8_act = [_]u8{ 10, 20, 30 };
    try std.testing.expectEqualSlices(u8, &u8_exp, &u8_act);

    // i32 slices
    const i32_exp = [_]i32{ -1, 0, 1 };
    const i32_act = [_]i32{ -1, 0, 1 };
    try std.testing.expectEqualSlices(i32, &i32_exp, &i32_act);

    // f64 slices
    const f64_exp = [_]f64{ 1.0, 2.0, 3.0 };
    const f64_act = [_]f64{ 1.0, 2.0, 3.0 };
    try std.testing.expectEqualSlices(f64, &f64_exp, &f64_act);
}

test "expectApproxEqAbs - edge cases" {
    // Zero tolerance (exact equality)
    try std.testing.expectApproxEqAbs(@as(f64, 1.0), @as(f64, 1.0), @as(f64, 0.0));

    // Negative numbers
    try std.testing.expectApproxEqAbs(@as(f64, -3.14), @as(f64, -3.15), @as(f64, 0.02));

    // Very small numbers
    try std.testing.expectApproxEqAbs(@as(f64, 1e-10), @as(f64, 1.1e-10), @as(f64, 1e-11));
}

test "tmpDir - multiple files" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const io = std.testing.io;

    // Create multiple files
    var file1 = try tmp.dir.createFile(io, "file1.txt", .{});
    file1.close(io);

    var file2 = try tmp.dir.createFile(io, "file2.txt", .{});
    file2.close(io);

    var file3 = try tmp.dir.createFile(io, "file3.txt", .{});
    file3.close(io);

    // All automatically cleaned up
}

test "scoped blocks for test isolation" {
    const allocator = std.testing.allocator;

    // Test 1
    {
        const data = try allocator.alloc(u8, 100);
        defer allocator.free(data);
        data[0] = 1;
    }

    // Test 2
    {
        const data = try allocator.alloc(u8, 200);
        defer allocator.free(data);
        data[0] = 2;
    }
}
