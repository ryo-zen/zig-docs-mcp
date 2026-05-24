const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    // Build initial list
    try list.appendSlice(allocator, &[_]i32{ 10, 30, 40 });
    std.debug.print("Initial: {any}\n", .{list.items});

    // Insert at index
    try list.insert(allocator, 1, 20);
    std.debug.print("After insert(1, 20): {any}\n", .{list.items});

    // Insert slice at index
    try list.insertSlice(allocator, 2, &[_]i32{ 25, 26 });
    std.debug.print("After insertSlice(2, [25,26]): {any}\n", .{list.items});

    // Add many undefined elements at position
    const slice = try list.addManyAt(allocator, 0, 2);
    slice[0] = 5;
    slice[1] = 8;
    std.debug.print("After addManyAt(0, 2): {any}\n", .{list.items});
}
