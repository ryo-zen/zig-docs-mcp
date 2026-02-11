// Ownership contract examples for zig_docs/memory.md
// Run with:
//   zig test zig_docs_std/Examples/memory_ownership_contract.tests.zig

const std = @import("std");
const testing = std.testing;

fn transform(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const out = try allocator.alloc(u8, input.len);
    errdefer allocator.free(out);

    @memcpy(out, input);
    for (out) |*c| c.* = std.ascii.toUpper(c.*);
    return out;
}

const Entry = struct { v: i32 };

const Config = struct {
    entries: []Entry,

    fn init(allocator: std.mem.Allocator, count: usize) !Config {
        const entries = try allocator.alloc(Entry, count);
        for (entries, 0..) |*e, i| e.* = .{ .v = @intCast(i) };
        return .{ .entries = entries };
    }

    fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.entries);
        self.entries = &.{};
    }
};

test "caller owns returned memory from transform" {
    const allocator = testing.allocator;

    const out = try transform(allocator, "hello");
    defer allocator.free(out);

    try testing.expectEqualStrings("HELLO", out);
}

test "ownership is not transferred on OOM failure" {
    var failing = std.testing.FailingAllocator.init(
        testing.allocator,
        .{ .fail_index = 0 },
    );
    const allocator = failing.allocator();

    const result = transform(allocator, "hello");
    try testing.expectError(error.OutOfMemory, result);
}

test "struct deinit contract frees owned allocations" {
    const allocator = testing.allocator;

    var cfg = try Config.init(allocator, 3);
    defer cfg.deinit(allocator);

    try testing.expectEqual(@as(usize, 3), cfg.entries.len);
    try testing.expectEqual(@as(i32, 2), cfg.entries[2].v);
}
