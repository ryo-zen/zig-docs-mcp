const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Example 1: toOwnedSlice transfers ownership
    {
        var list: std.ArrayList(u8) = .empty;
        try list.appendSlice(allocator, "Hello, World!");

        const owned = try list.toOwnedSlice(allocator);
        defer allocator.free(owned);

        std.debug.print("Owned slice: {s}\n", .{owned});
        std.debug.print("List is now empty - len: {}\n", .{list.items.len});

        list.deinit(allocator); // Safe but unnecessary - capacity is 0
    }

    // Example 2: clone creates independent copy
    {
        var original: std.ArrayList(i32) = .empty;
        defer original.deinit(allocator);
        try original.appendSlice(allocator, &[_]i32{ 1, 2, 3 });

        var copy = try original.clone(allocator);
        defer copy.deinit(allocator);

        try copy.append(allocator, 4);
        std.debug.print("Original: {any}\n", .{original.items});
        std.debug.print("Copy: {any}\n", .{copy.items});
    }

    // Example 3: Transfer ownership back and forth
    {
        var list: std.ArrayList(u8) = .empty;
        try list.appendSlice(allocator, "transfer");

        // Take ownership as slice
        const slice1 = try list.toOwnedSlice(allocator);
        std.debug.print("Slice 1: {s}\n", .{slice1});

        // Give it back to ArrayList for further modifications
        list = std.ArrayList(u8).fromOwnedSlice(slice1);
        try list.appendSlice(allocator, " ownership");
        defer list.deinit(allocator);

        std.debug.print("Modified list: {s}\n", .{list.items});
    }
}
