// Quick Start - Simple TCP Echo Server
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0); // Use ephemeral port
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    const actual_addr = server.socket.address;
    std.debug.print("✅ Echo server listening on {}\n", .{actual_addr});

    // Spawn client thread
    const client_thread = try std.Thread.spawn(.{}, struct {
        fn client(client_io: std.Io, server_addr: std.Io.net.IpAddress) !void {
            try client_io.sleep(std.Io.Duration.fromMilliseconds(50), std.Io.Clock.awake);

            const stream = try server_addr.connect(client_io, .{ .mode = .stream });
            defer stream.close(client_io);

            var wbuf: [256]u8 = undefined;
            var writer = stream.writer(client_io, &wbuf);
            try writer.interface.writeAll("Hello\n");
            try writer.interface.flush();

            var rbuf: [256]u8 = undefined;
            var reader = stream.reader(client_io, &rbuf);
            const response = try reader.interface.takeDelimiterInclusive('\n');
            std.debug.print("✅ Client received: {s}", .{response});
        }
    }.client, .{ io, actual_addr });

    // Accept one connection
    var stream = try server.accept(io);
    defer stream.close(io);

    // Echo back whatever we receive
    var buf: [1024]u8 = undefined;
    var reader = stream.reader(io, &buf);
    const data = try reader.interface.takeDelimiterInclusive('\n');

    var wbuf: [1024]u8 = undefined;
    var writer = stream.writer(io, &wbuf);
    try writer.interface.writeAll(data);
    try writer.interface.flush();

    client_thread.join();
    std.debug.print("✅ Test passed\n", .{});
}
