const std = @import("std");

const CPoint = extern struct {
    x: c_int,
    y: c_int,
};

fn mapErrno(code: c_int) !void {
    return switch (code) {
        0 => {},
        22 => error.InvalidInput,
        16 => error.Busy,
        else => error.Unknown,
    };
}

fn allocateOwned(allocator: std.mem.Allocator, len: usize) ![]u8 {
    const buf = try allocator.alloc(u8, len);
    @memset(buf, 0x5A);
    return buf;
}

test "extern struct layout checks" {
    try std.testing.expect(@sizeOf(CPoint) == @sizeOf(c_int) * 2);
    try std.testing.expect(@alignOf(CPoint) == @alignOf(c_int));
    try std.testing.expect(@offsetOf(CPoint, "x") == 0);
    try std.testing.expect(@offsetOf(CPoint, "y") == @sizeOf(c_int));
}

test "ownership transfer rule: caller frees returned allocation" {
    const allocator = std.testing.allocator;
    const buf = try allocateOwned(allocator, 32);
    defer allocator.free(buf);

    try std.testing.expect(buf.len == 32);
    try std.testing.expect(buf[0] == 0x5A);
}

test "error translation from C status code" {
    try mapErrno(0);
    try std.testing.expectError(error.InvalidInput, mapErrno(22));
    try std.testing.expectError(error.Busy, mapErrno(16));
    try std.testing.expectError(error.Unknown, mapErrno(1234));
}
