// Comprehensive tests for StringArrayHashMap (replacement for AutoArrayHashMap with string keys)
// NOTE: In Zig 0.16, use StringArrayHashMap for string keys, NOT AutoArrayHashMap([]const u8, V)
const std = @import("std");

test "StringArrayHashMap - Basic Usage" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("apple", 5);
    try map.put("banana", 3);

    try std.testing.expectEqual(@as(i32, 5), map.get("apple").?);
    try std.testing.expectEqual(@as(i32, 3), map.get("banana").?);
}

test "StringArrayHashMap - Iteration (Preserves Insertion Order)" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("first", 1);
    try map.put("second", 2);
    try map.put("third", 3);

    var iter = map.iterator();
    var count: usize = 0;
    const expected_keys = [_][]const u8{ "first", "second", "third" };
    while (iter.next()) |entry| {
        try std.testing.expectEqualStrings(expected_keys[count], entry.key_ptr.*);
        count += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), count);
}

test "StringArrayHashMap - getOrPut Pattern" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMap(i32).init(allocator);
    defer map.deinit();

    const result = try map.getOrPut("counter");
    if (!result.found_existing) {
        result.value_ptr.* = 0;
    }
    result.value_ptr.* += 1;

    try std.testing.expectEqual(@as(i32, 1), map.get("counter").?);

    // Increment again
    const result2 = try map.getOrPut("counter");
    result2.value_ptr.* += 1;
    try std.testing.expectEqual(@as(i32, 2), map.get("counter").?);
}

test "StringArrayHashMap - Word Frequency Counter" {
    const countWords = struct {
        fn func(alloc: std.mem.Allocator, text: []const u8) !std.StringArrayHashMap(usize) {
            var counts = std.StringArrayHashMap(usize).init(alloc);

            var iter = std.mem.tokenizeAny(u8, text, " \t\n");
            while (iter.next()) |word| {
                const result = try counts.getOrPut(word);
                if (!result.found_existing) {
                    result.value_ptr.* = 0;
                }
                result.value_ptr.* += 1;
            }

            return counts;
        }
    }.func;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var counts = try countWords(allocator, "hello world hello zig world zig zig");
    defer counts.deinit();

    try std.testing.expectEqual(@as(usize, 2), counts.get("hello").?);
    try std.testing.expectEqual(@as(usize, 2), counts.get("world").?);
    try std.testing.expectEqual(@as(usize, 3), counts.get("zig").?);
}

test "StringArrayHashMap - ensureTotalCapacity" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMap(i32).init(allocator);
    defer map.deinit();

    try map.ensureTotalCapacity(10);

    const keys = [_][]const u8{ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" };
    for (keys, 0..) |key, i| {
        map.putAssumeCapacity(key, @intCast(i));
    }

    try std.testing.expectEqual(@as(usize, 10), map.count());
    try std.testing.expectEqual(@as(i32, 5), map.get("f").?);
}

test "StringArrayHashMap - clone" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("key1", 42);
    try map.put("key2", 99);

    var map2 = try map.clone();
    defer map2.deinit();

    try std.testing.expectEqual(@as(i32, 42), map2.get("key1").?);
    try std.testing.expectEqual(@as(i32, 99), map2.get("key2").?);
}

test "StringArrayHashMap - sort" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("zebra", 1);
    try map.put("apple", 2);
    try map.put("banana", 3);

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

test "StringArrayHashMap - swapRemove vs orderedRemove" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test swapRemove (O(1), destroys order)
    {
        var map = std.StringArrayHashMap(i32).init(allocator);
        defer map.deinit();

        try map.put("a", 1);
        try map.put("b", 2);
        try map.put("c", 3);

        _ = map.swapRemove("b");
        try std.testing.expectEqual(@as(usize, 2), map.count());
        try std.testing.expect(map.get("b") == null);
    }

    // Test orderedRemove (O(N), preserves order)
    {
        var map = std.StringArrayHashMap(i32).init(allocator);
        defer map.deinit();

        try map.put("first", 1);
        try map.put("second", 2);
        try map.put("third", 3);

        _ = map.orderedRemove("second");

        const keys = map.keys();
        try std.testing.expectEqualStrings("first", keys[0]);
        try std.testing.expectEqualStrings("third", keys[1]);
    }
}

test "AutoArrayHashMap - Integer Keys (CORRECT USAGE)" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // AutoArrayHashMap works fine with integer keys
    var map = std.array_hash_map.AutoArrayHashMap(u64, []const u8).init(allocator);
    defer map.deinit();

    try map.put(100, "hundred");
    try map.put(200, "two hundred");

    try std.testing.expectEqualStrings("hundred", map.get(100).?);
    try std.testing.expectEqualStrings("two hundred", map.get(200).?);
}
