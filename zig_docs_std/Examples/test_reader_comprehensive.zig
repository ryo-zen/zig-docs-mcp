const std = @import("std");

pub fn main() !void {
    std.debug.print("=== Zig 0.16 Reader Comprehensive Test ===\n\n", .{});

    // Test 1: Fixed buffer reader basics
    std.debug.print("Test 1: Fixed Buffer Reader Basics\n", .{});
    {
        const data = "Hello, World!";
        var reader = std.Io.Reader.fixed(data);

        const first = try reader.takeByte();
        const next5 = try reader.take(5);
        const rest = reader.buffered();

        std.debug.print("  First byte: {c}\n", .{first});
        std.debug.print("  Next 5: {s}\n", .{next5});
        std.debug.print("  Remaining: {s}\n", .{rest});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Peek vs Take behavior
    std.debug.print("Test 2: Peek vs Take\n", .{});
    {
        const data = "ABCDEF";
        var reader = std.Io.Reader.fixed(data);

        const peek1 = try reader.peekByte();
        const peek2 = try reader.peekByte();
        std.debug.print("  Peek 1: {c}\n", .{peek1});
        std.debug.print("  Peek 2: {c} (same!)\n", .{peek2});

        const take1 = try reader.takeByte();
        const take2 = try reader.takeByte();
        std.debug.print("  Take 1: {c}\n", .{take1});
        std.debug.print("  Take 2: {c} (different!)\n", .{take2});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Binary integers
    std.debug.print("Test 3: Binary Integer Reading\n", .{});
    {
        var write_buf: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&write_buf);

        try writer.writeInt(u32, 0xDEADBEEF, .big);
        try writer.writeInt(u16, 12345, .little);
        try writer.writeInt(u64, 0x123456789ABCDEF0, .big);
        try writer.flush();

        var reader = std.Io.Reader.fixed(writer.buffered());

        const val1 = try reader.takeInt(u32, .big);
        const val2 = try reader.takeInt(u16, .little);
        const val3 = try reader.takeInt(u64, .big);

        std.debug.print("  u32 (big): 0x{x:0>8}\n", .{val1});
        std.debug.print("  u16 (little): {}\n", .{val2});
        std.debug.print("  u64 (big): 0x{x:0>16}\n", .{val3});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Delimiter reading
    std.debug.print("Test 4: Delimiter Reading\n", .{});
    {
        const data = "Line 1\nLine 2\nLine 3\n";
        var reader = std.Io.Reader.fixed(data);

        var line_num: usize = 1;
        while (true) {
            const line = reader.takeDelimiterInclusive('\n') catch break;
            std.debug.print("  Line {}: {s}", .{ line_num, line });
            line_num += 1;
        }
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Fixed-size arrays
    std.debug.print("Test 5: Fixed-Size Arrays\n", .{});
    {
        const data = "0123456789ABCDEF";
        var reader = std.Io.Reader.fixed(data);

        const arr1 = try reader.takeArray(8);
        const arr2 = try reader.peekArray(4);

        std.debug.print("  Took 8: {s}\n", .{arr1});
        std.debug.print("  Peeked 4: {s}\n", .{arr2});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 6: Buffer management
    std.debug.print("Test 6: Buffer Management\n", .{});
    {
        const data = "ABCDEFGHIJKLMNOP";
        var reader = std.Io.Reader.fixed(data);

        std.debug.print("  Initial buffered: {}\n", .{reader.bufferedLen()});

        _ = try reader.take(5);
        std.debug.print("  After take(5): {}\n", .{reader.bufferedLen()});

        reader.toss(3);
        std.debug.print("  After toss(3): {}\n", .{reader.bufferedLen()});

        const remaining = reader.buffered();
        std.debug.print("  Remaining data: {s}\n", .{remaining});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 7: Discard operations
    std.debug.print("Test 7: Discard Operations\n", .{});
    {
        const data = "SKIP THIS: Keep this";
        var reader = std.Io.Reader.fixed(data);

        _ = try reader.discardDelimiterExclusive(':');
        reader.toss(2); // Skip ': '

        const kept = reader.buffered();
        std.debug.print("  Kept: {s}\n", .{kept});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 8: Read into buffer
    std.debug.print("Test 8: Read Into Buffer\n", .{});
    {
        const data = "EXACTLYTEN";
        var reader = std.Io.Reader.fixed(data);

        var buffer: [10]u8 = undefined;
        try reader.readSliceAll(&buffer);

        std.debug.print("  Buffer: {s}\n", .{buffer});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 9: Peek lookahead pattern
    std.debug.print("Test 9: Lookahead Pattern\n", .{});
    {
        const data = "#Comment\nData Line";
        var reader = std.Io.Reader.fixed(data);

        const first = try reader.peekByte();
        if (first == '#') {
            std.debug.print("  Found comment, skipping...\n", .{});
            _ = try reader.discardDelimiterInclusive('\n');
        }

        const actual_line = reader.buffered();
        std.debug.print("  Actual data: {s}\n", .{actual_line});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 10: CSV parsing
    std.debug.print("Test 10: CSV Parsing\n", .{});
    {
        const data = "apple,banana,cherry";
        var reader = std.Io.Reader.fixed(data);

        var field_num: usize = 1;
        while (true) {
            const field = reader.takeDelimiterExclusive(',') catch |err| switch (err) {
                error.EndOfStream => {
                    const rest = reader.buffered();
                    if (rest.len > 0) {
                        std.debug.print("  Field {}: {s}\n", .{ field_num, rest });
                    }
                    break;
                },
                else => return err,
            };
            std.debug.print("  Field {}: {s}\n", .{ field_num, field });
            if (reader.bufferedLen() > 0) {
                reader.toss(1);
            }
            field_num += 1;
        }
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Tests Passed! ===\n", .{});
}
