// Verify updated documentation examples compile correctly
const std = @import("std");

test "Updated Threaded.init pattern" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Verify io is usable
    _ = io;
}

test "Updated Kqueue pattern (platform-specific)" {
    const is_bsd = switch (@import("builtin").os.tag) {
        .macos, .freebsd, .openbsd, .netbsd, .dragonfly => true,
        else => false,
    };

    if (!is_bsd) return error.SkipZigTest;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var kq: std.Io.Kqueue = undefined;
    try kq.init(gpa.allocator(), .{});
    defer kq.deinit();

    const io = kq.io();
    _ = io;
}

test "ShutdownHow usage example compiles" {
    const recv = std.Io.net.ShutdownHow.recv;
    const send = std.Io.net.ShutdownHow.send;
    const both = std.Io.net.ShutdownHow.both;

    try std.testing.expect(recv != send);
    try std.testing.expect(both != recv);
}

test "TypeErasedQueue with updated Io pattern" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var backing_buffer: [1024]u8 = undefined;
    var queue = std.Io.TypeErasedQueue.init(&backing_buffer);
    defer queue.close(io);

    // Basic operation test
    const data = "test";
    _ = try queue.put(io, data, data.len);
}
