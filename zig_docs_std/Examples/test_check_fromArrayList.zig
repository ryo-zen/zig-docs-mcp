const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);

    // Check if fromArrayList exists
    std.debug.print("Checking if std.Io.Writer.fromArrayList exists...\n", .{});
    
    // Try to call it
    const writer = std.Io.Writer.fromArrayList(&list);
    _ = writer;
    
    std.debug.print("Function exists!\n", .{});
}
