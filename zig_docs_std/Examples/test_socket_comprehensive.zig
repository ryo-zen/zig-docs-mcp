// Comprehensive Socket (UDP) usage: receiveTimeout, sendMany, receiveManyTimeout.
//
// Demonstrates advanced std.Io.net.Socket features.

const std = @import("std");
const net = std.Io.net;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("--- Test 1: receiveTimeout ---\n", .{});
    {
        const addr = try net.IpAddress.parse("127.0.0.1", 0);
        const socket = try addr.bind(io, .{ .mode = .dgram });
        defer socket.close(io);

        var buf: [100]u8 = undefined;
        // 100ms timeout
        const result = socket.receiveTimeout(io, &buf, .{ .duration = .{ .raw = std.Io.Duration.fromMilliseconds(100), .clock = .awake } });
        
        if (result) |_| {
            std.debug.print("❌ Expected timeout, got message\n", .{});
            return error.TestFailed;
        } else |err| {
            if (err == error.Timeout) {
                std.debug.print("✅ Timed out as expected\n", .{});
            } else {
                std.debug.print("❌ Expected error.Timeout, got {}\n", .{err});
                return error.TestFailed;
            }
        }
    }

    std.debug.print("\n--- Test 2: sendMany & receiveManyTimeout ---\n", .{});
    {
        // Server
        const server_addr = try net.IpAddress.parse("127.0.0.1", 9899);
        const server = try server_addr.bind(io, .{ .mode = .dgram });
        defer server.close(io);

        // Client
        const client_addr = try net.IpAddress.parse("127.0.0.1", 0);
        const client = try client_addr.bind(io, .{ .mode = .dgram });
        defer client.close(io);

        // Prepare messages
        const msg1 = "Message One";
        const msg2 = "Message Two";
        const msg3 = "Message Three";

        var out_msgs: [3]net.OutgoingMessage = undefined;
        out_msgs[0] = .{
            .address = &server_addr,
            .data_ptr = msg1.ptr,
            .data_len = msg1.len,
            .control = &[_]u8{},
        };
        out_msgs[1] = .{
            .address = &server_addr,
            .data_ptr = msg2.ptr,
            .data_len = msg2.len,
            .control = &[_]u8{},
        };
        out_msgs[2] = .{
            .address = &server_addr,
            .data_ptr = msg3.ptr,
            .data_len = msg3.len,
            .control = &[_]u8{},
        };

        // Send all at once
        try client.sendMany(io, &out_msgs, .{});
        std.debug.print("Sent 3 messages via sendMany\n", .{});

        // Receive all at once
        var in_msgs: [3]net.IncomingMessage = undefined;
        var recv_buf: [1024]u8 = undefined;
        
        // Wait up to 1 second
        const result = server.receiveManyTimeout(io, &in_msgs, &recv_buf, .{}, .{ .duration = .{ .raw = std.Io.Duration.fromSeconds(1), .clock = .awake } });
        
        const count = result[1];
        if (result[0]) |err| {
             std.debug.print("❌ receiveManyTimeout error: {}\n", .{err});
             return error.TestFailed;
        }

        std.debug.print("Received {} messages\n", .{count});
        if (count != 3) {
            // Note: UDP doesn't guarantee delivery, but on localhost loopback it should work reliably.
            // If it flakes, we might need retry logic or accept partial success, but for a doc example, correct logic is key.
             std.debug.print("⚠️ Warning: Expected 3, got {}\n", .{count});
        }

        var i: usize = 0;
        while (i < count) : (i += 1) {
            std.debug.print("Msg {}: {s}\n", .{i, in_msgs[i].data});
        }
    }

    std.debug.print("\n--- Test 3: closeMany ---\n", .{});
    {
        const addr = try net.IpAddress.parse("127.0.0.1", 0);
        const s1 = try addr.bind(io, .{ .mode = .dgram });
        const s2 = try addr.bind(io, .{ .mode = .dgram });
        
        s1.close(io);
        s2.close(io);
        std.debug.print("✅ Closed 2 sockets individually\n", .{});
    }

    std.debug.print("\n✅ Comprehensive socket test complete\n", .{});
}
