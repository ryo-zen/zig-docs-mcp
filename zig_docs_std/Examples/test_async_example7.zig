const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

fn juicyMain(gpa: Allocator, io: Io) !void {
    var a = io.async(doWork, .{ gpa, io, "hard" });
    defer if (a.cancel(io)) |s| gpa.free(s) else |_| {};

    var b = io.async(doWork, .{ gpa, io, "on an excuse not to drink Spezi" });
    defer if (b.cancel(io)) |s| gpa.free(s) else |_| {};

    const a_string = try a.await(io);
    const b_string = try b.await(io);
    std.debug.print("finished {s}\n", .{a_string});
    std.debug.print("finished {s}\n", .{b_string});
}

fn doWork(gpa: Allocator, io: Io, flavor_text: []const u8) ![]u8 {
    const copied_string = try gpa.dupe(u8, flavor_text);
    std.debug.print("working {s}\n", .{copied_string});
    io.sleep(.fromSeconds(1), .awake) catch {};
    return copied_string;
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
