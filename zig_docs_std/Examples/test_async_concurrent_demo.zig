const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

fn juicyMain(gpa: Allocator, io: Io) !void {
    _ = gpa;

    std.debug.print("Starting 3 tasks that each take 1 second...\n\n", .{});

    // Launch 3 tasks concurrently
    var task1 = io.async(doWork, .{ io, "Task 1" });
    var task2 = io.async(doWork, .{ io, "Task 2" });
    var task3 = io.async(doWork, .{ io, "Task 3" });

    // Wait for all to complete
    task1.await(io);
    task2.await(io);
    task3.await(io);

    std.debug.print("\n✅ All 3 tasks completed concurrently!\n", .{});
    std.debug.print("   (If sequential: would take ~3 seconds)\n", .{});
    std.debug.print("   (With async:    took ~1 second)\n", .{});
}

fn doWork(io: Io, name: []const u8) void {
    std.debug.print("{s} started\n", .{name});
    io.sleep(.fromSeconds(1), .awake) catch {};
    std.debug.print("{s} completed\n", .{name});
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
