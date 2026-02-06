// Comprehensive tests demonstrating std.mem.Allocator
// Shows allocation, deallocation, reallocation, duplication, and common patterns

const std = @import("std");

test "Allocator basic alloc and free" {
    std.debug.print("\n🧪 Test: Basic alloc and free\n", .{});

    const allocator = std.testing.allocator;

    const buf = try allocator.alloc(u8, 100);
    defer allocator.free(buf);

    try std.testing.expectEqual(@as(usize, 100), buf.len);

    // Memory is usable
    @memset(buf, 'A');
    try std.testing.expectEqual(@as(u8, 'A'), buf[0]);
    try std.testing.expectEqual(@as(u8, 'A'), buf[99]);

    std.debug.print("  ✅ PASS: alloc returns usable memory, free releases it\n", .{});
}

test "Allocator create and destroy single item" {
    std.debug.print("\n🧪 Test: create and destroy\n", .{});

    const allocator = std.testing.allocator;

    const Node = struct {
        value: i32,
        next: ?*@This(),
    };

    const node = try allocator.create(Node);
    defer allocator.destroy(node);

    node.* = .{ .value = 42, .next = null };
    try std.testing.expectEqual(@as(i32, 42), node.value);
    try std.testing.expect(node.next == null);

    std.debug.print("  ✅ PASS: create/destroy works for single items\n", .{});
}

test "Allocator allocSentinel for null-terminated strings" {
    std.debug.print("\n🧪 Test: allocSentinel\n", .{});

    const allocator = std.testing.allocator;

    const str = try allocator.allocSentinel(u8, 5, 0);
    defer allocator.free(str);

    // Fill with data
    @memcpy(str, "hello");

    // Sentinel is accessible at index 5
    try std.testing.expectEqual(@as(usize, 5), str.len);
    try std.testing.expectEqualStrings("hello", str);

    std.debug.print("  ✅ PASS: allocSentinel creates sentinel-terminated buffer\n", .{});
}

test "Allocator realloc grows memory" {
    std.debug.print("\n🧪 Test: realloc grow\n", .{});

    const allocator = std.testing.allocator;

    var buf = try allocator.alloc(u8, 10);

    // Fill initial buffer
    @memset(buf, 'X');

    // Grow the buffer
    buf = try allocator.realloc(buf, 20);
    defer allocator.free(buf);

    // Original data preserved
    try std.testing.expectEqual(@as(usize, 20), buf.len);
    try std.testing.expectEqual(@as(u8, 'X'), buf[0]);
    try std.testing.expectEqual(@as(u8, 'X'), buf[9]);

    std.debug.print("  ✅ PASS: realloc grows and preserves data\n", .{});
}

test "Allocator realloc shrinks memory" {
    std.debug.print("\n🧪 Test: realloc shrink\n", .{});

    const allocator = std.testing.allocator;

    var buf = try allocator.alloc(u8, 20);

    // Fill buffer
    for (buf, 0..) |*b, i| {
        b.* = @intCast(i);
    }

    // Shrink the buffer
    buf = try allocator.realloc(buf, 5);
    defer allocator.free(buf);

    try std.testing.expectEqual(@as(usize, 5), buf.len);
    // Original data preserved in remaining portion
    try std.testing.expectEqual(@as(u8, 0), buf[0]);
    try std.testing.expectEqual(@as(u8, 4), buf[4]);

    std.debug.print("  ✅ PASS: realloc shrinks and preserves remaining data\n", .{});
}

test "Allocator dupe copies a slice" {
    std.debug.print("\n🧪 Test: dupe\n", .{});

    const allocator = std.testing.allocator;

    const original = "hello world";
    const copy = try allocator.dupe(u8, original);
    defer allocator.free(copy);

    try std.testing.expectEqualStrings("hello world", copy);

    // Verify it's a true copy (different memory)
    try std.testing.expect(original.ptr != copy.ptr);

    std.debug.print("  ✅ PASS: dupe creates independent copy\n", .{});
}

test "Allocator dupeZ creates null-terminated copy" {
    std.debug.print("\n🧪 Test: dupeZ\n", .{});

    const allocator = std.testing.allocator;

    const name: []const u8 = "hello";
    const c_name = try allocator.dupeZ(u8, name);
    defer allocator.free(c_name);

    try std.testing.expectEqualStrings("hello", c_name);
    try std.testing.expectEqual(@as(usize, 5), c_name.len);
    // Sentinel accessible
    try std.testing.expectEqual(@as(u8, 0), c_name[5]);

    std.debug.print("  ✅ PASS: dupeZ creates null-terminated copy\n", .{});
}

