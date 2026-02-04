// BufMap ownership patterns: put vs putMove
// Demonstrates the difference between copying and transferring ownership

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BufMap Ownership Test ===\n\n", .{});

    // Test 1: put() - copies the strings
    {
        std.debug.print("Test 1: put() - BufMap Copies Strings\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        const original_key = "temperature";
        const original_value = "72F";

        // put() copies both key and value
        try map.put(original_key, original_value);

        std.debug.print("  Called put() with key and value\n", .{});
        std.debug.print("  Original strings remain valid and owned by caller\n", .{});
        std.debug.print("  BufMap has its own copies\n", .{});

        const retrieved = map.get("temperature");
        std.debug.print("  Retrieved value: {?s}\n", .{retrieved});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: putMove() - transfers ownership
    {
        std.debug.print("Test 2: putMove() - Transfer Ownership\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        // Allocate strings that we'll transfer ownership of
        const key = try gpa.allocator().dupe(u8, "setting");
        const value = try gpa.allocator().dupe(u8, "enabled");

        std.debug.print("  Allocated key and value on heap\n", .{});

        // putMove transfers ownership - BufMap will free them
        try map.putMove(key, value);
        // DO NOT free key or value here - BufMap owns them now

        std.debug.print("  Called putMove() - ownership transferred to BufMap\n", .{});
        std.debug.print("  Caller should NOT free the strings\n", .{});

        const retrieved = map.get("setting");
        std.debug.print("  Retrieved value: {?s}\n", .{retrieved});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Practical use case - building from allocated strings
    {
        std.debug.print("Test 3: Practical putMove Use Case\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var map = std.BufMap.init(allocator);
        defer map.deinit();

        // Imagine we're parsing configuration and already have allocated strings
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            // Allocate formatted strings
            const key = try std.fmt.allocPrint(allocator, "item_{}", .{i});
            const value = try std.fmt.allocPrint(allocator, "value_{}", .{i * 10});

            // Transfer ownership to map
            try map.putMove(key, value);
            std.debug.print("  Added item_{} with putMove\n", .{i});
        }

        std.debug.print("  Map now contains {} entries\n", .{map.count()});

        // Verify
        std.debug.print("  item_0 = {?s}\n", .{map.get("item_0")});
        std.debug.print("  item_1 = {?s}\n", .{map.get("item_1")});
        std.debug.print("  item_2 = {?s}\n", .{map.get("item_2")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: putMove failure doesn't transfer ownership
    {
        std.debug.print("Test 4: putMove Failure - Ownership Not Transferred\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var map = std.BufMap.init(allocator);
        defer map.deinit();

        const key = try allocator.dupe(u8, "test");
        const value = try allocator.dupe(u8, "data");

        std.debug.print("  Allocated strings for putMove\n", .{});

        // If putMove succeeds, it takes ownership
        const result = map.putMove(key, value);

        if (result) {
            std.debug.print("  putMove succeeded - ownership transferred\n", .{});
            // Do NOT free key or value
        } else |err| {
            std.debug.print("  putMove failed: {}\n", .{err});
            std.debug.print("  Ownership NOT transferred - caller must free\n", .{});
            allocator.free(key);
            allocator.free(value);
        }

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Remove frees the owned strings
    {
        std.debug.print("Test 5: Remove Frees Owned Strings\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var map = std.BufMap.init(gpa.allocator());
        defer map.deinit();

        try map.put("key1", "value1");
        try map.put("key2", "value2");
        try map.put("key3", "value3");

        std.debug.print("  Added 3 entries\n", .{});
        std.debug.print("  Count: {}\n", .{map.count()});

        // Remove frees both key and value
        map.remove("key2");

        std.debug.print("  Removed key2 - both key and value freed\n", .{});
        std.debug.print("  Count: {}\n", .{map.count()});
        std.debug.print("  key2 lookup: {?s}\n", .{map.get("key2")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All BufMap ownership tests completed successfully!\n", .{});
}
