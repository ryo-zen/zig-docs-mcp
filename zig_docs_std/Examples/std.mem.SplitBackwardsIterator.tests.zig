// Comprehensive tests demonstrating std.mem.SplitBackwardsIterator
// Shows reverse iteration, comparison with forward splitting, and practical use cases

const std = @import("std");

test "SplitBackwardsIterator basic usage (scalar delimiter)" {
    std.debug.print("\n🧪 Test: Basic backward splitting\n", .{});

    const input = "one,two,three";
    var iter = std.mem.splitBackwardsScalar(u8, input, ',');

    // Iterate from right to left
    try std.testing.expectEqualStrings("three", iter.next().?);
    try std.testing.expectEqualStrings("two", iter.next().?);
    try std.testing.expectEqualStrings("one", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Backward iteration returns fields right-to-left\n", .{});
}

test "SplitBackwardsIterator with sequence delimiter" {
    std.debug.print("\n🧪 Test: Backward splitting with sequence delimiter\n", .{});

    const input = "foo::bar::baz";
    var iter = std.mem.splitBackwardsSequence(u8, input, "::");

    try std.testing.expectEqualStrings("baz", iter.next().?);
    try std.testing.expectEqualStrings("bar", iter.next().?);
    try std.testing.expectEqualStrings("foo", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Sequence delimiter works with backward iteration\n", .{});
}

test "SplitBackwardsIterator with .any delimiter" {
    std.debug.print("\n🧪 Test: Backward splitting with .any delimiter\n", .{});

    const input = "a,b;c,d";
    var iter = std.mem.splitBackwardsAny(u8, input, ",;");

    try std.testing.expectEqualStrings("d", iter.next().?);
    try std.testing.expectEqualStrings("c", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: .any delimiter type works backward\n", .{});
}

test "SplitBackwardsIterator preserves empty fields" {
    std.debug.print("\n🧪 Test: Empty fields preserved\n", .{});

    const input = "a,,b,";
    var iter = std.mem.splitBackwardsScalar(u8, input, ',');

    try std.testing.expectEqualStrings("", iter.next().?); // trailing delimiter
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("", iter.next().?); // consecutive delimiters
    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Empty fields between delimiters preserved\n", .{});
}

test "SplitBackwardsIterator first() method" {
    std.debug.print("\n🧪 Test: first() method\n", .{});

    const input = "x,y,z";
    var iter = std.mem.splitBackwardsScalar(u8, input, ',');

    // first() returns the first field and starts iteration
    const first_field = iter.first();
    try std.testing.expectEqualStrings("z", first_field);

    // After first(), use next() to get remaining fields
    try std.testing.expectEqualStrings("y", iter.next().?);
    try std.testing.expectEqualStrings("x", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: first() returns rightmost field and begins iteration\n", .{});
}

test "SplitBackwardsIterator rest() method" {
    std.debug.print("\n🧪 Test: rest() method\n", .{});

    const input = "a,b,c,d";
    var iter = std.mem.splitBackwardsScalar(u8, input, ',');

    // Consume some fields
    _ = iter.next(); // "d"
    _ = iter.next(); // "c"

    // rest() returns everything from current position to start
    const remaining = iter.rest();
    try std.testing.expectEqualStrings("a,b", remaining);

    // Can still continue iterating
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("a", iter.next().?);

    std.debug.print("  ✅ PASS: rest() returns unprocessed portion\n", .{});
}

test "SplitBackwardsIterator reset() method" {
    std.debug.print("\n🧪 Test: reset() method\n", .{});

    const input = "1,2,3";
    var iter = std.mem.splitBackwardsScalar(u8, input, ',');

    // First iteration
    try std.testing.expectEqualStrings("3", iter.next().?);
    try std.testing.expectEqualStrings("2", iter.next().?);

    // Reset and iterate again
    iter.reset();
    try std.testing.expectEqualStrings("3", iter.next().?);
    try std.testing.expectEqualStrings("2", iter.next().?);
    try std.testing.expectEqualStrings("1", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: reset() allows re-iteration\n", .{});
}

test "Comparison: forward vs backward splitting" {
    std.debug.print("\n🧪 Test: Forward vs Backward comparison\n", .{});

    const input = "alpha,beta,gamma";

    // Forward iteration
    {
        var iter = std.mem.splitScalar(u8, input, ',');
        try std.testing.expectEqualStrings("alpha", iter.next().?);
        try std.testing.expectEqualStrings("beta", iter.next().?);
        try std.testing.expectEqualStrings("gamma", iter.next().?);
        std.debug.print("  ✅ Forward: alpha → beta → gamma\n", .{});
    }

    // Backward iteration
    {
        var iter = std.mem.splitBackwardsScalar(u8, input, ',');
        try std.testing.expectEqualStrings("gamma", iter.next().?);
        try std.testing.expectEqualStrings("beta", iter.next().?);
        try std.testing.expectEqualStrings("alpha", iter.next().?);
        std.debug.print("  ✅ Backward: gamma → beta → alpha\n", .{});
    }

    std.debug.print("  ✅ PASS: Forward and backward produce opposite orders\n", .{});
}

test "Real-world: path component extraction" {
    std.debug.print("\n🧪 Test: Extract path components\n", .{});

    const path = "/usr/local/bin/myapp";
    var iter = std.mem.splitBackwardsScalar(u8, path, '/');

    // Extract from right to left
    const filename = iter.next().?;
    try std.testing.expectEqualStrings("myapp", filename);

    const parent_dir = iter.next().?;
    try std.testing.expectEqualStrings("bin", parent_dir);

    const grandparent = iter.next().?;
    try std.testing.expectEqualStrings("local", grandparent);

    std.debug.print("  ✅ PASS: Path parsing from end is efficient with backward split\n", .{});
}

test "Real-world: file extension extraction" {
    std.debug.print("\n🧪 Test: Extract file extension\n", .{});

    const filename = "document.backup.tar.gz";
    var iter = std.mem.splitBackwardsScalar(u8, filename, '.');

    const ext = iter.next().?;
    try std.testing.expectEqualStrings("gz", ext);

    const second_ext = iter.next().?;
    try std.testing.expectEqualStrings("tar", second_ext);

    std.debug.print("  ✅ PASS: Extension extraction using backward split\n", .{});
}

test "Real-world: parse URL query string from end" {
    std.debug.print("\n🧪 Test: Parse URL query backwards\n", .{});

    const query = "page=1&limit=10&sort=desc";
    var iter = std.mem.splitBackwardsScalar(u8, query, '&');

    // Process parameters from right to left
    const param3 = iter.next().?;
    try std.testing.expectEqualStrings("sort=desc", param3);

    const param2 = iter.next().?;
    try std.testing.expectEqualStrings("limit=10", param2);

    const param1 = iter.next().?;
    try std.testing.expectEqualStrings("page=1", param1);

    std.debug.print("  ✅ PASS: URL query parsing backwards works\n", .{});
}

test "Real-world: log line processing (most recent first)" {
    std.debug.print("\n🧪 Test: Process log entries in reverse\n", .{});

    // Simulate multiline log with newline-separated entries
    const log = "INFO: App started\nWARN: Low memory\nERROR: Connection failed";
    var iter = std.mem.splitBackwardsScalar(u8, log, '\n');

    // Process most recent (last) log entry first
    const entry1 = iter.next().?;
    try std.testing.expect(std.mem.startsWith(u8, entry1, "ERROR"));

    const entry2 = iter.next().?;
    try std.testing.expect(std.mem.startsWith(u8, entry2, "WARN"));

    const entry3 = iter.next().?;
    try std.testing.expect(std.mem.startsWith(u8, entry3, "INFO"));

    std.debug.print("  ✅ PASS: Log processing from most recent backward\n", .{});
}

test "Edge case: empty input" {
    std.debug.print("\n🧪 Test: Empty input\n", .{});

    const empty = "";
    var iter = std.mem.splitBackwardsScalar(u8, empty, ',');

    // Empty input yields one empty field
    try std.testing.expectEqualStrings("", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Empty input handled correctly\n", .{});
}

test "Edge case: no delimiters" {
    std.debug.print("\n🧪 Test: No delimiters in input\n", .{});

    const input = "nodels";
    var iter = std.mem.splitBackwardsScalar(u8, input, ',');

    // Returns entire string as single field
    try std.testing.expectEqualStrings("nodels", iter.next().?);
    try std.testing.expect(iter.next() == null);

    std.debug.print("  ✅ PASS: Input without delimiters returns whole string\n", .{});
}
