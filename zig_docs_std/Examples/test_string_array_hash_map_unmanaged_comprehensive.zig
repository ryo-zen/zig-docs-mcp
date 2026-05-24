// Comprehensive tests for StringArrayHashMapUnmanaged
// NOTE: Use StringArrayHashMapUnmanaged for string keys, NOT AutoArrayHashMapUnmanaged([]const u8, V)
const std = @import("std");

test "StringArrayHashMapUnmanaged - Basic Usage" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMapUnmanaged(i32){};
    defer map.deinit(allocator);

    try map.put(allocator, "apple", 5);
    try map.put(allocator, "banana", 3);

    try std.testing.expectEqual(@as(i32, 5), map.get("apple").?);
    try std.testing.expectEqual(@as(i32, 3), map.get("banana").?);
}

test "StringArrayHashMapUnmanaged - Iteration Pattern" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMapUnmanaged(i32){};
    defer map.deinit(allocator);

    try map.put(allocator, "first", 1);
    try map.put(allocator, "second", 2);
    try map.put(allocator, "third", 3);

    var iter = map.iterator();
    var count: usize = 0;
    while (iter.next()) |entry| {
        _ = entry;
        count += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), count);
}

test "StringArrayHashMapUnmanaged - getOrPut with Allocator" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMapUnmanaged(i32){};
    defer map.deinit(allocator);

    const result = try map.getOrPut(allocator, "counter");
    if (!result.found_existing) {
        result.value_ptr.* = 0;
    }
    result.value_ptr.* += 1;

    try std.testing.expectEqual(@as(i32, 1), map.get("counter").?);
}

test "StringArrayHashMapUnmanaged - Pre-allocation for Performance" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMapUnmanaged(i32){};
    defer map.deinit(allocator);

    try map.ensureTotalCapacity(allocator, 100);

    const keys = [_][]const u8{ "a", "b", "c", "d", "e" };
    for (keys, 0..) |key, i| {
        map.putAssumeCapacity(key, @intCast(i));
    }

    try std.testing.expectEqual(@as(usize, 5), map.count());
}

test "StringArrayHashMapUnmanaged - Word Frequency Counter" {
    const countWords = struct {
        fn func(alloc: std.mem.Allocator, text: []const u8) !std.StringArrayHashMapUnmanaged(usize) {
            var counts = std.StringArrayHashMapUnmanaged(usize){};

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

    var counts = try countWords(allocator, "hello world hello zig");
    defer counts.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 2), counts.get("hello").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("world").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("zig").?);
}

test "StringArrayHashMapUnmanaged - Embedding in a Struct" {
    const StringCache = struct {
        data: std.StringArrayHashMapUnmanaged([]const u8) = .{},

        pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
            self.data.deinit(alloc);
        }

        pub fn put(self: *@This(), alloc: std.mem.Allocator, key: []const u8, value: []const u8) !void {
            try self.data.put(alloc, key, value);
        }

        pub fn get(self: *@This(), key: []const u8) ?[]const u8 {
            return self.data.get(key);
        }

        pub fn count(self: *@This()) usize {
            return self.data.count();
        }
    };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = StringCache{};
    defer cache.deinit(allocator);

    try cache.put(allocator, "Alice", "Engineer");
    try cache.put(allocator, "Bob", "Designer");

    try std.testing.expectEqualStrings("Engineer", cache.get("Alice").?);
    try std.testing.expectEqual(@as(usize, 2), cache.count());
}

test "StringArrayHashMapUnmanaged - Batch Insert" {
    const KeyValue = struct { key: []const u8, value: i32 };

    const bulkInsert = struct {
        fn func(
            map: *std.StringArrayHashMapUnmanaged(i32),
            alloc: std.mem.Allocator,
            pairs: []const KeyValue,
        ) !void {
            try map.ensureUnusedCapacity(alloc, pairs.len);

            for (pairs) |pair| {
                map.putAssumeCapacity(pair.key, pair.value);
            }
        }
    }.func;

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMapUnmanaged(i32){};
    defer map.deinit(allocator);

    const pairs = [_]KeyValue{
        .{ .key = "a", .value = 1 },
        .{ .key = "b", .value = 2 },
        .{ .key = "c", .value = 3 },
    };

    try bulkInsert(&map, allocator, &pairs);

    try std.testing.expectEqual(@as(i32, 1), map.get("a").?);
    try std.testing.expectEqual(@as(i32, 2), map.get("b").?);
    try std.testing.expectEqual(@as(i32, 3), map.get("c").?);
}

test "StringArrayHashMapUnmanaged - Clone" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringArrayHashMapUnmanaged(i32){};
    defer map.deinit(allocator);

    try map.put(allocator, "key1", 42);
    try map.put(allocator, "key2", 99);

    var map2 = try map.clone(allocator);
    defer map2.deinit(allocator);

    try std.testing.expectEqual(@as(i32, 42), map2.get("key1").?);
    try std.testing.expectEqual(@as(i32, 99), map2.get("key2").?);
}

test "AutoArrayHashMapUnmanaged - Integer Keys (CORRECT USAGE)" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // AutoArrayHashMapUnmanaged works fine with integer keys
    var map = std.AutoArrayHashMapUnmanaged(u64, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 100, "hundred");
    try map.put(allocator, 200, "two hundred");

    try std.testing.expectEqualStrings("hundred", map.get(100).?);
}
