const std = @import("std");
const net = std.Io.net;

/// Basic Stream usage: listen, connect, write, read, close.
/// A simple TCP echo server and client in one program.
///
/// Stream.reader() / .writer() return wrapper structs; the actual
/// Io.Reader / Io.Writer interface is accessed via the .interface field.
///
/// Note: use takeDelimiterInclusive (not Exclusive) to correctly advance
/// past the delimiter byte in the reader buffer.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // --- Server: listen on loopback ---
    const addr = net.IpAddress.parse("127.0.0.1", 8181) catch unreachable;
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);
    std.debug.print("Server listening on 127.0.0.1:8181\n", .{});

    // --- Client: connect to the server ---
    const client_stream = try addr.connect(io, .{ .mode = .stream });
    defer client_stream.close(io);
    std.debug.print("Client connected\n", .{});

    // --- Server: accept the connection ---
    var server_stream = try server.accept(io);
    defer server_stream.close(io);
    std.debug.print("Server accepted connection\n", .{});

    // --- Client: write a message ---
    var wbuf: [256]u8 = undefined;
    var writer = client_stream.writer(io, &wbuf);
    try writer.interface.writeAll("Hello, Stream!\n");
    try writer.interface.flush();
    std.debug.print("Client sent: Hello, Stream!\n", .{});

    // --- Server: read the message and echo it back ---
    var server_rbuf: [256]u8 = undefined;
    var server_reader = server_stream.reader(io, &server_rbuf);
    // takeDelimiterInclusive returns content + delimiter; strip the \n
    const received_with_delim = try server_reader.interface.takeDelimiterInclusive('\n');
    const received = received_with_delim[0 .. received_with_delim.len - 1];
    std.debug.print("Server received: {s}\n", .{received});

    var server_wbuf: [256]u8 = undefined;
    var server_writer = server_stream.writer(io, &server_wbuf);
    try server_writer.interface.writeAll(received);
    try server_writer.interface.writeAll(" (echoed)\n");
    try server_writer.interface.flush();

    // --- Client: read the echo ---
    var rbuf: [256]u8 = undefined;
    var reader = client_stream.reader(io, &rbuf);
    const echo_with_delim = try reader.interface.takeDelimiterInclusive('\n');
    const echo = echo_with_delim[0 .. echo_with_delim.len - 1];
    std.debug.print("Client received: {s}\n", .{echo});

    std.debug.print("✅ Basic stream test complete\n", .{});
}
