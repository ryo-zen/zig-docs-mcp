// Tests for std.array_list namespace documentation
// Validates all code examples from std.array_list.md work with Zig 0.16

const std = @import("std");

// ============================================================================
// Quick Start Pattern Tests
// ============================================================================

test "Quick Start - Basic Dynamic Array" {
    std.debug.print("\n=== Quick Start - Basic Dynamic Array ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa.allocator());

    try list.append(gpa.allocator(), 42);
    try list.append(gpa.allocator(), 100);
    try list.append(gpa.allocator(), 7);

    std.debug.print("Items: {any}\n", .{list.items});
    try std.testing.expectEqual(@as(usize, 3), list.items.len);
    try std.testing.expectEqual(@as(i32, 42), list.items[0]);
    try std.testing.expectEqual(@as(i32, 100), list.items[1]);
    try std.testing.expectEqual(@as(i32, 7), list.items[2]);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start - Pre-allocated Capacity" {
    std.debug.print("\n=== Quick Start - Pre-allocated Capacity ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try list.ensureTotalCapacity(allocator, 1024);
    list.appendAssumeCapacity('H');
    list.appendAssumeCapacity('i');

    try std.testing.expectEqual(@as(usize, 2), list.items.len);
    try std.testing.expectEqual(@as(u8, 'H'), list.items[0]);
    try std.testing.expectEqual(@as(u8, 'i'), list.items[1]);
    try std.testing.expect(list.capacity >= 1024);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start - String Building" {
    std.debug.print("\n=== Quick Start - String Building ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var string: std.ArrayList(u8) = .empty;
    defer string.deinit(allocator);

    try string.appendSlice(allocator, "Hello, ");
    try string.appendSlice(allocator, "World!");

    std.debug.print("String: {s}\n", .{string.items});
    try std.testing.expectEqualStrings("Hello, World!", string.items);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Core Growth Function Tests
// ============================================================================

test "Function - append" {
    std.debug.print("\n=== Function - append ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.append(allocator, 42);
    try list.append(allocator, 100);
    std.debug.print("Length: {}\n", .{list.items.len});

    try std.testing.expectEqual(@as(usize, 2), list.items.len);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Function - appendSlice" {
    std.debug.print("\n=== Function - appendSlice ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, "Hello");
    try list.appendSlice(allocator, " World");
    std.debug.print("{s}\n", .{list.items});

    try std.testing.expectEqualStrings("Hello World", list.items);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Function - insert" {
    std.debug.print("\n=== Function - insert ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &[_]i32{ 1, 2, 4 });
    try list.insert(allocator, 2, 3);

    std.debug.print("Items: {any}\n", .{list.items});
    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 3, 4 }, list.items);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Core Removal Function Tests
// ============================================================================

test "Function - orderedRemove" {
    std.debug.print("\n=== Function - orderedRemove ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &[_]i32{ 10, 20, 30, 40 });
    const removed = list.orderedRemove(1);

    std.debug.print("Removed: {}, Items: {any}\n", .{ removed, list.items });
    try std.testing.expectEqual(@as(i32, 20), removed);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 30, 40 }, list.items);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Function - swapRemove" {
    std.debug.print("\n=== Function - swapRemove ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &[_]i32{ 10, 20, 30, 40 });
    const removed = list.swapRemove(1);

    std.debug.print("Removed: {}, Items: {any}\n", .{ removed, list.items });
    try std.testing.expectEqual(@as(i32, 20), removed);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 40, 30 }, list.items);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Function - pop" {
    std.debug.print("\n=== Function - pop ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.append(allocator, 42);
    const last = list.pop();

    std.debug.print("Popped: {?}, Length: {}\n", .{ last, list.items.len });
    try std.testing.expectEqual(@as(i32, 42), last.?);
    try std.testing.expectEqual(@as(usize, 0), list.items.len);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Memory Management Function Tests
// ============================================================================

test "Function - ensureTotalCapacity" {
    std.debug.print("\n=== Function - ensureTotalCapacity ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try list.ensureTotalCapacity(allocator, 1000);
    for (0..1000) |i| {
        list.appendAssumeCapacity(@intCast(i % 256));
    }

    std.debug.print("Length: {}, Capacity: {}\n", .{ list.items.len, list.capacity });
    try std.testing.expectEqual(@as(usize, 1000), list.items.len);
    try std.testing.expect(list.capacity >= 1000);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Function - toOwnedSlice" {
    std.debug.print("\n=== Function - toOwnedSlice ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, "Hello");
    const owned = try list.toOwnedSlice(allocator);
    defer allocator.free(owned);

    std.debug.print("{s}\n", .{owned});
    try std.testing.expectEqualStrings("Hello", owned);
    try std.testing.expectEqual(@as(usize, 0), list.items.len);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Function - clearRetainingCapacity" {
    std.debug.print("\n=== Function - clearRetainingCapacity ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.ensureTotalCapacity(allocator, 100);
    try list.appendSlice(allocator, &[_]i32{ 1, 2, 3 });

    const old_capacity = list.capacity;
    list.clearRetainingCapacity();

    std.debug.print("Length: {}, Capacity: {} (was {})\n", .{ list.items.len, list.capacity, old_capacity });
    try std.testing.expectEqual(@as(usize, 0), list.items.len);
    try std.testing.expectEqual(old_capacity, list.capacity);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Function - clearAndFree" {
    std.debug.print("\n=== Function - clearAndFree ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &[_]i32{ 1, 2, 3, 4, 5 });
    list.clearAndFree(allocator);

    std.debug.print("Length: {}, Capacity: {}\n", .{ list.items.len, list.capacity });
    try std.testing.expectEqual(@as(usize, 0), list.items.len);
    try std.testing.expectEqual(@as(usize, 0), list.capacity);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Core Type Tests
// ============================================================================

test "Type - Aligned with custom alignment" {
    std.debug.print("\n=== Type - Aligned with custom alignment ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var aligned_list: std.array_list.Aligned(f32, .@"16") = .empty;
    defer aligned_list.deinit(allocator);

    try aligned_list.append(allocator, 3.14);
    try aligned_list.append(allocator, 2.71);

    std.debug.print("Items: {any}\n", .{aligned_list.items});
    try std.testing.expectEqual(@as(usize, 2), aligned_list.items.len);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Type - AlignedManaged" {
    std.debug.print("\n=== Type - AlignedManaged ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.array_list.AlignedManaged(i32, null).init(allocator);
    defer list.deinit();

    try list.append(42);
    try list.appendSlice(&[_]i32{ 1, 2, 3 });

    std.debug.print("Items: {any}\n", .{list.items});
    try std.testing.expectEqual(@as(usize, 4), list.items.len);
    try std.testing.expectEqual(@as(i32, 42), list.items[0]);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Type - Managed" {
    std.debug.print("\n=== Type - Managed ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.array_list.Managed(i32).init(allocator);
    defer list.deinit();

    try list.append(100);

    std.debug.print("Items: {any}\n", .{list.items});
    try std.testing.expectEqual(@as(i32, 100), list.items[0]);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Usage Pattern Tests
// ============================================================================

fn buildGreeting(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    var string: std.ArrayList(u8) = .empty;
    errdefer string.deinit(allocator);

    try string.appendSlice(allocator, "Hello, ");
    try string.appendSlice(allocator, name);
    try string.append(allocator, '!');

    return string.toOwnedSlice(allocator);
}

test "Usage Pattern - String Building" {
    std.debug.print("\n=== Usage Pattern - String Building ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const greeting = try buildGreeting(gpa.allocator(), "Zig");
    defer gpa.allocator().free(greeting);

    std.debug.print("{s}\n", .{greeting});
    try std.testing.expectEqualStrings("Hello, Zig!", greeting);

    std.debug.print("  ✅ PASS\n\n", .{});
}

fn processItems(allocator: std.mem.Allocator, count: usize) !void {
    var results: std.ArrayList(i32) = .empty;
    defer results.deinit(allocator);

    try results.ensureTotalCapacity(allocator, count);

    for (0..count) |i| {
        results.appendAssumeCapacity(@intCast(i * 2));
    }

    std.debug.print("Processed {} items\n", .{results.items.len});
}

test "Usage Pattern - Pre-allocated Buffer" {
    std.debug.print("\n=== Usage Pattern - Pre-allocated Buffer ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    try processItems(gpa.allocator(), 100);

    std.debug.print("  ✅ PASS\n\n", .{});
}

fn filterEven(allocator: std.mem.Allocator, numbers: []const i32) ![]i32 {
    var filtered = std.array_list.Managed(i32).init(allocator);
    errdefer filtered.deinit();

    for (numbers) |num| {
        if (@rem(num, 2) == 0) {
            try filtered.append(num);
        }
    }

    return filtered.toOwnedSlice();
}

test "Usage Pattern - Filtering with Managed Variant" {
    std.debug.print("\n=== Usage Pattern - Filtering with Managed Variant ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const numbers = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    const evens = try filterEven(gpa.allocator(), &numbers);
    defer gpa.allocator().free(evens);

    std.debug.print("Evens: {any}\n", .{evens});
    try std.testing.expectEqualSlices(i32, &[_]i32{ 2, 4, 6, 8, 10 }, evens);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Performance Tip Tests
// ============================================================================

test "Performance Tip - Pre-allocate for loops" {
    std.debug.print("\n=== Performance Tip - Pre-allocate for loops ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.ensureTotalCapacity(allocator, 1000);
    for (0..1000) |i| {
        list.appendAssumeCapacity(@intCast(i));
    }

    try std.testing.expectEqual(@as(usize, 1000), list.items.len);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Performance Tip - swapRemove vs orderedRemove" {
    std.debug.print("\n=== Performance Tip - swapRemove vs orderedRemove ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &[_]i32{ 1, 2, 3, 4, 5 });
    _ = list.swapRemove(2);

    std.debug.print("After swapRemove: {any}\n", .{list.items});
    try std.testing.expectEqual(@as(usize, 4), list.items.len);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Performance Tip - clearRetainingCapacity for reuse" {
    std.debug.print("\n=== Performance Tip - clearRetainingCapacity for reuse ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var batch: std.ArrayList(i32) = .empty;
    defer batch.deinit(allocator);

    for (0..3) |_| {
        batch.clearRetainingCapacity();
        try batch.appendSlice(allocator, &[_]i32{ 1, 2, 3 });
    }

    std.debug.print("Final batch: {any}\n", .{batch.items});

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Performance Tip - appendSlice vs loop append" {
    std.debug.print("\n=== Performance Tip - appendSlice vs loop append ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    // Good - single allocation
    try list.appendSlice(allocator, &[_]i32{ 1, 2, 3, 4, 5 });

    try std.testing.expectEqual(@as(usize, 5), list.items.len);

    std.debug.print("  ✅ PASS\n\n", .{});
}
