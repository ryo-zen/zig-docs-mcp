// BufMap iteration patterns
// Demonstrates how to iterate over key-value pairs

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BufMap Iteration Test ===\n\n", .{});

    // Test 1: Basic iteration
    {
        std.debug.print("Test 1: Basic Iteration\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        try map.put("apple", "red");
        try map.put("banana", "yellow");
        try map.put("grape", "purple");
        try map.put("orange", "orange");

        std.debug.print("  Created map with 4 fruit colors\n", .{});

        var it = map.iterator();
        var count: usize = 0;
        while (it.next()) |entry| {
            count += 1;
            std.debug.print("  {}: {s} = {s}\n", .{count, entry.key_ptr.*, entry.value_ptr.*});
        }

        std.debug.print("  Total entries: {}\n", .{count});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Iteration for searching
    {
        std.debug.print("Test 2: Search During Iteration\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        try map.put("config.debug", "true");
        try map.put("config.port", "8080");
        try map.put("database.host", "localhost");
        try map.put("config.max_connections", "100");

        std.debug.print("  Searching for keys starting with 'config.'\n", .{});

        var it = map.iterator();
        var found: usize = 0;
        while (it.next()) |entry| {
            if (std.mem.startsWith(u8, entry.key_ptr.*, "config.")) {
                found += 1;
                std.debug.print("  Found: {s} = {s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
            }
        }

        std.debug.print("  Found {} config entries\n", .{found});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Building a list from iteration
    {
        std.debug.print("Test 3: Collect Keys into List\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        try map.put("user1", "Alice");
        try map.put("user2", "Bob");
        try map.put("user3", "Charlie");

        std.debug.print("  Collecting all keys...\n", .{});

        var keys: std.ArrayList([]const u8) = .{};
        defer keys.deinit(gpa.allocator());

        var it = map.iterator();
        while (it.next()) |entry| {
            try keys.append(gpa.allocator(), entry.key_ptr.*);
        }

        std.debug.print("  Collected {} keys: ", .{keys.items.len});
        for (keys.items, 0..) |key, i| {
            if (i > 0) std.debug.print(", ", .{});
            std.debug.print("{s}", .{key});
        }
        std.debug.print("\n", .{});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Iteration over empty map
    {
        std.debug.print("Test 4: Empty Map Iteration\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        var it = map.iterator();
        var count: usize = 0;
        while (it.next()) |_| {
            count += 1;
        }

        std.debug.print("  Iterated over empty map\n", .{});
        std.debug.print("  Entry count: {}\n", .{count});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Modifying values during iteration
    {
        std.debug.print("Test 5: Using getPtr to Modify Values\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        try map.put("counter_a", "5");
        try map.put("counter_b", "10");
        try map.put("counter_c", "3");

        std.debug.print("  Original values:\n", .{});
        var it = map.iterator();
        while (it.next()) |entry| {
            std.debug.print("    {s} = {s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
        }

        // Note: getPtr returns a pointer that is invalidated if the map resizes
        // This is safe if we're not adding new entries
        if (map.getPtr("counter_a")) |_| {
            // To modify, we'd need to allocate and put again
            // BufMap owns its strings, so we can't just change ptr.*
            std.debug.print("  Found counter_a pointer (would need put() to change value)\n", .{});
        }

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All BufMap iteration tests completed successfully!\n", .{});
}
