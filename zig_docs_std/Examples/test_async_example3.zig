const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

fn juicyMain(gpa: Allocator, io: Io) !void {
    _ = gpa;

    var a = io.async(doWork, .{ io, "hard" });
    var b = io.async(doWork, .{ io, "on an excuse not to drink Spezi" });

    a.await(io);
    b.await(io);
}

fn doWork(io: Io, flavor_text: []const u8) void {
    std.debug.print("working {s}\n", .{flavor_text});
    io.sleep(.fromSeconds(1), .awake) catch {};
}

pub fn main() !void {
    // Set up allocator
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer assert(debug_allocator.deinit() == .ok);
    const gpa = debug_allocator.allocator();

    // Set up our I/O implementation
    var threaded = std.Io.Threaded.init(gpa, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    return juicyMain(gpa, io);
}
