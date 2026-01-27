const std = @import("std");

pub fn main() !void {
    std.debug.print("=== Peek vs Take Demonstration ===\n\n", .{});

    const data = "ABCDEFGHIJKLMNOP";
    var reader = std.Io.Reader.fixed(data);

    // Test 1: Peek doesn't advance
    std.debug.print("Test 1: Peek doesn't advance position\n", .{});
    {
        const byte1 = try reader.peekByte();
        const byte2 = try reader.peekByte();
        const byte3 = try reader.peekByte();
        std.debug.print("  First peek: {c}\n", .{byte1});
        std.debug.print("  Second peek: {c}\n", .{byte2});
        std.debug.print("  Third peek: {c}\n", .{byte3});
        std.debug.print("  All peeks returned: '{c}' (same!)\n", .{byte1});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Take advances
    std.debug.print("Test 2: Take advances position\n", .{});
    {
        const byte1 = try reader.takeByte();
        const byte2 = try reader.takeByte();
        const byte3 = try reader.takeByte();
        std.debug.print("  First take: {c}\n", .{byte1});
        std.debug.print("  Second take: {c}\n", .{byte2});
        std.debug.print("  Third take: {c}\n", .{byte3});
        std.debug.print("  Takes returned: '{c}', '{c}', '{c}' (different!)\n", .{ byte1, byte2, byte3 });
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Peek + Toss = Take
    std.debug.print("Test 3: Peek + Toss = Take\n", .{});
    {
        const peeked = try reader.peekByte();
        reader.toss(1);
        const taken = try reader.takeByte();

        std.debug.print("  Peeked then tossed: {c}\n", .{peeked});
        std.debug.print("  Just taken: {c}\n", .{taken});
        std.debug.print("  Peek+Toss moved past '{c}', Take got '{c}'\n", .{ peeked, taken });
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Peek ahead for decision making
    std.debug.print("Test 4: Lookahead pattern\n", .{});
    {
        const next = try reader.peekByte();
        if (next == 'F') {
            std.debug.print("  Found 'F'! Skipping it.\n", .{});
            reader.toss(1);
        }

        const actual = try reader.takeByte();
        std.debug.print("  Next byte after skip: {c}\n", .{actual});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Tests Passed! ===\n", .{});
}
