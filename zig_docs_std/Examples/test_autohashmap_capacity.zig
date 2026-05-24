// Test AutoHashMap capacity management from documentation
const std = @import("std");

test "count" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try std.testing.expectEqual(@as(u32, 0), map.count());

    try map.put(1, 10);
    try map.put(2, 20);

    try std.testing.expectEqual(@as(u32, 2), map.count());
}

test "capacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    const initial_capacity = map.capacity();
    try std.testing.expect(initial_capacity >= 0);

    try map.ensureTotalCapacity(100);
    try std.testing.expect(map.capacity() >= 100);
}

test "ensureTotalCapacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.ensureTotalCapacity(1000); // Prepare for 1000 entries
    for (0..1000) |i| {
        map.putAssumeCapacity(@intCast(i), @intCast(i * 2)); // No allocation
    }

    try std.testing.expectEqual(@as(u32, 1000), map.count());
}

test "ensureUnusedCapacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    const current = map.count();

    try map.ensureUnusedCapacity(100); // Room for 100 more
    // Next 100 insertions guaranteed not to allocate

    for (0..100) |i| {
        map.putAssumeCapacity(@intCast(i + 100), @intCast(i));
    }

    try std.testing.expectEqual(current + 100, map.count());
}

test "clearRetainingCapacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.ensureTotalCapacity(100);
    try map.put(1, 10);
    try map.put(2, 20);

    const capacity_before = map.capacity();
    map.clearRetainingCapacity();

    try std.testing.expectEqual(@as(u32, 0), map.count());
    try std.testing.expectEqual(capacity_before, map.capacity());
}

test "clearAndFree" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    try map.put(2, 20);

    map.clearAndFree();

    try std.testing.expectEqual(@as(u32, 0), map.count());
    try std.testing.expectEqual(@as(u32, 0), map.capacity());
}

test "clearRetainingCapacity reuse pattern" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    // Simulate processing batches
    const batches = [_][3]u32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    };

    for (batches) |batch| {
        defer map.clearRetainingCapacity();

        for (batch) |item| {
            try map.put(item, @as(i32, @intCast(item * 10)));
        }

        try std.testing.expectEqual(@as(u32, 3), map.count());
    }
}
