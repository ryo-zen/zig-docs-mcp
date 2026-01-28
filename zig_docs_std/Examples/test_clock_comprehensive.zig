//! Comprehensive test suite for std.Io.Clock, std.Io.Duration, and
//! std.Io.Timestamp covering time reading, arithmetic, conversions, and sleep.

const std = @import("std");
const testing = std.testing;

test "Clock.real.now returns unix timestamp" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const ts = try std.Io.Clock.real.now(io);
    const seconds = ts.toSeconds();
    // Should be after 2020-01-01 (1577836800)
    try testing.expect(seconds > 1_577_836_800);
}

test "Clock.awake.now is monotonic" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const t1 = try std.Io.Clock.awake.now(io);
    const t2 = try std.Io.Clock.awake.now(io);

    // t2 >= t1 (monotonic guarantee)
    const diff = t1.durationTo(t2);
    try testing.expect(diff.nanoseconds >= 0);
}

test "Duration fromSeconds and conversions" {
    const d = std.Io.Duration.fromSeconds(5);
    try testing.expectEqual(@as(i64, 5), d.toSeconds());
    try testing.expectEqual(@as(i64, 5000), d.toMilliseconds());
}

test "Duration fromMilliseconds and conversions" {
    const d = std.Io.Duration.fromMilliseconds(1500);
    try testing.expectEqual(@as(i64, 1), d.toSeconds());
    try testing.expectEqual(@as(i64, 1500), d.toMilliseconds());
}

test "Duration fromNanoseconds and toNanoseconds" {
    const d = std.Io.Duration.fromNanoseconds(2_500_000);
    try testing.expectEqual(@as(i96, 2_500_000), d.toNanoseconds());
    try testing.expectEqual(@as(i64, 2), d.toMilliseconds());
}

test "Timestamp addDuration and durationTo" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const t1 = try std.Io.Clock.real.now(io);
    const five_seconds = std.Io.Duration.fromSeconds(5);
    const t2 = t1.addDuration(five_seconds);

    const diff = t1.durationTo(t2);
    try testing.expectEqual(@as(i64, 5), diff.toSeconds());
}

test "Timestamp subDuration" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const now = try std.Io.Clock.real.now(io);
    const ten_ago = now.subDuration(.fromSeconds(10));

    const diff = ten_ago.durationTo(now);
    try testing.expectEqual(@as(i64, 10), diff.toSeconds());
}

test "Timestamp durationTo returns negative for past" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const now = try std.Io.Clock.real.now(io);
    const past = now.subDuration(.fromSeconds(5));

    // now.durationTo(past) should be negative
    const diff = now.durationTo(past);
    try testing.expect(diff.nanoseconds < 0);
    try testing.expectEqual(@as(i64, -5), diff.toSeconds());
}

test "io.sleep with Duration" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const before = try std.Io.Clock.awake.now(io);
    io.sleep(.fromMilliseconds(50), .awake) catch {};
    const after = try std.Io.Clock.awake.now(io);

    const elapsed = before.durationTo(after);
    // Should have slept at least 40ms (allow some slack)
    try testing.expect(elapsed.toMilliseconds() >= 40);
}
