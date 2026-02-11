// Out-of-memory handling examples for zig_docs/memory.md
// Run with:
//   zig test zig_docs_std/Examples/memory_oom_handling.tests.zig

const std = @import("std");
const testing = std.testing;

fn allocPair(allocator: std.mem.Allocator) !struct { a: []u8, b: []u8 } {
    const a = try allocator.alloc(u8, 8);
    errdefer allocator.free(a);

    const b = try allocator.alloc(u8, 8);
    errdefer allocator.free(b);

    return .{ .a = a, .b = b };
}

test "std.testing.failing_allocator always returns OutOfMemory" {
    const result = std.testing.failing_allocator.alloc(u8, 1);
    try testing.expectError(error.OutOfMemory, result);
}

test "FailingAllocator can fail after N successful allocations" {
    var failing = std.testing.FailingAllocator.init(
        testing.allocator,
        .{ .fail_index = 1 },
    );
    const allocator = failing.allocator();

    const first = try allocator.alloc(u8, 8);
    defer allocator.free(first);

    const second = allocator.alloc(u8, 8);
    try testing.expectError(error.OutOfMemory, second);
    try testing.expect(failing.has_induced_failure);
}

test "errdefer cleans up partial allocations on OOM" {
    var failing = std.testing.FailingAllocator.init(
        testing.allocator,
        .{ .fail_index = 1 },
    );
    const allocator = failing.allocator();

    const result = allocPair(allocator);
    try testing.expectError(error.OutOfMemory, result);
}
