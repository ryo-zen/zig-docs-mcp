const std = @import("std");

pub fn main() !void {
    // Create binary data buffer
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    // Write binary data
    try writer.writeInt(u32, 0x12345678, .big);
    try writer.writeInt(u16, 1000, .little);
    try writer.writeInt(u64, 0xDEADBEEFCAFEBABE, .little);
    try writer.writeAll("TEXT");
    try writer.flush();

    const written = writer.buffered();
    std.debug.print("Created {} bytes of binary data\n", .{written.len});

    // Now read it back
    var reader = std.Io.Reader.fixed(written);

    const val1 = try reader.takeInt(u32, .big);
    const val2 = try reader.takeInt(u16, .little);
    const val3 = try reader.takeInt(u64, .little);
    const text = try reader.take(4);

    std.debug.print("Read u32 (big-endian): 0x{x:0>8}\n", .{val1});
    std.debug.print("Read u16 (little-endian): {}\n", .{val2});
    std.debug.print("Read u64 (little-endian): 0x{x:0>16}\n", .{val3});
    std.debug.print("Read text: {s}\n", .{text});
}
