const std = @import("std");

const BoundaryError = error{
    ValueOutOfRange,
    UnalignedPointer,
    NullAddress,
    MissingSentinel,
    InvalidEnumTag,
    InvalidRange,
    NonFinite,
    Overlap,
};

const Mode = enum(u8) {
    off = 0,
    on = 1,
};

fn checkedNarrowI64ToU16(value: i64) BoundaryError!u16 {
    if (value < 0 or value > std.math.maxInt(u16)) return error.ValueOutOfRange;
    return @intCast(value);
}

fn checkedFloatToI32(value: f64) BoundaryError!i32 {
    if (!std.math.isFinite(value)) return error.NonFinite;

    const min_i32_f64 = @as(f64, @floatFromInt(std.math.minInt(i32)));
    const max_i32_f64 = @as(f64, @floatFromInt(std.math.maxInt(i32)));
    if (value < min_i32_f64 or value > max_i32_f64) return error.ValueOutOfRange;

    return @intFromFloat(value);
}

fn checkedAlignCastToU32(ptr: [*]const u8) BoundaryError!*const u32 {
    if (@intFromPtr(ptr) % @alignOf(u32) != 0) return error.UnalignedPointer;
    return @ptrCast(@alignCast(ptr));
}

fn checkedPtrFromIntU32(addr: usize) BoundaryError!*const u32 {
    if (addr == 0) return error.NullAddress;
    if (addr % @alignOf(u32) != 0) return error.UnalignedPointer;
    const raw: *const anyopaque = @ptrFromInt(addr);
    return @ptrCast(@alignCast(raw));
}

fn checkedCStr(bytes: []const u8) BoundaryError![:0]const u8 {
    if (bytes.len == 0 or bytes[bytes.len - 1] != 0) return error.MissingSentinel;
    return bytes[0 .. bytes.len - 1 :0];
}

fn checkedModeFromInt(value: u8) BoundaryError!Mode {
    return switch (value) {
        0, 1 => @enumFromInt(value),
        else => error.InvalidEnumTag,
    };
}

fn checkedSubslice(bytes: []const u8, start: usize, end: usize) BoundaryError![]const u8 {
    if (start > end or end > bytes.len) return error.InvalidRange;
    return bytes[start..end];
}

fn checkedCopyNoOverlap(dst: []u8, src: []const u8) BoundaryError!void {
    if (dst.len < src.len) return error.ValueOutOfRange;

    const dst_start = @intFromPtr(dst.ptr);
    const dst_end = dst_start + src.len;
    const src_start = @intFromPtr(src.ptr);
    const src_end = src_start + src.len;

    const overlaps = dst_start < src_end and src_start < dst_end;
    if (overlaps) return error.Overlap;

    @memcpy(dst[0..src.len], src);
}

test "unsafe boundary pair: integer narrowing" {
    try std.testing.expectError(error.ValueOutOfRange, checkedNarrowI64ToU16(-1));
    try std.testing.expectEqual(@as(u16, 42), try checkedNarrowI64ToU16(42));
}

test "unsafe boundary pair: float to int" {
    try std.testing.expectError(error.NonFinite, checkedFloatToI32(std.math.nan(f64)));
    try std.testing.expectEqual(@as(i32, 123), try checkedFloatToI32(123.0));
}

test "unsafe boundary pair: alignment guard" {
    var bytes: [8]u8 = .{ 1, 0, 0, 0, 2, 0, 0, 0 };
    try std.testing.expectError(error.UnalignedPointer, checkedAlignCastToU32(bytes[1..].ptr));

    const p = try checkedAlignCastToU32(bytes[0..].ptr);
    try std.testing.expectEqual(@as(u32, 1), p.*);
}

test "unsafe boundary pair: ptrFromInt guard rails" {
    try std.testing.expectError(error.NullAddress, checkedPtrFromIntU32(0));

    var value: u32 = 99;
    const addr = @intFromPtr(&value);
    const ptr = try checkedPtrFromIntU32(addr);
    try std.testing.expectEqual(@as(u32, 99), ptr.*);
}

test "unsafe boundary pair: sentinel contract" {
    const missing = "abc";
    try std.testing.expectError(error.MissingSentinel, checkedCStr(missing));

    const with_zero = [_]u8{ 'a', 'b', 'c', 0 };
    const cstr = try checkedCStr(&with_zero);
    try std.testing.expectEqual(@as(usize, 3), cstr.len);
}

test "unsafe boundary pair: enum tag validation" {
    try std.testing.expectError(error.InvalidEnumTag, checkedModeFromInt(2));
    try std.testing.expectEqual(Mode.on, try checkedModeFromInt(1));
}

test "unsafe boundary pair: slice bounds" {
    const data = "hello";
    try std.testing.expectError(error.InvalidRange, checkedSubslice(data, 4, 9));
    try std.testing.expectEqualStrings("ell", try checkedSubslice(data, 1, 4));
}

test "unsafe boundary pair: overlap-aware copy" {
    var buf = [_]u8{ 1, 2, 3, 4, 5, 6 };
    try std.testing.expectError(error.Overlap, checkedCopyNoOverlap(buf[1..4], buf[0..3]));

    var dst = [_]u8{ 0, 0, 0 };
    try checkedCopyNoOverlap(dst[0..], buf[0..3]);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3 }, &dst);
}
