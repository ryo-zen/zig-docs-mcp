// Comprehensive tests for ArrayHashMap with custom context
// These examples demonstrate proper usage of ArrayHashMap in Zig 0.16
const std = @import("std");

test "ArrayHashMap - Basic Usage with Custom Context" {
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

    var map = std.array_hash_map.ArrayHashMap(
        []const u8,
        i32,
        StringContext,
        true,
    ).init(allocator);
    defer map.deinit();

    try map.put("key", 42);
    try std.testing.expectEqual(@as(i32, 42), map.get("key").?);
}

test "ArrayHashMap - Stateful Context with Seed" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const MyContext = struct {
        seed: u64,

        pub fn hash(ctx: @This(), key: u64) u32 {
            var hasher = std.hash.Wyhash.init(ctx.seed);
            std.hash.autoHash(&hasher, key);
            return @truncate(hasher.final());
        }

        pub fn eql(ctx: @This(), a: u64, b: u64, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return a == b;
        }
    };

    const ctx = MyContext{ .seed = 12345 };
    var map = std.array_hash_map.ArrayHashMap(u64, []const u8, MyContext, false).initContext(allocator, ctx);
    defer map.deinit();

    try map.put(100, "test");
    try std.testing.expectEqualStrings("test", map.get(100).?);
}

test "ArrayHashMap - Case-Insensitive String Map" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const CaseInsensitiveContext = struct {
        pub fn hash(ctx: @This(), key: []const u8) u32 {
            _ = ctx;
            var hasher = std.hash.Wyhash.init(0);
            for (key) |c| {
                std.hash.autoHash(&hasher, std.ascii.toLower(c));
            }
            return @truncate(hasher.final());
        }

        pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return std.ascii.eqlIgnoreCase(a, b);
        }
    };

    var map = std.array_hash_map.ArrayHashMap(
        []const u8,
        i32,
        CaseInsensitiveContext,
        true,
    ).init(gpa.allocator());
    defer map.deinit();

    try map.put("Hello", 1);
    try std.testing.expectEqual(@as(i32, 1), map.get("HELLO").?);
    try std.testing.expectEqual(@as(i32, 1), map.get("hello").?);
    try std.testing.expectEqual(@as(i32, 1), map.get("HeLLo").?);
}

test "ArrayHashMap - Custom Struct Keys" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const Point = struct {
        x: i32,
        y: i32,
    };

    const PointContext = struct {
        pub fn hash(ctx: @This(), p: Point) u32 {
            _ = ctx;
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, p.x);
            std.hash.autoHash(&hasher, p.y);
            return @truncate(hasher.final());
        }

        pub fn eql(ctx: @This(), a: Point, b: Point, b_index: usize) bool {
            _ = ctx;
            _ = b_index;
            return a.x == b.x and a.y == b.y;
        }
    };

    var map = std.array_hash_map.ArrayHashMap(
        Point,
        []const u8,
        PointContext,
        false,
    ).init(gpa.allocator());
    defer map.deinit();

    try map.put(Point{ .x = 10, .y = 20 }, "A");
    try map.put(Point{ .x = 30, .y = 40 }, "B");

    try std.testing.expectEqualStrings("A", map.get(Point{ .x = 10, .y = 20 }).?);
    try std.testing.expectEqualStrings("B", map.get(Point{ .x = 30, .y = 40 }).?);
}

test "ArrayHashMap - getOrPut Pattern" {
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

    var map = std.array_hash_map.ArrayHashMap(
        []const u8,
        i32,
        StringContext,
        true,
    ).init(allocator);
    defer map.deinit();

    const result = try map.getOrPut("counter");
    if (!result.found_existing) {
        result.value_ptr.* = 0;
    }
    result.value_ptr.* += 1;

    try std.testing.expectEqual(@as(i32, 1), map.get("counter").?);
}

test "ArrayHashMap - Iteration and Sort" {
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

    var map = std.array_hash_map.ArrayHashMap(
        u64,
        i32,
        IntContext,
        false,
    ).init(allocator);
    defer map.deinit();

    try map.put(30, 3);
    try map.put(10, 1);
    try map.put(20, 2);

    const SortCtx = struct {
        keys: []const u64,
        pub fn lessThan(ctx: @This(), a_idx: usize, b_idx: usize) bool {
            return ctx.keys[a_idx] < ctx.keys[b_idx];
        }
    };

    map.sort(SortCtx{ .keys = map.keys() });

    const keys = map.keys();
    try std.testing.expectEqual(@as(u64, 10), keys[0]);
    try std.testing.expectEqual(@as(u64, 20), keys[1]);
    try std.testing.expectEqual(@as(u64, 30), keys[2]);
}

test "ArrayHashMap - Clone" {
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

    var map = std.array_hash_map.ArrayHashMap(u64, i32, IntContext, false).init(allocator);
    defer map.deinit();

    try map.put(1, 10);
    try map.put(2, 20);

    var map2 = try map.clone();
    defer map2.deinit();

    try std.testing.expectEqual(@as(i32, 10), map2.get(1).?);
    try std.testing.expectEqual(@as(i32, 20), map2.get(2).?);
}
