// Test basic AutoHashMap operations from documentation
const std = @import("std");

test "Basic Key-Value Storage" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Use StringHashMap for string keys
    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("score", 100);
    try map.put("level", 5);

    if (map.get("score")) |value| {
        try std.testing.expectEqual(@as(i32, 100), value);
    } else {
        return error.TestFailed;
    }
}

test "Pre-allocated Capacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, []const u8).init(allocator);
    defer map.deinit();

    try map.ensureTotalCapacity(1000); // Pre-allocate for 1000 entries
    map.putAssumeCapacity(1, "one"); // No allocation needed
    map.putAssumeCapacity(2, "two");

    try std.testing.expectEqualStrings("one", map.get(1).?);
    try std.testing.expectEqualStrings("two", map.get(2).?);
}

test "Checking and Updating" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(u32).init(allocator);
    defer map.deinit();

    const result = try map.getOrPut("counter");
    if (result.found_existing) {
        result.value_ptr.* += 1; // Increment existing
    } else {
        result.value_ptr.* = 1; // Initialize new
    }

    try std.testing.expectEqual(@as(u32, 1), map.get("counter").?);

    // Try again - should increment
    const result2 = try map.getOrPut("counter");
    if (result2.found_existing) {
        result2.value_ptr.* += 1;
    } else {
        result2.value_ptr.* = 1;
    }

    try std.testing.expectEqual(@as(u32, 2), map.get("counter").?);
}

test "Iterating Over Entries" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("Alice", 25);
    try map.put("Bob", 30);

    var count: usize = 0;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        _ = entry;
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 2), count);
}

test "put and get operations" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("name", 100);
    try std.testing.expectEqual(@as(i32, 100), map.get("name").?);

    try map.put("name", 200); // Replaces 100 with 200
    try std.testing.expectEqual(@as(i32, 200), map.get("name").?);
}

test "putNoClobber assertion" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.putNoClobber(1, 12345);
    try std.testing.expectEqual(@as(i32, 12345), map.get(1).?);
}

test "putAssumeCapacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, []const u8).init(allocator);
    defer map.deinit();

    try map.ensureUnusedCapacity(10); // Reserve space for 10 more entries
    map.putAssumeCapacity(1, "one");
    map.putAssumeCapacity(2, "two");

    try std.testing.expectEqualStrings("one", map.get(1).?);
}

test "putAssumeCapacityNoClobber" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.ensureTotalCapacity(100);
    for (0..10) |i| {
        map.putAssumeCapacityNoClobber(@intCast(i), @intCast(i * 2));
    }

    try std.testing.expectEqual(@as(i32, 0), map.get(0).?);
    try std.testing.expectEqual(@as(i32, 18), map.get(9).?);
}

test "get with optional" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("score", 100);

    if (map.get("score")) |score| {
        try std.testing.expectEqual(@as(i32, 100), score);
    } else {
        return error.TestFailed;
    }

    try std.testing.expect(map.get("nonexistent") == null);
}

test "getPtr for in-place modification" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("counter", 10);

    if (map.getPtr("counter")) |counter_ptr| {
        counter_ptr.* += 1; // Increment in-place
    }

    try std.testing.expectEqual(@as(i32, 11), map.get("counter").?);
}

test "getEntry" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("user", 42);

    if (map.getEntry("user")) |entry| {
        try std.testing.expectEqual(@as(i32, 42), entry.value_ptr.*);
        entry.value_ptr.* = 999; // Modify in-place
    }

    try std.testing.expectEqual(@as(i32, 999), map.get("user").?);
}

test "contains" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("admin", 1);

    try std.testing.expect(map.contains("admin"));
    try std.testing.expect(!map.contains("user"));
}

test "getOrPut" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(u32).init(allocator);
    defer map.deinit();

    const result = try map.getOrPut("counter");
    if (result.found_existing) {
        result.value_ptr.* += 1;
    } else {
        result.value_ptr.* = 1; // Initialize for new entry
    }

    try std.testing.expectEqual(@as(u32, 1), map.get("counter").?);
}

test "getOrPutAssumeCapacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.ensureUnusedCapacity(1);
    const result = map.getOrPutAssumeCapacity("key");
    result.value_ptr.* = 42;

    try std.testing.expectEqual(@as(i32, 42), map.get("key").?);
}

test "getOrPutValue" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    const entry = try map.getOrPutValue("default", 0);
    try std.testing.expectEqual(@as(i32, 0), entry.value_ptr.*);
}

test "fetchPut" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("config", 100);

    const old = try map.fetchPut("config", 200);
    try std.testing.expect(old != null);
    try std.testing.expectEqual(@as(i32, 100), old.?.value);
    try std.testing.expectEqual(@as(i32, 200), map.get("config").?);
}

test "remove" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("temporary", 1);
    try std.testing.expect(map.remove("temporary"));
    try std.testing.expect(!map.remove("temporary"));
}

test "fetchRemove" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("cache_entry", 42);

    if (map.fetchRemove("cache_entry")) |kv| {
        try std.testing.expectEqual(@as(i32, 42), kv.value);
    } else {
        return error.TestFailed;
    }

    try std.testing.expect(map.get("cache_entry") == null);
}

test "removeByPtr" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("target", 1);

    if (map.getKeyPtr("target")) |key_ptr| {
        map.removeByPtr(key_ptr);
    }

    try std.testing.expect(map.get("target") == null);
}
