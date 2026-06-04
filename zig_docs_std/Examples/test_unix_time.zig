const std = @import("std");

pub fn getTimeGlobal() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}

pub fn getTime(io: std.Io) i64 {
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}

test "unix time now (Io.Clock.real)" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const ts = std.Io.Clock.real.now(io);
    const seconds = ts.toSeconds();

    std.debug.print("unix seconds: {}\n", .{seconds});
    try std.testing.expect(seconds > 1_500_000_000);
}

test "global single-threaded Io timestamp helper returns unix seconds" {
    const seconds = getTimeGlobal();
    try std.testing.expect(seconds > 1_500_000_000);
}

test "explicit Io timestamp helper returns unix seconds" {
    const io = std.Io.Threaded.global_single_threaded.io();
    const seconds = getTime(io);
    try std.testing.expect(seconds > 1_500_000_000);
}
