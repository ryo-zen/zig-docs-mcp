const std = @import("std");
const net = std.Io.net;

// Global state for the client thread
var server_addr: net.IpAddress = undefined;

fn runClient(ctx: anytype) !void {
    const io: std.Io = ctx.io;
    const iterations: usize = ctx.iterations;

    // Small delay to ensure server is strictly ready if on a slow system,
    // though spawn happens after listen so it should be fine.
    try io.sleep(std.Io.Duration.fromMilliseconds(10), std.Io.Clock.awake);

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // 1. Connect
        const conn = try server_addr.connect(io, .{ .mode = .stream });
        defer conn.close(io);

        // 2. Send Request
        var wbuf: [128]u8 = undefined;
        var writer = conn.writer(io, &wbuf);

        try writer.interface.print("Ping {d}\n", .{i});
        try writer.interface.flush();

        // 3. Read Response
        var rbuf: [128]u8 = undefined;
        var reader = conn.reader(io, &rbuf);

        const response = try reader.interface.takeDelimiterInclusive('\n');
        // Strip newline for clean printing
        const clean_response = response[0 .. response.len - 1];

        // Sync print to avoid garbled output
        std.debug.print("   [Client] Rx: \"{s}\"\n", .{clean_response});
    }
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    // Use Threaded IO backend
    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("🚀 Starting Server Comprehensive Test\n", .{});
    std.debug.print("-------------------------------------\n", .{});

    // 1. Setup Server on ephemeral port (0)
    // We use port 0 to let the OS assign a free port, avoiding conflicts.
    const loopback = try net.IpAddress.parse("127.0.0.1", 0);
    var server = try loopback.listen(io, .{
        .reuse_address = true,
        .kernel_backlog = 10,
    });
    defer server.deinit(io);

    // Retrieve the actual assigned port
    server_addr = server.socket.address;
    std.debug.print("✅ [Server] Listening on {}\n", .{server_addr});

    // 2. Spawn Client Thread
    const TOTAL_REQUESTS = 5;
    const client_thread = try std.Thread.spawn(.{}, runClient, .{.{ .io = io, .iterations = TOTAL_REQUESTS }});

    // 3. Accept Loop
    var processed: usize = 0;
    while (processed < TOTAL_REQUESTS) : (processed += 1) {
        // Block until a client connects
        var stream = try server.accept(io);
        defer stream.close(io);

        // Handle connection (sequentially for this test)
        var buf: [1024]u8 = undefined;
        var reader = stream.reader(io, &buf);

        // We expect one line per connection in this protocol
        const request = try reader.interface.takeDelimiterInclusive('\n');

        // Prepare response
        var wbuf: [1024]u8 = undefined;
        var writer = stream.writer(io, &wbuf);

        try writer.interface.writeAll("Echo: ");
        try writer.interface.writeAll(request); // request includes \n
        try writer.interface.flush();

        std.debug.print("✅ [Server] Handled connection {d}/{d}\n", .{processed + 1, TOTAL_REQUESTS});
    }

    // 4. Cleanup
    client_thread.join();
    std.debug.print("-------------------------------------\n", .{});
    std.debug.print("✅ Test Complete: All requests handled successfully.\n", .{});
}
