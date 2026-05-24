const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const file = try std.Io.Dir.cwd().openFile(io, "zig_docs_std/Examples/data/dummy.txt", .{ .mode = .read_only });
    defer file.close(io);

    var buf: [100]u8 = undefined;
    const bytes_read = try file.readStreaming(io, &.{buf[0..]});
    std.debug.print("Read {} bytes using std.Io.File\n", .{bytes_read});
}
