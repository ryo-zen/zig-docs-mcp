// Testing Pattern: Client-Server in One Test
const std = @import("std");

test "server accepts connection" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Server: ephemeral port
    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
    var server = try addr.listen(io, .{});
    defer server.deinit(io);

    const server_addr = server.socket.address;

    // Client thread
    const client_thread = try std.Thread.spawn(.{}, struct {
        fn connect(io2: std.Io, sa: std.Io.net.IpAddress) !void {
            // Small delay to ensure server is ready
            try io2.sleep(std.Io.Duration.fromMilliseconds(50), std.Io.Clock.awake);

            const stream = try sa.connect(io2, .{ .mode = .stream });
            stream.close(io2);
        }
    }.connect, .{ io, server_addr });

    // Server accepts
    var stream = try server.accept(io);
    stream.close(io);

    client_thread.join();

    std.debug.print("✅ Test pattern passed\n", .{});
}
