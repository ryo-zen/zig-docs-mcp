// Test file for all code examples in zen.md
// Validates that all snippets are syntactically correct and demonstrate valid patterns

const std = @import("std");

// ============================================================================
// Communicate intent precisely
// ============================================================================

fn parseNumber(input: []const u8) !i32 {
    return std.fmt.parseInt(i32, input, 10);
}

test "Zen: Communicate intent precisely" {
    std.debug.print("\n🧘 Test: Communicate intent precisely\n", .{});

    const input = "42";
    // ✅ Intent is clear
    const result = try parseNumber(input);
    try std.testing.expectEqual(42, result);

    std.debug.print("  ✅ PASS: Intent is explicit with try\n", .{});
}

// ============================================================================
// Edge cases matter
// ============================================================================

fn processBuffer(buffer: []const u8) !u8 {
    // ✅ Handles empty case
    if (buffer.len == 0) return error.EmptyBuffer;

    const first = buffer[0];
    return first;
}

test "Zen: Edge cases matter" {
    std.debug.print("\n🧘 Test: Edge cases matter\n", .{});

    // Test normal case
    const valid = "hello";
    try std.testing.expectEqual('h', try processBuffer(valid));

    // Test edge case
    const empty = "";
    try std.testing.expectError(error.EmptyBuffer, processBuffer(empty));

    std.debug.print("  ✅ PASS: Edge cases handled explicitly\n", .{});
}

// ============================================================================
// Favor reading code over writing code
// ============================================================================

test "Zen: Favor reading code over writing code" {
    std.debug.print("\n🧘 Test: Favor reading code\n", .{});

    const bytes: usize = 10240;

    // ✅ Clear and readable
    const bytes_per_kilobyte = 1024;
    const total_kb = bytes / bytes_per_kilobyte;
    try std.testing.expectEqual(10, total_kb);

    // ❌ Clever but unclear (shown for contrast, but still valid)
    const b: usize = 10240;
    const x = b >> 10; // what is this calculating?
    try std.testing.expectEqual(10, x);

    // Both produce same result, but first is clearer
    try std.testing.expectEqual(total_kb, x);

    std.debug.print("  ✅ PASS: Readability demonstrated\n", .{});
}

// ============================================================================
// Only one obvious way to do things
// ============================================================================

test "Zen: Only one obvious way" {
    std.debug.print("\n🧘 Test: Only one obvious way\n", .{});

    const input = "a,,b";

    // ✅ Clear distinction in purpose
    {
        var split = std.mem.splitScalar(u8, input, ',');
        try std.testing.expectEqualStrings("a", split.next().?);
        try std.testing.expectEqualStrings("", split.next().?); // preserves empty
        try std.testing.expectEqualStrings("b", split.next().?);
        std.debug.print("  ✅ splitScalar preserves empty fields\n", .{});
    }

    {
        var tokenize = std.mem.tokenizeScalar(u8, input, ',');
        try std.testing.expectEqualStrings("a", tokenize.next().?);
        try std.testing.expectEqualStrings("b", tokenize.next().?); // skips empty
        try std.testing.expect(tokenize.next() == null);
        std.debug.print("  ✅ tokenizeScalar skips empty fields\n", .{});
    }

    std.debug.print("  ✅ PASS: Each function has specific purpose\n", .{});
}

// ============================================================================
// Runtime crashes are better than bugs
// ============================================================================

fn accessElement(buffer: []const u8, index: usize) !u8 {
    // ✅ Fails immediately on invalid state
    if (index >= buffer.len) return error.IndexOutOfBounds;
    return buffer[index];
}

test "Zen: Runtime crashes are better than bugs" {
    std.debug.print("\n🧘 Test: Runtime crashes > bugs\n", .{});

    const buffer = "hello";

    // Valid access
    try std.testing.expectEqual('e', try accessElement(buffer, 1));

    // Invalid access caught explicitly
    try std.testing.expectError(error.IndexOutOfBounds, accessElement(buffer, 10));

    std.debug.print("  ✅ PASS: Fails explicitly on invalid access\n", .{});
}

// ============================================================================
// Compile errors are better than runtime crashes
// ============================================================================

