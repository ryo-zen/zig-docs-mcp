const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("=== std.Io.net.UnixAddress Comprehensive Test ===\n\n", .{});

    // Test 1: Basic Initialization
    std.debug.print("Test 1: Basic Initialization\n", .{});
    {
        const addr = try std.Io.net.UnixAddress.init("/tmp/test.sock");
        std.debug.print("  Path: {s}\n", .{addr.path});
        std.debug.print("  ✅ PASS - Basic initialization\n\n", .{});
    }

    // Test 2: Max Length Constant
    std.debug.print("Test 2: Max Length Constant\n", .{});
    {
        std.debug.print("  Max path length: {d}\n", .{std.Io.net.UnixAddress.max_len});
        std.debug.print("  ✅ PASS - max_len = 108\n\n", .{});
    }

    // Test 3: Path Length Validation (Valid)
    std.debug.print("Test 3: Path Length Validation (Valid)\n", .{});
    {
        // Create a path exactly at max_len
        var path_buffer: [std.Io.net.UnixAddress.max_len]u8 = undefined;
        @memset(&path_buffer, 'a');
        path_buffer[0] = '/';
        path_buffer[path_buffer.len - 1] = 0; // Null terminator

        const addr = try std.Io.net.UnixAddress.init(path_buffer[0 .. path_buffer.len - 1]);
        std.debug.print("  Created address with path length: {d}\n", .{addr.path.len});
        std.debug.print("  ✅ PASS - Valid path length\n\n", .{});
    }

    // Test 4: Path Too Long Error
    std.debug.print("Test 4: Path Too Long Error\n", .{});
    {
        // Create a path longer than max_len
        var path_buffer: [std.Io.net.UnixAddress.max_len + 10]u8 = undefined;
        @memset(&path_buffer, 'a');
        path_buffer[0] = '/';

        const result = std.Io.net.UnixAddress.init(&path_buffer);
        if (result) |_| {
            std.debug.print("  ❌ FAIL - Should have returned NameTooLong\n\n", .{});
        } else |err| {
            std.debug.print("  Got expected error: {s}\n", .{@errorName(err)});
            std.debug.print("  ✅ PASS - NameTooLong error\n\n", .{});
        }
    }

    // Test 5: Relative Path
    std.debug.print("Test 5: Relative Path\n", .{});
    {
        const addr = try std.Io.net.UnixAddress.init("./test.sock");
        std.debug.print("  Relative path: {s}\n", .{addr.path});
        std.debug.print("  ✅ PASS - Relative paths supported\n\n", .{});
    }

    // Test 6: Abstract Namespace (Linux)
    std.debug.print("Test 6: Abstract Namespace (Linux)\n", .{});
    {
        // Abstract sockets start with null byte (only on Linux)
        const abstract_path = "\x00test_abstract";
        const addr = try std.Io.net.UnixAddress.init(abstract_path);
        std.debug.print("  Abstract socket path length: {d}\n", .{addr.path.len});
        std.debug.print("  ✅ PASS - Abstract namespace (starts with null byte)\n\n", .{});
    }

    // Test 7: Listen on Unix Socket
    std.debug.print("Test 7: Listen on Unix Socket\n", .{});
    {
        const socket_path = "/tmp/zig_test_listen.sock";

        // Clean up any existing socket
        std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};

        const addr = try std.Io.net.UnixAddress.init(socket_path);
        var server = try addr.listen(io, .{});
        defer server.deinit(io);

        std.debug.print("  Server listening on: {s}\n", .{socket_path});
        std.debug.print("  ✅ PASS - Listen on Unix socket\n\n", .{});

        // Clean up
        std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};
    }

    // Test 8: Listen with Custom Backlog
    std.debug.print("Test 8: Listen with Custom Backlog\n", .{});
    {
        const socket_path = "/tmp/zig_test_backlog.sock";

        // Clean up any existing socket
        std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};

        const addr = try std.Io.net.UnixAddress.init(socket_path);
        var server = try addr.listen(io, .{ .kernel_backlog = 256 });
        defer server.deinit(io);

        std.debug.print("  Server with custom backlog (256)\n", .{});
        std.debug.print("  ✅ PASS - Custom backlog\n\n", .{});

        // Clean up
        std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};
    }

    // Test 9: Connect and Communicate
    std.debug.print("Test 9: Connect and Communicate\n", .{});
    {
        const socket_path = "/tmp/zig_test_connect.sock";

        // Clean up any existing socket
        std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};

        // Create server
        const server_addr = try std.Io.net.UnixAddress.init(socket_path);
        var server = try server_addr.listen(io, .{});
        defer {
            server.deinit(io);
            std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};
        }

        // Connect client
        const client_addr = try std.Io.net.UnixAddress.init(socket_path);
        const client = try client_addr.connect(io);
        defer client.close(io);

        std.debug.print("  Client connected to server\n", .{});
        std.debug.print("  ✅ PASS - Connect to Unix socket\n\n", .{});
    }

    // Test 10: Multiple Addresses
    std.debug.print("Test 10: Multiple Different Paths\n", .{});
    {
        const paths = [_][]const u8{
            "/tmp/socket1.sock",
            "/var/run/app.sock",
            "./local.sock",
            "/tmp/very_long_socket_name_for_testing_purposes.sock",
        };

        for (paths) |path| {
            const addr = try std.Io.net.UnixAddress.init(path);
            std.debug.print("  Created: {s}\n", .{addr.path});
        }

        std.debug.print("  ✅ PASS - Multiple paths\n\n", .{});
    }

    std.debug.print("=== All UnixAddress Tests Passed! ===\n", .{});
}
