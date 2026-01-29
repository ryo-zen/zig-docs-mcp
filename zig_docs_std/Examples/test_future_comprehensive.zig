//! Comprehensive test suite for std.Io.Future covering task lifecycle,
//! cancellation cleanup, error propagation, and non-allocating tasks.

const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Io = std.Io;

fn double(x: u32) u32 {
    return x * 2;
}

fn allocatingWork(gpa: Allocator, io: Io, input: []const u8) ![]u8 {
    const result = try gpa.dupe(u8, input);
    io.sleep(.fromMilliseconds(10), .awake) catch {};
    return result;
}

fn failingWork(gpa: Allocator, io: Io) ![]u8 {
    _ = gpa;
    io.sleep(.fromMilliseconds(10), .awake) catch {};
    return error.SimulatedFailure;
}

test "Future await returns task result" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var task = io.async(double, .{21});
    defer _ = task.cancel(io);

    const result = task.await(io);
    try testing.expectEqual(@as(u32, 42), result);
}

test "Future await is idempotent" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var task = io.async(double, .{10});
    defer _ = task.cancel(io);

    const r1 = task.await(io);
    const r2 = task.await(io);
    try testing.expectEqual(r1, r2);
    try testing.expectEqual(@as(u32, 20), r1);
}

test "Future cancel after await is no-op" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var task = io.async(double, .{7});

    const awaited = task.await(io);
    const canceled = task.cancel(io);
    // Both should return the same value
    try testing.expectEqual(awaited, canceled);
    try testing.expectEqual(@as(u32, 14), awaited);
}

test "Future with heap-allocated result and defer cancel cleanup" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // defer cancel owns the result — do not free manually
    var task = io.async(allocatingWork, .{ allocator, io, "hello future" });
    defer if (task.cancel(io)) |s| allocator.free(s) else |_| {};

    const result = try task.await(io);
    try testing.expectEqualStrings("hello future", result);
}

test "Future fan-out: multiple concurrent tasks" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var task1 = io.async(allocatingWork, .{ allocator, io, "alpha" });
    defer if (task1.cancel(io)) |s| allocator.free(s) else |_| {};

    var task2 = io.async(allocatingWork, .{ allocator, io, "beta" });
    defer if (task2.cancel(io)) |s| allocator.free(s) else |_| {};

    var task3 = io.async(allocatingWork, .{ allocator, io, "gamma" });
    defer if (task3.cancel(io)) |s| allocator.free(s) else |_| {};

    // defer cancels own the results — do not free manually
    const r1 = try task1.await(io);
    const r2 = try task2.await(io);
    const r3 = try task3.await(io);

    try testing.expectEqualStrings("alpha", r1);
    try testing.expectEqualStrings("beta", r2);
    try testing.expectEqualStrings("gamma", r3);
}

test "Future error propagation from task" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var task = io.async(failingWork, .{ allocator, io });
    defer if (task.cancel(io)) |s| {
        allocator.free(s);
    } else |_| {};

    const result = task.await(io);
    try testing.expectError(error.SimulatedFailure, result);
}

test "Future defer cancel frees result when caller errors early" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // This simulates: launch two tasks, first succeeds but second fails.
    // The defer on task1 must still free its result even though we never
    // manually free it — the cancel cleanup handles it.
    var task1 = io.async(allocatingWork, .{ allocator, io, "will be freed by defer" });
    defer if (task1.cancel(io)) |s| allocator.free(s) else |_| {};

    var task2 = io.async(failingWork, .{ allocator, io });
    defer if (task2.cancel(io)) |s| allocator.free(s) else |_| {};

    // Await task1 but discard the value — defer cancel owns the result
    _ = try task1.await(io);

    // task2 fails — verify the error propagates
    const result = task2.await(io);
    try testing.expectError(error.SimulatedFailure, result);
    // If we get here without a leak, task1's result was freed by the defer
}
