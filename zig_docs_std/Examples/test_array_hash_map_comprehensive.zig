// Comprehensive tests for ArrayHashMapUnmanaged with custom context
// These examples demonstrate proper ArrayHashMap usage in Zig 0.16
const std = @import("std");

test "ArrayHashMapUnmanaged - Basic Usage with Custom Context" {
    var gpa = std.heap.DebugAllocator(.{}){};
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

    var map: std.ArrayHashMapUnmanaged(
        []const u8,
        i32,
        StringContext,
        true,
    ) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, "key", 42);
    try std.testing.expectEqual(@as(i32, 42), map.get("key").?);
}

test "ArrayHashMapUnmanaged - Stateful Context with Seed" {
    var gpa = std.heap.DebugAllocator(.{}){};
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
    var map: std.ArrayHashMapUnmanaged(u64, []const u8, MyContext, false) = .empty;
    defer map.deinit(allocator);

    try map.putContext(allocator, 100, "test", ctx);
    try std.testing.expectEqualStrings("test", map.getContext(100, ctx).?);
}

test "ArrayHashMapUnmanaged - Case-Insensitive String Map" {
    var gpa = std.heap.DebugAllocator(.{}){};
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

    var map: std.ArrayHashMapUnmanaged(
        []const u8,
        i32,
        CaseInsensitiveContext,
        true,
    ) = .empty;
    defer map.deinit(gpa.allocator());

    try map.put(gpa.allocator(), "Hello", 1);
    try std.testing.expectEqual(@as(i32, 1), map.get("HELLO").?);
    try std.testing.expectEqual(@as(i32, 1), map.get("hello").?);
    try std.testing.expectEqual(@as(i32, 1), map.get("HeLLo").?);
}

test "ArrayHashMapUnmanaged - Custom Struct Keys" {
    var gpa = std.heap.DebugAllocator(.{}){};
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

    var map: std.ArrayHashMapUnmanaged(
        Point,
        []const u8,
        PointContext,
        false,
    ) = .empty;
    defer map.deinit(gpa.allocator());

    try map.put(gpa.allocator(), Point{ .x = 10, .y = 20 }, "A");
    try map.put(gpa.allocator(), Point{ .x = 30, .y = 40 }, "B");

    try std.testing.expectEqualStrings("A", map.get(Point{ .x = 10, .y = 20 }).?);
    try std.testing.expectEqualStrings("B", map.get(Point{ .x = 30, .y = 40 }).?);
}

test "ArrayHashMapUnmanaged - getOrPut Pattern" {
    var gpa = std.heap.DebugAllocator(.{}){};
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

    var map: std.ArrayHashMapUnmanaged(
        []const u8,
        i32,
        StringContext,
        true,
    ) = .empty;
    defer map.deinit(allocator);

    const result = try map.getOrPut(allocator, "counter");
    if (!result.found_existing) {
        result.value_ptr.* = 0;
    }
    result.value_ptr.* += 1;

    try std.testing.expectEqual(@as(i32, 1), map.get("counter").?);
}

test "ArrayHashMapUnmanaged - Iteration and Sort" {
    var gpa = std.heap.DebugAllocator(.{}){};
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

    var map: std.ArrayHashMapUnmanaged(
        u64,
        i32,
        IntContext,
        false,
    ) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, 30, 3);
    try map.put(allocator, 10, 1);
    try map.put(allocator, 20, 2);

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

test "ArrayHashMapUnmanaged - Clone" {
    var gpa = std.heap.DebugAllocator(.{}){};
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

    var map: std.ArrayHashMapUnmanaged(u64, i32, IntContext, false) = .empty;
    defer map.deinit(allocator);

    try map.put(allocator, 1, 10);
    try map.put(allocator, 2, 20);

    var map2 = try map.clone(allocator);
    defer map2.deinit(allocator);

    try std.testing.expectEqual(@as(i32, 10), map2.get(1).?);
    try std.testing.expectEqual(@as(i32, 20), map2.get(2).?);
}
