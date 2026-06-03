// Test examples from Event, Mutex, and CancelProtection documentation
const std = @import("std");

test "Event - basic initialization" {
    var event = std.Io.Event.unset;
    try std.testing.expect(event.isSet() == false);

    // Cannot test set/wait without Io instance, but verify it compiles
    _ = &event;
}

test "Event - isSet check" {
    var event = std.Io.Event.unset;
    try std.testing.expect(event.isSet() == false);

    // Manually set to is_set state
    event = std.Io.Event.is_set;
    try std.testing.expect(event.isSet() == true);
}

test "Event - reset" {
    var event = std.Io.Event.is_set;
    try std.testing.expect(event.isSet() == true);

    event.reset();
    try std.testing.expect(event.isSet() == false);
}

test "Mutex - initialization" {
    var mutex = std.Io.Mutex.init;

    // Verify mutex exists and has the expected type
    _ = &mutex;
}

test "Mutex - tryLock without Io" {
    var mutex = std.Io.Mutex.init;

    // tryLock doesn't require Io
    const acquired = mutex.tryLock();
    try std.testing.expect(acquired == true);
}

test "CancelProtection - enum values" {
    const unblocked = std.Io.CancelProtection.unblocked;
    const blocked = std.Io.CancelProtection.blocked;

    try std.testing.expect(unblocked != blocked);
}

test "Futex - wait returns immediately when value differs" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var value = std.atomic.Value(u32).init(1);

    try io.futexWaitTimeout(u32, &value.raw, 0, .{
        .duration = .{
            .raw = .fromMilliseconds(10),
            .clock = .awake,
        },
    });
    io.futexWake(u32, &value.raw, 0);
}

const FutexWorkerArgs = struct {
    io: std.Io,
    value: *std.atomic.Value(u32),
    ready: *std.atomic.Value(bool),
    observed: *std.atomic.Value(bool),
    failed: *std.atomic.Value(bool),
};

fn futexWaitWorker(args: FutexWorkerArgs) void {
    args.ready.store(true, .release);

    while (args.value.load(.acquire) == 0) {
        args.io.futexWait(u32, &args.value.raw, 0) catch {
            args.failed.store(true, .release);
            return;
        };
    }

    args.observed.store(true, .release);
}

test "Futex - wait and wake with Io.Threaded" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var value = std.atomic.Value(u32).init(0);
    var ready = std.atomic.Value(bool).init(false);
    var observed = std.atomic.Value(bool).init(false);
    var failed = std.atomic.Value(bool).init(false);

    const thread = try std.Thread.spawn(.{}, futexWaitWorker, .{FutexWorkerArgs{
        .io = io,
        .value = &value,
        .ready = &ready,
        .observed = &observed,
        .failed = &failed,
    }});

    while (!ready.load(.acquire)) {
        std.Thread.yield() catch {};
    }

    value.store(1, .release);
    io.futexWake(u32, &value.raw, 1);
    thread.join();

    try std.testing.expect(!failed.load(.acquire));
    try std.testing.expect(observed.load(.acquire));
}

test "Event with Io - basic set and wait" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var event = std.Io.Event.unset;

    // Set the event
    event.set(io);

    // Should be set now
    try std.testing.expect(event.isSet() == true);

    // Wait should return immediately since it's already set
    try event.wait(io);
}

test "Mutex with Io - basic lock and unlock" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var mutex = std.Io.Mutex.init;

    try mutex.lock(io);
    defer mutex.unlock(io);

    // Critical section would go here
}

test "Mutex - lockUncancelable" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var mutex = std.Io.Mutex.init;

    mutex.lockUncancelable(io);
    defer mutex.unlock(io);

    // Uncancelable critical section
}

test "CancelProtection - swapCancelProtection" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const old = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old);

    // Protected section - cancellation is blocked
}
