// Bidirectional Stream: separate read/write buffers, multi-line exchange.
// Demonstrates an HTTP-style request/response pattern over a local TCP stream.
//
// Stream.reader() / .writer() return wrapper structs; the actual
// Io.Reader / Io.Writer methods are on the .interface field.
//
// Use takeDelimiterInclusive (not Exclusive) to correctly advance
// past the delimiter byte in the reader buffer.

const std = @import("std");
const net = std.Io.net;

/// Strip trailing \r from a \r\n line that was split on \n.
fn stripCR(s: []const u8) []const u8 {
    if (s.len > 0 and s[s.len - 1] == '\r') return s[0 .. s.len - 1];
    return s;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // --- Server setup ---
    const addr = net.IpAddress.parse("127.0.0.1", 8182) catch unreachable;
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    // --- Client: connect and send an HTTP-style request ---
    const client_stream = try addr.connect(io, .{ .mode = .stream });
    defer client_stream.close(io);

    var wbuf: [2048]u8 = undefined;
    var writer = client_stream.writer(io, &wbuf);
    try writer.interface.writeAll("GET / HTTP/1.1\r\n");
    try writer.interface.writeAll("Host: 127.0.0.1:8182\r\n");
    try writer.interface.writeAll("Connection: close\r\n");
    try writer.interface.writeAll("\r\n");
    try writer.interface.flush();
    std.debug.print("Client sent request\n", .{});

    // --- Server: accept and read request headers ---
    var server_stream = try server.accept(io);
    defer server_stream.close(io);

    var server_rbuf: [4096]u8 = undefined;
    var server_reader = server_stream.reader(io, &server_rbuf);

    // Read request line, strip \r\n
    const req_raw = try server_reader.interface.takeDelimiterInclusive('\n');
    std.debug.print("Server got request: {s}\n", .{stripCR(req_raw[0 .. req_raw.len - 1])});

    // Read headers until empty line
    while (true) {
        const raw = try server_reader.interface.takeDelimiterInclusive('\n');
        const line = stripCR(raw[0 .. raw.len - 1]);
        if (line.len == 0) break;
        std.debug.print("  Header: {s}\n", .{line});
    }

    // --- Server: send HTTP-style response ---
    var server_wbuf: [2048]u8 = undefined;
    var server_writer = server_stream.writer(io, &server_wbuf);
    try server_writer.interface.writeAll("HTTP/1.1 200 OK\r\n");
    try server_writer.interface.writeAll("Content-Type: text/plain\r\n");
    try server_writer.interface.writeAll("Content-Length: 13\r\n");
    try server_writer.interface.writeAll("\r\n");
    try server_writer.interface.writeAll("Hello, World!");
    try server_writer.interface.flush();
    std.debug.print("Server sent response\n", .{});

    // --- Client: read response status and headers ---
    var rbuf: [4096]u8 = undefined;
    var reader = client_stream.reader(io, &rbuf);

    const status_raw = try reader.interface.takeDelimiterInclusive('\n');
    std.debug.print("Client status: {s}\n", .{stripCR(status_raw[0 .. status_raw.len - 1])});

    std.debug.print("Client headers:\n", .{});
    while (true) {
        const raw = try reader.interface.takeDelimiterInclusive('\n');
        const line = stripCR(raw[0 .. raw.len - 1]);
        if (line.len == 0) break;
        std.debug.print("  {s}\n", .{line});
    }

    // Read body (13 bytes as declared in Content-Length)
    const body = try reader.interface.take(13);
    std.debug.print("Client body: {s}\n", .{body});

    std.debug.print("✅ Bidirectional stream test complete\n", .{});
}
