const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Basic ArrayList usage (default alignment)
    var list: std.ArrayList(i32) = .{};
    defer list.deinit(allocator);

    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.append(allocator, 30);

    std.debug.print("Items: {any}\n", .{list.items});
    std.debug.print("Length: {}, Capacity: {}\n", .{ list.items.len, list.capacity });

    // Access items directly
    for (list.items, 0..) |item, i| {
        std.debug.print("  [{d}] = {d}\n", .{ i, item });
    }
}
