// Tests for std.hash_map namespace documentation
// Validates all code examples from std.hash_map.md work with Zig 0.16

const std = @import("std");

// ============================================================================
// Quick Start Pattern Tests
// ============================================================================

test "Quick Start - String Keys" {
    std.debug.print("\n=== Quick Start - String Keys ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var map = std.StringHashMap(i32).init(gpa.allocator());
    defer map.deinit();

    try map.put("score", 100);
    try map.put("level", 5);

    if (map.get("score")) |value| {
        std.debug.print("Score: {}\n", .{value});
        try std.testing.expectEqual(@as(i32, 100), value);
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start - Integer/Enum Keys" {
    std.debug.print("\n=== Quick Start - Integer/Enum Keys ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, []const u8).init(allocator);
    defer map.deinit();

    try map.put(1, "one");
    try map.put(2, "two");

    const value = map.get(1) orelse "not found";
    std.debug.print("{s}\n", .{value});
    try std.testing.expectEqualStrings("one", value);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start - Counting/Frequency Map" {
    std.debug.print("\n=== Quick Start - Counting/Frequency Map ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var counts = std.StringHashMap(usize).init(allocator);
    defer counts.deinit();

    const words = [_][]const u8{ "foo", "bar", "foo", "baz", "foo" };
    for (words) |word| {
        const result = try counts.getOrPut(word);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    std.debug.print("foo count: {}\n", .{counts.get("foo").?});
    try std.testing.expectEqual(@as(usize, 3), counts.get("foo").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("bar").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("baz").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start - Iterating Over Entries" {
    std.debug.print("\n=== Quick Start - Iterating Over Entries ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("Alice", 25);
    try map.put("Bob", 30);

    var iter = map.iterator();
    var count: usize = 0;
    while (iter.next()) |entry| {
        std.debug.print("{s}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 2), count);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Core Type Tests
// ============================================================================

test "Type - AutoHashMap" {
    std.debug.print("\n=== Type - AutoHashMap ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, []const u8).init(allocator);
    defer map.deinit();

    try map.put(42, "answer");
    const val = map.get(42);

    std.debug.print("Value: {s}\n", .{val.?});
    try std.testing.expectEqualStrings("answer", val.?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Type - AutoHashMapUnmanaged" {
    std.debug.print("\n=== Type - AutoHashMapUnmanaged ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.AutoHashMapUnmanaged(u32, i32) = .{};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 100);
    try map.put(allocator, 2, 200);

    try std.testing.expectEqual(@as(i32, 100), map.get(1).?);
    try std.testing.expectEqual(@as(i32, 200), map.get(2).?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Type - StringHashMap" {
    std.debug.print("\n=== Type - StringHashMap ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("Alice", 25);
    try map.put("Bob", 30);

    try std.testing.expectEqual(@as(i32, 25), map.get("Alice").?);
    try std.testing.expectEqual(@as(i32, 30), map.get("Bob").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Type - StringHashMapUnmanaged" {
    std.debug.print("\n=== Type - StringHashMapUnmanaged ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.StringHashMapUnmanaged(i32) = .{};
    defer map.deinit(allocator);

    try map.put(allocator, "key", 42);

    try std.testing.expectEqual(@as(i32, 42), map.get("key").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Utility Function Tests
// ============================================================================

test "Utility - hashString" {
    std.debug.print("\n=== Utility - hashString ===\n", .{});

    const hash1 = std.hash_map.hashString("hello");
    const hash2 = std.hash_map.hashString("hello");
    const hash3 = std.hash_map.hashString("world");

    std.debug.print("hash1: {}, hash2: {}, hash3: {}\n", .{ hash1, hash2, hash3 });
    try std.testing.expectEqual(hash1, hash2);
    try std.testing.expect(hash1 != hash3);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Utility - eqlString" {
    std.debug.print("\n=== Utility - eqlString ===\n", .{});

    const equal = std.hash_map.eqlString("foo", "foo");
    const not_equal = std.hash_map.eqlString("foo", "bar");

    std.debug.print("equal: {}, not_equal: {}\n", .{ equal, not_equal });
    try std.testing.expect(equal);
    try std.testing.expect(!not_equal);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Common Operations Tests
// ============================================================================

test "Operation - put and get" {
    std.debug.print("\n=== Operation - put and get ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("key", 42);
    const value = map.get("key") orelse 0;

    try std.testing.expectEqual(@as(i32, 42), value);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Operation - getOrPut" {
    std.debug.print("\n=== Operation - getOrPut ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(u32).init(allocator);
    defer map.deinit();

    const result = try map.getOrPut("counter");
    if (result.found_existing) {
        result.value_ptr.* += 1;
    } else {
        result.value_ptr.* = 1;
    }

    try std.testing.expectEqual(@as(u32, 1), map.get("counter").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Operation - remove" {
    std.debug.print("\n=== Operation - remove ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("key", 42);
    const removed = map.remove("key");

    std.debug.print("removed: {}\n", .{removed});
    try std.testing.expect(removed);
    try std.testing.expect(map.get("key") == null);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Operation - contains" {
    std.debug.print("\n=== Operation - contains ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("key", 42);

    try std.testing.expect(map.contains("key"));
    try std.testing.expect(!map.contains("missing"));

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Operation - clearAndFree" {
    std.debug.print("\n=== Operation - clearAndFree ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("key1", 1);
    try map.put("key2", 2);

    map.clearAndFree();

    try std.testing.expectEqual(@as(usize, 0), map.count());

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Usage Pattern Tests
// ============================================================================

fn countWords(allocator: std.mem.Allocator, text: []const u8) !std.StringHashMap(usize) {
    var counts = std.StringHashMap(usize).init(allocator);
    errdefer counts.deinit();

    var iter = std.mem.tokenizeAny(u8, text, " \t\n,.");
    while (iter.next()) |word| {
        const result = try counts.getOrPut(word);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    return counts;
}

test "Usage Pattern - Word Frequency Counter" {
    std.debug.print("\n=== Usage Pattern - Word Frequency Counter ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var counts = try countWords(gpa.allocator(), "foo bar foo baz foo");
    defer counts.deinit();

    var iter = counts.iterator();
    while (iter.next()) |entry| {
        std.debug.print("{s}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    try std.testing.expectEqual(@as(usize, 3), counts.get("foo").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("bar").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("baz").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

const FibCache = std.AutoHashMap(u64, u64);

fn fibonacci(cache: *FibCache, n: u64) !u64 {
    if (n <= 1) return n;

    if (cache.get(n)) |cached| {
        return cached;
    }

    const result = try fibonacci(cache, n - 1) + try fibonacci(cache, n - 2);
    try cache.put(n, result);
    return result;
}

test "Usage Pattern - Memoization Cache" {
    std.debug.print("\n=== Usage Pattern - Memoization Cache ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var cache = FibCache.init(gpa.allocator());
    defer cache.deinit();

    const result = try fibonacci(&cache, 50);
    std.debug.print("fib(50) = {}\n", .{result});

    try std.testing.expectEqual(@as(u64, 12586269025), result);

    std.debug.print("  ✅ PASS\n\n", .{});
}

fn loadConfig(allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var config = std.StringHashMap([]const u8).init(allocator);
    errdefer config.deinit();

    try config.ensureTotalCapacity(10);

    config.putAssumeCapacity("host", "localhost");
    config.putAssumeCapacity("port", "8080");
    config.putAssumeCapacity("timeout", "30");

    return config;
}

test "Usage Pattern - Configuration Map with Pre-allocation" {
    std.debug.print("\n=== Usage Pattern - Configuration Map with Pre-allocation ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var config = try loadConfig(gpa.allocator());
    defer config.deinit();

    try std.testing.expectEqualStrings("localhost", config.get("host").?);
    try std.testing.expectEqualStrings("8080", config.get("port").?);
    try std.testing.expectEqualStrings("30", config.get("timeout").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

const Cache = struct {
    map: std.AutoHashMapUnmanaged(u32, []const u8) = .{},
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Cache {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Cache) void {
        self.map.deinit(self.allocator);
    }

    pub fn put(self: *Cache, key: u32, value: []const u8) !void {
        try self.map.put(self.allocator, key, value);
    }

    pub fn get(self: *Cache, key: u32) ?[]const u8 {
        return self.map.get(key);
    }
};

test "Usage Pattern - Unmanaged Map for Explicit Control" {
    std.debug.print("\n=== Usage Pattern - Unmanaged Map for Explicit Control ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var cache = Cache.init(gpa.allocator());
    defer cache.deinit();

    try cache.put(1, "one");
    try cache.put(2, "two");

    try std.testing.expectEqualStrings("one", cache.get(1).?);
    try std.testing.expectEqualStrings("two", cache.get(2).?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Performance Tip Tests
// ============================================================================

test "Performance Tip - Pre-allocate capacity" {
    std.debug.print("\n=== Performance Tip - Pre-allocate capacity ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Use AutoHashMap for performance test to avoid string allocation complexity
    var map = std.AutoHashMap(usize, i32).init(allocator);
    defer map.deinit();

    try map.ensureTotalCapacity(1000);
    for (0..1000) |i| {
        map.putAssumeCapacity(i, @intCast(i));
    }

    try std.testing.expectEqual(@as(usize, 1000), map.count());

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Performance Tip - Use getPtr to avoid double lookup" {
    std.debug.print("\n=== Performance Tip - Use getPtr to avoid double lookup ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.StringHashMap(i32).init(allocator);
    defer map.deinit();

    try map.put("counter", 0);

    if (map.getPtr("counter")) |value_ptr| {
        value_ptr.* += 1;
    }

    try std.testing.expectEqual(@as(i32, 1), map.get("counter").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Performance Tip - putAssumeCapacity after pre-allocation" {
    std.debug.print("\n=== Performance Tip - putAssumeCapacity after pre-allocation ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMap(u32, i32).init(allocator);
    defer map.deinit();

    try map.ensureTotalCapacity(100);
    for (0..100) |i| {
        map.putAssumeCapacity(@intCast(i), @intCast(i * 2));
    }

    try std.testing.expectEqual(@as(usize, 100), map.count());

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Performance Tip - clearRetainingCapacity for reuse" {
    std.debug.print("\n=== Performance Tip - clearRetainingCapacity for reuse ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = std.StringHashMap(i32).init(allocator);
    defer cache.deinit();

    for (0..3) |batch| {
        cache.clearRetainingCapacity();
        try cache.put("batch", @intCast(batch));
    }

    try std.testing.expectEqual(@as(i32, 2), cache.get("batch").?);

    std.debug.print("  ✅ PASS\n\n", .{});
}
