// Runnable examples for std.ascii.
// Run with: zig test zig_docs_std/Examples/std.ascii.tests.zig

const std = @import("std");
const testing = std.testing;

test "classify ASCII bytes" {
    try testing.expect(std.ascii.isAlphabetic('A'));
    try testing.expect(std.ascii.isAlphabetic('z'));
    try testing.expect(std.ascii.isDigit('7'));
    try testing.expect(std.ascii.isAlphanumeric('9'));
    try testing.expect(std.ascii.isHex('f'));
    try testing.expect(std.ascii.isWhitespace('\n'));
    try testing.expect(std.ascii.isPunctuation('!'));
    try testing.expect(!std.ascii.isAscii(0x80));
}

test "case conversion for one byte and whole strings" {
    try testing.expectEqual(@as(u8, 'A'), std.ascii.toUpper('a'));
    try testing.expectEqual(@as(u8, 'z'), std.ascii.toLower('Z'));
    try testing.expectEqual(@as(u8, '?'), std.ascii.toUpper('?'));

    var lower_buf: [5]u8 = undefined;
    const lower = std.ascii.lowerString(&lower_buf, "HeLLo");
    try testing.expectEqualStrings("hello", lower);

    var upper_buf: [5]u8 = undefined;
    const upper = std.ascii.upperString(&upper_buf, "HeLLo");
    try testing.expectEqualStrings("HELLO", upper);
}

test "case-insensitive comparisons and search" {
    try testing.expect(std.ascii.eqlIgnoreCase("Content-Type", "content-type"));
    try testing.expect(std.ascii.startsWithIgnoreCase("Bearer token", "bearer"));
    try testing.expect(std.ascii.endsWithIgnoreCase("README.MD", ".md"));

    const index = std.ascii.findIgnoreCase("accept-encoding", "ENCODING").?;
    try testing.expectEqual(@as(usize, 7), index);

    try testing.expect(std.ascii.lessThanIgnoreCase("abc", "BCD"));
}

test "allocated case conversion" {
    const allocator = testing.allocator;

    const lowered = try std.ascii.allocLowerString(allocator, "MiXeD");
    defer allocator.free(lowered);
    try testing.expectEqualStrings("mixed", lowered);

    const uppered = try std.ascii.allocUpperString(allocator, "MiXeD");
    defer allocator.free(uppered);
    try testing.expectEqualStrings("MIXED", uppered);
}