fn processBufferComptime(comptime size: usize) void {
    // ✅ Compile-time validation
    if (size == 0) @compileError("Buffer size must be non-zero");
    const buffer: [size]u8 = undefined;
    _ = buffer;
}

test "Zen: Compile errors are better than runtime crashes" {
    std.debug.print("\n🧘 Test: Compile errors > runtime crashes\n", .{});

    // Valid call
    processBufferComptime(10);

    // This would cause compile error:
    // processBufferComptime(0); // Compile error: Buffer size must be non-zero

    std.debug.print("  ✅ PASS: Compile-time validation works\n", .{});
}

// ============================================================================
// Avoid local maximums
// ============================================================================

fn flexibleProcessing(allocator: std.mem.Allocator, needed_size: usize) !void {
    // ✅ Better long-term: flexible and composable
    const buffer = try allocator.alloc(u8, needed_size);
    defer allocator.free(buffer);

    // Use buffer...
    @memset(buffer, 0);
    try std.testing.expectEqual(needed_size, buffer.len);
}

test "Zen: Avoid local maximums" {
    std.debug.print("\n🧘 Test: Avoid local maximums\n", .{});

    // ❌ Local maximum: fast but inflexible
    {
        const buffer: [1024]u8 = undefined;
        _ = buffer;
        std.debug.print("  ✅ Fixed buffer works but inflexible\n", .{});
    }

    // ✅ Better approach
    try flexibleProcessing(std.testing.allocator, 2048);
    std.debug.print("  ✅ PASS: Flexible allocation handles any size\n", .{});
}

// ============================================================================
// Resource allocation may fail; resource deallocation must succeed
// ============================================================================

fn demoResourceManagement(allocator: std.mem.Allocator, size: usize) !void {
    // ✅ Allocation can fail, cleanup guaranteed
    const buffer = try allocator.alloc(u8, size); // may fail
    defer allocator.free(buffer); // must succeed

    // Cleanup runs even if error occurs later
    @memset(buffer, 42);
}

test "Zen: Resource allocation may fail; deallocation must succeed" {
    std.debug.print("\n🧘 Test: Allocation may fail; deallocation must succeed\n", .{});

    // Normal case
    try demoResourceManagement(std.testing.allocator, 100);

    // Allocation failure case
    const result = demoResourceManagement(std.testing.failing_allocator, 100);
    try std.testing.expectError(error.OutOfMemory, result);

    std.debug.print("  ✅ PASS: Allocation can fail, cleanup guaranteed\n", .{});
}

// ============================================================================
// Memory is a resource
// ============================================================================

test "Zen: Memory is a resource" {
    std.debug.print("\n🧘 Test: Memory is a resource\n", .{});

    const allocator = std.testing.allocator;

    // Explicit allocator parameters
    const buffer = try allocator.alloc(u8, 256);
    defer allocator.free(buffer);

    // Manual memory management with tools to make it safe
    @memset(buffer, 0);

    try std.testing.expectEqual(256, buffer.len);

    std.debug.print("  ✅ PASS: Explicit memory management\n", .{});
}

// ============================================================================
// Summary test
// ============================================================================

test "Zen: All principles demonstrated" {
    std.debug.print("\n🧘 Summary: All Zen principles have working code examples\n", .{});
    std.debug.print("  ✅ 1. Communicate intent precisely\n", .{});
    std.debug.print("  ✅ 2. Edge cases matter\n", .{});
    std.debug.print("  ✅ 3. Favor reading code over writing code\n", .{});
    std.debug.print("  ✅ 4. Only one obvious way to do things\n", .{});
    std.debug.print("  ✅ 5. Runtime crashes are better than bugs\n", .{});
    std.debug.print("  ✅ 6. Compile errors are better than runtime crashes\n", .{});
    std.debug.print("  ✅ 7. Avoid local maximums\n", .{});
    std.debug.print("  ✅ 8. Resource allocation may fail; deallocation must succeed\n", .{});
    std.debug.print("  ✅ 9. Memory is a resource\n", .{});
    std.debug.print("\n  📚 Principles 7, 10-13 are conceptual (no code examples needed)\n", .{});
}
