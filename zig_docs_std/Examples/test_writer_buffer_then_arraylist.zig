const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Write to a buffer first, then copy to ArrayList
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    try writer.print("Formatted: {d:0>4}\n", .{42});
    try writer.writeAll("More data\n");
    try writer.flush();

    const written = writer.buffered();
    std.debug.print("Written to buffer ({} bytes):\n{s}", .{written.len, written});

    // Or just use fmt.allocPrint for ArrayList
    const formatted = try std.fmt.allocPrint(allocator, "Value: {d:0>4}\n", .{42});
    defer allocator.free(formatted);
    std.debug.print("Using allocPrint: {s}", .{formatted});
}
