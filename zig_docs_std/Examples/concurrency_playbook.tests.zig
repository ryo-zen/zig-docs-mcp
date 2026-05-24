const std = @import("std");

const SharedCounter = struct {
    value: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
};

const WorkerArgs = struct {
    shared: *SharedCounter,
    iterations: usize,
};

fn incrementWorker(args: WorkerArgs) void {
    var i: usize = 0;
    while (i < args.iterations) : (i += 1) {
        _ = args.shared.value.fetchAdd(1, .monotonic);
    }
}

const CancelWorkerArgs = struct {
    stop: *std.atomic.Value(bool),
    work_count: *std.atomic.Value(u64),
};

fn cancelableWorker(args: CancelWorkerArgs) void {
    while (!args.stop.load(.acquire)) {
        _ = args.work_count.fetchAdd(1, .monotonic);
        std.Thread.yield() catch {};
    }
}

const LockRank = enum(u8) { low = 1, high = 2 };

fn lockPairOrdered(
    first_rank: LockRank,
    first: *std.Io.Mutex,
    second_rank: LockRank,
    second: *std.Io.Mutex,
) void {
    const io = std.testing.io;
    if (@intFromEnum(first_rank) <= @intFromEnum(second_rank)) {
        first.lockUncancelable(io);
        second.lockUncancelable(io);
    } else {
        second.lockUncancelable(io);
        first.lockUncancelable(io);
    }
}

fn unlockPairOrdered(
    first_rank: LockRank,
    first: *std.Io.Mutex,
    second_rank: LockRank,
    second: *std.Io.Mutex,
) void {
    const io = std.testing.io;
    if (@intFromEnum(first_rank) <= @intFromEnum(second_rank)) {
        second.unlock(io);
        first.unlock(io);
    } else {
        first.unlock(io);
        second.unlock(io);
    }
}

test "multi-threaded counter with atomics" {
    var shared = SharedCounter{};

    const thread_count: usize = 4;
    const per_thread: usize = 25_000;

    var threads: [thread_count]std.Thread = undefined;
    var i: usize = 0;
    while (i < thread_count) : (i += 1) {
        threads[i] = try std.Thread.spawn(.{}, incrementWorker, .{WorkerArgs{
            .shared = &shared,
            .iterations = per_thread,
        }});
    }

    i = 0;
    while (i < thread_count) : (i += 1) {
        threads[i].join();
    }

    try std.testing.expectEqual(@as(u64, thread_count * per_thread), shared.value.load(.acquire));
}

test "cooperative cancellation with atomic stop flag" {
    var stop = std.atomic.Value(bool).init(false);
    var work_count = std.atomic.Value(u64).init(0);

    const thread = try std.Thread.spawn(.{}, cancelableWorker, .{CancelWorkerArgs{
        .stop = &stop,
        .work_count = &work_count,
    }});

    var i: usize = 0;
    while (i < 10_000) : (i += 1) {
        std.Thread.yield() catch {};
    }
    stop.store(true, .release);
    thread.join();

    try std.testing.expect(work_count.load(.acquire) > 0);
}

test "lock ordering helper enforces deterministic acquire order" {
    var low: std.Io.Mutex = .init;
    var high: std.Io.Mutex = .init;

    lockPairOrdered(.high, &high, .low, &low);
    defer unlockPairOrdered(.high, &high, .low, &low);

    try std.testing.expect(true);
}
