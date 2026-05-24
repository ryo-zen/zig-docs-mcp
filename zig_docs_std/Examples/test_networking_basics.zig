// Test examples from ShutdownHow, ReceiveFlags, SendFlags, and std.Io.net documentation
const std = @import("std");

// Stub functions for examples
fn performWork() void {}
fn processBytes(_: []const u8) void {}

test "ShutdownHow - basic usage" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    // Just verify the enum values exist
    const recv_shutdown = std.Io.net.ShutdownHow.recv;
    const send_shutdown = std.Io.net.ShutdownHow.send;
    const both_shutdown = std.Io.net.ShutdownHow.both;

    try std.testing.expect(recv_shutdown != send_shutdown);
    try std.testing.expect(both_shutdown != recv_shutdown);
}

test "ReceiveFlags - field initialization" {
    const flags_default = std.Io.net.ReceiveFlags{};
    try std.testing.expect(flags_default.oob == false);
    try std.testing.expect(flags_default.peek == false);
    try std.testing.expect(flags_default.trunc == false);

    const flags_peek = std.Io.net.ReceiveFlags{ .peek = true };
    try std.testing.expect(flags_peek.peek == true);
    try std.testing.expect(flags_peek.oob == false);
}

test "SendFlags - field initialization" {
    const flags_default = std.Io.net.SendFlags{};
    try std.testing.expect(flags_default.confirm == false);
    try std.testing.expect(flags_default.dont_route == false);
    try std.testing.expect(flags_default.eor == false);
    try std.testing.expect(flags_default.oob == false);
    try std.testing.expect(flags_default.fastopen == false);

    const flags_fastopen = std.Io.net.SendFlags{ .fastopen = true };
    try std.testing.expect(flags_fastopen.fastopen == true);
    try std.testing.expect(flags_fastopen.confirm == false);
}

test "std.Io.net - has_unix_sockets value" {
    // Just verify the value exists and is a bool
    const has_sockets: bool = std.Io.net.has_unix_sockets;
    _ = has_sockets; // Silence unused warning
}
