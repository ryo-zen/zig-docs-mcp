const std = @import("std");

pub fn main() !void {
    const net = std.Io.net;
    const addr = try net.IpAddress.parse("127.0.0.1", 1234);
    std.debug.print("Addr: {}\n", .{addr});
}