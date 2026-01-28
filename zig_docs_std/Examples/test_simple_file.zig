const std = @import("std");

pub fn main() !void {
    // Try using posix directly
    const path = "test_arraylist_016.zig";
    const fd = try std.posix.open(path, .{ .ACCMODE = .RDONLY }, 0);
    defer std.posix.close(fd);

    var buf: [100]u8 = undefined;
    const bytes_read = try std.posix.read(fd, &buf);
    std.debug.print("Read {} bytes using posix directly\n", .{bytes_read});
}
