const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, "Hello, World!");
    std.debug.print("Original: {s}\n", .{list.items});

    // Replace "World" with "Zig"
    try list.replaceRange(allocator, 7, 5, "Zig");
    std.debug.print("After replaceRange(7, 5, \"Zig\"): {s}\n", .{list.items});

    // Replace with longer text (grows the list)
    try list.replaceRange(allocator, 7, 3, "Ziggy");
    std.debug.print("After replaceRange(7, 3, \"Ziggy\"): {s}\n", .{list.items});

    // Replace with shorter text (shrinks the list)
    try list.replaceRange(allocator, 7, 5, "Z");
    std.debug.print("After replaceRange(7, 5, \"Z\"): {s}\n", .{list.items});

    // Using resize to change length
    try list.resize(allocator, 5);
    std.debug.print("After resize(5): {s}\n", .{list.items});

    // Expand and fill
    const old_len = list.items.len;
    try list.resize(allocator, old_len + 3);
    @memset(list.items[old_len..], '!');
    std.debug.print("After expand and fill: {s}\n", .{list.items});
}
