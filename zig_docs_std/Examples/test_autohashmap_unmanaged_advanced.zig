// Advanced features of AutoHashMapUnmanaged
const std = @import("std");

test "fetchPut returns previous value - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    // First insert - no previous value
    const result1 = try map.fetchPut(allocator, 1, "first");
    try std.testing.expect(result1 == null);

    // Second insert - returns previous value
    const result2 = try map.fetchPut(allocator, 1, "second");
    try std.testing.expect(result2 != null);
    try std.testing.expectEqualStrings("first", result2.?.value);
    try std.testing.expectEqual(@as(u32, 1), result2.?.key);

    // Current value is "second"
    try std.testing.expectEqualStrings("second", map.get(1).?);
}

test "fetchPutAssumeCapacity - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.ensureTotalCapacity(allocator, 10);

    // Insert without allocation
    const result1 = map.fetchPutAssumeCapacity(1, 100);
    try std.testing.expect(result1 == null);

    const result2 = map.fetchPutAssumeCapacity(1, 200);
    try std.testing.expect(result2 != null);
    try std.testing.expectEqual(@as(i32, 100), result2.?.value);
}

test "getOrPutValue - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    // Insert new entry with default value
    const entry1 = try map.getOrPutValue(allocator, 1, 999);
    try std.testing.expectEqual(@as(i32, 999), entry1.value_ptr.*);

    // Get existing entry (value unchanged)
    const entry2 = try map.getOrPutValue(allocator, 1, 111);
    try std.testing.expectEqual(@as(i32, 999), entry2.value_ptr.*);
}

test "getKey and getKeyPtr - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map.deinit(allocator);

    try map.put(allocator, 42, "value");

    // Get copy of key
    const key = map.getKey(42);
    try std.testing.expect(key != null);
    try std.testing.expectEqual(@as(u32, 42), key.?);

    // Get pointer to key
    const key_ptr = map.getKeyPtr(42);
    try std.testing.expect(key_ptr != null);
    try std.testing.expectEqual(@as(u32, 42), key_ptr.?.*);
}

test "removeByPtr - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try map.put(allocator, 1, 100);
    try map.put(allocator, 2, 200);

    // Get key pointer and remove by it
    if (map.getKeyPtr(1)) |key_ptr| {
        map.removeByPtr(key_ptr);
    }

    try std.testing.expect(!map.contains(1));
    try std.testing.expect(map.contains(2));
}

test "Multiple hashmaps with same allocator - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Multiple unmanaged maps can share allocator efficiently
    var map1 = std.AutoHashMapUnmanaged(u32, i32){};
    defer map1.deinit(allocator);

    var map2 = std.AutoHashMapUnmanaged(u32, []const u8){};
    defer map2.deinit(allocator);

    var map3 = std.StringHashMapUnmanaged(u32){};
    defer map3.deinit(allocator);

    try map1.put(allocator, 1, 100);
    try map2.put(allocator, 2, "two");
    try map3.put(allocator, "three", 3);

    try std.testing.expectEqual(@as(i32, 100), map1.get(1).?);
    try std.testing.expectEqualStrings("two", map2.get(2).?);
    try std.testing.expectEqual(@as(u32, 3), map3.get("three").?);
}

