const std = @import("std");

pub fn main() !void {
    const data = "Hello, World! Answer = 42\n";
    var reader = std.Io.Reader.fixed(data);

    // Read first byte
    const first = try reader.takeByte();
    std.debug.print("First byte: {c}\n", .{first});

    // Read next 5 bytes
    const hello = try reader.take(5);
    std.debug.print("Next 5 bytes: {s}\n", .{hello});

    // Read rest (use buffered to see what's available)
    const rest = reader.buffered();
    std.debug.print("Remaining: {s}", .{rest});
}
