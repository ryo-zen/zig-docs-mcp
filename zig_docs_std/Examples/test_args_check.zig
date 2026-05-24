const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Cross-platform argument iteration in Zig 0.16 uses std.process.Init.
    var args_iter = try init.minimal.args.iterateAllocator(init.gpa);
    defer args_iter.deinit();

    std.debug.print("Arguments:\n", .{});
    while (args_iter.next()) |arg| {
        std.debug.print("- {s}\n", .{arg});
    }
}
