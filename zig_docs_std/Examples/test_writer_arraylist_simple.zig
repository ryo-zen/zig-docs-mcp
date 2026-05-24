const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Let's try to just use ArrayList directly for writing
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    // Use an allocating writer backed by the ArrayList.
    var allocating_writer = std.Io.Writer.Allocating.fromArrayList(allocator, &list);

    try allocating_writer.writer.print("Formatted: {d:0>4}\n", .{42});
    try allocating_writer.writer.writeAll("More data\n");
    try allocating_writer.writer.flush();

    var final_list = allocating_writer.writer.toArrayList();
    defer final_list.deinit(allocator);

    std.debug.print("ArrayList contents:\n{s}", .{final_list.items});
}
