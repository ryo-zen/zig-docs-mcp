// Comprehensive tests for ArrayHashMapUnmanaged
// Demonstrates unmanaged variant with manual allocator passing
const std = @import("std");

test "ArrayHashMapUnmanaged - Basic Usage" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const StringContext = struct {
        pub fn hash(ctx: @This(), key: []const u8) u32 {
            _ = ctx;
            return std.array_hash_map.hashString(key);
        }
        pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return std.mem.eql(u8, a, b);
        }
    };

    var map = std.array_hash_map.ArrayHashMapUnmanaged(
        []const u8,
        i32,
        StringContext,
        true,
    ){};
    defer map.deinit(allocator);

    try map.put(allocator, "key", 42);
    try std.testing.expectEqual(@as(i32, 42), map.get("key").?);
}

test "ArrayHashMapUnmanaged - Empty Initialization" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const IntContext = struct {
        pub fn hash(ctx: @This(), key: u64) u32 {
            _ = ctx;
            return @truncate(key);
        }
        pub fn eql(ctx: @This(), a: u64, b: u64, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return a == b;
        }
    };

    var map = std.array_hash_map.ArrayHashMapUnmanaged(u64, i32, IntContext, false).empty;
    defer map.deinit(allocator);

    try map.put(allocator, 1, 10);
    try std.testing.expectEqual(@as(i32, 10), map.get(1).?);
}

test "ArrayHashMapUnmanaged - Pre-allocation for Performance" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const IntContext = struct {
        pub fn hash(ctx: @This(), key: u64) u32 {
            _ = ctx;
            return @truncate(key);
        }
        pub fn eql(ctx: @This(), a: u64, b: u64, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return a == b;
        }
    };

    var map = std.array_hash_map.ArrayHashMapUnmanaged(u64, u64, IntContext, false).empty;
    defer map.deinit(allocator);

    try map.ensureTotalCapacity(allocator, 100);
    for (0..100) |i| {
        map.putAssumeCapacity(i, i * 2);
    }

    try std.testing.expectEqual(@as(usize, 100), map.count());
    try std.testing.expectEqual(@as(u64, 198), map.get(99).?);
}

test "ArrayHashMapUnmanaged - Word Counter" {
    const StringContext = struct {
        pub fn hash(ctx: @This(), key: []const u8) u32 {
            _ = ctx;
            return std.array_hash_map.hashString(key);
        }
        pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return std.mem.eql(u8, a, b);
        }
    };

    const countWords = struct {
        fn func(alloc: std.mem.Allocator, text: []const u8) !std.array_hash_map.ArrayHashMapUnmanaged([]const u8, usize, StringContext, true) {
            var counts = std.array_hash_map.ArrayHashMapUnmanaged([]const u8, usize, StringContext, true).empty;

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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var counts = try countWords(allocator, "hello world hello zig world");
    defer counts.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 2), counts.get("hello").?);
    try std.testing.expectEqual(@as(usize, 2), counts.get("world").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("zig").?);
}

test "ArrayHashMapUnmanaged - Embedding in Struct" {
    const IntContext = std.array_hash_map.AutoContext(u64);

    const Cache = struct {
        data: std.array_hash_map.ArrayHashMapUnmanaged(u64, []const u8, IntContext, false) = .{},
        allocator: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) @This() {
            return .{ .allocator = alloc };
        }

        pub fn deinit(self: *@This()) void {
            self.data.deinit(self.allocator);
        }

        pub fn put(self: *@This(), key: u64, value: []const u8) !void {
            try self.data.put(self.allocator, key, value);
        }

        pub fn get(self: *@This(), key: u64) ?[]const u8 {
            return self.data.get(key);
        }

        pub fn count(self: *@This()) usize {
            return self.data.count();
        }
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = Cache.init(allocator);
    defer cache.deinit();

    try cache.put(1, "one");
    try cache.put(2, "two");

    try std.testing.expectEqualStrings("one", cache.get(1).?);
    try std.testing.expectEqual(@as(usize, 2), cache.count());
}

test "ArrayHashMapUnmanaged - init with slices" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const StringContext = struct {
        pub fn hash(ctx: @This(), key: []const u8) u32 {
            _ = ctx;
            return std.array_hash_map.hashString(key);
        }
        pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return std.mem.eql(u8, a, b);
        }
    };

    const keys = [_][]const u8{ "a", "b", "c" };
    const values = [_]i32{ 1, 2, 3 };
    var map = try std.array_hash_map.ArrayHashMapUnmanaged([]const u8, i32, StringContext, true).init(
        allocator,
        &keys,
        &values,
    );
    defer map.deinit(allocator);

    try std.testing.expectEqual(@as(i32, 1), map.get("a").?);
    try std.testing.expectEqual(@as(i32, 2), map.get("b").?);
    try std.testing.expectEqual(@as(i32, 3), map.get("c").?);
}
