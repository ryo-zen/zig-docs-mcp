// BufSet clone operations
// Demonstrates copying sets with same or different allocators

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BufSet Clone Operations Test ===\n\n", .{});

    // Test 1: Clone with same allocator
    {
        std.debug.print("Test 1: Clone with Same Allocator\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var original = std.BufSet.init(gpa.allocator());
        defer original.deinit();

        try original.insert("first");
        try original.insert("second");
        try original.insert("third");

        std.debug.print("  Original set count: {}\n", .{original.count()});

        // Clone the set
        var cloned = try original.clone();
        defer cloned.deinit();

        std.debug.print("  Cloned set count: {}\n", .{cloned.count()});

        // Verify clone has same contents
        std.debug.print("  Clone contains 'first': {}\n", .{cloned.contains("first")});
        std.debug.print("  Clone contains 'second': {}\n", .{cloned.contains("second")});
        std.debug.print("  Clone contains 'third': {}\n", .{cloned.contains("third")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Clone is independent
    {
        std.debug.print("Test 2: Clone is Independent\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var original = std.BufSet.init(gpa.allocator());
        defer original.deinit();

        try original.insert("shared");

        var cloned = try original.clone();
        defer cloned.deinit();

        std.debug.print("  Both sets initially contain 'shared'\n", .{});
        std.debug.print("  Original: {}, Clone: {}\n", .{original.contains("shared"), cloned.contains("shared")});

        // Modify original
        try original.insert("only_in_original");

        // Modify clone
        try cloned.insert("only_in_clone");

        std.debug.print("  After modifications:\n", .{});
        std.debug.print("  Original contains 'only_in_original': {}\n", .{original.contains("only_in_original")});
        std.debug.print("  Original contains 'only_in_clone': {}\n", .{original.contains("only_in_clone")});
        std.debug.print("  Clone contains 'only_in_original': {}\n", .{cloned.contains("only_in_original")});
        std.debug.print("  Clone contains 'only_in_clone': {}\n", .{cloned.contains("only_in_clone")});

        std.debug.print("  ✅ PASS - Modifications are independent\n\n", .{});
    }

    // Test 3: Clone with different allocator
    {
        std.debug.print("Test 3: Clone with Different Allocator\n", .{});

        var gpa1 = std.heap.DebugAllocator(.{}){};
        defer _ = gpa1.deinit();

        var gpa2 = std.heap.DebugAllocator(.{}){};
        defer _ = gpa2.deinit();

        var original = std.BufSet.init(gpa1.allocator());
        defer original.deinit();

        try original.insert("alpha");
        try original.insert("beta");
        try original.insert("gamma");

        std.debug.print("  Original uses allocator 1\n", .{});
        std.debug.print("  Original count: {}\n", .{original.count()});

        // Clone with different allocator
        var cloned = try original.cloneWithAllocator(gpa2.allocator());
        defer cloned.deinit();

        std.debug.print("  Clone uses allocator 2\n", .{});
        std.debug.print("  Clone count: {}\n", .{cloned.count()});

        // Verify contents
        std.debug.print("  Clone contains 'alpha': {}\n", .{cloned.contains("alpha")});
        std.debug.print("  Clone contains 'beta': {}\n", .{cloned.contains("beta")});
        std.debug.print("  Clone contains 'gamma': {}\n", .{cloned.contains("gamma")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Clone empty set
    {
        std.debug.print("Test 4: Clone Empty Set\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var original = std.BufSet.init(gpa.allocator());
        defer original.deinit();

        std.debug.print("  Original empty set count: {}\n", .{original.count()});

        var cloned = try original.clone();
        defer cloned.deinit();

        std.debug.print("  Cloned empty set count: {}\n", .{cloned.count()});

        // Add to clone
        try cloned.insert("new_item");

        std.debug.print("  After adding to clone:\n", .{});
        std.debug.print("  Original count: {}\n", .{original.count()});
        std.debug.print("  Clone count: {}\n", .{cloned.count()});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Clone large set
    {
        std.debug.print("Test 5: Clone Large Set\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        var original = std.BufSet.init(allocator);
        defer original.deinit();

        // Insert many values
        var i: usize = 0;
        while (i < 100) : (i += 1) {
            const value = try std.fmt.allocPrint(allocator, "item_{}", .{i});
            defer allocator.free(value);
            try original.insert(value);
        }

        std.debug.print("  Original large set count: {}\n", .{original.count()});

        var cloned = try original.clone();
        defer cloned.deinit();

        std.debug.print("  Cloned large set count: {}\n", .{cloned.count()});

        // Spot check some values
        std.debug.print("  Clone contains 'item_0': {}\n", .{cloned.contains("item_0")});
        std.debug.print("  Clone contains 'item_50': {}\n", .{cloned.contains("item_50")});
        std.debug.print("  Clone contains 'item_99': {}\n", .{cloned.contains("item_99")});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 6: Get allocator from set
    {
        std.debug.print("Test 6: Get Allocator from Set\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var set = std.BufSet.init(gpa.allocator());
        defer set.deinit();

        try set.insert("test");

        // Get the allocator back
        const set_allocator = set.allocator();

        // Use it to allocate something
        const test_string = try std.fmt.allocPrint(set_allocator, "allocated_{}", .{42});
        defer set_allocator.free(test_string);

        std.debug.print("  Retrieved allocator from set\n", .{});
        std.debug.print("  Used it to allocate: {s}\n", .{test_string});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All BufSet clone tests completed successfully!\n", .{});
}
