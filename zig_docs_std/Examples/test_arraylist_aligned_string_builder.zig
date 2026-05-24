const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Using ArrayList as a string builder
    var string: std.ArrayList(u8) = .empty;
    defer string.deinit(allocator);

    try string.appendSlice(allocator, "Hello, ");
    try string.print(allocator, "{s}! ", .{"World"});
    try string.print(allocator, "The answer is {d}.", .{42});

    std.debug.print("Built string: {s}\n", .{string.items});

    // Modify in place
    try string.appendNTimes(allocator, '\n', 1);
    try string.appendSlice(allocator, "Additional line.");

    std.debug.print("Final string:\n{s}\n", .{string.items});

    // Convert to owned slice for return
    const result = try string.toOwnedSlice(allocator);
    defer allocator.free(result);
    std.debug.print("As owned slice: {s}\n", .{result});
}
