const std = @import("std");

fn hotPath(iterations: usize) u64 {
    var acc: u64 = 0;
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        acc +%= @as(u64, @intCast(i));
    }
    return acc;
}

test "timer harness baseline" {
    var timer = try std.time.Timer.start();
    const value = hotPath(200_000);
    const elapsed_ns = timer.read();

    try std.testing.expect(value != 0);
    try std.testing.expect(elapsed_ns > 0);
}

test "allocation pattern with bounded buffer" {
    var backing: [256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&backing);
    const allocator = fba.allocator();

    const bytes = try allocator.alloc(u8, 64);
    defer allocator.free(bytes);

    @memset(bytes, 0xAB);
    try std.testing.expect(bytes[0] == 0xAB);
    try std.testing.expect(bytes.len == 64);
}

fn quadraticScore(items: []const u32) u64 {
    var total: u64 = 0;
    for (items) |x| {
        for (items) |y| {
            total +%= @as(u64, x) * @as(u64, y);
        }
    }
    return total;
}

fn linearScore(items: []const u32) u64 {
    var sum: u64 = 0;
    for (items) |x| sum +%= x;
    return sum * sum;
}

test "algorithmic rewrite keeps semantics" {
    const values = [_]u32{ 1, 2, 3, 4, 5, 6 };
    try std.testing.expectEqual(quadraticScore(&values), linearScore(&values));
}
