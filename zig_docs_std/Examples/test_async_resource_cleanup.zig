const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

fn juicyMain(gpa: Allocator, io: Io) !void {
    std.debug.print("=== Test 1: Both tasks succeed ===\n", .{});
    try testBothSucceed(gpa, io);

    std.debug.print("\n=== Test 2: One task fails (error handled) ===\n", .{});
    testOneFailsSafe(gpa, io);

    std.debug.print("\n✅ All resource cleanup tests passed!\n", .{});
}

fn testBothSucceed(gpa: Allocator, io: Io) !void {
    var a = io.async(doWork, .{ gpa, io, "task A", false });
    defer if (a.cancel(io)) |s| {
        std.debug.print("Cleanup: freeing '{s}'\n", .{s});
        gpa.free(s);
    } else |_| {};

    var b = io.async(doWork, .{ gpa, io, "task B", false });
    defer if (b.cancel(io)) |s| {
        std.debug.print("Cleanup: freeing '{s}'\n", .{s});
        gpa.free(s);
    } else |_| {};

    const a_string = try a.await(io);
    const b_string = try b.await(io);
    std.debug.print("Result: {s}\n", .{a_string});
    std.debug.print("Result: {s}\n", .{b_string});
}

fn testOneFailsSafe(gpa: Allocator, io: Io) void {
    var a = io.async(doWork, .{ gpa, io, "will succeed", false });
    defer if (a.cancel(io)) |s| {
        std.debug.print("Cleanup: freeing '{s}'\n", .{s});
        gpa.free(s);
    } else |_| {};

    var b = io.async(doWork, .{ gpa, io, "will fail", true });
    defer if (b.cancel(io)) |s| {
        std.debug.print("Cleanup: freeing '{s}'\n", .{s});
        gpa.free(s);
    } else |err| {
        std.debug.print("Cleanup: task failed with error: {}\n", .{err});
    };

    if (a.await(io)) |a_string| {
        std.debug.print("Result: {s}\n", .{a_string});
    } else |_| {}

    if (b.await(io)) |b_string| {
        std.debug.print("Result: {s}\n", .{b_string});
    } else |err| {
        std.debug.print("Expected error caught: {}\n", .{err});
    }
}

fn doWork(gpa: Allocator, io: Io, name: []const u8, should_fail: bool) ![]u8 {
    const copied_string = try gpa.dupe(u8, name);
    std.debug.print("Working on: {s}\n", .{copied_string});
    io.sleep(.fromMilliseconds(500), .awake) catch {};

    if (should_fail) {
        gpa.free(copied_string);
        return error.SimulatedFailure;
    }

    return copied_string;
}

pub fn main() !void {
    // Set up allocator with leak detection
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer assert(debug_allocator.deinit() == .ok);
    const gpa = debug_allocator.allocator();

    // Set up our I/O implementation
    var threaded = std.Io.Threaded.init(gpa, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    return juicyMain(gpa, io);
}
