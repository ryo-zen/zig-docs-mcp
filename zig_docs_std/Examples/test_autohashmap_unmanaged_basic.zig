// Test basic AutoHashMapUnmanaged operations from documentation
const std = @import("std");

test "Basic Key-Value Storage - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Unmanaged version requires passing allocator to each operation
    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, "one");
    try map.put(allocator, 2, "two");
    try map.put(allocator, 3, "three");

    try std.testing.expectEqualStrings("one", map.get(1).?);
    try std.testing.expectEqualStrings("two", map.get(2).?);
    try std.testing.expectEqualStrings("three", map.get(3).?);
}

test "Pre-allocated Capacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    // Pre-allocate for 100 entries
    try map.ensureTotalCapacity(allocator, 100);

    // Now insert without allocation
    for (0..100) |i| {
        map.putAssumeCapacity(@intCast(i), @intCast(i * 2));
    }

    try std.testing.expectEqual(@as(usize, 100), map.count());
    try std.testing.expectEqual(@as(i32, 0), map.get(0).?);
    try std.testing.expectEqual(@as(i32, 198), map.get(99).?);
}

test "getOrPut Pattern - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMapUnmanaged(u32){};
    defer map.deinit(allocator);

    // First time - new entry
    const result1 = try map.getOrPut(allocator, "counter");
    if (result1.found_existing) {
        result1.value_ptr.* += 1;
    } else {
        result1.value_ptr.* = 1;
    }
    try std.testing.expectEqual(@as(u32, 1), map.get("counter").?);

    // Second time - increment existing
    const result2 = try map.getOrPut(allocator, "counter");
    if (result2.found_existing) {
        result2.value_ptr.* += 1;
    } else {
        result2.value_ptr.* = 1;
    }
    try std.testing.expectEqual(@as(u32, 2), map.get("counter").?);
}

test "put and get operations - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, "first");
    try std.testing.expectEqualStrings("first", map.get(1).?);

    // Clobber existing value
    try map.put(allocator, 1, "updated");
    try std.testing.expectEqualStrings("updated", map.get(1).?);
}

test "getPtr for in-place modification - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 100);

    // Modify in-place
    if (map.getPtr(1)) |value_ptr| {
        value_ptr.* += 50;
    }

    try std.testing.expectEqual(@as(i32, 150), map.get(1).?);
}

test "contains check - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, void){};
    defer map.deinit(allocator);

    try map.put(allocator, 42, {});
    try map.put(allocator, 100, {});

    try std.testing.expect(map.contains(42));
    try std.testing.expect(map.contains(100));
    try std.testing.expect(!map.contains(99));
}

test "remove operations - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, "one");
    try map.put(allocator, 2, "two");
    try map.put(allocator, 3, "three");

    // Remove returns true if key existed
    try std.testing.expect(map.remove(2));
    try std.testing.expect(!map.contains(2));

    // Remove returns false if key didn't exist
    try std.testing.expect(!map.remove(99));
}

test "fetchRemove returns old value - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 42, 100);

    // fetchRemove returns the old key-value pair
    if (map.fetchRemove(42)) |kv| {
        try std.testing.expectEqual(@as(u32, 42), kv.key);
        try std.testing.expectEqual(@as(i32, 100), kv.value);
    } else {
        return error.TestFailed;
    }

    // Now it's gone
    try std.testing.expect(!map.contains(42));
}

test "putNoClobber asserts on duplicate - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.putNoClobber(allocator, 1, 100);
    try std.testing.expectEqual(@as(i32, 100), map.get(1).?);

    // This would assert in debug mode if key already exists
    // try map.putNoClobber(allocator, 1, 200); // ← Would panic
}

test "getEntry returns both key and value pointers - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 42, 100);

    if (map.getEntry(42)) |entry| {
        try std.testing.expectEqual(@as(u32, 42), entry.key_ptr.*);
        try std.testing.expectEqual(@as(i32, 100), entry.value_ptr.*);

        // Can modify in-place
        entry.value_ptr.* = 999;
    } else {
        return error.TestFailed;
    }

    try std.testing.expectEqual(@as(i32, 999), map.get(42).?);
}

test "count and capacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 0), map.count());
    try std.testing.expectEqual(@as(usize, 0), map.capacity());

    try map.put(allocator, 1, 10);
    try std.testing.expectEqual(@as(usize, 1), map.count());
    try std.testing.expect(map.capacity() >= 1);
}

test "clearRetainingCapacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.ensureTotalCapacity(allocator, 100);
    for (0..10) |i| {
        try map.put(allocator, @intCast(i), @intCast(i));
    }

    const old_capacity = map.capacity();
    map.clearRetainingCapacity();

    try std.testing.expectEqual(@as(usize, 0), map.count());
    try std.testing.expectEqual(old_capacity, map.capacity());
}

test "clearAndFree - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.ensureTotalCapacity(allocator, 100);
    for (0..10) |i| {
        try map.put(allocator, @intCast(i), @intCast(i));
    }

    map.clearAndFree(allocator);

    try std.testing.expectEqual(@as(usize, 0), map.count());
    try std.testing.expectEqual(@as(usize, 0), map.capacity());
}
