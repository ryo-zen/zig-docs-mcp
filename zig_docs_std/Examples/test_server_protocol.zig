// Pattern 7: Request/Response Protocol
const std = @import("std");

fn handleConnection(io: std.Io, stream: std.Io.net.Stream) !void {
    defer stream.close(io);

    var rbuf: [1024]u8 = undefined;
    var reader = stream.reader(io, &rbuf);

    while (true) {
        const command = reader.interface.takeDelimiterInclusive('\n') catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };

        // Parse command (strip newline)
        const cmd = command[0 .. command.len - 1];

        var wbuf: [1024]u8 = undefined;
        var writer = stream.writer(io, &wbuf);

        if (std.mem.eql(u8, cmd, "PING")) {
            try writer.interface.writeAll("PONG\n");
        } else if (std.mem.eql(u8, cmd, "QUIT")) {
            try writer.interface.writeAll("BYE\n");
            try writer.interface.flush();
            break;
        } else {
            try writer.interface.writeAll("ERROR: Unknown command\n");
        }

        try writer.interface.flush();
    }
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    const server_addr = server.socket.address;
    std.debug.print("✅ Protocol server listening on {}\n", .{server_addr});

    // Client thread
    const client_thread = try std.Thread.spawn(.{}, struct {
        fn client(client_io: std.Io, sa: std.Io.net.IpAddress) !void {
            try client_io.sleep(std.Io.Duration.fromMilliseconds(50), std.Io.Clock.awake);

            const stream = try sa.connect(client_io, .{ .mode = .stream });
            defer stream.close(client_io);

            var wbuf: [256]u8 = undefined;
            var writer = stream.writer(client_io, &wbuf);

            var rbuf: [256]u8 = undefined;
            var reader = stream.reader(client_io, &rbuf);

            // Test PING
            try writer.interface.writeAll("PING\n");
            try writer.interface.flush();
            const resp1 = try reader.interface.takeDelimiterInclusive('\n');
            std.debug.print("✅ Client got: {s}", .{resp1});

            // Test unknown command
            try writer.interface.writeAll("INVALID\n");
            try writer.interface.flush();
            const resp2 = try reader.interface.takeDelimiterInclusive('\n');
            std.debug.print("✅ Client got: {s}", .{resp2});

            // Test QUIT
            try writer.interface.writeAll("QUIT\n");
            try writer.interface.flush();
            const resp3 = try reader.interface.takeDelimiterInclusive('\n');
            std.debug.print("✅ Client got: {s}", .{resp3});
        }
    }.client, .{ io, server_addr });

    // Accept and handle
    const stream = try server.accept(io);
    try handleConnection(io, stream);

    client_thread.join();
    std.debug.print("✅ Protocol test passed\n", .{});
}
