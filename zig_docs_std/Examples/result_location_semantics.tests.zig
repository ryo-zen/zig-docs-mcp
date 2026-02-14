const std = @import("std");

// Test 1: Basic result type propagation
test "result type propagates through variable declaration" {
    const x: u32 = 42; // 42 is comptime_int, gets result type u32
    try std.testing.expectEqual(@as(u32, 42), x);
    try std.testing.expectEqual(u32, @TypeOf(x));
}

// Test 2: Result type propagation through struct initializer
test "result type propagates through struct fields" {
    const Point = struct { x: i32, y: i32 };
    const large_val: i64 = 100;

    const p: Point = .{
        .x = @intCast(large_val), // Result type i32 from Point.x
        .y = @intCast(large_val), // Result type i32 from Point.y
    };

    try std.testing.expectEqual(@as(i32, 100), p.x);
    try std.testing.expectEqual(@as(i32, 100), p.y);
}

// Test 3: Result type from function parameter
test "function parameter provides result type" {
    const double = struct {
        fn call(x: u32) u32 {
            return x * 2;
        }
    }.call;

    const val: u64 = 21;
    const result = double(@intCast(val)); // Result type u32 from parameter
    try std.testing.expectEqual(@as(u32, 42), result);
}

// Test 4: THE SWAP PROBLEM - wrong way (demonstrates the issue)
test "array swap fails with naive aggregate assignment" {
    var arr: [2]u32 = .{ 1, 2 };

    // This does NOT swap because writes happen in order:
    // arr[0] = arr[1]  // arr is now [2, 2]
    // arr[1] = arr[0]  // arr is now [2, 2]
    arr = .{ arr[1], arr[0] };

    try std.testing.expectEqual(@as(u32, 2), arr[0]);
    // This would fail: try std.testing.expectEqual(@as(u32, 1), arr[1]);
    try std.testing.expectEqual(@as(u32, 2), arr[1]); // Both are 2!
}

// Test 5: THE SWAP SOLUTION - correct way
test "array swap succeeds with explicit temporary" {
    var arr: [2]u32 = .{ 1, 2 };

    // CORRECT: Use explicit temporary to avoid overlap
    const tmp: [2]u32 = .{ arr[1], arr[0] };
    arr = tmp;

    try std.testing.expectEqual(@as(u32, 2), arr[0]);
    try std.testing.expectEqual(@as(u32, 1), arr[1]); // ✅ Now it works!
}

// Test 6: Alternative swap with std.mem.swap
test "std.mem.swap is the idiomatic solution" {
    var arr: [2]u32 = .{ 1, 2 };

    std.mem.swap(u32, &arr[0], &arr[1]);

    try std.testing.expectEqual(@as(u32, 2), arr[0]);
    try std.testing.expectEqual(@as(u32, 1), arr[1]);
}

// Test 7: Result location with struct field assignment
test "result location propagates to struct fields" {
    const Buffer = struct {
        data: [4]u8,
    };

    var buf: Buffer = undefined;

    // Inferred initializer: writes directly to buf.data
    buf = .{ .data = .{ 1, 2, 3, 4 } };

    try std.testing.expectEqual(@as(u8, 1), buf.data[0]);
    try std.testing.expectEqual(@as(u8, 4), buf.data[3]);
}

// Test 8: Inferred vs typed initializer difference
test "inferred vs typed initializer propagation" {
    const Point = struct { x: i32, y: i32 };
    var p: Point = undefined;

    // Inferred initializer: result location propagates
    // Writes directly to p.x and p.y
    p = .{ .x = 10, .y = 20 };
    try std.testing.expectEqual(@as(i32, 10), p.x);

    // Typed initializer: result location does NOT propagate
    // Builds temporary, then copies
    p = Point{ .x = 30, .y = 40 };
    try std.testing.expectEqual(@as(i32, 30), p.x);

    // Both work correctly, but behavior differs for overlapping updates
}

// Test 9: Pointer result type propagation
test "taking address propagates result type" {
    var x: u32 = 42;
    const ptr: *u32 = &x; // &x has result type *u32, so x must be u32

    try std.testing.expectEqual(@as(u32, 42), ptr.*);
}

