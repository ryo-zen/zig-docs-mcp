const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    std.debug.print("Creating ALLOCATING writer from ArrayList...\n", .{});
    var allocating_writer = std.Io.Writer.Allocating.fromArrayList(allocator, &list);
    
    std.debug.print("Trying to write...\n", .{});
    try allocating_writer.writer.writeAll("Hello, ");
    try allocating_writer.writer.print("World! {}\n", .{42});
    try allocating_writer.writer.flush();
    
    std.debug.print("Success! Converting back to ArrayList...\n", .{});
    var final_list = allocating_writer.writer.toArrayList();
    defer final_list.deinit(allocator);
    
    std.debug.print("ArrayList contents:\n{s}", .{final_list.items});
}