test "Allocator alloc typed slices" {
    std.debug.print("\n🧪 Test: Typed allocation\n", .{});

    const allocator = std.testing.allocator;

    // Allocate different types
    const ints = try allocator.alloc(i32, 5);
    defer allocator.free(ints);

    const floats = try allocator.alloc(f64, 3);
    defer allocator.free(floats);

    // Use typed memory
    for (ints, 0..) |*val, i| {
        val.* = @intCast(i * 10);
    }
    try std.testing.expectEqual(@as(i32, 0), ints[0]);
    try std.testing.expectEqual(@as(i32, 40), ints[4]);

    floats[0] = 3.14;
    floats[1] = 2.71;
    floats[2] = 1.41;
    try std.testing.expect(floats[0] > 3.0);

    std.debug.print("  ✅ PASS: Typed allocation works for various types\n", .{});
}

test "Allocator zero-length allocation" {
    std.debug.print("\n🧪 Test: Zero-length allocation\n", .{});

    const allocator = std.testing.allocator;

    // Allocating zero items is valid
    const empty = try allocator.alloc(u8, 0);
    defer allocator.free(empty);

    try std.testing.expectEqual(@as(usize, 0), empty.len);

    std.debug.print("  ✅ PASS: Zero-length allocation is valid\n", .{});
}

test "Allocator failing allocator" {
    std.debug.print("\n🧪 Test: Failing allocator\n", .{});

    // std.mem.Allocator.failing always returns OutOfMemory
    const allocator = std.mem.Allocator.failing;

    const result = allocator.alloc(u8, 10);
    try std.testing.expectError(error.OutOfMemory, result);

    std.debug.print("  ✅ PASS: Failing allocator returns OutOfMemory\n", .{});
}

test "Pattern: Arena allocator for batch operations" {
    std.debug.print("\n🧪 Test: Arena allocator pattern\n", .{});

    // ArenaAllocator wraps a backing allocator
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit(); // Frees ALL allocations at once

    const allocator = arena.allocator();

    // Make many allocations — no need to free individually
    var total_bytes: usize = 0;
    for (0..10) |i| {
        const size = (i + 1) * 100;
        const buf = try allocator.alloc(u8, size);
        @memset(buf, 0);
        total_bytes += buf.len;
    }

    try std.testing.expectEqual(@as(usize, 5500), total_bytes);

    std.debug.print("  ✅ PASS: Arena allocator bulk-frees all allocations\n", .{});
}

test "Pattern: FixedBufferAllocator for stack-based allocation" {
    std.debug.print("\n🧪 Test: FixedBufferAllocator pattern\n", .{});

    // Allocate from a fixed buffer — no OS calls
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const a = try allocator.alloc(u8, 100);
    const b = try allocator.alloc(u8, 200);

    @memset(a, 'A');
    @memset(b, 'B');

    try std.testing.expectEqual(@as(u8, 'A'), a[0]);
    try std.testing.expectEqual(@as(u8, 'B'), b[0]);

    std.debug.print("  ✅ PASS: FixedBufferAllocator uses stack memory\n", .{});
}

test "Pattern: passing allocator to functions" {
    std.debug.print("\n🧪 Test: Allocator passing pattern\n", .{});

    const allocator = std.testing.allocator;

    const result = try std.mem.join(allocator, ", ", &.{ "one", "two", "three" });
    defer allocator.free(result);

    try std.testing.expectEqualStrings("one, two, three", result);

    std.debug.print("  ✅ PASS: Allocator passed to std.mem functions\n", .{});
}

test "Pattern: concat with allocator" {
    std.debug.print("\n🧪 Test: concat with allocator\n", .{});

    const allocator = std.testing.allocator;

    const slices: []const []const u8 = &.{ "hello", " ", "world" };
    const result = try std.mem.concat(allocator, u8, slices);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("hello world", result);

    std.debug.print("  ✅ PASS: std.mem.concat uses allocator correctly\n", .{});
}

test "Leak detection with testing allocator" {
    std.debug.print("\n🧪 Test: Leak detection\n", .{});

    // std.testing.allocator will report leaks at test end
    const allocator = std.testing.allocator;

    // This allocation is properly freed — no leak
    const data = try allocator.alloc(u8, 42);
    allocator.free(data);

    // If we had forgotten to free, the test runner would report:
    // "error: memory leak detected"

    std.debug.print("  ✅ PASS: Testing allocator detects leaks (none here)\n", .{});
}
