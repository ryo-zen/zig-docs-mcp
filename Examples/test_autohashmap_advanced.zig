// Test AutoHashMap advanced operations from documentation
const std = @import("std");

test "clone" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    try map.put(2, 20);

    var map_copy = try map.clone();
    defer map_copy.deinit();

    try std.testing.expectEqual(@as(i32, 10), map_copy.get(1).?);
    try std.testing.expectEqual(@as(i32, 20), map_copy.get(2).?);

    // Verify they're independent
    try map.put(3, 30);
    try std.testing.expect(map_copy.get(3) == null);
}

test "move" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map1 = std.AutoHashMap(u32, i32).init(allocator);
    try map1.put(1, 100);

    var map2 = map1.move(); // map1 is now empty, map2 owns the data
    defer map2.deinit();
    // No need to deinit map1 - it's empty

    try std.testing.expectEqual(@as(u32, 0), map1.count());
    try std.testing.expectEqual(@as(i32, 100), map2.get(1).?);
}

test "getPtr for large values" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const LargeStruct = struct {
        data: [1024]u8,
    };

    var map = std.AutoHashMap(u32, LargeStruct).init(allocator);
    defer map.deinit();

    try map.put(1, .{ .data = [_]u8{0} ** 1024 });

    // Use getPtr to avoid copying large value
    if (map.getPtr(1)) |value_ptr| {
        value_ptr.data[0] = 42;
    }

    try std.testing.expectEqual(@as(u8, 42), map.get(1).?.data[0]);
}

test "getOrPut pattern for caching" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = std.StringHashMap([]const u8).init(allocator);
    defer cache.deinit();

    const key = "computed_value";

    // First access - compute and store
    {
        const result = try cache.getOrPut(key);
        if (!result.found_existing) {
            result.value_ptr.* = "expensive_result";
        }
        try std.testing.expectEqualStrings("expensive_result", result.value_ptr.*);
    }

    // Second access - use cached value
    {
        const result = try cache.getOrPut(key);
        try std.testing.expect(result.found_existing);
        try std.testing.expectEqualStrings("expensive_result", result.value_ptr.*);
    }
}

test "fetchPut for cleanup" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, []u8).init(allocator);
    defer {
        // Clean up any remaining values
        var iter = map.valueIterator();
        while (iter.next()) |value_ptr| {
            allocator.free(value_ptr.*);
        }
        map.deinit();
    }

    const old_value = try allocator.dupe(u8, "old");
    try map.put(1, old_value);

    const new_value = try allocator.dupe(u8, "new");
    if (try map.fetchPut(1, new_value)) |old| {
        // Clean up the old value
        allocator.free(old.value);
    }

    try std.testing.expectEqualStrings("new", map.get(1).?);
}

test "ensureTotalCapacity for bulk inserts" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, u32).init(allocator);
    defer map.deinit();

    const count = 10000;
    try map.ensureTotalCapacity(count);

    // All these inserts won't allocate
    for (0..count) |i| {
        map.putAssumeCapacity(@intCast(i), @intCast(i * 2));
    }

    try std.testing.expectEqual(@as(u32, count), map.count());
}

test "contains vs get performance pattern" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, [100]u8).init(allocator);
    defer map.deinit();

    try map.put(1, [_]u8{42} ** 100);

    // Use contains when you just need existence check
    if (map.contains(1)) {
        // Key exists - no value was copied
        try std.testing.expect(true);
    }

    // Use get when you need the value
    if (map.get(1)) |value| {
        // Value was copied
        try std.testing.expectEqual(@as(u8, 42), value[0]);
    }
}

test "StringHashMap for proper string hashing" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // StringHashMap hashes string contents, not pointers
    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    const key1 = "hello";
    const key2 = "hello"; // Different string literal, same content

    try map.put(key1, 42);

    // This works because StringHashMap compares contents
    try std.testing.expectEqual(@as(i32, 42), map.get(key2).?);
}

test "AssumeCapacity pattern in loops" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Item = struct {
        id: u32,
        value: i32,
    };

    const items = [_]Item{
        .{ .id = 1, .value = 10 },
        .{ .id = 2, .value = 20 },
        .{ .id = 3, .value = 30 },
    };

    var map = std.AutoHashMap(u32, Item).init(allocator);
    defer map.deinit();

    // Pre-allocate once
    try map.ensureUnusedCapacity(items.len);

    // No error handling needed in loop
    for (items) |item| {
        map.putAssumeCapacity(item.id, item);
    }

    try std.testing.expectEqual(@as(usize, 3), map.count());
}
