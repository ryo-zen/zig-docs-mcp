// Basic Stream usage: listen, connect, write, read, close.
// A simple TCP echo server and client in one program.
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

    // --- Server: listen on loopback ---
    const addr = net.IpAddress.parse("127.0.0.1", 8181) catch unreachable;
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);
    std.debug.print("Server listening on 127.0.0.1:8181\n", .{});

    // --- Client: connect ---
    const client_stream = try addr.connect(io, .{ .mode = .stream });
    defer client_stream.close(io);
    std.debug.print("Client connected\n", .{});

    // --- Server: accept ---
    var server_stream = try server.accept(io);
    defer server_stream.close(io);
    std.debug.print("Server accepted connection\n", .{});

    // --- Client: write a message ---
    var wbuf: [256]u8 = undefined;
    var writer = client_stream.writer(io, &wbuf);
    try writer.interface.writeAll("Hello, Stream!\n");
    try writer.interface.flush();
    std.debug.print("Client sent: Hello, Stream!\n", .{});

    // --- Server: read and echo back ---
    var server_rbuf: [256]u8 = undefined;
    var server_reader = server_stream.reader(io, &server_rbuf);
    const raw = try server_reader.interface.takeDelimiterInclusive('\n');
    const received = raw[0 .. raw.len - 1]; // strip \n
    std.debug.print("Server received: {s}\n", .{received});

    var server_wbuf: [256]u8 = undefined;
    var server_writer = server_stream.writer(io, &server_wbuf);
    try server_writer.interface.writeAll(received);
    try server_writer.interface.writeAll(" (echoed)\n");
    try server_writer.interface.flush();

    // --- Client: read the echo ---
    var rbuf: [256]u8 = undefined;
    var reader = client_stream.reader(io, &rbuf);
    const echo_raw = try reader.interface.takeDelimiterInclusive('\n');
    std.debug.print("Client received: {s}\n", .{echo_raw[0 .. echo_raw.len - 1]});

    std.debug.print("✅ Basic stream test complete\n", .{});
}
