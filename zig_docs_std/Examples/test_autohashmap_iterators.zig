// Test AutoHashMap iterator operations from documentation
const std = @import("std");

test "iterator over entries" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    try map.put(2, 20);
    try map.put(3, 30);

    var count: usize = 0;
    var sum: i32 = 0;

    var iter = map.iterator();
    while (iter.next()) |entry| {
        count += 1;
        sum += entry.value_ptr.*;
    }

    try std.testing.expectEqual(@as(usize, 3), count);
    try std.testing.expectEqual(@as(i32, 60), sum);
}

test "keyIterator" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    try map.put(2, 20);
    try map.put(3, 30);

    var count: usize = 0;
    var key_sum: u32 = 0;

    var iter = map.keyIterator();
    while (iter.next()) |key_ptr| {
        count += 1;
        key_sum += key_ptr.*;
    }

    try std.testing.expectEqual(@as(usize, 3), count);
    try std.testing.expectEqual(@as(u32, 6), key_sum);
}

test "valueIterator" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    try map.put(2, 20);
    try map.put(3, 30);

    var sum: i32 = 0;
    var iter = map.valueIterator();
    while (iter.next()) |value_ptr| {
        sum += value_ptr.*;
    }

    try std.testing.expectEqual(@as(i32, 60), sum);
}

test "iterator with modification" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    try map.put(2, 20);
    try map.put(3, 30);

    // Modify all values
    var iter = map.valueIterator();
    while (iter.next()) |value_ptr| {
        value_ptr.* *= 2;
    }

    try std.testing.expectEqual(@as(i32, 20), map.get(1).?);
    try std.testing.expectEqual(@as(i32, 40), map.get(2).?);
    try std.testing.expectEqual(@as(i32, 60), map.get(3).?);
}
