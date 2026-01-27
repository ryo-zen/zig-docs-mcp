const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Let's try to just use ArrayList directly for writing
    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);

    // Use ArrayList's writer method if it has one
    const writer = list.writer(allocator);

    try writer.print("Formatted: {d:0>4}\n", .{42});
    try writer.writeAll("More data\n");

    std.debug.print("ArrayList contents:\n{s}", .{list.items});
}
