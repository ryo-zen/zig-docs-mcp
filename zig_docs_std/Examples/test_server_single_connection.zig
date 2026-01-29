// Example 1: Single-Connection Server
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Listen on ephemeral port for testing
    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    const actual_addr = server.socket.address;
    std.debug.print("✅ Waiting for connection on {}...\n", .{actual_addr});

    // Client thread
    const client_thread = try std.Thread.spawn(.{}, struct {
        fn connect(client_io: std.Io, server_addr: std.Io.net.IpAddress) !void {
            try client_io.sleep(std.Io.Duration.fromMilliseconds(50), std.Io.Clock.awake);
            const stream = try server_addr.connect(client_io, .{ .mode = .stream });
            defer stream.close(client_io);

            var rbuf: [256]u8 = undefined;
            var reader = stream.reader(client_io, &rbuf);
            const msg = try reader.interface.takeDelimiterInclusive('\n');
            std.debug.print("✅ Client received: {s}", .{msg});
        }
    }.connect, .{ io, actual_addr });

    // Accept exactly one connection
    var stream = try server.accept(io);
    defer stream.close(io);

    std.debug.print("✅ Client connected!\n", .{});

    // Send welcome message
    var wbuf: [256]u8 = undefined;
    var writer = stream.writer(io, &wbuf);
    try writer.interface.writeAll("Hello from Zig server!\n");
    try writer.interface.flush();

    client_thread.join();
    std.debug.print("✅ Single-connection test passed\n", .{});
}
