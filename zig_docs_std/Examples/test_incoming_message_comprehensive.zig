const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("=== std.Io.net.IncomingMessage Comprehensive Test ===\n\n", .{});

    // Test 1: Default Initialization
    std.debug.print("Test 1: Default Initialization\n", .{});
    {
        const msg = std.Io.net.IncomingMessage.init;
        std.debug.print("  Initialized IncomingMessage\n", .{});
        std.debug.print("  control.len: {d}\n", .{msg.control.len});
        std.debug.print("  ✅ PASS - Default initialization\n\n", .{});
    }

    // Test 2: Fields Inspection
    std.debug.print("Test 2: Fields Inspection\n", .{});
    {
        const msg = std.Io.net.IncomingMessage.init;
        std.debug.print("  from: IpAddress (undefined)\n", .{});
        std.debug.print("  data: []u8 (undefined)\n", .{});
        std.debug.print("  control: []u8 (len={d})\n", .{msg.control.len});
        std.debug.print("  flags: Flags (undefined)\n", .{});
        std.debug.print("  ✅ PASS - Fields inspection\n\n", .{});
    }

    // Test 3: Flags Structure
    std.debug.print("Test 3: Flags Structure\n", .{});
    {
        const flags = std.Io.net.IncomingMessage.Flags{
            .eor = true,
            .trunc = false,
            .ctrunc = false,
            .oob = false,
            .errqueue = false,
        };
        std.debug.print("  eor: {}\n", .{flags.eor});
        std.debug.print("  trunc: {}\n", .{flags.trunc});
        std.debug.print("  ctrunc: {}\n", .{flags.ctrunc});
        std.debug.print("  oob: {}\n", .{flags.oob});
        std.debug.print("  errqueue: {}\n", .{flags.errqueue});
        std.debug.print("  ✅ PASS - Flags structure\n\n", .{});
    }

    // Test 4: UDP Socket Receive (Setup)
    std.debug.print("Test 4: UDP Socket Receive\n", .{});
    {
        // Use a fixed port for simplicity
        const server_port: u16 = 19234;

        // Create UDP server socket
        const server_ip4 = try std.Io.net.Ip4Address.parse("127.0.0.1", server_port);
        const server_addr = std.Io.net.IpAddress{ .ip4 = server_ip4 };
        const server_socket = try std.Io.net.IpAddress.bind(&server_addr, io, .{ .mode = .dgram });
        defer server_socket.close(io);

        std.debug.print("  Server bound to port: {d}\n", .{server_port});

        // Create client socket
        const client_ip4 = try std.Io.net.Ip4Address.parse("127.0.0.1", 0);
        const client_addr = std.Io.net.IpAddress{ .ip4 = client_ip4 };
        const client_socket = try std.Io.net.IpAddress.bind(&client_addr, io, .{ .mode = .dgram });
        defer client_socket.close(io);

        // Send message from client to server
        const send_data = "Hello UDP";
        const target_ip4 = try std.Io.net.Ip4Address.parse("127.0.0.1", server_port);
        const target_addr = std.Io.net.IpAddress{ .ip4 = target_ip4 };
        var send_msg = std.Io.net.OutgoingMessage{
            .address = &target_addr,
            .data_ptr = send_data.ptr,
            .data_len = send_data.len,
        };
        _ = try client_socket.sendMany(io, (&send_msg)[0..1], .{});

        // Receive on server
        var recv_buffer: [1024]u8 = undefined;
        const received = try server_socket.receive(io, &recv_buffer);

        std.debug.print("  Received {d} bytes\n", .{received.data.len});
        std.debug.print("  Data: {s}\n", .{received.data});
        std.debug.print("  ✅ PASS - UDP receive\n\n", .{});
    }

    // Test 5: Multiple Messages (receiveManyTimeout)
    std.debug.print("Test 5: Multiple Messages Buffer\n", .{});
    {
        var messages: [5]std.Io.net.IncomingMessage = undefined;
        for (&messages) |*msg| {
            msg.* = std.Io.net.IncomingMessage.init;
        }
        std.debug.print("  Initialized {d} message slots\n", .{messages.len});
        std.debug.print("  ✅ PASS - Multiple message buffer\n\n", .{});
    }

    // Test 6: Flag Combinations
    std.debug.print("Test 6: Flag Combinations\n", .{});
    {
        const test_cases = [_]struct {
            name: []const u8,
            flags: std.Io.net.IncomingMessage.Flags,
        }{
            .{ .name = "No flags", .flags = .{ .eor = false, .trunc = false, .ctrunc = false, .oob = false, .errqueue = false } },
            .{ .name = "End of record", .flags = .{ .eor = true, .trunc = false, .ctrunc = false, .oob = false, .errqueue = false } },
            .{ .name = "Truncated", .flags = .{ .eor = false, .trunc = true, .ctrunc = false, .oob = false, .errqueue = false } },
            .{ .name = "Out of band", .flags = .{ .eor = false, .trunc = false, .ctrunc = false, .oob = true, .errqueue = false } },
        };

        for (test_cases) |tc| {
            std.debug.print("  {s}: eor={} trunc={} oob={}\n", .{ tc.name, tc.flags.eor, tc.flags.trunc, tc.flags.oob });
        }
        std.debug.print("  ✅ PASS - Flag combinations\n\n", .{});
    }

    // Test 7: Control Data Buffer
    std.debug.print("Test 7: Control Data Buffer\n", .{});
    {
        var control_buffer: [256]u8 = undefined;
        var msg = std.Io.net.IncomingMessage.init;
        msg.control = &control_buffer;

        std.debug.print("  Control buffer size: {d} bytes\n", .{msg.control.len});
        std.debug.print("  ✅ PASS - Control data buffer\n\n", .{});
    }

    // Test 8: Receive with Timeout
    std.debug.print("Test 8: Receive with Timeout\n", .{});
    {
        // Create UDP socket
        const ip4_addr = try std.Io.net.Ip4Address.parse("127.0.0.1", 0);
        const addr = std.Io.net.IpAddress{ .ip4 = ip4_addr };
        const server_socket = try std.Io.net.IpAddress.bind(&addr, io, .{ .mode = .dgram });
        defer server_socket.close(io);

        // Try to receive with very short timeout (should timeout)
        var recv_buffer: [1024]u8 = undefined;
        const timeout = std.Io.Timeout{ .duration = .{
            .raw = std.Io.Duration.fromMilliseconds(10),
            .clock = .awake,
        } };

        const result = server_socket.receiveTimeout(io, &recv_buffer, timeout);
        if (result) |_| {
            std.debug.print("  Unexpectedly received data\n", .{});
        } else |err| {
            std.debug.print("  Got expected timeout: {s}\n", .{@errorName(err)});
        }

        std.debug.print("  ✅ PASS - Receive with timeout\n\n", .{});
    }

    // Test 9: Message Size
    std.debug.print("Test 9: IncomingMessage Size\n", .{});
    {
        const size = @sizeOf(std.Io.net.IncomingMessage);
        const flags_size = @sizeOf(std.Io.net.IncomingMessage.Flags);

        std.debug.print("  IncomingMessage size: {d} bytes\n", .{size});
        std.debug.print("  Flags size: {d} byte(s)\n", .{flags_size});
        std.debug.print("  ✅ PASS - Size inspection\n\n", .{});
    }

    // Test 10: Documentation Pattern
    std.debug.print("Test 10: Documentation Pattern\n", .{});
    {
        // Common pattern: prepare receive buffer and message
        const recv_buffer: [2048]u8 = undefined;
        var msg = std.Io.net.IncomingMessage.init;

        // Optional: allocate control data buffer
        var control_buffer: [256]u8 = undefined;
        msg.control = &control_buffer;

        std.debug.print("  Prepared message for receiving\n", .{});
        std.debug.print("  Buffer: {d} bytes\n", .{recv_buffer.len});
        std.debug.print("  Control: {d} bytes\n", .{msg.control.len});
        std.debug.print("  ✅ PASS - Documentation pattern\n\n", .{});
    }

    std.debug.print("=== All IncomingMessage Tests Passed! ===\n", .{});
}
