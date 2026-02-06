// Comprehensive tests demonstrating std.mem.SplitIterator
// Shows forward iteration, empty field preservation, and practical use cases

const std = @import("std");

test "SplitIterator basic usage (scalar delimiter)" {
    std.debug.print("\n🧪 Test: Basic forward splitting\n", .{});

    const input = "one,two,three";
    var iter = std.mem.splitScalar(u8, input, ',');

    try std.testing.expectEqualStrings("one", iter.next().?);
    try std.testing.expectEqualStrings("two", iter.next().?);
    try std.testing.expectEqualStrings("three", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Forward iteration returns fields left-to-right\n", .{});
}

test "SplitIterator with sequence delimiter" {
    std.debug.print("\n🧪 Test: Forward splitting with sequence delimiter\n", .{});

    const input = "foo::bar::baz";
    var iter = std.mem.splitSequence(u8, input, "::");

    try std.testing.expectEqualStrings("foo", iter.next().?);
    try std.testing.expectEqualStrings("bar", iter.next().?);
    try std.testing.expectEqualStrings("baz", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Sequence delimiter works with forward iteration\n", .{});
}

test "SplitIterator with .any delimiter" {
    std.debug.print("\n🧪 Test: Forward splitting with .any delimiter\n", .{});

    const input = "a,b;c,d";
    var iter = std.mem.splitAny(u8, input, ",;");

    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("c", iter.next().?);
    try std.testing.expectEqualStrings("d", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: .any delimiter type works forward\n", .{});
}

test "SplitIterator preserves empty fields" {
    std.debug.print("\n🧪 Test: Empty fields preserved\n", .{});

    const input = "a,,b,";
    var iter = std.mem.splitScalar(u8, input, ',');

    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("", iter.next().?); // consecutive delimiters
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("", iter.next().?); // trailing delimiter
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Empty fields between delimiters preserved\n", .{});
}

test "SplitIterator leading delimiter produces empty field" {
    std.debug.print("\n🧪 Test: Leading delimiter\n", .{});

    const input = ",a,b";
    var iter = std.mem.splitScalar(u8, input, ',');

    try std.testing.expectEqualStrings("", iter.next().?); // leading delimiter
    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Leading delimiter produces empty first field\n", .{});
}

test "SplitIterator first() method" {
    std.debug.print("\n🧪 Test: first() method\n", .{});

    const input = "x,y,z";
    var iter = std.mem.splitScalar(u8, input, ',');

    // first() returns the first field and starts iteration
    const first_field = iter.first();
    try std.testing.expectEqualStrings("x", first_field);

    // After first(), use next() to get remaining fields
    try std.testing.expectEqualStrings("y", iter.next().?);
    try std.testing.expectEqualStrings("z", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: first() returns leftmost field and begins iteration\n", .{});
}

test "SplitIterator peek() method" {
    std.debug.print("\n🧪 Test: peek() method\n", .{});

    const input = "a,b,c";
    var iter = std.mem.splitScalar(u8, input, ',');

    // peek() returns next field without advancing
    const peeked = iter.peek().?;
    try std.testing.expectEqualStrings("a", peeked);

    // next() returns same value and advances
    const next_val = iter.next().?;
    try std.testing.expectEqualStrings("a", next_val);

    // peek() now shows the second field
    const peeked2 = iter.peek().?;
    try std.testing.expectEqualStrings("b", peeked2);

    std.debug.print("  ✅ PASS: peek() inspects without advancing\n", .{});
}

test "SplitIterator rest() method" {
    std.debug.print("\n🧪 Test: rest() method\n", .{});

    const input = "a,b,c,d";
    var iter = std.mem.splitScalar(u8, input, ',');

    // Consume one field
    _ = iter.next(); // "a"

    // rest() returns everything from current position to end
    const remaining = iter.rest();
    try std.testing.expectEqualStrings("b,c,d", remaining);

    // Can still continue iterating
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("c", iter.next().?);
    try std.testing.expectEqualStrings("d", iter.next().?);

    std.debug.print("  ✅ PASS: rest() returns unprocessed portion\n", .{});
}

test "SplitIterator reset() method" {
    std.debug.print("\n🧪 Test: reset() method\n", .{});

    const input = "1,2,3";
    var iter = std.mem.splitScalar(u8, input, ',');

    // First iteration
    try std.testing.expectEqualStrings("1", iter.next().?);
    try std.testing.expectEqualStrings("2", iter.next().?);

    // Reset and iterate again
    iter.reset();
    try std.testing.expectEqualStrings("1", iter.next().?);
    try std.testing.expectEqualStrings("2", iter.next().?);
    try std.testing.expectEqualStrings("3", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: reset() allows re-iteration\n", .{});
}

test "Comparison: SplitIterator vs TokenIterator" {
    std.debug.print("\n🧪 Test: Split vs Token comparison\n", .{});

    const input = "a,,b,,c";

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

    // TokenIterator skips empty fields
    {
        var iter = std.mem.tokenizeScalar(u8, input, ',');
        try std.testing.expectEqualStrings("a", iter.next().?);
        try std.testing.expectEqualStrings("b", iter.next().?);
        try std.testing.expectEqualStrings("c", iter.next().?);
        try std.testing.expect(iter.next() == null);
        std.debug.print("  ✅ Token: a → b → c (3 fields)\n", .{});
    }

    std.debug.print("  ✅ PASS: Split preserves empties, Token skips them\n", .{});
}

test "Real-world: CSV row parsing" {
    std.debug.print("\n🧪 Test: CSV row parsing\n", .{});

    const row = "Alice,,30,Engineer";
    var iter = std.mem.splitScalar(u8, row, ',');

    const name = iter.next().?;
    try std.testing.expectEqualStrings("Alice", name);

    const middle = iter.next().?;
    try std.testing.expectEqualStrings("", middle); // empty field preserved

    const age = iter.next().?;
    try std.testing.expectEqualStrings("30", age);

    const role = iter.next().?;
    try std.testing.expectEqualStrings("Engineer", role);

    std.debug.print("  ✅ PASS: CSV parsing preserves empty columns\n", .{});
}

test "Real-world: config key-value parsing" {
    std.debug.print("\n🧪 Test: Config key-value parsing\n", .{});

    const line = "database_host=localhost";
    var iter = std.mem.splitScalar(u8, line, '=');

    const key = iter.next().?;
    try std.testing.expectEqualStrings("database_host", key);

    const value = iter.rest();
    try std.testing.expectEqualStrings("localhost", value);

    std.debug.print("  ✅ PASS: Key-value parsing with rest()\n", .{});
}

test "Real-world: config value containing delimiter" {
    std.debug.print("\n🧪 Test: Value containing delimiter\n", .{});

    // rest() is useful when the value itself may contain the delimiter
    const line = "connection_string=host=db;port=5432";
    var iter = std.mem.splitScalar(u8, line, '=');

    const key = iter.next().?;
    try std.testing.expectEqualStrings("connection_string", key);

    const value = iter.rest();
    try std.testing.expectEqualStrings("host=db;port=5432", value);

    std.debug.print("  ✅ PASS: rest() captures value with delimiters intact\n", .{});
}

test "Real-world: path component extraction" {
    std.debug.print("\n🧪 Test: Path component extraction\n", .{});

    const path = "/usr/local/bin/myapp";
    var iter = std.mem.splitScalar(u8, path, '/');

    // Leading slash produces empty first field
    try std.testing.expectEqualStrings("", iter.next().?);
    try std.testing.expectEqualStrings("usr", iter.next().?);
    try std.testing.expectEqualStrings("local", iter.next().?);
    try std.testing.expectEqualStrings("bin", iter.next().?);
    try std.testing.expectEqualStrings("myapp", iter.next().?);

    std.debug.print("  ✅ PASS: Path splitting handles leading slash\n", .{});
}

test "Edge case: empty input" {
    std.debug.print("\n🧪 Test: Empty input\n", .{});

    const empty = "";
    var iter = std.mem.splitScalar(u8, empty, ',');

    // Empty input yields one empty field
    try std.testing.expectEqualStrings("", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Empty input handled correctly\n", .{});
}

test "Edge case: no delimiters" {
    std.debug.print("\n🧪 Test: No delimiters in input\n", .{});

    const input = "hello";
    var iter = std.mem.splitScalar(u8, input, ',');

    // Returns entire string as single field
    try std.testing.expectEqualStrings("hello", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Input without delimiters returns whole string\n", .{});
}

test "Edge case: only delimiters" {
    std.debug.print("\n🧪 Test: Input is only delimiters\n", .{});

    const input = ",,";
    var iter = std.mem.splitScalar(u8, input, ',');

    try std.testing.expectEqualStrings("", iter.next().?);
    try std.testing.expectEqualStrings("", iter.next().?);
    try std.testing.expectEqualStrings("", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Delimiter-only input produces empty fields\n", .{});
}
