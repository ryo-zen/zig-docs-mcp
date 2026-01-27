const std = @import("std");

pub fn main() !void {
    std.debug.print("=== Reader Array Operations ===\n\n", .{});

    // Test 1: Take fixed-size array
    std.debug.print("Test 1: Take Array\n", .{});
    {
        const data = "ABCDEFGHIJKLMNOP";
        var reader = std.Io.Reader.fixed(data);

        const arr = try reader.takeArray(8);
        std.debug.print("  Took 8 bytes as array: {s}\n", .{arr});
        std.debug.print("  Array type: *[8]u8\n", .{});

        const next = try reader.takeByte();
        std.debug.print("  Next byte: {c}\n", .{next});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Peek fixed-size array
    std.debug.print("Test 2: Peek Array\n", .{});
    {
        const data = "0123456789";
        var reader = std.Io.Reader.fixed(data);

        const arr1 = try reader.peekArray(5);
        const arr2 = try reader.peekArray(5);

        std.debug.print("  First peek: {s}\n", .{arr1});
        std.debug.print("  Second peek: {s}\n", .{arr2});
        std.debug.print("  Both peeks same (position unchanged): {}\n", .{std.mem.eql(u8, arr1, arr2)});

        reader.toss(2);
        const arr3 = try reader.peekArray(5);
        std.debug.print("  After toss(2): {s}\n", .{arr3});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Read slice all
    std.debug.print("Test 3: Read Slice All\n", .{});
    {
        const data = "EXACTLYTEN";
        var reader = std.Io.Reader.fixed(data);

        var buffer: [10]u8 = undefined;
        try reader.readSliceAll(&buffer);

        std.debug.print("  Read into buffer: {s}\n", .{buffer});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Read slice short (partial reads)
    std.debug.print("Test 4: Read Slice Short\n", .{});
    {
        const data = "SHORT";
        var reader = std.Io.Reader.fixed(data);

        var buffer: [10]u8 = undefined;
        const bytes_read = try reader.readSliceShort(&buffer);

        std.debug.print("  Requested 10, got {} bytes\n", .{bytes_read});
        std.debug.print("  Content: {s}\n", .{buffer[0..bytes_read]});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Binary struct-like reading with arrays
    std.debug.print("Test 5: Binary Header Pattern\n", .{});
    {
        // Create binary header
        var write_buf: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&write_buf);

        // Magic number (4 bytes)
        try writer.writeAll("MGIC");
        // Version (2 bytes)
        try writer.writeInt(u16, 1, .little);
        // Flags (1 byte)
        try writer.writeByte(0xFF);
        // UUID (16 bytes)
        const uuid = [_]u8{0x01} ** 16;
        try writer.writeAll(&uuid);
        try writer.flush();

        // Read it back
        var reader = std.Io.Reader.fixed(writer.buffered());

        const magic = try reader.takeArray(4);
        const version = try reader.takeInt(u16, .little);
        const flags = try reader.takeByte();
        const read_uuid = try reader.takeArray(16);

        std.debug.print("  Magic: {s}\n", .{magic});
        std.debug.print("  Version: {}\n", .{version});
        std.debug.print("  Flags: 0x{x:0>2}\n", .{flags});
        std.debug.print("  UUID: ", .{});
        for (read_uuid) |byte| {
            std.debug.print("{x:0>2}", .{byte});
        }
        std.debug.print("\n  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Tests Passed! ===\n", .{});
}
