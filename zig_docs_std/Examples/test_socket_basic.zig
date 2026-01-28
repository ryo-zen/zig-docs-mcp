// Basic Socket (UDP) usage: bind, send, receive, close.
// A simple UDP echo server and client in one program.
//
// Demonstrates how to use std.Io.net.Socket for connectionless communication.

const std = @import("std");
const net = std.Io.net;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Initialize IO context
    var threaded = std.Io.Threaded.init(gpa.allocator(), .{
        .environ = .empty,
    });
    defer threaded.deinit();
    const io = threaded.io();

    // --- Server: bind to specific port ---
    // We use a high port number to avoid conflicts.
    const server_addr = try net.IpAddress.parse("127.0.0.1", 9898);
    const server_socket = try server_addr.bind(io, .{ .mode = .dgram });
    defer server_socket.close(io);
    std.debug.print("Server bound to {}\n", .{server_addr});

    // --- Client: bind to ephemeral port ---
    // Binding to port 0 lets the OS assign an available port.
    const client_bind_addr = try net.IpAddress.parse("127.0.0.1", 0);
    const client_socket = try client_bind_addr.bind(io, .{ .mode = .dgram });
    defer client_socket.close(io);
    
    // The socket.address field contains the actual bound address (with the assigned port).
    std.debug.print("Client bound to {}\n", .{client_socket.address});

    // --- Client: send message to server ---
    const msg = "Hello, UDP!";
    try client_socket.send(io, &server_addr, msg);
    std.debug.print("Client sent: {s}\n", .{msg});

    // --- Server: receive message ---
    var server_buf: [1024]u8 = undefined;
    const incoming = try server_socket.receive(io, &server_buf);
    std.debug.print("Server received from {}: {s}\n", .{incoming.from, incoming.data});

    // Verify received data
    if (!std.mem.eql(u8, incoming.data, msg)) {
        std.debug.print("❌ Mismatch! Expected '{s}', got '{s}'\n", .{msg, incoming.data});
        return error.TestFailed;
    }

    // --- Server: echo back ---
    // We send back to the address that sent the message (incoming.from)
    try server_socket.send(io, &incoming.from, incoming.data);
    std.debug.print("Server echoed data back\n", .{
    });

    // --- Client: receive echo ---
    var client_buf: [1024]u8 = undefined;
    const echo = try client_socket.receive(io, &client_buf);
    std.debug.print("Client received: {s}\n", .{echo.data});

    // Verify echo
    if (!std.mem.eql(u8, echo.data, msg)) {
        std.debug.print("❌ Echo Mismatch! Expected '{s}', got '{s}'\n", .{msg, echo.data});
        return error.TestFailed;
    }

    std.debug.print("✅ Basic socket test complete\n", .{
    });
}
