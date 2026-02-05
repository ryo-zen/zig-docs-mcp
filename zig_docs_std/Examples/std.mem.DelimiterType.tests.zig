// Comprehensive tests demonstrating std.mem.DelimiterType behavior
// Tests show the difference between .sequence, .any, and .scalar delimiter types

const std = @import("std");

test "DelimiterType.sequence - matches entire substring" {
    std.debug.print("\n🧪 Test: DelimiterType.sequence\n", .{});

    // Split on double-colon as a complete sequence
    const input = "foo::bar::baz";
    var iter = std.mem.splitSequence(u8, input, "::");

    const first = iter.next().?;
    try std.testing.expectEqualStrings("foo", first);

    const second = iter.next().?;
    try std.testing.expectEqualStrings("bar", second);

    const third = iter.next().?;
    try std.testing.expectEqualStrings("baz", third);

    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: .sequence matches complete substring '::'\n", .{});
}

test "DelimiterType.any - matches any character in set" {
    std.debug.print("\n🧪 Test: DelimiterType.any\n", .{});

    // Split on comma OR semicolon (any character in the delimiter string)
    const input = "foo,bar;baz,qux";
    var iter = std.mem.splitAny(u8, input, ",;");

    const parts = [_][]const u8{ "foo", "bar", "baz", "qux" };
    for (parts) |expected| {
        const actual = iter.next().?;
        try std.testing.expectEqualStrings(expected, actual);
    }

    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: .any matches any of ',' or ';'\n", .{});
}

test "DelimiterType.scalar - matches single character exactly" {
    std.debug.print("\n🧪 Test: DelimiterType.scalar\n", .{});

    // Split on comma only
    const input = "apple,banana,cherry";
    var iter = std.mem.splitScalar(u8, input, ',');

    try std.testing.expectEqualStrings("apple", iter.next().?);
    try std.testing.expectEqualStrings("banana", iter.next().?);
    try std.testing.expectEqualStrings("cherry", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: .scalar matches only ','\n", .{});
}

test "Comparison: sequence vs any behavior" {
    std.debug.print("\n🧪 Test: Comparing .sequence vs .any\n", .{});

    // When delimiter is "::" ...
    const input = "a::b:c::d";

    // .sequence treats "::" as one unit
    {
        var iter = std.mem.splitSequence(u8, input, "::");
        try std.testing.expectEqualStrings("a", iter.next().?);
        try std.testing.expectEqualStrings("b:c", iter.next().?); // middle colon preserved
        try std.testing.expectEqualStrings("d", iter.next().?);
        try std.testing.expect(iter.next() == null);
        std.debug.print("  ✅ .sequence: splits on '::' only, preserves single ':'\n", .{});
    }

    // .any treats each ':' independently
    {
        var iter = std.mem.splitAny(u8, input, "::");
        try std.testing.expectEqualStrings("a", iter.next().?);
        try std.testing.expectEqualStrings("", iter.next().?); // empty between colons
        try std.testing.expectEqualStrings("b", iter.next().?);
        try std.testing.expectEqualStrings("c", iter.next().?);
        try std.testing.expectEqualStrings("", iter.next().?); // empty between colons
        try std.testing.expectEqualStrings("d", iter.next().?);
        try std.testing.expect(iter.next() == null);
        std.debug.print("  ✅ .any: splits on each ':' independently\n", .{});
    }
}

test "Real-world use case: parsing CSV vs whitespace" {
    std.debug.print("\n🧪 Test: Real-world parsing scenarios\n", .{});

    // CSV parsing with .scalar (single comma delimiter)
    {
        const csv_line = "Alice,30,Engineer";
        var iter = std.mem.splitScalar(u8, csv_line, ',');

        try std.testing.expectEqualStrings("Alice", iter.next().?);
        try std.testing.expectEqualStrings("30", iter.next().?);
        try std.testing.expectEqualStrings("Engineer", iter.next().?);

        std.debug.print("  ✅ CSV parsing with .scalar works correctly\n", .{});
    }

    // Split on any whitespace with .any
    {
        const text = "one\ttwo   three\nfour";
        var iter = std.mem.splitAny(u8, text, " \t\n");

        var count: usize = 0;
        const words = [_][]const u8{ "one", "two", "three", "four" };

        while (iter.next()) |token| {
            if (token.len == 0) continue; // skip empty tokens from consecutive delimiters
            try std.testing.expectEqualStrings(words[count], token);
            count += 1;
        }

        try std.testing.expectEqual(4, count);
        std.debug.print("  ✅ Whitespace tokenization with .any handles tabs/spaces/newlines\n", .{});
    }
}
