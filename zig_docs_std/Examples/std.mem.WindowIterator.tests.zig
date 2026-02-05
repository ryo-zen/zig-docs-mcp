// Comprehensive tests demonstrating std.mem.WindowIterator
// Shows sliding windows, overlapping/non-overlapping patterns, and practical use cases

const std = @import("std");

test "WindowIterator with maximum overlap (advance = 1)" {
    std.debug.print("\n🧪 Test: Maximum overlap (bigrams)\n", .{});

    const input = "hello";
    var iter = std.mem.window(u8, input, 2, 1);

    // Each position yields a 2-character window
    try std.testing.expectEqualStrings("he", iter.next().?);
    try std.testing.expectEqualStrings("el", iter.next().?);
    try std.testing.expectEqualStrings("ll", iter.next().?);
    try std.testing.expectEqualStrings("lo", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Bigrams (2-char windows, advance=1) work correctly\n", .{});
}

test "WindowIterator with no overlap (advance = size)" {
    std.debug.print("\n🧪 Test: Non-overlapping chunks\n", .{});

    const input = "abcdefgh";
    var iter = std.mem.window(u8, input, 3, 3);

    // Non-overlapping 3-character chunks
    try std.testing.expectEqualStrings("abc", iter.next().?);
    try std.testing.expectEqualStrings("def", iter.next().?);
    // Last window is only 2 chars (partial window)
    try std.testing.expectEqualStrings("gh", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Non-overlapping chunks work correctly\n", .{});
}

test "WindowIterator with partial overlap" {
    std.debug.print("\n🧪 Test: Partial overlap (advance < size)\n", .{});

    const input = "abcdefg";
    var iter = std.mem.window(u8, input, 4, 2);

    // Window size 4, advance 2: 2-char overlap
    try std.testing.expectEqualStrings("abcd", iter.next().?);
    try std.testing.expectEqualStrings("cdef", iter.next().?);
    try std.testing.expectEqualStrings("efg", iter.next().?); // partial final window
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Partial overlap (advance=2, size=4) works\n", .{});
}

test "WindowIterator with gaps (advance > size)" {
    std.debug.print("\n🧪 Test: Windows with gaps\n", .{});

    const input = "0123456789";
    var iter = std.mem.window(u8, input, 2, 4);

    // Window size 2, advance 4: 2-char gap between windows
    try std.testing.expectEqualStrings("01", iter.next().?);
    try std.testing.expectEqualStrings("45", iter.next().?);
    try std.testing.expectEqualStrings("89", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Gaps between windows (advance > size) work\n", .{});
}

test "WindowIterator reset functionality" {
    std.debug.print("\n🧪 Test: Reset and re-iterate\n", .{});

    const input = "test";
    var iter = std.mem.window(u8, input, 2, 1);

    // First iteration
    var count1: usize = 0;
    while (iter.next()) |_| count1 += 1;
    try std.testing.expectEqual(3, count1); // "te", "es", "st"

    // Reset and iterate again
    iter.reset();
    var count2: usize = 0;
    while (iter.next()) |_| count2 += 1;
    try std.testing.expectEqual(3, count2);

    std.debug.print("  ✅ PASS: Reset allows re-iteration\n", .{});
}

test "WindowIterator with numeric data" {
    std.debug.print("\n🧪 Test: Windows over numeric arrays\n", .{});

    const numbers = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    var iter = std.mem.window(i32, &numbers, 3, 2);

    const w1 = iter.next().?;
    try std.testing.expectEqual(3, w1.len);
    try std.testing.expectEqual(1, w1[0]);
    try std.testing.expectEqual(2, w1[1]);
    try std.testing.expectEqual(3, w1[2]);

    const w2 = iter.next().?;
    try std.testing.expectEqual(3, w2[0]);
    try std.testing.expectEqual(4, w2[1]);
    try std.testing.expectEqual(5, w2[2]);

    std.debug.print("  ✅ PASS: Works with numeric types\n", .{});
}

test "Real-world: trigram analysis" {
    std.debug.print("\n🧪 Test: Trigram text analysis\n", .{});

    const text = "the quick brown fox";
    var iter = std.mem.window(u8, text, 3, 1);

    var trigram_count: usize = 0;
    while (iter.next()) |trigram| {
        trigram_count += 1;
        // In real usage, you'd add these to a frequency map
        std.debug.print("    Trigram: '{s}'\n", .{trigram});
    }

    // Text length is 19, so we get 19-3+1 = 17 trigrams
    try std.testing.expectEqual(17, trigram_count);

    std.debug.print("  ✅ PASS: Trigram analysis produces expected count\n", .{});
}

test "Real-world: processing data in fixed chunks" {
    std.debug.print("\n🧪 Test: Process data in 4-byte chunks\n", .{});

    // Simulate reading chunks from a file or network stream
    const data = [_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09 };
    var iter = std.mem.window(u8, &data, 4, 4);

    var chunk_num: usize = 0;
    while (iter.next()) |chunk| {
        chunk_num += 1;

        if (chunk_num == 1) {
            // First full chunk
            try std.testing.expectEqual(4, chunk.len);
            try std.testing.expectEqual(0x01, chunk[0]);
        } else if (chunk_num == 2) {
            // Second full chunk
            try std.testing.expectEqual(4, chunk.len);
            try std.testing.expectEqual(0x05, chunk[0]);
        } else if (chunk_num == 3) {
            // Partial final chunk
            try std.testing.expectEqual(1, chunk.len);
            try std.testing.expectEqual(0x09, chunk[0]);
        }
    }

    try std.testing.expectEqual(3, chunk_num);
    std.debug.print("  ✅ PASS: Chunked processing handles full and partial chunks\n", .{});
}

test "Real-world: moving average calculation" {
    std.debug.print("\n🧪 Test: Calculate moving averages\n", .{});

    const values = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };
    const window_size = 3;

    var iter = std.mem.window(f32, &values, window_size, 1);

    // Calculate moving averages
    var averages: std.ArrayList(f32) = .empty;
    defer averages.deinit(std.testing.allocator);

    while (iter.next()) |window| {
        var sum: f32 = 0.0;
        for (window) |val| sum += val;
        const avg = sum / @as(f32, @floatFromInt(window.len));
        try averages.append(std.testing.allocator, avg);
    }

    // Check some moving averages
    // [1,2,3] → 2.0
    try std.testing.expectApproxEqAbs(2.0, averages.items[0], 0.001);
    // [2,3,4] → 3.0
    try std.testing.expectApproxEqAbs(3.0, averages.items[1], 0.001);
    // [3,4,5] → 4.0
    try std.testing.expectApproxEqAbs(4.0, averages.items[2], 0.001);

    std.debug.print("  ✅ PASS: Moving average calculation works correctly\n", .{});
}

test "Edge case: empty buffer" {
    std.debug.print("\n🧪 Test: Empty buffer edge case\n", .{});

    const empty: []const u8 = &[_]u8{};
    var iter = std.mem.window(u8, empty, 3, 1);

    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Empty buffer returns null immediately\n", .{});
}

test "Edge case: window size larger than buffer" {
    std.debug.print("\n🧪 Test: Window larger than buffer\n", .{});

    const small = "ab";
    var iter = std.mem.window(u8, small, 5, 1);

    // When window size > buffer length, returns a partial window
    const partial = iter.next().?;
    try std.testing.expectEqualStrings("ab", partial);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Window larger than buffer returns partial window\n", .{});
}
