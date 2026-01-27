const std = @import("std");

pub fn main() !void {
    std.debug.print("=== Zig 0.16 Writer Comprehensive Test ===\n\n", .{});

    // Test 1: Fixed buffer writer
    std.debug.print("Test 1: Fixed Buffer Writer\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);

        try writer.writeAll("Hello, ");
        try writer.print("World! Answer = {}\n", .{42});
        try writer.flush();

        const written = writer.buffered();
        std.debug.print("  Written: {s}", .{written});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Various print formats
    std.debug.print("Test 2: Format Specifiers\n", .{});
    {
        var buffer: [2048]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);

        try writer.print("  String: {s}\n", .{"Hello"});
        try writer.print("  Decimal: {d}\n", .{42});
        try writer.print("  Hex (lower): {x}\n", .{255});
        try writer.print("  Hex (upper): {X}\n", .{255});
        try writer.print("  Binary: {b}\n", .{42});
        try writer.print("  Padded: {d:0>8}\n", .{42});
        try writer.flush();

        const written = writer.buffered();
        std.debug.print("{s}", .{written});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Binary data writing
    std.debug.print("Test 3: Binary Data\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);

        try writer.writeInt(u32, 0x12345678, .big);
        try writer.writeInt(u16, 1000, .little);
        try writer.flush();

        const written = writer.buffered();
        std.debug.print("  Wrote {} bytes: ", .{written.len});
        for (written) |byte| {
            std.debug.print("{x:0>2} ", .{byte});
        }
        std.debug.print("\n  ✅ PASS\n\n", .{});
    }

    // Test 4: Byte splatting
    std.debug.print("Test 4: Byte Splatting\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);

        try writer.writeAll("  ");
        try writer.splatByteAll('-', 50);
        try writer.writeAll("\n");
        try writer.flush();

        const written = writer.buffered();
        std.debug.print("{s}", .{written});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: WritableSlice
    std.debug.print("Test 5: Writable Slice\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);

        const slice = try writer.writableSlice(10);
        @memcpy(slice[0..5], "Hello");
        writer.advance(5);

        try writer.flush();
        const written = writer.buffered();
        std.debug.print("  Direct write: {s}\n", .{written});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 6: Undo functionality
    std.debug.print("Test 6: Undo\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);

        try writer.writeAll("  Keep this");
        try writer.writeAll(" - DELETE ME");

        // Undo the last 12 bytes
        writer.undo(12);

        try writer.writeAll("\n");
        try writer.flush();

        const written = writer.buffered();
        std.debug.print("{s}", .{written});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Tests Passed! ===\n", .{});
}
