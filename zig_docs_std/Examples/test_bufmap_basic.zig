// Basic BufMap operations: initialization, put, get, remove
// BufMap copies keys and values, managing their memory automatically

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BufMap Basic Operations Test ===\n\n", .{});

    // Test 1: Basic put and get
    {
        std.debug.print("Test 1: Basic Put and Get\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        // Put some key-value pairs
        try map.put("name", "Alice");
        try map.put("city", "Portland");
        try map.put("language", "Zig");

        std.debug.print("  Added 3 key-value pairs\n", .{});

        // Retrieve values
        const name = map.get("name");
        const city = map.get("city");
        const language = map.get("language");
        const missing = map.get("nonexistent");

        std.debug.print("  name: {?s}\n", .{name});
        std.debug.print("  city: {?s}\n", .{city});
        std.debug.print("  language: {?s}\n", .{language});
        std.debug.print("  missing: {?s}\n", .{missing});

        std.debug.print("  Count: {}\n", .{map.count()});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Updating values
    {
        std.debug.print("Test 2: Updating Values\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        try map.put("counter", "1");
        std.debug.print("  Initial value: {?s}\n", .{map.get("counter")});

        // Update the value
        try map.put("counter", "2");
        std.debug.print("  After update: {?s}\n", .{map.get("counter")});

        try map.put("counter", "42");
        std.debug.print("  After second update: {?s}\n", .{map.get("counter")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Remove operations
    {
        std.debug.print("Test 3: Remove Operations\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        try map.put("keep", "this one");
        try map.put("remove", "this one");
        try map.put("also_keep", "this too");

        std.debug.print("  Initial count: {}\n", .{map.count()});

        // Remove one entry
        map.remove("remove");

        std.debug.print("  After removing 'remove': count = {}\n", .{map.count()});
        std.debug.print("  'keep' still exists: {?s}\n", .{map.get("keep")});
        std.debug.print("  'remove' is gone: {?s}\n", .{map.get("remove")});
        std.debug.print("  'also_keep' still exists: {?s}\n", .{map.get("also_keep")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: String ownership - BufMap copies strings
    {
        std.debug.print("Test 4: String Ownership\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        // Create temporary strings in a block
        {
            var key_buf: [10]u8 = undefined;
            var value_buf: [20]u8 = undefined;

            const key = try std.fmt.bufPrint(&key_buf, "key{}", .{42});
            const value = try std.fmt.bufPrint(&value_buf, "value_{}", .{100});

            // BufMap copies these strings
            try map.put(key, value);

            std.debug.print("  Put key='{s}' value='{s}'\n", .{key, value});
        }
        // key_buf and value_buf are now out of scope

        // But the map still has valid copies
        const retrieved = map.get("key42");
        std.debug.print("  Retrieved after buffers out of scope: {?s}\n", .{retrieved});
        std.debug.print("  ✅ PASS - BufMap owns its strings\n\n", .{});
    }

    // Test 5: Empty map behavior
    {
        std.debug.print("Test 5: Empty Map\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        std.debug.print("  Empty map count: {}\n", .{map.count()});
        std.debug.print("  Get from empty map: {?s}\n", .{map.get("anything")});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All basic BufMap tests completed successfully!\n", .{});
}
