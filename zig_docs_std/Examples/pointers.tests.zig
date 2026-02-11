// Core pointer examples for zig_docs/pointers.md
// Run with:
//   zig test zig_docs_std/Examples/pointers.tests.zig

const std = @import("std");
const testing = std.testing;

test "single-item pointers via address-of" {
    const x: i32 = 1234;
    const x_ptr = &x;
    try testing.expect(@TypeOf(x_ptr) == *const i32);
    try testing.expect(x_ptr.* == 1234);

    var y: i32 = 5678;
    const y_ptr = &y;
    y_ptr.* += 1;
    try testing.expect(@TypeOf(y_ptr) == *i32);
    try testing.expect(y == 5679);
}

test "single-item to array pointer to many-item conversion" {
    var x: i32 = 1234;
    const x_ptr = &x;
    const x_array_ptr = x_ptr[0..1];
    const x_many_ptr: [*]i32 = x_array_ptr;

    try testing.expect(@TypeOf(x_array_ptr) == *[1]i32);
    try testing.expect(x_many_ptr[0] == 1234);
}

test "many-item pointer arithmetic" {
    const array = [_]i32{ 1, 2, 3, 4 };
    var ptr: [*]const i32 = &array;

    try testing.expect(ptr[0] == 1);
    ptr += 1;
    try testing.expect(ptr[0] == 2);
    try testing.expect(ptr[1..] == ptr + 1);
    try testing.expect(&ptr[1] - &ptr[0] == 1);
}

test "slice bounds are explicit and stable" {
    var array = [_]u8{ 1, 2, 3, 4, 5 };
    var start: usize = 1;
    _ = &start;
    const slice = array[start..4];

    try testing.expectEqual(@as(usize, 3), slice.len);
    try testing.expectEqual(@as(u8, 2), slice[0]);
}

test "pointer-int conversion without dereference" {
    const addr: usize = 0xdeadbee0;
    const ptr: *i32 = @ptrFromInt(addr);
    try testing.expect(@intFromPtr(ptr) == addr);
}

test "pointer cast with alignment guarantees" {
    const bytes align(@alignOf(u32)) = [_]u8{ 0x12, 0x12, 0x12, 0x12 };

    const u32_ptr: *const u32 = @ptrCast(&bytes);
    try testing.expect(u32_ptr.* == 0x12121212);

    const via_slice = std.mem.bytesAsSlice(u32, bytes[0..])[0];
    try testing.expect(via_slice == 0x12121212);
}

test "volatile pointer type for MMIO-style access" {
    const mmio_ptr: *volatile u8 = @ptrFromInt(0x12345678);
    try testing.expect(@TypeOf(mmio_ptr) == *volatile u8);
}

test "allowzero pointer can represent address zero" {
    var zero: usize = 0;
    _ = &zero;
    const ptr: *allowzero i32 = @ptrFromInt(zero);
    try testing.expect(@intFromPtr(ptr) == 0);
}

test "sentinel-terminated pointer from string literal" {
    const msg: [*:0]const u8 = "Hello";
    try testing.expect(msg[0] == 'H');
}
