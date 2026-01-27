const std = @import("std");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    // Write some data
    try writer.writeAll("Hello, ");
    try writer.print("World! Answer = {}\n", .{42});

    // Flush to ensure all data is written
    try writer.flush();

    // Get the buffered content
    const written = writer.buffered();
    std.debug.print("Written to buffer: {s}", .{written});
}
