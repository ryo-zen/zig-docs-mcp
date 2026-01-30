//! Test suite for std.Io.Event demonstrating signaling between tasks.

const std = @import("std");
const testing = std.testing;
const Io = std.Io;

test "Io.Event basic signaling" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var event = std.Io.Event.unset;
    try testing.expect(!event.isSet());

    // In a real scenario, this would be in another thread/task
    event.set(io);
    try testing.expect(event.isSet());

    try event.wait(io);
    try testing.expect(event.isSet());

    event.reset();
    try testing.expect(!event.isSet());
}

test "Io.Event async signaling" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var event = std.Io.Event.unset;

    const Worker = struct {
        fn run(ctx: struct { io: Io, event: *std.Io.Event }) void {
            // Simulate work
            // std.Io.sleep(io, duration, clock)
            ctx.io.sleep(std.Io.Duration.fromMilliseconds(10), .awake) catch {};
            ctx.event.set(ctx.io);
        }
    };

    var task = io.async(Worker.run, .{.{ .io = io, .event = &event }});
    defer _ = task.cancel(io);

    // Wait for the worker to signal
    try event.wait(io);
    try testing.expect(event.isSet());
}

test "Io.Event waitTimeout" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var event = std.Io.Event.unset;

    // Test timeout occurs
    // event.waitTimeout(io, Timeout)
    const timeout_result = event.waitTimeout(io, .{ .duration = .{ .raw = std.Io.Duration.fromMilliseconds(10), .clock = .awake } });
    try testing.expectError(error.Timeout, timeout_result);

    // Test success before timeout
    event.set(io);
    try event.waitTimeout(io, .{ .duration = .{ .raw = std.Io.Duration.fromMilliseconds(100), .clock = .awake } });
}
