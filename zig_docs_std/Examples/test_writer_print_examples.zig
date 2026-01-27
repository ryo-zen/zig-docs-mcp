const std = @import("std");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    // Test various print formats
    try writer.print("User {s} has {} points\n", .{"Alice", 1337});
    try writer.print("Hex: 0x{x:0>8}\n", .{0xDEADBEEF});
    try writer.print("Binary: {b}\n", .{42});

    // Test printInt
    try writer.printInt(255, 16, .lower, .{});
    try writer.writeAll(" (hex)\n");

    // Test splatByte
    try writer.splatByteAll('-', 40);
    try writer.writeAll("\n");

    try writer.flush();

    const written = writer.buffered();
    std.debug.print("Output:\n{s}", .{written});
}