test "Passing map to functions - Unmanaged" {
    const Helper = struct {
        fn addItems(map: *std.AutoHashMapUnmanaged(u32, i32), alloc: std.mem.Allocator) !void {
            for (0..10) |i| {
                try map.put(alloc, @intCast(i), @intCast(i * 10));
            }
        }

        fn countEven(map: *const std.AutoHashMapUnmanaged(u32, i32)) usize {
            var count: usize = 0;
            var iter = map.iterator();
            while (iter.next()) |entry| {
                if (@rem(entry.value_ptr.*, 20) == 0) {
                    count += 1;
                }
            }
            return count;
        }
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    try Helper.addItems(&map, allocator);
    const even_count = Helper.countEven(&map);

    try std.testing.expectEqual(@as(usize, 10), map.count());
    try std.testing.expectEqual(@as(usize, 5), even_count);
}

test "Struct with embedded unmanaged map - Unmanaged" {
    const Cache = struct {
        data: std.AutoHashMapUnmanaged(u32, []const u8) = .{},

        fn init() @This() {
            return .{
                .data = .{},
            };
        }

        fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
            self.data.deinit(alloc);
        }

        fn put(self: *@This(), alloc: std.mem.Allocator, key: u32, value: []const u8) !void {
            try self.data.put(alloc, key, value);
        }

        fn get(self: *const @This(), key: u32) ?[]const u8 {
            return self.data.get(key);
        }
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = Cache.init();
    defer cache.deinit(allocator);

    try cache.put(allocator, 1, "one");
    try cache.put(allocator, 2, "two");

    try std.testing.expectEqualStrings("one", cache.get(1).?);
    try std.testing.expectEqual(@as(usize, 2), cache.data.count());
}

test "Promote to managed map - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var unmanaged = std.AutoHashMapUnmanaged(u32, i32){};
    try unmanaged.put(allocator, 1, 100);
    try unmanaged.put(allocator, 2, 200);

    // Promote to managed (wraps unmanaged with allocator)
    // Note: promote doesn't move data, it wraps it
    var managed = unmanaged.promote(allocator);
    defer managed.deinit();

    // managed wraps the data and can use simplified API
    try std.testing.expectEqual(@as(usize, 2), managed.count());
    try managed.put(3, 300); // No allocator parameter needed
    try std.testing.expectEqual(@as(i32, 300), managed.get(3).?);

    // The original unmanaged map now should not be used (managed owns it)
}

test "Combining multiple maps - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map1 = std.AutoHashMapUnmanaged(u32, i32){};
    defer map1.deinit(allocator);

    var map2 = std.AutoHashMapUnmanaged(u32, i32){};
    defer map2.deinit(allocator);

    // Populate maps
    try map1.put(allocator, 1, 10);
    try map1.put(allocator, 2, 20);

    try map2.put(allocator, 3, 30);
    try map2.put(allocator, 4, 40);

    // Merge map2 into map1
    var iter = map2.iterator();
    while (iter.next()) |entry| {
        try map1.put(allocator, entry.key_ptr.*, entry.value_ptr.*);
    }

    try std.testing.expectEqual(@as(usize, 4), map1.count());
    try std.testing.expectEqual(@as(i32, 30), map1.get(3).?);
}

test "Memory efficiency comparison - Unmanaged vs Managed" {
    // Unmanaged: no stored allocator (saves 8 bytes per instance)
    const unmanaged_size = @sizeOf(std.AutoHashMapUnmanaged(u32, i32));
    const managed_size = @sizeOf(std.AutoHashMap(u32, i32));

    // Unmanaged is smaller
    try std.testing.expect(unmanaged_size < managed_size);
}

test "Context-aware operations - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, i32){};
    defer map.deinit(allocator);

    const ctx = std.hash_map.AutoContext(u32){};

    // Use context-aware operations
    try map.putContext(allocator, 1, 100, ctx);
    const value = map.getContext(1, ctx);

    try std.testing.expectEqual(@as(i32, 100), value.?);
}

test "Empty map constant - Unmanaged" {
    // Can use the empty constant
    var map: std.AutoHashMapUnmanaged(u32, i32) = .empty;
    defer map.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 0), map.count());
    try std.testing.expectEqual(@as(usize, 0), map.capacity());
}

test "Large batch insertion with pre-allocation - Unmanaged" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoHashMapUnmanaged(u32, u32){};
    defer map.deinit(allocator);

    const count = 10000;

    // Single allocation
    try map.ensureTotalCapacity(allocator, count);

    // Hot loop - no allocations
    for (0..count) |i| {
        const key: u32 = @intCast(i);
        map.putAssumeCapacity(key, key * key);
    }

    try std.testing.expectEqual(@as(usize, count), map.count());
    try std.testing.expectEqual(@as(u32, 9801), map.get(99).?);
}
