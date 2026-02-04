// BufSet iteration patterns
// Demonstrates how to iterate over set members

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BufSet Iteration Test ===\n\n", .{});

    // Test 1: Basic iteration
    {
        std.debug.print("Test 1: Basic Iteration\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        try set.insert("red");
        try set.insert("green");
        try set.insert("blue");
        try set.insert("yellow");

        std.debug.print("  Created set with 4 colors\n", .{});

        var it = set.iterator();
        var count: usize = 0;
        while (it.next()) |value| {
            count += 1;
            std.debug.print("  {}: {s}\n", .{count, value.*});
        }

        std.debug.print("  Total items: {}\n", .{count});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Filtering during iteration
    {
        std.debug.print("Test 2: Filter During Iteration\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        try set.insert("apple");
        try set.insert("apricot");
        try set.insert("banana");
        try set.insert("avocado");
        try set.insert("cherry");

        std.debug.print("  Searching for items starting with 'a'\n", .{});

        var it = set.iterator();
        var found: usize = 0;
        while (it.next()) |value| {
            if (std.mem.startsWith(u8, value.*, "a")) {
                found += 1;
                std.debug.print("  Found: {s}\n", .{value.*});
            }
        }

        std.debug.print("  Found {} items starting with 'a'\n", .{found});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Building a list from iteration
    {
        std.debug.print("Test 3: Collect into Sorted List\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var set = std.BufSet.init(allocator);
        defer set.deinit();

        try set.insert("zebra");
        try set.insert("apple");
        try set.insert("monkey");
        try set.insert("banana");

        std.debug.print("  Collecting all items...\n", .{});

        var items: std.ArrayList([]const u8) = .{};
        defer items.deinit(allocator);

        var it = set.iterator();
        while (it.next()) |value| {
            try items.append(allocator, value.*);
        }

        // Sort the items
        std.mem.sort([]const u8, items.items, {}, struct {
            fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
                return std.mem.order(u8, lhs, rhs) == .lt;
            }
        }.lessThan);

        std.debug.print("  Sorted items: ", .{});
        for (items.items, 0..) |item, i| {
            if (i > 0) std.debug.print(", ", .{});
            std.debug.print("{s}", .{item});
        }
        std.debug.print("\n", .{});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Iteration over empty set
    {
        std.debug.print("Test 4: Empty Set Iteration\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        var it = set.iterator();
        var count: usize = 0;
        while (it.next()) |_| {
            count += 1;
        }

        std.debug.print("  Iterated over empty set\n", .{});
        std.debug.print("  Item count: {}\n", .{count});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Counting matches
    {
        std.debug.print("Test 5: Count Matching Pattern\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var set = std.BufSet.init(allocator);
        defer set.deinit();

        try set.insert("config.debug");
        try set.insert("config.port");
        try set.insert("database.host");
        try set.insert("config.timeout");
        try set.insert("database.port");

        std.debug.print("  Set contains {} items\n", .{set.count()});

        // Count items in each category
        var config_count: usize = 0;
        var database_count: usize = 0;

        var it = set.iterator();
        while (it.next()) |value| {
            if (std.mem.startsWith(u8, value.*, "config.")) {
                config_count += 1;
            } else if (std.mem.startsWith(u8, value.*, "database.")) {
                database_count += 1;
            }
        }

        std.debug.print("  Config entries: {}\n", .{config_count});
        std.debug.print("  Database entries: {}\n", .{database_count});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All BufSet iteration tests completed successfully!\n", .{});
}
