const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.Args.toSlice(init.minimal.args, allocator);
    // On Linux (Posix), args slice itself needs freeing, but strings point to init.minimal.args?
    // Let's defer freeing the slice.
    defer allocator.free(args);

    std.debug.print("Args:\n", .{});
    for (args) |arg| {
        std.debug.print("- {s}\n", .{arg});
    }
}

