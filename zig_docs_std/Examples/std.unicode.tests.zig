// Runnable examples for std.unicode.
// Run with: zig test zig_docs_std/Examples/std.unicode.tests.zig

const std = @import("std");
const testing = std.testing;

test "validate and count UTF-8 codepoints" {
    const valid = "A\xE2\x82\xAC"; // A + euro sign
    const invalid = [_]u8{ 0xE2, 0x28, 0xA1 };

    try testing.expect(std.unicode.utf8ValidateSlice(valid));
    try testing.expect(!std.unicode.utf8ValidateSlice(&invalid));

    try testing.expectEqual(@as(usize, 2), try std.unicode.utf8CountCodepoints(valid));
}

test "encode and decode one UTF-8 codepoint" {
    var buf: [4]u8 = undefined;
    const len = try std.unicode.utf8Encode(0x1F642, &buf);
    try testing.expectEqual(@as(u3, 4), len);

    const decoded = try std.unicode.utf8Decode(buf[0..len]);
    try testing.expectEqual(@as(u21, 0x1F642), decoded);
}

test "iterate UTF-8 codepoints" {
    const text = "A\xE2\x82\xAC";

    const view = try std.unicode.Utf8View.init(text);
    var it = view.iterator();

    try testing.expectEqual(@as(u21, 'A'), it.nextCodepoint().?);
    try testing.expectEqual(@as(u21, 0x20AC), it.nextCodepoint().?);
    try testing.expect(it.nextCodepoint() == null);
}

test "convert UTF-16 little-endian to UTF-8" {
    const utf16 = [_]u16{ 'H', 'i', 0x20AC };

    var buf: [16]u8 = undefined;
    const len = try std.unicode.utf16LeToUtf8(&buf, &utf16);

    try testing.expectEqualStrings("Hi\xE2\x82\xAC", buf[0..len]);
}
