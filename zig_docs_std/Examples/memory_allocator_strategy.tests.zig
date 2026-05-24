// Allocator strategy examples for zig_docs/memory.md
// Run with:
//   zig test zig_docs_std/Examples/memory_allocator_strategy.tests.zig

const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

test "DebugAllocator: baseline strategy" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const status = gpa.deinit();
        std.debug.assert(status == .ok);
    }
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 64);
    defer allocator.free(bytes);
    @memset(bytes, 0xAB);

    try testing.expect(bytes.len == 64);
}

test "ArenaAllocator: phase-scoped allocations" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const a = try allocator.alloc(u8, 32);
    const b = try allocator.alloc(u8, 48);
    _ = .{ a, b };

    // No individual free calls; arena.deinit() reclaims all.
    try testing.expect(true);
}

test "FixedBufferAllocator: bounded memory and deterministic OOM" {
    var storage: [32]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&storage);
    const allocator = fba.allocator();

    const first = try allocator.alloc(u8, 24);
    _ = first;

    // Remaining space is insufficient for 16 bytes.
    const second = allocator.alloc(u8, 16);
    try testing.expectError(error.OutOfMemory, second);
}

test "page_allocator: page-backed allocation" {
    const allocator = std.heap.page_allocator;
    const buf = try allocator.alloc(u8, 256);
    defer allocator.free(buf);

    @memset(buf, 0);
    try testing.expect(buf[0] == 0);
}

test "c_allocator: use when interoperating with libc" {
    if (!builtin.link_libc) return error.SkipZigTest;

    const allocator = std.heap.c_allocator;
    const p = try allocator.create(u64);
    defer allocator.destroy(p);
    p.* = 1234;

    try testing.expectEqual(@as(u64, 1234), p.*);
}
