const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.array_list.Managed(u32).init(allocator);
    defer list.deinit();

    try list.append(42);
    std.debug.print("Item: {}\n", .{list.items[0]});
}

