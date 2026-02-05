// Comprehensive tests demonstrating std.mem.ValidationAllocator
// Shows proper usage patterns and how validation catches common mistakes

const std = @import("std");

test "ValidationAllocator basic usage" {
    std.debug.print("\n🧪 Test: Basic ValidationAllocator usage\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var validating = std.mem.validationWrap(gpa.allocator());
    const allocator = validating.allocator();

    // Normal allocation and free
    const slice = try allocator.alloc(u8, 100);
    try std.testing.expectEqual(100, slice.len);

    // Write to ensure memory is usable
    for (slice, 0..) |*byte, i| {
        byte.* = @intCast(i % 256);
    }

    allocator.free(slice);

    std.debug.print("  ✅ PASS: Basic alloc/free works correctly\n", .{});
}

test "ValidationAllocator with multiple allocations" {
    std.debug.print("\n🧪 Test: Multiple allocations\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var validating = std.mem.validationWrap(gpa.allocator());
    const allocator = validating.allocator();

    // Allocate multiple buffers
    const buf1 = try allocator.alloc(u32, 10);
    const buf2 = try allocator.alloc(u64, 20);
    const buf3 = try allocator.alloc(u8, 100);

    // Verify sizes
    try std.testing.expectEqual(10, buf1.len);
    try std.testing.expectEqual(20, buf2.len);
    try std.testing.expectEqual(100, buf3.len);

    // Free in different order than allocated
    allocator.free(buf2);
    allocator.free(buf1);
    allocator.free(buf3);

    std.debug.print("  ✅ PASS: Multiple allocations tracked correctly\n", .{});
}

test "ValidationAllocator with create/destroy" {
    std.debug.print("\n🧪 Test: Single-item create/destroy\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var validating = std.mem.validationWrap(gpa.allocator());
    const allocator = validating.allocator();

    const Point = struct {
        x: i32,
        y: i32,
    };

    // Create single item
    const point = try allocator.create(Point);
    point.* = Point{ .x = 10, .y = 20 };

    try std.testing.expectEqual(10, point.x);
    try std.testing.expectEqual(20, point.y);

    allocator.destroy(point);

    std.debug.print("  ✅ PASS: Create/destroy for single items works\n", .{});
}

// Note: reset() method was removed in later Zig versions
// ValidationAllocator no longer requires manual reset between test cases

test "ValidationAllocator with dynamic structures" {
    std.debug.print("\n🧪 Test: Dynamic data structures\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var validating = std.mem.validationWrap(gpa.allocator());
    const allocator = validating.allocator();

    // ArrayList usage
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.append(allocator, 30);

    try std.testing.expectEqual(3, list.items.len);
    try std.testing.expectEqual(20, list.items[1]);

    std.debug.print("  ✅ ArrayList with validated allocator works\n", .{});

    // HashMap usage
    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("foo", 1);
    try map.put("bar", 2);

    try std.testing.expectEqual(2, map.count());
    try std.testing.expectEqual(1, map.get("foo").?);

    std.debug.print("  ✅ HashMap with validated allocator works\n", .{});
    std.debug.print("  ✅ PASS: Dynamic structures properly validated\n", .{});
}

// Note: The following test demonstrates what ValidationAllocator *would* catch,
// but we cannot actually run it since it would cause an assertion failure.
// This is commented out for documentation purposes only.
//
// test "ValidationAllocator catches double-free (WILL ASSERT)" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//
//     var validating = std.mem.validationWrap(gpa.allocator());
//     const allocator = validating.allocator();
//
//     const slice = try allocator.alloc(u8, 100);
//     allocator.free(slice);
//
//     // This would trigger an assertion in debug builds:
//     // allocator.free(slice); // ❌ Double free detected!
// }

test "Real-world pattern: conditional validation in debug mode" {
    std.debug.print("\n🧪 Test: Conditional validation pattern\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Pattern: use validation in debug, skip in release for performance
    const base_allocator = gpa.allocator();

    var validating = std.mem.validationWrap(base_allocator);
    const allocator = if (@import("builtin").mode == .Debug)
        validating.allocator()
    else
        base_allocator;

    // Use the allocator normally - validation happens automatically in debug
    const buffer = try allocator.alloc(u8, 256);
    defer allocator.free(buffer);

    @memset(buffer, 0);
    try std.testing.expectEqual(0, buffer[100]);

    std.debug.print("  ✅ PASS: Conditional validation pattern implemented\n", .{});
}
