const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("Starting file reader readiness example\n", .{});

    const file = try std.Io.Dir.cwd().openFile(io, "zig_docs_std/Examples/data/dummy.txt", .{ .mode = .read_only });
    defer file.close(io);

    var buffer: [1024]u8 = undefined;
    var reader = file.readerStreaming(io, &buffer);
    const data = try reader.interface.allocRemaining(allocator, .limited(1024));
    defer allocator.free(data);

    std.debug.print("Read {d} bytes: {s}\n", .{ data.len, data[0..@min(data.len, 50)] });
}
