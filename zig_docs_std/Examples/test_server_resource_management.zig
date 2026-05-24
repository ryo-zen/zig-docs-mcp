// Critical: Resource Management example
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
    var server = try addr.listen(io, .{});
    defer server.deinit(io); // ALWAYS clean up the server

    const server_addr = server.socket.address;
    std.debug.print("✅ Server initialized with defer cleanup\n", .{});

    // Client connection
    const client_thread = try std.Thread.spawn(.{}, struct {
        fn connect(client_io: std.Io, sa: std.Io.net.IpAddress) !void {
            try client_io.sleep(std.Io.Duration.fromMilliseconds(50), std.Io.Clock.awake);
            const stream = try sa.connect(client_io, .{ .mode = .stream });
            stream.close(client_io);
        }
    }.connect, .{ io, server_addr });

    var stream = try server.accept(io);
    defer stream.close(io); // ALWAYS close accepted connections

    std.debug.print("✅ Connection accepted with defer cleanup\n", .{});

    // Without defer, connections leak on early returns!
    client_thread.join();
    std.debug.print("✅ Resource management test passed\n", .{});
}
