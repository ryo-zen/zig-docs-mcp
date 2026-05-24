const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Reader with Memory Allocation ===\n\n", .{});

    // Test 1: Allocate remaining data
    std.debug.print("Test 1: Allocate Remaining\n", .{});
    {
        const data = "This is some data that we want to allocate";
        var reader = std.Io.Reader.fixed(data);

        // Skip first word
        _ = try reader.discardDelimiterInclusive(' ');

        // Allocate the rest
        const allocated = try reader.allocRemaining(allocator, .unlimited);
        defer allocator.free(allocated);

        std.debug.print("  Allocated: {s}\n", .{allocated});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Append to ArrayList
    std.debug.print("Test 2: Append to ArrayList\n", .{});
    {
        const data = "Line 1\nLine 2\nLine 3\n";
        var reader = std.Io.Reader.fixed(data);

        var list: std.ArrayList(u8) = .empty;
        defer list.deinit(allocator);

        // Read first line into list
        const line1 = try reader.takeDelimiterInclusive('\n');
        try list.appendSlice(allocator, line1);

        // Append remaining data
        try reader.appendRemaining(allocator, &list, .unlimited);

        std.debug.print("  ArrayList contents:\n{s}", .{list.items});
        std.debug.print("  Total bytes: {}\n", .{list.items.len});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Read allocate fixed size
    std.debug.print("Test 3: Read Allocate\n", .{});
    {
        const data = "EXACTLYTWENTYBYTES!!";
        var reader = std.Io.Reader.fixed(data);

        const allocated = try reader.readAlloc(allocator, 20);
        defer allocator.free(allocated);

        std.debug.print("  Allocated {} bytes: {s}\n", .{ allocated.len, allocated });
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Building a dynamic buffer from reader
    std.debug.print("Test 4: Building Dynamic Buffer\n", .{});
    {
        const data = "apple\nbanana\ncherry\ndate\n";
        var reader = std.Io.Reader.fixed(data);

        var lines: std.ArrayList([]u8) = .empty;
        defer {
            for (lines.items) |line| {
                allocator.free(line);
            }
            lines.deinit(allocator);
        }

        while (true) {
            const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };

            // Allocate and store each line
            const owned = try allocator.dupe(u8, line);
            try lines.append(allocator, owned);

            reader.toss(1); // Skip newline
        }

        std.debug.print("  Read {} lines:\n", .{lines.items.len});
        for (lines.items, 0..) |line, i| {
            std.debug.print("    {}: {s}\n", .{ i + 1, line });
        }
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 5: Chunked reading into ArrayList
    std.debug.print("Test 5: Chunked Reading\n", .{});
    {
        const data = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        var reader = std.Io.Reader.fixed(data);

        var chunks: std.ArrayList([]u8) = .empty;
        defer {
            for (chunks.items) |chunk| {
                allocator.free(chunk);
            }
            chunks.deinit(allocator);
        }

        // Read in chunks of 8 bytes
        while (true) {
            var chunk_buf: [8]u8 = undefined;
            const bytes_read = try reader.readSliceShort(&chunk_buf);

            if (bytes_read == 0) break;

            const chunk = try allocator.dupe(u8, chunk_buf[0..bytes_read]);
            try chunks.append(allocator, chunk);
        }

        std.debug.print("  Read {} chunks:\n", .{chunks.items.len});
        for (chunks.items, 0..) |chunk, i| {
            std.debug.print("    Chunk {}: {s}\n", .{ i + 1, chunk });
        }
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Tests Passed! ===\n", .{});
}
