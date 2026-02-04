// Test AutoHashMapUnmanaged iterator operations
const std = @import("std");

test "Basic iterator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, "one");
    try map.put(allocator, 2, "two");
    try map.put(allocator, 3, "three");

    var count: usize = 0;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        try std.testing.expect(entry.key_ptr.* >= 1);
        try std.testing.expect(entry.key_ptr.* <= 3);
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 3), count);
}

test "Iterator entry modification - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 10);
    try map.put(allocator, 2, 20);
    try map.put(allocator, 3, 30);

    // Modify all values through iterator
    var iter = map.iterator();
    while (iter.next()) |entry| {
        entry.value_ptr.* *= 10;
    }

    try std.testing.expectEqual(@as(i32, 100), map.get(1).?);
    try std.testing.expectEqual(@as(i32, 200), map.get(2).?);
    try std.testing.expectEqual(@as(i32, 300), map.get(3).?);
}

test "keyIterator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 10, "ten");
    try map.put(allocator, 20, "twenty");
    try map.put(allocator, 30, "thirty");

    var sum: u32 = 0;
    var key_iter = map.keyIterator();
    while (key_iter.next()) |key_ptr| {
        sum += key_ptr.*;
    }

    try std.testing.expectEqual(@as(u32, 60), sum);
}

test "valueIterator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMapUnmanaged(i32){};
    defer map.deinit(allocator);

    try map.put(allocator, "a", 100);
    try map.put(allocator, "b", 200);
    try map.put(allocator, "c", 300);

    var sum: i32 = 0;
    var value_iter = map.valueIterator();
    while (value_iter.next()) |value_ptr| {
        sum += value_ptr.*;
    }

    try std.testing.expectEqual(@as(i32, 600), sum);
}

test "Modifying values through valueIterator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 1);
    try map.put(allocator, 2, 2);
    try map.put(allocator, 3, 3);

    // Double all values
    var value_iter = map.valueIterator();
    while (value_iter.next()) |value_ptr| {
        value_ptr.* *= 2;
    }

    var sum: i32 = 0;
    var iter = map.valueIterator();
    while (iter.next()) |value_ptr| {
        sum += value_ptr.*;
    }

    try std.testing.expectEqual(@as(i32, 12), sum); // (1+2+3)*2 = 12
}

test "Iterating empty map - Unmanaged" {
    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(std.testing.allocator);

    var count: usize = 0;
    var iter = map.iterator();
    while (iter.next()) |_| {
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 0), count);
}

test "Collecting keys into array - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, "one");
    try map.put(allocator, 2, "two");
    try map.put(allocator, 3, "three");

    var keys: std.ArrayList(u32) = .{};
    defer keys.deinit(allocator);

    var key_iter = map.keyIterator();
    while (key_iter.next()) |key_ptr| {
        try keys.append(allocator, key_ptr.*);
    }

    try std.testing.expectEqual(@as(usize, 3), keys.items.len);
}

test "Collecting values into array - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 100);
    try map.put(allocator, 2, 200);
    try map.put(allocator, 3, 300);

    var values: std.ArrayList(i32) = .{};
    defer values.deinit(allocator);

    var value_iter = map.valueIterator();
    while (value_iter.next()) |value_ptr| {
        try values.append(allocator, value_ptr.*);
    }

    try std.testing.expectEqual(@as(usize, 3), values.items.len);

    var sum: i32 = 0;
    for (values.items) |val| {
        sum += val;
    }
    try std.testing.expectEqual(@as(i32, 600), sum);
}

test "Filtering with iterator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    for (0..10) |i| {
        try map.put(allocator, @intCast(i), @intCast(i * 10));
    }

    // Count even keys
    var even_count: usize = 0;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        if (@rem(entry.key_ptr.*, 2) == 0) {
            even_count += 1;
        }
    }

    try std.testing.expectEqual(@as(usize, 5), even_count);
}

test "Computing sum with iterator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 10);
    try map.put(allocator, 2, 20);
    try map.put(allocator, 3, 30);
    try map.put(allocator, 4, 40);

    var sum: i32 = 0;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        sum += entry.value_ptr.*;
    }

    try std.testing.expectEqual(@as(i32, 100), sum);
}

test "Finding max value with iterator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 42);
    try map.put(allocator, 2, 100);
    try map.put(allocator, 3, 17);
    try map.put(allocator, 4, 99);

    var max: i32 = std.math.minInt(i32);
    var iter = map.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.* > max) {
            max = entry.value_ptr.*;
        }
    }

    try std.testing.expectEqual(@as(i32, 100), max);
}
