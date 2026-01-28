//! Comprehensive test suite for std.Io.File covering streaming I/O,
//! positional I/O, and file metadata operations.

const std = @import("std");
const testing = std.testing;

test "File buffered writer and readStreaming" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_buffered.txt";
    defer cwd.deleteFile(io, filename) catch {};

    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);

        var buffer: [1024]u8 = undefined;
        var writer = file.writer(io, &buffer);
        try writer.interface.writeAll("Hello Buffered World");
        try writer.interface.flush();
    }

    {
        const file = try cwd.openFile(io, filename, .{});
        defer file.close(io);

        var buf: [100]u8 = undefined;
        const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
        try testing.expectEqualStrings("Hello Buffered World", buf[0..bytes_read]);
    }
}

test "File writeStreamingAll one-shot" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_streaming_all.txt";
    defer cwd.deleteFile(io, filename) catch {};

    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "one-shot streaming write");
    }

    {
        const file = try cwd.openFile(io, filename, .{});
        defer file.close(io);

        var buf: [100]u8 = undefined;
        const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
        try testing.expectEqualStrings("one-shot streaming write", buf[0..bytes_read]);
    }
}

test "File positional write and read" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_positional.dat";
    defer cwd.deleteFile(io, filename) catch {};

    // Write phase
    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);
        try file.writePositionalAll(io, "AAAA", 0);
        try file.writePositionalAll(io, "BBBB", 4);
    }

    // Read phase
    {
        const file = try cwd.openFile(io, filename, .{});
        defer file.close(io);

        var buf: [4]u8 = undefined;
        _ = try file.readPositionalAll(io, &buf, 4);
        try testing.expectEqualStrings("BBBB", &buf);

        _ = try file.readPositionalAll(io, &buf, 0);
        try testing.expectEqualStrings("AAAA", &buf);
    }
}

test "File stat and length" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_stat.txt";
    defer cwd.deleteFile(io, filename) catch {};

    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "hello stat");
    }

    {
        const file = try cwd.openFile(io, filename, .{});
        defer file.close(io);

        const len = try file.length(io);
        try testing.expectEqual(@as(u64, 10), len);

        const info = try file.stat(io);
        try testing.expectEqual(@as(u64, 10), info.size);
    }
}
