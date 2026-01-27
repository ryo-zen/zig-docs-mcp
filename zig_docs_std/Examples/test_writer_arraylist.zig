const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);

    var writer = std.Io.Writer.fromArrayList(&list);

    try writer.print("Formatted: {d:0>4}\n", .{42});
    try writer.writeAll("More data\n");
    try writer.flush();

    std.debug.print("ArrayList contents:\n{s}", .{list.items});
}
