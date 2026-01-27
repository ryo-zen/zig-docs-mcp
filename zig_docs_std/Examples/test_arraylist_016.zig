const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test the new ArrayList API
    var list: std.ArrayList(u32) = .{};
    defer list.deinit(allocator);

    try list.append(allocator, 42);
    try list.append(allocator, 100);

    std.debug.print("ArrayList items: {any}\n", .{list.items});
}
