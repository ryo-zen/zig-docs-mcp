// Representative tests for zig_docs/identifiers.md examples.
// Run with:
//   zig test zig_docs_std/Examples/identifiers.tests.zig

const std = @import("std");
const testing = std.testing;

const @"identifier with spaces in it" = 0xff;
const @"1SmallStep4Man" = 112358;

const Color = enum {
    red,
    @"really red",
};

const color: Color = .@"really red";

test "string identifier syntax supports otherwise invalid names" {
    try testing.expectEqual(@as(comptime_int, 0xff), @"identifier with spaces in it");
    try testing.expectEqual(@as(comptime_int, 112358), @"1SmallStep4Man");
}

test "enum literals can use string identifier syntax" {
    try testing.expectEqual(Color.@"really red", color);
    try testing.expectEqualStrings("really red", @tagName(color));
}
