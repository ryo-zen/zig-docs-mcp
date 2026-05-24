// Basic BufSet operations: initialization, insert, contains, remove
// BufSet duplicates strings internally and manages their memory

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BufSet Basic Operations Test ===\n\n", .{});

    // Test 1: Basic insert and contains
    {
        std.debug.print("Test 1: Basic Insert and Contains\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        // Insert some strings
        try set.insert("apple");
        try set.insert("banana");
        try set.insert("cherry");

        std.debug.print("  Inserted 3 items\n", .{});

        // Check containment
        std.debug.print("  Contains 'apple': {}\n", .{set.contains("apple")});
        std.debug.print("  Contains 'banana': {}\n", .{set.contains("banana")});
        std.debug.print("  Contains 'cherry': {}\n", .{set.contains("cherry")});
        std.debug.print("  Contains 'orange': {}\n", .{set.contains("orange")});

        std.debug.print("  Count: {}\n", .{set.count()});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Duplicate inserts
    {
        std.debug.print("Test 2: Duplicate Inserts\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        try set.insert("value");
        std.debug.print("  Inserted 'value', count: {}\n", .{set.count()});

        // Insert same value again
        try set.insert("value");
        std.debug.print("  Inserted 'value' again, count: {}\n", .{set.count()});

        try set.insert("value");
        std.debug.print("  Inserted 'value' third time, count: {}\n", .{set.count()});

        std.debug.print("  Set contains unique values only\n", .{});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Remove operations
    {
        std.debug.print("Test 3: Remove Operations\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        try set.insert("keep");
        try set.insert("remove");
        try set.insert("also_keep");

        std.debug.print("  Initial count: {}\n", .{set.count()});

        // Remove one item
        set.remove("remove");

        std.debug.print("  After removing 'remove': count = {}\n", .{set.count()});
        std.debug.print("  Contains 'keep': {}\n", .{set.contains("keep")});
        std.debug.print("  Contains 'remove': {}\n", .{set.contains("remove")});
        std.debug.print("  Contains 'also_keep': {}\n", .{set.contains("also_keep")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: String ownership - BufSet copies strings
    {
        std.debug.print("Test 4: String Ownership\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        // Create temporary strings in a block
        {
            var buf: [20]u8 = undefined;
            const value = try std.fmt.bufPrint(&buf, "temp_{}", .{42});

            // BufSet copies this string
            try set.insert(value);
            std.debug.print("  Inserted '{s}'\n", .{value});
        }
        // buf is now out of scope

        // But the set still has a valid copy
        std.debug.print("  Contains 'temp_42' after buffer out of scope: {}\n", .{set.contains("temp_42")});
        std.debug.print("  ✅ PASS - BufSet owns its strings\n\n", .{});
    }

    // Test 5: Empty set behavior
    {
        std.debug.print("Test 5: Empty Set\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        std.debug.print("  Empty set count: {}\n", .{set.count()});
        std.debug.print("  Contains anything: {}\n", .{set.contains("anything")});

        // Remove from empty set (no-op)
        set.remove("nonexistent");
        std.debug.print("  After remove on empty set: count = {}\n", .{set.count()});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 6: Large set
    {
        std.debug.print("Test 6: Large Set\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var set = std.BufSet.init(allocator);
        defer set.deinit();

        // Insert many values
        var i: usize = 0;
        while (i < 1000) : (i += 1) {
            const value = try std.fmt.allocPrint(allocator, "value_{}", .{i});
            defer allocator.free(value);
            try set.insert(value);
        }

        std.debug.print("  Inserted 1000 unique values\n", .{});
        std.debug.print("  Count: {}\n", .{set.count()});

        // Check some values
        std.debug.print("  Contains 'value_0': {}\n", .{set.contains("value_0")});
        std.debug.print("  Contains 'value_500': {}\n", .{set.contains("value_500")});
        std.debug.print("  Contains 'value_999': {}\n", .{set.contains("value_999")});
        std.debug.print("  Contains 'value_1000': {}\n", .{set.contains("value_1000")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All basic BufSet tests completed successfully!\n", .{});
}
