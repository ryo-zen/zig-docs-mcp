// Real-world usage patterns for AutoHashMapUnmanaged
const std = @import("std");

test "Word frequency counter - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const text = "the quick brown fox jumps over the lazy dog the fox";

    var counts = std.StringHashMapUnmanaged(u32){};
    defer counts.deinit(allocator);

    var iter = std.mem.tokenizeScalar(u8, text, ' ');
    while (iter.next()) |word| {
        const result = try counts.getOrPut(allocator, word);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    try std.testing.expectEqual(@as(u32, 3), counts.get("the").?);
    try std.testing.expectEqual(@as(u32, 2), counts.get("fox").?);
    try std.testing.expectEqual(@as(u32, 1), counts.get("quick").?);
}

test "Caching expensive computations - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = std.AutoHashMapUnmanaged(u64, u64){};
    defer cache.deinit(allocator);

    // Simulate expensive computation (fibonacci)
    const fib = struct {
        fn compute(n: u64, c: *std.AutoHashMapUnmanaged(u64, u64), alloc: std.mem.Allocator) !u64 {
            if (n <= 1) return n;

            // Check cache
            if (c.get(n)) |cached| {
                return cached;
            }

            // Compute and cache
            const result = try compute(n - 1, c, alloc) + try compute(n - 2, c, alloc);
            try c.put(alloc, n, result);
            return result;
        }
    }.compute;

    const result = try fib(20, &cache, allocator);
    try std.testing.expectEqual(@as(u64, 6765), result);

    // Verify cache was used
    try std.testing.expect(cache.count() > 0);
}

test "Set operations with void values - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var set = std.AutoHashMapUnmanaged(u32, void){};
    defer set.deinit(allocator);

    // Add elements to set
    try set.put(allocator, 1, {});
    try set.put(allocator, 2, {});
    try set.put(allocator, 3, {});
    try set.put(allocator, 2, {}); // Duplicate - no effect

    try std.testing.expectEqual(@as(usize, 3), set.count());
    try std.testing.expect(set.contains(1));
    try std.testing.expect(set.contains(2));
    try std.testing.expect(!set.contains(4));
}

test "Deduplication with set - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const numbers = [_]i32{ 1, 2, 3, 2, 4, 1, 5, 3, 6 };

    var seen = std.AutoHashMapUnmanaged(i32, void){};
    defer seen.deinit(allocator);

    var unique: std.ArrayList(i32) = .empty;
    defer unique.deinit(allocator);

    for (numbers) |num| {
        const result = try seen.getOrPut(allocator, num);
        if (!result.found_existing) {
            try unique.append(allocator, num);
        }
    }

    try std.testing.expectEqual(@as(usize, 6), unique.items.len);
}

test "Building lookup table - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const User = struct {
        id: u32,
        name: []const u8,
        age: u32,
    };

    const users = [_]User{
        .{ .id = 1, .name = "Alice", .age = 25 },
        .{ .id = 2, .name = "Bob", .age = 30 },
        .{ .id = 3, .name = "Charlie", .age = 35 },
    };

    var lookup = std.AutoHashMapUnmanaged(u32, User){};
    defer lookup.deinit(allocator);

    // Pre-allocate for all users
    try lookup.ensureTotalCapacity(allocator, users.len);

    for (users) |user| {
        lookup.putAssumeCapacity(user.id, user);
    }

    // Fast O(1) lookup
    const user = lookup.get(2).?;
    try std.testing.expectEqualStrings("Bob", user.name);
    try std.testing.expectEqual(@as(u32, 30), user.age);
}

test "Grouping data by category - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Item = struct {
        category: []const u8,
        value: i32,
    };

    const items = [_]Item{
        .{ .category = "fruit", .value = 10 },
        .{ .category = "vegetable", .value = 20 },
        .{ .category = "fruit", .value = 15 },
        .{ .category = "vegetable", .value = 25 },
    };

    var totals = std.StringHashMapUnmanaged(i32){};
    defer totals.deinit(allocator);

    for (items) |item| {
        const result = try totals.getOrPut(allocator, item.category);
        if (result.found_existing) {
            result.value_ptr.* += item.value;
        } else {
            result.value_ptr.* = item.value;
        }
    }

    try std.testing.expectEqual(@as(i32, 25), totals.get("fruit").?);
    try std.testing.expectEqual(@as(i32, 45), totals.get("vegetable").?);
}

test "Graph adjacency list - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var graph = std.AutoHashMapUnmanaged(u32, std.ArrayList(u32)){};
    defer {
        var iter = graph.valueIterator();
        while (iter.next()) |list_ptr| {
            list_ptr.deinit(allocator);
        }
        graph.deinit(allocator);
    }

    // Add edges: 1->2, 1->3, 2->3, 3->4
    const edges = [_][2]u32{
        .{ 1, 2 },
        .{ 1, 3 },
        .{ 2, 3 },
        .{ 3, 4 },
    };

    for (edges) |edge| {
        const from = edge[0];
        const to = edge[1];

        const result = try graph.getOrPut(allocator, from);
        if (!result.found_existing) {
            result.value_ptr.* = .empty;
        }
        try result.value_ptr.append(allocator, to);
    }

    // Verify edges
    const neighbors_of_1 = graph.get(1).?;
    try std.testing.expectEqual(@as(usize, 2), neighbors_of_1.items.len);
}

test "Batch processing with clearRetainingCapacity - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    // Process 3 batches
    for (0..3) |batch_num| {
        defer map.clearRetainingCapacity();

        // Ensure capacity for this batch
        try map.ensureUnusedCapacity(allocator, 100);

        // Process batch items
        for (0..100) |i| {
            const key: u32 = @intCast(i);
            map.putAssumeCapacity(key, @intCast(batch_num));
        }

        try std.testing.expectEqual(@as(usize, 100), map.count());
    }

    // Map is empty after last defer
    try std.testing.expectEqual(@as(usize, 0), map.count());
}

test "Index remapping - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Map old IDs to new IDs
    var id_map = std.AutoHashMapUnmanaged(u32, u32){};
    defer id_map.deinit(allocator);

    const old_ids = [_]u32{ 100, 200, 300, 400 };

    for (old_ids, 0..) |old_id, new_id| {
        try id_map.put(allocator, old_id, @intCast(new_id));
    }

    // Lookup new ID for old ID
    try std.testing.expectEqual(@as(u32, 0), id_map.get(100).?);
    try std.testing.expectEqual(@as(u32, 2), id_map.get(300).?);
}

test "Counting unique elements in batches - Unmanaged" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var unique_counts = std.AutoHashMapUnmanaged(u32, void){};
    defer unique_counts.deinit(allocator);

    const batches = [_][]const u32{
        &[_]u32{ 1, 2, 3, 1, 2 },
        &[_]u32{ 4, 5, 3, 4 },
        &[_]u32{ 6, 1, 7 },
    };

    for (batches) |batch| {
        for (batch) |num| {
            try unique_counts.put(allocator, num, {});
        }
    }

    try std.testing.expectEqual(@as(usize, 7), unique_counts.count());
}
