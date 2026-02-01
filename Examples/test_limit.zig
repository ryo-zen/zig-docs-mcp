// Test examples from Limit documentation
const std = @import("std");

test "Limit - basic initialization" {
    const limit_1024 = std.Io.Limit.limited(1024);
    const unlimited = std.Io.Limit.unlimited;
    const nothing = std.Io.Limit.nothing;

    try std.testing.expect(limit_1024.toInt().? == 1024);
    try std.testing.expect(unlimited.toInt() == null);
    try std.testing.expect(nothing.toInt().? == 0);
}

test "Limit - slice buffer" {
    const limit = std.Io.Limit.limited(1024);
    var buffer: [4096]u8 = undefined;
    const safe_slice = limit.slice(&buffer);

    try std.testing.expect(safe_slice.len == 1024);
}

test "Limit - subtract tracking" {
    var remaining = std.Io.Limit.limited(1000);

    // Subtract 300
    remaining = remaining.subtract(300) orelse return error.TestFailed;
    try std.testing.expect(remaining.toInt().? == 700);

    // Try to subtract 800 (would exceed)
    const result = remaining.subtract(800);
    try std.testing.expect(result == null);
}

test "Limit - min operations" {
    const limit = std.Io.Limit.limited(100);
    const chunk_size = limit.minInt(256);
    try std.testing.expect(chunk_size == 100);

    const unlimited = std.Io.Limit.unlimited;
    const unlimited_chunk = unlimited.minInt(256);
    try std.testing.expect(unlimited_chunk == 256);
}

test "Limit - nonzero check" {
    const limit = std.Io.Limit.limited(100);
    try std.testing.expect(limit.nonzero() == true);

    const nothing = std.Io.Limit.nothing;
    try std.testing.expect(nothing.nonzero() == false);
}

test "Limit - slice1 with extra byte" {
    const limit = std.Io.Limit.limited(100);
    var buffer: [256]u8 = undefined;
    const probe_slice = limit.slice1(&buffer);

    try std.testing.expect(probe_slice.len == 101);
}

test "Limit - sliceConst" {
    const data: []const u8 = "Hello, World!";
    const limit = std.Io.Limit.limited(5);
    const truncated = limit.sliceConst(data);

    try std.testing.expectEqualStrings("Hello", truncated);
}

test "Limit - countVec" {
    const slices = [_][]const u8{ "Hello", " ", "World" };
    const total = std.Io.Limit.countVec(&slices);

    try std.testing.expect(total.toInt().? == 11);
}

test "Limit - limited64" {
    const limit = std.Io.Limit.limited64(4096);
    try std.testing.expect(limit.toInt().? == 4096);

    // Test overflow to unlimited
    const huge = std.Io.Limit.limited64(std.math.maxInt(u64));
    try std.testing.expect(huge.toInt() == null);
}

test "Limit - min comparison" {
    const limit_a = std.Io.Limit.limited(2048);
    const limit_b = std.Io.Limit.limited(1024);
    const effective = std.Io.Limit.min(limit_a, limit_b);

    try std.testing.expect(effective.toInt().? == 1024);
}
