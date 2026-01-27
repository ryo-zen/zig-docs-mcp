const std = @import("std");

test "unix time now (Io.Clock.real)" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const ts = try std.Io.Clock.real.now(io);
    const seconds = ts.toSeconds();

    std.debug.print("unix seconds: {}\n", .{seconds});
    try std.testing.expect(seconds > 1_500_000_000);
}
