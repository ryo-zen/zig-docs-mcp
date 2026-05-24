const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Pre-allocate capacity to avoid multiple allocations
    var list = try std.ArrayList(u8).initCapacity(allocator, 100);
    defer list.deinit(allocator);

    std.debug.print("Initial - Length: {}, Capacity: {}\n", .{ list.items.len, list.capacity });

    // Use ensureUnusedCapacity for batch operations
    try list.ensureUnusedCapacity(allocator, 50);

    // Now we can use AssumeCapacity variants without error handling
    for (0..50) |i| {
        list.appendAssumeCapacity(@intCast(i));
    }

    std.debug.print("After appends - Length: {}, Capacity: {}\n", .{ list.items.len, list.capacity });
    std.debug.print("First 10 items: {any}\n", .{list.items[0..10]});
}
