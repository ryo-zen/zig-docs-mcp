// Comprehensive tests for StringArrayHashMapUnmanaged (replacement for AutoArrayHashMap with string keys)
// NOTE: In Zig 0.16, use StringArrayHashMapUnmanaged for string keys, NOT AutoArrayHashMap([]const u8, V)
const std = @import("std");

test "StringArrayHashMapUnmanaged - Basic Usage" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, "apple", 5);
    try map.put(allocator, "banana", 3);

    try std.testing.expectEqual(@as(i32, 5), map.get("apple").?);
    try std.testing.expectEqual(@as(i32, 3), map.get("banana").?);
}

test "StringArrayHashMapUnmanaged - Iteration (Preserves Insertion Order)" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, "first", 1);
    try map.put(allocator, "second", 2);
    try map.put(allocator, "third", 3);

    var iter = map.iterator();
    var count: usize = 0;
    const expected_keys = [_][]const u8{ "first", "second", "third" };
    while (iter.next()) |entry| {
        try std.testing.expectEqualStrings(expected_keys[count], entry.key_ptr.*);
        count += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), count);
}

test "StringArrayHashMapUnmanaged - getOrPut Pattern" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
    defer map.deinit(allocator);

    const result = try map.getOrPut(allocator, "counter");
    if (!result.found_existing) {
        result.value_ptr.* = 0;
    }
    result.value_ptr.* += 1;

    try std.testing.expectEqual(@as(i32, 1), map.get("counter").?);

    // Increment again
    const result2 = try map.getOrPut(allocator, "counter");
    result2.value_ptr.* += 1;
    try std.testing.expectEqual(@as(i32, 2), map.get("counter").?);
}

test "StringArrayHashMapUnmanaged - Word Frequency Counter" {
    const countWords = struct {
        fn func(alloc: std.mem.Allocator, text: []const u8) !std.StringArrayHashMapUnmanaged(usize) {
            var counts: std.StringArrayHashMapUnmanaged(usize) = .empty;

            var iter = std.mem.tokenizeAny(u8, text, " \t\n");
            while (iter.next()) |word| {
                const result = try counts.getOrPut(alloc, word);
                if (!result.found_existing) {
                    result.value_ptr.* = 0;
                }
                result.value_ptr.* += 1;
            }

            return counts;
        }
    }.func;

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var counts = try countWords(allocator, "hello world hello zig world zig zig");
    defer counts.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 2), counts.get("hello").?);
    try std.testing.expectEqual(@as(usize, 2), counts.get("world").?);
    try std.testing.expectEqual(@as(usize, 3), counts.get("zig").?);
}

test "StringArrayHashMapUnmanaged - ensureTotalCapacity" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
    defer map.deinit(allocator);

    try map.ensureTotalCapacity(allocator, 10);

    const keys = [_][]const u8{ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" };
    for (keys, 0..) |key, i| {
        map.putAssumeCapacity(key, @intCast(i));
    }

    try std.testing.expectEqual(@as(usize, 10), map.count());
    try std.testing.expectEqual(@as(i32, 5), map.get("f").?);
}

test "StringArrayHashMapUnmanaged - clone" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, "key1", 42);
    try map.put(allocator, "key2", 99);

    var map2 = try map.clone(allocator);
    defer map2.deinit(allocator);

    try std.testing.expectEqual(@as(i32, 42), map2.get("key1").?);
    try std.testing.expectEqual(@as(i32, 99), map2.get("key2").?);
}

test "StringArrayHashMapUnmanaged - sort" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, "zebra", 1);
    try map.put(allocator, "apple", 2);
    try map.put(allocator, "banana", 3);

    const SortCtx = struct {
        keys: []const []const u8,
        pub fn lessThan(ctx: @This(), a_idx: usize, b_idx: usize) bool {
            return std.mem.order(u8, ctx.keys[a_idx], ctx.keys[b_idx]) == .lt;
        }
    };

    map.sort(SortCtx{ .keys = map.keys() });

    const keys = map.keys();
    try std.testing.expectEqualStrings("apple", keys[0]);
    try std.testing.expectEqualStrings("banana", keys[1]);
    try std.testing.expectEqualStrings("zebra", keys[2]);
}

test "StringArrayHashMapUnmanaged - swapRemove vs orderedRemove" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test swapRemove (O(1), destroys order)
    {
        var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
        defer map.deinit(allocator);

        try map.put(allocator, "a", 1);
        try map.put(allocator, "b", 2);
        try map.put(allocator, "c", 3);

        _ = map.swapRemove("b");
        try std.testing.expectEqual(@as(usize, 2), map.count());
        try std.testing.expect(map.get("b") == null);
    }

    // Test orderedRemove (O(N), preserves order)
    {
        var map: std.StringArrayHashMapUnmanaged(i32) = .empty;
        defer map.deinit(allocator);

        try map.put(allocator, "first", 1);
        try map.put(allocator, "second", 2);
        try map.put(allocator, "third", 3);

        _ = map.orderedRemove("second");

        const keys = map.keys();
        try std.testing.expectEqualStrings("first", keys[0]);
        try std.testing.expectEqualStrings("third", keys[1]);
    }
}

test "AutoArrayHashMap - Integer Keys (CORRECT USAGE)" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // AutoArrayHashMapUnmanaged works fine with integer keys
    var map: std.AutoArrayHashMapUnmanaged(u64, []const u8) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, 100, "hundred");
    try map.put(allocator, 200, "two hundred");

    try std.testing.expectEqualStrings("hundred", map.get(100).?);
    try std.testing.expectEqualStrings("two hundred", map.get(200).?);
}
