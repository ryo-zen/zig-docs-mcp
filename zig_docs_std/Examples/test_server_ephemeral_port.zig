// Quick Start - Server with Ephemeral Port (Testing)
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Let OS assign a free port (avoids conflicts)
    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    // Get the actual assigned port
    const actual_addr = server.socket.address;
    std.debug.print("✅ Listening on {}\n", .{actual_addr});

    // Verify we can get the port number
    const port = switch (actual_addr) {
        .ip4 => |ip4| ip4.port,
        .ip6 => |ip6| ip6.port,
    };
    std.debug.print("✅ Port number: {}\n", .{port});

    // Test connection
    const client_thread = try std.Thread.spawn(.{}, struct {
        fn connect(client_io: std.Io, server_addr: std.Io.net.IpAddress) !void {
            try client_io.sleep(std.Io.Duration.fromMilliseconds(50), std.Io.Clock.awake);
            const stream = try server_addr.connect(client_io, .{ .mode = .stream });
            stream.close(client_io);
        }
    }.connect, .{ io, actual_addr });

    var stream = try server.accept(io);
    stream.close(io);

    client_thread.join();
    std.debug.print("✅ Ephemeral port test passed\n", .{});
}
