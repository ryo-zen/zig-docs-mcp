//! Comprehensive test suite for std.Io.Threaded covering initialization,
//! concurrency, file I/O, and environment handling.

const std = @import("std");
const testing = std.testing;
const Io = std.Io;

test "Io.Threaded initialization" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();

    const io = threaded.io();
    _ = io;
    try testing.expectEqual(@as(usize, 0), threaded.busy_count);
}

test "Io.Threaded concurrent tasks" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const TaskData = struct {
        value: u32,
    };

    const Work = struct {
        fn double(data: TaskData) u32 {
            return data.value * 2;
        }
    };

    var task1 = io.async(Work.double, .{TaskData{ .value = 10 }});
    defer _ = task1.cancel(io);

    var task2 = io.async(Work.double, .{TaskData{ .value = 20 }});
    defer _ = task2.cancel(io);

    const res1 = task1.await(io);
    const res2 = task2.await(io);

    try testing.expectEqual(@as(u32, 20), res1);
    try testing.expectEqual(@as(u32, 40), res2);
}

test "Io.Threaded file operations" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_threaded.txt";
    defer cwd.deleteFile(io, filename) catch {};

    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);

        var buffer: [1024]u8 = undefined;
        var writer = file.writer(io, &buffer);
        try writer.interface.writeAll("Hello Threaded World");
        try writer.interface.flush();
    }

    {
        const file = try cwd.openFile(io, filename, .{});
        defer file.close(io);

        var buf: [100]u8 = undefined;
        // readStreaming requires a slice of slices (scatter/gather I/O)
        const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
        const read_slice = buf[0..bytes_read];

        try testing.expectEqualStrings("Hello Threaded World", read_slice);
    }
}

test "Io.Threaded environment variables" {
    const allocator = testing.allocator;

    // Verify mechanism works with safe .empty defaults
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();

    const result = threaded.environString("PATH");
    try testing.expect(result == null);
}

