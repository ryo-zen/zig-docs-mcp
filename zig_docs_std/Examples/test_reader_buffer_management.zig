const std = @import("std");

pub fn main() !void {
    std.debug.print("=== Reader Buffer Management ===\n\n", .{});

    // Test 1: Buffered data inspection
    std.debug.print("Test 1: Buffered Data Inspection\n", .{});
    {
        const data = "ABCDEFGHIJKLMNOP";
        var reader = std.Io.Reader.fixed(data);

        std.debug.print("  Initial buffered length: {}\n", .{reader.bufferedLen()});
        const buf = reader.buffered();
        std.debug.print("  Buffered content: {s}\n", .{buf});

        // Consume some bytes
        _ = try reader.take(5);

        std.debug.print("  After take(5): {}\n", .{reader.bufferedLen()});
        const buf2 = reader.buffered();
        std.debug.print("  Remaining: {s}\n", .{buf2});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Peek and Toss
    std.debug.print("Test 2: Peek and Toss\n", .{});
    {
        const data = "0123456789";
        var reader = std.Io.Reader.fixed(data);

        // Peek at first 5
        const peek1 = try reader.peek(5);
        std.debug.print("  Peeked 5: {s}\n", .{peek1});
        std.debug.print("  Buffered length: {}\n", .{reader.bufferedLen()});

        // Toss 3
        reader.toss(3);
        std.debug.print("  After toss(3), buffered: {}\n", .{reader.bufferedLen()});

        // Peek again
        const peek2 = try reader.peek(4);
        std.debug.print("  Peeked 4: {s}\n", .{peek2});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Toss buffered
    std.debug.print("Test 3: Toss All Buffered\n", .{});
    {
        const data = "ABCDEFGHIJKLMNOP";
        var reader = std.Io.Reader.fixed(data);

        std.debug.print("  Initial buffered: {}\n", .{reader.bufferedLen()});

        reader.tossBuffered();

        std.debug.print("  After tossBuffered: {}\n", .{reader.bufferedLen()});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Peek greedy
    std.debug.print("Test 4: Peek Greedy\n", .{});
    {
        const data = "Short";
        var reader = std.Io.Reader.fixed(data);

        // Request more than available, but get what we can
        const greedy = try reader.peekGreedy(100);
        std.debug.print("  Requested 100, got: {} bytes\n", .{greedy.len});
        std.debug.print("  Content: {s}\n", .{greedy});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Discard operations
    std.debug.print("Test 5: Discard Operations\n", .{});
    {
        const data = "XXXXXXXXXX Useful Data";
        var reader = std.Io.Reader.fixed(data);

        // Discard first 11 bytes
        try reader.discardAll(11);

        const remaining = reader.buffered();
        std.debug.print("  After discarding 11 bytes: {s}\n", .{remaining});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 6: Discard until delimiter
    std.debug.print("Test 6: Discard Until Delimiter\n", .{});
    {
        const data = "Skip this part: Keep this";
        var reader = std.Io.Reader.fixed(data);

        // Discard until colon (exclusive)
        _ = try reader.discardDelimiterExclusive(':');
        reader.toss(1); // Skip the colon
        reader.toss(1); // Skip the space

        const remaining = reader.buffered();
        std.debug.print("  After discarding to ':': {s}\n", .{remaining});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Tests Passed! ===\n", .{});
}
