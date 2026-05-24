// Graceful shutdown: demonstrate .send shutdown and reading remaining data.
// The client sends data, shuts down the write direction, then drains the
// server's echo response before closing.
//
// Stream.reader() / .writer() return wrapper structs; the actual
// Io.Reader / Io.Writer methods are on the .interface field.
//
// Use takeDelimiterInclusive (not Exclusive) to correctly advance
// past the delimiter byte in the reader buffer.

const std = @import("std");
const net = std.Io.net;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // --- Server setup ---
    const addr = net.IpAddress.parse("127.0.0.1", 8183) catch unreachable;
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    // --- Client: connect and send ---
    const client_stream = try addr.connect(io, .{ .mode = .stream });
    defer client_stream.close(io);

    var wbuf: [256]u8 = undefined;
    var writer = client_stream.writer(io, &wbuf);
    try writer.interface.writeAll("line 1\n");
    try writer.interface.writeAll("line 2\n");
    try writer.interface.writeAll("line 3\n");
    try writer.interface.flush();
    std.debug.print("Client sent 3 lines\n", .{});

    // Shut down write direction — server will see EOF after reading our data
    try client_stream.shutdown(io, .send);
    std.debug.print("Client shut down write direction (.send)\n", .{});

    // --- Server: accept, read until EOF, echo everything back ---
    var server_stream = try server.accept(io);
    defer server_stream.close(io);

    var server_rbuf: [1024]u8 = undefined;
    var server_reader = server_stream.reader(io, &server_rbuf);

    var server_wbuf: [1024]u8 = undefined;
    var server_writer = server_stream.writer(io, &server_wbuf);

    std.debug.print("Server echoing:\n", .{});
    while (true) {
        const raw = server_reader.interface.takeDelimiterInclusive('\n') catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        const line = raw[0 .. raw.len - 1];
        std.debug.print("  > {s}\n", .{line});
        try server_writer.interface.writeAll(line);
        try server_writer.interface.writeAll("\n");
    }
    try server_writer.interface.flush();
    std.debug.print("Server done echoing\n", .{});

    // Server shuts down its write direction
    try server_stream.shutdown(io, .send);
    std.debug.print("Server shut down write direction (.send)\n", .{});

    // --- Client: read echoed data until EOF ---
    var rbuf: [1024]u8 = undefined;
    var reader = client_stream.reader(io, &rbuf);

    std.debug.print("Client reading echo:\n", .{});
    while (true) {
        const raw = reader.interface.takeDelimiterInclusive('\n') catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        std.debug.print("  < {s}\n", .{raw[0 .. raw.len - 1]});
    }

    std.debug.print("✅ Graceful shutdown test complete\n", .{});
}
