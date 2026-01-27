const std = @import("std");

pub fn main() !void {
    // Using ArrayList with stack-allocated buffer
    // initBuffer creates a list that doesn't own its memory
    var buffer: [1024]u8 = undefined;
    var list = std.ArrayList(u8).initBuffer(&buffer);

    // Do NOT call deinit when using initBuffer - the buffer is not owned!
    // The list will be cleaned up when it goes out of scope

    list.appendAssumeCapacity('H');
    list.appendAssumeCapacity('e');
    list.appendAssumeCapacity('l');
    list.appendAssumeCapacity('l');
    list.appendAssumeCapacity('o');

    std.debug.print("Stack buffer list: {s}\n", .{list.items});
    std.debug.print("Capacity: {}\n", .{list.capacity});

    // Can append more up to buffer size (use AssumeCapacity since buffer is fixed)
    const msg = ", World!";
    for (msg) |c| {
        list.appendAssumeCapacity(c);
    }
    std.debug.print("After append: {s}\n", .{list.items});

    // This is useful for temporary buffers in hot code paths
    list.clearRetainingCapacity();
    const msg2 = "Reused buffer";
    for (msg2) |c| {
        list.appendAssumeCapacity(c);
    }
    std.debug.print("Reused: {s}\n", .{list.items});
}
