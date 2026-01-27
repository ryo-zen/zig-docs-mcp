const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Try to use argsWithAllocator
    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();

    std.debug.print("Arguments:\n", .{});
    while (args_iter.next()) |arg| {
        std.debug.print("- {s}\n", .{arg});
    }
}

