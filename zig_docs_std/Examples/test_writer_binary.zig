const std = @import("std");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    // Write integers in different byte orders
    try writer.writeInt(u32, 0x12345678, .big);
    try writer.writeInt(u16, 1000, .little);

    // Write some bytes
    try writer.writeAll("TEXT");

    try writer.flush();

    const written = writer.buffered();
    std.debug.print("Wrote {} bytes\n", .{written.len});

    // Print as hex
    std.debug.print("Hex dump: ", .{});
    for (written) |byte| {
        std.debug.print("{x:0>2} ", .{byte});
    }
    std.debug.print("\n", .{});
}
