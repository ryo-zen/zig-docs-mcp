// Runnable examples for std.base64.
// Run with: zig test zig_docs_std/Examples/std.base64.tests.zig

const std = @import("std");
const testing = std.testing;

test "standard Base64 encode and decode" {
    const input = "hello";

    var encoded_buf: [std.base64.standard.Encoder.calcSize(input.len)]u8 = undefined;
    const encoded = std.base64.standard.Encoder.encode(&encoded_buf, input);
    try testing.expectEqualStrings("aGVsbG8=", encoded);

    const decoded_len = try std.base64.standard.Decoder.calcSizeForSlice(encoded);
    var decoded_buf: [16]u8 = undefined;
    try std.base64.standard.Decoder.decode(decoded_buf[0..decoded_len], encoded);
    try testing.expectEqualStrings(input, decoded_buf[0..decoded_len]);
}

test "URL-safe Base64 without padding" {
    const input = &[_]u8{ 0xfb, 0xff, 0xee };

    var encoded_buf: [std.base64.url_safe_no_pad.Encoder.calcSize(input.len)]u8 = undefined;
    const encoded = std.base64.url_safe_no_pad.Encoder.encode(&encoded_buf, input);
    try testing.expectEqualStrings("-__u", encoded);

    const decoded_len = try std.base64.url_safe_no_pad.Decoder.calcSizeForSlice(encoded);
    var decoded_buf: [16]u8 = undefined;
    try std.base64.url_safe_no_pad.Decoder.decode(decoded_buf[0..decoded_len], encoded);
    try testing.expectEqualSlices(u8, input, decoded_buf[0..decoded_len]);
}

test "decoder that ignores whitespace" {
    const encoded_with_newlines =
        \\aGVs
        \\bG8=
    ;

    const decoder = std.base64.standard.decoderWithIgnore("\n");
    var decoded_buf: [5]u8 = undefined;
    const len = try decoder.decode(&decoded_buf, encoded_with_newlines);
    try testing.expectEqualStrings("hello", decoded_buf[0..len]);
}
