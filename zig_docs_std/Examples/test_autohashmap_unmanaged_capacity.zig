// Test AutoHashMapUnmanaged capacity management operations
const std = @import("std");

test "ensureTotalCapacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    // Ensure we can hold at least 500 entries
    try map.ensureTotalCapacity(allocator, 500);

    try std.testing.expect(map.capacity() >= 500);
    try std.testing.expectEqual(@as(usize, 0), map.count());
}

test "ensureUnusedCapacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    // Add some entries
    for (0..10) |i| {
        try map.put(allocator, @intCast(i), @intCast(i * 2));
    }

    const current_count = map.count();

    // Ensure room for 50 MORE entries beyond current count
    try map.ensureUnusedCapacity(allocator, 50);

    try std.testing.expect(map.capacity() >= current_count + 50);
}

test "putAssumeCapacity after pre-allocation - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    // Pre-allocate capacity
    try map.ensureTotalCapacity(allocator, 1000);

    // Now we can insert without allocation or error handling
    for (0..1000) |i| {
        map.putAssumeCapacity(@intCast(i), "value");
    }

    try std.testing.expectEqual(@as(usize, 1000), map.count());
}

test "getOrPutAssumeCapacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, u32){};
    defer map.deinit(allocator);

    try map.ensureUnusedCapacity(allocator, 10);

    for (0..10) |i| {
        const key: u32 = @intCast(i);
        const result = map.getOrPutAssumeCapacity(key);
        if (!result.found_existing) {
            result.value_ptr.* = key * 10;
        }
    }

    try std.testing.expectEqual(@as(u32, 0), map.get(0).?);
    try std.testing.expectEqual(@as(u32, 90), map.get(9).?);
}

test "capacity management prevents reallocations - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    // Pre-allocate once
    try map.ensureTotalCapacity(allocator, 500);
    const initial_capacity = map.capacity();

    // Insert many entries - should not reallocate
    for (0..400) |i| {
        map.putAssumeCapacity(@intCast(i), @intCast(i));
    }

    // Capacity should remain the same (no reallocation)
    try std.testing.expectEqual(initial_capacity, map.capacity());
    try std.testing.expectEqual(@as(usize, 400), map.count());
}

test "Batch insertion with ensureUnusedCapacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    const batch_size = 100;

    // Process multiple batches
    for (0..5) |batch| {
        try map.ensureUnusedCapacity(allocator, batch_size);

        const base: u32 = @intCast(batch * batch_size);
        for (0..batch_size) |i| {
            map.putAssumeCapacity(base + @as(u32, @intCast(i)), "item");
        }
    }

    try std.testing.expectEqual(@as(usize, 500), map.count());
}

test "clearRetainingCapacity for reuse - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    // Allocate and fill
    try map.ensureTotalCapacity(allocator, 1000);
    for (0..500) |i| {
        map.putAssumeCapacity(@intCast(i), @intCast(i));
    }

    const capacity_before_clear = map.capacity();

    // Clear but keep capacity
    map.clearRetainingCapacity();

    try std.testing.expectEqual(@as(usize, 0), map.count());
    try std.testing.expectEqual(capacity_before_clear, map.capacity());

    // Reuse without reallocation
    for (0..500) |i| {
        map.putAssumeCapacity(@intCast(i + 1000), @intCast(i));
    }

    try std.testing.expectEqual(@as(usize, 500), map.count());
    try std.testing.expectEqual(capacity_before_clear, map.capacity());
}

test "clearAndFree deallocates memory - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.ensureTotalCapacity(allocator, 1000);
    for (0..500) |i| {
        try map.put(allocator, @intCast(i), @intCast(i));
    }

    // Free all memory
    map.clearAndFree(allocator);

    try std.testing.expectEqual(@as(usize, 0), map.count());
    try std.testing.expectEqual(@as(usize, 0), map.capacity());

    // Can still use the map after clearAndFree
    try map.put(allocator, 1, 100);
    try std.testing.expectEqual(@as(i32, 100), map.get(1).?);
}

test "Efficient pattern: pre-allocate then AssumeCapacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, u32){};
    defer map.deinit(allocator);

    const items_to_add = 1000;

    // Single allocation upfront
    try map.ensureTotalCapacity(allocator, items_to_add);

    // Hot loop - no error handling, no allocations
    for (0..items_to_add) |i| {
        const key: u32 = @intCast(i);
        map.putAssumeCapacity(key, key * key);
    }

    // Verify
    try std.testing.expectEqual(@as(usize, items_to_add), map.count());
    try std.testing.expectEqual(@as(u32, 0), map.get(0).?);
    try std.testing.expectEqual(@as(u32, 998001), map.get(999).?);
}

test "move transfers ownership - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map1 = std.AutoHashMapUnmanaged(u32, i32){};
    try map1.put(allocator, 1, 100);
    try map1.put(allocator, 2, 200);

    // Transfer ownership
    var map2 = map1.move();
    defer map2.deinit(allocator);

    // map1 is now empty
    try std.testing.expectEqual(@as(usize, 0), map1.count());

    // map2 owns the data
    try std.testing.expectEqual(@as(usize, 2), map2.count());
    try std.testing.expectEqual(@as(i32, 100), map2.get(1).?);
    try std.testing.expectEqual(@as(i32, 200), map2.get(2).?);
}

test "clone creates independent copy - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var original = std.AutoHashMapUnmanaged(u32, i32){};
    defer original.deinit(allocator);

    try original.put(allocator, 1, 100);
    try original.put(allocator, 2, 200);

    // Create independent copy
    var copy = try original.clone(allocator);
    defer copy.deinit(allocator);

    // Modify original
    try original.put(allocator, 1, 999);

    // Copy is unaffected
    try std.testing.expectEqual(@as(i32, 100), copy.get(1).?);
    try std.testing.expectEqual(@as(i32, 999), original.get(1).?);
}
