// Test AutoHashMap usage patterns from documentation
const std = @import("std");

test "Word Frequency Counter" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const text = "hello world hello zig world zig zig";

    var counts = std.StringHashMap(u32).init(allocator);
    defer counts.deinit();

    var iter = std.mem.tokenizeAny(u8, text, " \t\n");
    while (iter.next()) |word| {
        const result = try counts.getOrPut(word);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    try std.testing.expectEqual(@as(u32, 2), counts.get("hello").?);
    try std.testing.expectEqual(@as(u32, 2), counts.get("world").?);
    try std.testing.expectEqual(@as(u32, 3), counts.get("zig").?);
}

test "Caching Function Results" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = std.AutoHashMap(u64, u64).init(allocator);
    defer cache.deinit();

    // Simulate caching expensive computation (factorial)
    const fibonacci = struct {
        fn compute(c: *std.AutoHashMap(u64, u64), n: u64) !u64 {
            if (c.get(n)) |cached| {
                return cached;
            }

            const result = if (n <= 1) n else blk: {
                const a = try compute(c, n - 1);
                const b = try compute(c, n - 2);
                break :blk a + b;
            };

            try c.put(n, result);
            return result;
        }
    }.compute;

    const result = try fibonacci(&cache, 10);
    try std.testing.expectEqual(@as(u64, 55), result);

    // Verify cache has entries
    try std.testing.expect(cache.count() > 0);
}

test "Building a Lookup Table" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const User = struct {
        id: u32,
        name: []const u8,
    };

    const users = [_]User{
        .{ .id = 1, .name = "Alice" },
        .{ .id = 2, .name = "Bob" },
        .{ .id = 3, .name = "Charlie" },
    };

    var lookup = std.AutoHashMap(u32, User).init(allocator);
    defer lookup.deinit();

    try lookup.ensureTotalCapacity(@intCast(users.len));

    for (users) |user| {
        lookup.putAssumeCapacity(user.id, user);
    }

    try std.testing.expectEqualStrings("Alice", lookup.get(1).?.name);
    try std.testing.expectEqualStrings("Bob", lookup.get(2).?.name);
    try std.testing.expectEqualStrings("Charlie", lookup.get(3).?.name);
}

test "Removing Duplicates" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const items = [_]i32{ 1, 2, 3, 2, 4, 1, 5, 3, 6 };

    var seen = std.AutoHashMap(i32, void).init(allocator);
    defer seen.deinit();

    var result: std.ArrayList(i32) = .empty;
    defer result.deinit(allocator);

    for (items) |item| {
        const gop = try seen.getOrPut(item);
        if (!gop.found_existing) {
            try result.append(allocator, item);
        }
    }

    const unique = result.items;
    try std.testing.expectEqual(@as(usize, 6), unique.len);
    try std.testing.expectEqual(@as(i32, 1), unique[0]);
    try std.testing.expectEqual(@as(i32, 2), unique[1]);
    try std.testing.expectEqual(@as(i32, 3), unique[2]);
    try std.testing.expectEqual(@as(i32, 4), unique[3]);
    try std.testing.expectEqual(@as(i32, 5), unique[4]);
    try std.testing.expectEqual(@as(i32, 6), unique[5]);
}

test "Set-like behavior with void values" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // AutoHashMap with void value acts like a set
    var set = std.AutoHashMap(u32, void).init(allocator);
    defer set.deinit();

    try set.put(1, {});
    try set.put(2, {});
    try set.put(3, {});

    try std.testing.expect(set.contains(1));
    try std.testing.expect(set.contains(2));
    try std.testing.expect(!set.contains(4));

    _ = set.remove(2);
    try std.testing.expect(!set.contains(2));
}

test "Counter Pattern" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var counter = std.StringHashMap(usize).init(allocator);
    defer counter.deinit();

    const items = [_][]const u8{ "apple", "banana", "apple", "orange", "banana", "apple" };

    for (items) |item| {
        const result = try counter.getOrPut(item);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    try std.testing.expectEqual(@as(usize, 3), counter.get("apple").?);
    try std.testing.expectEqual(@as(usize, 2), counter.get("banana").?);
    try std.testing.expectEqual(@as(usize, 1), counter.get("orange").?);
}
