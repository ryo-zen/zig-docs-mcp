// Comprehensive tests demonstrating std.mem.TokenIterator
// Shows tokenization, delimiter skipping, and practical use cases

const std = @import("std");

test "TokenIterator basic usage (scalar delimiter)" {
    std.debug.print("\n🧪 Test: Basic tokenization\n", .{});

    const input = "hello world foo";
    var iter = std.mem.tokenizeScalar(u8, input, ' ');

    try std.testing.expectEqualStrings("hello", iter.next().?);
    try std.testing.expectEqualStrings("world", iter.next().?);
    try std.testing.expectEqualStrings("foo", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Basic tokenization returns non-empty tokens\n", .{});
}

test "TokenIterator skips consecutive delimiters" {
    std.debug.print("\n🧪 Test: Consecutive delimiters skipped\n", .{});

    const input = "a,,,b,,c";
    var iter = std.mem.tokenizeScalar(u8, input, ',');

    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("c", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Consecutive delimiters produce no empty tokens\n", .{});
}

test "TokenIterator skips leading delimiters" {
    std.debug.print("\n🧪 Test: Leading delimiters skipped\n", .{});

    const input = ",,a,b";
    var iter = std.mem.tokenizeScalar(u8, input, ',');

    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Leading delimiters ignored\n", .{});
}

test "TokenIterator skips trailing delimiters" {
    std.debug.print("\n🧪 Test: Trailing delimiters skipped\n", .{});

    const input = "a,b,,";
    var iter = std.mem.tokenizeScalar(u8, input, ',');

    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Trailing delimiters ignored\n", .{});
}

test "TokenIterator with sequence delimiter" {
    std.debug.print("\n🧪 Test: Tokenization with sequence delimiter\n", .{});

    const input = "first---second---third";
    var iter = std.mem.tokenizeSequence(u8, input, "---");

    try std.testing.expectEqualStrings("first", iter.next().?);
    try std.testing.expectEqualStrings("second", iter.next().?);
    try std.testing.expectEqualStrings("third", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Sequence delimiter tokenization works\n", .{});
}

test "TokenIterator with .any delimiter" {
    std.debug.print("\n🧪 Test: Tokenization with .any delimiter\n", .{});

    const input = "word1\tword2  word3\nword4";
    var iter = std.mem.tokenizeAny(u8, input, " \t\n");

    try std.testing.expectEqualStrings("word1", iter.next().?);
    try std.testing.expectEqualStrings("word2", iter.next().?);
    try std.testing.expectEqualStrings("word3", iter.next().?);
    try std.testing.expectEqualStrings("word4", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: .any delimiter type tokenizes correctly\n", .{});
}

test "TokenIterator peek() method" {
    std.debug.print("\n🧪 Test: peek() method\n", .{});

    const input = "a b c";
    var iter = std.mem.tokenizeScalar(u8, input, ' ');

    // peek() returns next token without advancing
    const peeked = iter.peek().?;
    try std.testing.expectEqualStrings("a", peeked);

    // next() returns same value and advances
    const next_val = iter.next().?;
    try std.testing.expectEqualStrings("a", next_val);

    // peek() now shows the second token
    const peeked2 = iter.peek().?;
    try std.testing.expectEqualStrings("b", peeked2);

    std.debug.print("  ✅ PASS: peek() inspects without advancing\n", .{});
}

test "TokenIterator rest() method" {
    std.debug.print("\n🧪 Test: rest() method\n", .{});

    const input = "one two three four";
    var iter = std.mem.tokenizeScalar(u8, input, ' ');

    _ = iter.next(); // "one"

    const remaining = iter.rest();
    try std.testing.expectEqualStrings("two three four", remaining);

    // Can still continue iterating
    try std.testing.expectEqualStrings("two", iter.next().?);
    try std.testing.expectEqualStrings("three", iter.next().?);
    try std.testing.expectEqualStrings("four", iter.next().?);

    std.debug.print("  ✅ PASS: rest() returns unprocessed portion\n", .{});
}

test "TokenIterator reset() method" {
    std.debug.print("\n🧪 Test: reset() method\n", .{});

    const input = "a b c";
    var iter = std.mem.tokenizeScalar(u8, input, ' ');

    // First iteration
    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);

    // Reset and iterate again
    iter.reset();
    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("c", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: reset() allows re-iteration\n", .{});
}

test "Comparison: TokenIterator vs SplitIterator" {
    std.debug.print("\n🧪 Test: Token vs Split comparison\n", .{});

    const input = "a,,b,,c";

    // TokenIterator skips empty fields
    {
        var iter = std.mem.tokenizeScalar(u8, input, ',');
        try std.testing.expectEqualStrings("a", iter.next().?);
        try std.testing.expectEqualStrings("b", iter.next().?);
        try std.testing.expectEqualStrings("c", iter.next().?);
        try std.testing.expect(iter.next() == null);
        std.debug.print("  ✅ Token: a → b → c (3 tokens)\n", .{});
    }

    // SplitIterator preserves empty fields
    {
        var iter = std.mem.splitScalar(u8, input, ',');
        try std.testing.expectEqualStrings("a", iter.next().?);
        try std.testing.expectEqualStrings("", iter.next().?);
        try std.testing.expectEqualStrings("b", iter.next().?);
        try std.testing.expectEqualStrings("", iter.next().?);
        try std.testing.expectEqualStrings("c", iter.next().?);
        try std.testing.expect(iter.next() == null);
        std.debug.print("  ✅ Split: a → \"\" → b → \"\" → c (5 fields)\n", .{});
    }

    std.debug.print("  ✅ PASS: Token skips empties, Split preserves them\n", .{});
}

test "Real-world: whitespace word extraction" {
    std.debug.print("\n🧪 Test: Whitespace word extraction\n", .{});

    const text = "  The   quick   brown   fox  ";
    var iter = std.mem.tokenizeScalar(u8, text, ' ');

    try std.testing.expectEqualStrings("The", iter.next().?);
    try std.testing.expectEqualStrings("quick", iter.next().?);
    try std.testing.expectEqualStrings("brown", iter.next().?);
    try std.testing.expectEqualStrings("fox", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Extracts words ignoring variable whitespace\n", .{});
}

test "Real-world: shell argument parsing" {
    std.debug.print("\n🧪 Test: Shell argument parsing\n", .{});

    const command = "ls   -la    /usr/local/bin";
    var iter = std.mem.tokenizeScalar(u8, command, ' ');

    const program = iter.next().?;
    try std.testing.expectEqualStrings("ls", program);

    const flag = iter.next().?;
    try std.testing.expectEqualStrings("-la", flag);

    const path = iter.next().?;
    try std.testing.expectEqualStrings("/usr/local/bin", path);

    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Shell-like argument splitting works\n", .{});
}

test "Real-world: mixed whitespace tokenization" {
    std.debug.print("\n🧪 Test: Mixed whitespace tokenization\n", .{});

    const log_line = "2024-01-15\t10:30:00\t\tINFO\t  Server started";
    var iter = std.mem.tokenizeAny(u8, log_line, " \t");

    try std.testing.expectEqualStrings("2024-01-15", iter.next().?);
    try std.testing.expectEqualStrings("10:30:00", iter.next().?);
    try std.testing.expectEqualStrings("INFO", iter.next().?);
    try std.testing.expectEqualStrings("Server", iter.next().?);
    try std.testing.expectEqualStrings("started", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Mixed whitespace handled with .any delimiter\n", .{});
}

test "Real-world: counting tokens" {
    std.debug.print("\n🧪 Test: Counting tokens\n", .{});

    const sentence = "  hello   world   foo   bar  ";
    var iter = std.mem.tokenizeScalar(u8, sentence, ' ');

    var count: usize = 0;
    while (iter.next()) |_| {
        count += 1;
    }
    try std.testing.expectEqual(@as(usize, 4), count);

    std.debug.print("  ✅ PASS: Token count is correct\n", .{});
}

test "Edge case: empty input" {
    std.debug.print("\n🧪 Test: Empty input\n", .{});

    const empty = "";
    var iter = std.mem.tokenizeScalar(u8, empty, ',');

    // Empty input produces no tokens
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Empty input returns null immediately\n", .{});
}

test "Edge case: delimiter-only input" {
    std.debug.print("\n🧪 Test: Delimiter-only input\n", .{});

    const input = ",,,";
    var iter = std.mem.tokenizeScalar(u8, input, ',');

    // No actual tokens, just delimiters
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Delimiter-only input returns null\n", .{});
}

test "Edge case: single token no delimiters" {
    std.debug.print("\n🧪 Test: Single token, no delimiters\n", .{});

    const input = "hello";
    var iter = std.mem.tokenizeScalar(u8, input, ',');

    try std.testing.expectEqualStrings("hello", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Single token without delimiters works\n", .{});
}