// Test 10: Array result type from slice
test "slice result type determines array size" {
    const arr: [4]u8 = .{ 1, 2, 3, 4 };
    const slice: []const u8 = &arr; // &arr knows result type is []const u8

    try std.testing.expectEqual(@as(usize, 4), slice.len);
}

// Test 11: Assignment provides result type and location
test "assignment provides both result type and result location" {
    const Point = struct { x: i32, y: i32 };
    var p: Point = undefined;

    // Right-hand side gets:
    // - Result type: Point (from @TypeOf(p))
    // - Result location: &p (pointer to p)
    p = .{ .x = 5, .y = 10 };

    try std.testing.expectEqual(@as(i32, 5), p.x);
    try std.testing.expectEqual(@as(i32, 10), p.y);
}

// Test 12: No result location for @as
test "@as does not propagate result location" {
    const Point = struct { x: i32, y: i32 };
    var p: Point = undefined;

    // Even though p provides a result location,
    // @as creates a new value that gets copied
    p = @as(Point, .{ .x = 100, .y = 200 });

    try std.testing.expectEqual(@as(i32, 100), p.x);
}

// Test 13: Nested struct result type propagation
test "nested struct initializers propagate result types" {
    const Inner = struct { value: u32 };
    const Outer = struct { inner: Inner };

    const val: u64 = 42;
    const outer: Outer = .{
        .inner = .{
            .value = @intCast(val), // Gets u32 from Inner.value
        },
    };

    try std.testing.expectEqual(@as(u32, 42), outer.inner.value);
}

// Test 14: Array initializer with result location
test "array initializer elements get result locations" {
    var arr: [3]u32 = undefined;

    // Each element writes directly to arr[i]
    arr = .{ 10, 20, 30 };

    try std.testing.expectEqual(@as(u32, 10), arr[0]);
    try std.testing.expectEqual(@as(u32, 20), arr[1]);
    try std.testing.expectEqual(@as(u32, 30), arr[2]);
}

// Test 15: Struct update with overlapping read/write
test "struct self-update requires care with overlapping fields" {
    const Pair = struct { a: u32, b: u32 };
    var p: Pair = .{ .a = 1, .b = 2 };

    // PROBLEM: This reads p.b while writing to p
    // Depending on field order, could cause issues
    // p = .{ .a = p.b, .b = p.a };  // Be cautious!

    // SAFE: Use explicit temporary
    const tmp: Pair = .{ .a = p.b, .b = p.a };
    p = tmp;

    try std.testing.expectEqual(@as(u32, 2), p.a);
    try std.testing.expectEqual(@as(u32, 1), p.b);
}

// Test 16: Result type from return type
test "return statement provides result type" {
    const getValue = struct {
        fn call() u32 {
            const val: u64 = 42;
            return @intCast(val); // Result type u32 from return type
        }
    }.call;

    try std.testing.expectEqual(@as(u32, 42), getValue());
}

// Test 17: Bitshift operand gets result type
test "bitshift right operand gets specialized type" {
    const x: u32 = 16;
    const shift_amount: u8 = 2; // Type is Log2Int of u32's type
    const result = x >> shift_amount;

    try std.testing.expectEqual(@as(u32, 4), result);
}

// Test 18: Optional result type propagation
test "optional result type propagates through initialization" {
    const value: u64 = 42;
    const opt: ?u32 = @intCast(value); // Result type u32 from ?u32

    try std.testing.expectEqual(@as(u32, 42), opt.?);
}

// Test 19: Error union result type propagation
test "error union result type propagates" {
    const MyError = error{Failed};
    const value: u64 = 42;
    const result: MyError!u32 = @intCast(value); // Result type u32

    try std.testing.expectEqual(@as(u32, 42), try result);
}

// Test 20: Practical example - avoiding temporaries
test "result location can avoid temporary allocations" {
    const Config = struct {
        name: [32]u8 = undefined,
        value: u32,
    };

    var config: Config = undefined;

    // Writes directly to config fields (no temporary Config created)
    config = .{
        .name = [_]u8{0} ** 32,
        .value = 100,
    };

    try std.testing.expectEqual(@as(u32, 100), config.value);
    try std.testing.expectEqual(@as(u8, 0), config.name[0]);
}
