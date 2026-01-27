const std = @import("std");

pub fn main() !void {
    std.debug.print("=== Binary Protocol Parsing Example ===\n\n", .{});

    // Simulate a binary protocol message:
    // [Type:u8][Length:u32][Payload:bytes]
    std.debug.print("Creating binary protocol messages...\n\n", .{});

    var write_buf: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&write_buf);

    // Message 1: Type 0x01 (TEXT)
    try writer.writeByte(0x01);
    const msg1 = "Hello";
    try writer.writeInt(u32, @as(u32, @intCast(msg1.len)), .little);
    try writer.writeAll(msg1);

    // Message 2: Type 0x02 (BINARY)
    try writer.writeByte(0x02);
    const msg2 = [_]u8{ 0xDE, 0xAD, 0xBE, 0xEF };
    try writer.writeInt(u32, @as(u32, @intCast(msg2.len)), .little);
    try writer.writeAll(&msg2);

    // Message 3: Type 0x01 (TEXT)
    try writer.writeByte(0x01);
    const msg3 = "World";
    try writer.writeInt(u32, @as(u32, @intCast(msg3.len)), .little);
    try writer.writeAll(msg3);

    try writer.flush();

    std.debug.print("Created {} bytes of protocol data\n\n", .{writer.buffered().len});

    // Now parse the protocol
    std.debug.print("Parsing protocol messages:\n\n", .{});

    var reader = std.Io.Reader.fixed(writer.buffered());

    var msg_num: usize = 1;
    while (true) {
        // Peek at message type to decide how to parse
        const msg_type = reader.peekByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        std.debug.print("Message {}: ", .{msg_num});

        switch (msg_type) {
            0x01 => {
                std.debug.print("TEXT\n", .{});
                reader.toss(1); // Consume type byte

                const length = try reader.takeInt(u32, .little);
                std.debug.print("  Length: {}\n", .{length});

                const payload = try reader.take(length);
                std.debug.print("  Payload: {s}\n", .{payload});
            },
            0x02 => {
                std.debug.print("BINARY\n", .{});
                reader.toss(1); // Consume type byte

                const length = try reader.takeInt(u32, .little);
                std.debug.print("  Length: {}\n", .{length});

                const payload = try reader.take(length);
                std.debug.print("  Payload (hex): ", .{});
                for (payload) |byte| {
                    std.debug.print("{x:0>2} ", .{byte});
                }
                std.debug.print("\n", .{});
            },
            else => {
                std.debug.print("UNKNOWN (0x{x:0>2})\n", .{msg_type});
                break;
            },
        }

        std.debug.print("\n", .{});
        msg_num += 1;
    }

    std.debug.print("=== Protocol Parsing Complete ===\n", .{});
}
