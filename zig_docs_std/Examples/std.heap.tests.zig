// Test file for std.heap documentation examples
// Run with: zig test std.heap.tests.zig

const std = @import("std");

test "Quick Start - DebugAllocator" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leak detected!");
    }
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);

    std.debug.print("✅ GPA allocated 100 bytes\n", .{});
    try std.testing.expect(bytes.len == 100);
}

test "Quick Start - ArenaAllocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const items = try allocator.alloc(i32, 1000);

    std.debug.print("✅ Arena allocated 1000 items\n", .{});
    try std.testing.expect(items.len == 1000);
}

test "Quick Start - FixedBufferAllocator" {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const data = try allocator.alloc(u8, 100);

    std.debug.print("✅ FBA allocated 100 bytes from stack\n", .{});
    try std.testing.expect(data.len == 100);
}

test "Quick Start - page_allocator" {
    const allocator = std.heap.page_allocator;
    const large_buffer = try allocator.alloc(u8, 1024 * 1024);
    defer allocator.free(large_buffer);

    std.debug.print("✅ page_allocator allocated 1 MB\n", .{});
    try std.testing.expect(large_buffer.len == 1024 * 1024);
}

// SKIPPED: c_allocator requires linking libc with -lc flag
// test "Quick Start - c_allocator" {
//     const allocator = std.heap.c_allocator;
//
//     const MyStruct = struct { value: i32 };
//     const ptr = try allocator.create(MyStruct);
//     defer allocator.destroy(ptr);
//
//     ptr.* = .{ .value = 42 };
//
//     std.debug.print("✅ c_allocator created struct with value {d}\n", .{ptr.value});
//     try std.testing.expectEqual(@as(i32, 42), ptr.value);
// }

test "Common Operations - alloc and free" {
    const allocator = std.testing.allocator;

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);

    std.debug.print("✅ alloc/free: allocated {d} bytes\n", .{bytes.len});
    try std.testing.expect(bytes.len == 100);
}

test "Common Operations - create and destroy" {
    const allocator = std.testing.allocator;

    const Node = struct { value: i32, next: ?*@This() = null };
    const node = try allocator.create(Node);
    defer allocator.destroy(node);

    node.* = .{ .value = 42 };

    std.debug.print("✅ create/destroy: node value {d}\n", .{node.value});
    try std.testing.expectEqual(@as(i32, 42), node.value);
}

test "Common Operations - realloc" {
    const allocator = std.testing.allocator;

    var bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);

    // Fill with data
    for (bytes, 0..) |*b, i| {
        b.* = @intCast(i % 256);
    }

    // Reallocate to larger size
    bytes = try allocator.realloc(bytes, 200);

    std.debug.print("✅ realloc: resized from 100 to {d} bytes\n", .{bytes.len});
    try std.testing.expect(bytes.len == 200);
    try std.testing.expectEqual(@as(u8, 0), bytes[0]);
}

test "Common Operations - dupe" {
    const allocator = std.testing.allocator;

    const original = "Hello, World!";
    const duplicated = try allocator.dupe(u8, original);
    defer allocator.free(duplicated);

    std.debug.print("✅ dupe: {s}\n", .{duplicated});
    try std.testing.expectEqualStrings(original, duplicated);
}

test "DebugAllocator - Basic Usage" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    const numbers = try allocator.alloc(i32, 10);
    defer allocator.free(numbers);

    for (numbers, 0..) |*num, i| {
        num.* = @intCast(i * 2);
    }

    std.debug.print("✅ GPA numbers: {any}\n", .{numbers});
    try std.testing.expectEqual(@as(i32, 0), numbers[0]);
    try std.testing.expectEqual(@as(i32, 18), numbers[9]);
}

test "DebugAllocator - Leak Detection" {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();

    _ = try allocator.alloc(u8, 100);
    // Intentionally not freeing to test leak detection

    const deinit_status = gpa.deinit();

    std.debug.print("✅ GPA leak detection: {s}\n", .{@tagName(deinit_status)});
    try std.testing.expect(deinit_status == .leak);
}

test "ArenaAllocator - Bulk Free" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Multiple allocations
    const user = try allocator.create(struct { name: []const u8, age: u32 });
    user.* = .{ .name = "Alice", .age = 30 };

    const name = try allocator.dupe(u8, "Bob");
    const scores = try allocator.alloc(i32, 100);

    std.debug.print("✅ Arena: user={s}, name={s}, scores.len={d}\n", .{ user.name, name, scores.len });

    // All freed by arena.deinit()
    try std.testing.expectEqualStrings("Alice", user.name);
    try std.testing.expectEqualStrings("Bob", name);
}

test "FixedBufferAllocator - Stack Memory" {
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const data = try allocator.alloc(u8, 100);
    for (data, 0..) |*d, i| {
        d.* = @intCast(i);
    }

    std.debug.print("✅ FBA: allocated {d} bytes, first={d}, last={d}\n", .{ data.len, data[0], data[99] });
    try std.testing.expectEqual(@as(u8, 0), data[0]);
    try std.testing.expectEqual(@as(u8, 99), data[99]);
}

test "FixedBufferAllocator - Reset" {
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const data1 = try allocator.alloc(u8, 100);
    std.debug.print("✅ FBA reset: allocated {d} bytes\n", .{data1.len});

    fba.reset();

    const data2 = try allocator.alloc(u8, 200);
    std.debug.print("✅ FBA reset: re-allocated {d} bytes\n", .{data2.len});

    try std.testing.expect(data2.len == 200);
}

test "page_allocator - Large Allocation" {
    const allocator = std.heap.page_allocator;

    const large_buffer = try allocator.alloc(u8, 1024 * 1024);
    defer allocator.free(large_buffer);

    std.debug.print("✅ page_allocator: allocated {d} bytes at {*}\n", .{ large_buffer.len, large_buffer.ptr });
    try std.testing.expect(large_buffer.len == 1024 * 1024);
}

// SKIPPED: c_allocator requires linking libc with -lc flag
// test "c_allocator - Basic Usage" {
//     const allocator = std.heap.c_allocator;
//
//     const buffer = try allocator.alloc(u8, 256);
//     defer allocator.free(buffer);
//
//     var list = std.ArrayList(i32).empty;
//     defer list.deinit(allocator);
//
//     try list.append(allocator, 42);
//
//     std.debug.print("✅ c_allocator: buffer.len={d}, list[0]={d}\n", .{ buffer.len, list.items[0] });
//     try std.testing.expectEqual(@as(i32, 42), list.items[0]);
// }

test "StackFallbackAllocator - Small Allocation" {
    var fallback = std.heap.stackFallback(4096, std.heap.page_allocator);
    const allocator = fallback.get();

    const small = try allocator.alloc(u8, 100);
    defer allocator.free(small);

    std.debug.print("✅ StackFallback: small allocation {d} bytes (stack)\n", .{small.len});
    try std.testing.expect(small.len == 100);
}

test "StackFallbackAllocator - Large Allocation" {
    var fallback = std.heap.stackFallback(4096, std.heap.page_allocator);
    const allocator = fallback.get();

    const large = try allocator.alloc(u8, 10000);
    defer allocator.free(large);

    std.debug.print("✅ StackFallback: large allocation {d} bytes (fallback)\n", .{large.len});
    try std.testing.expect(large.len == 10000);
}

test "MemoryPool - Object Pooling" {
    const allocator = std.heap.page_allocator;
    const Node = struct {
        value: i32,
        next: ?*@This(),
    };

    var pool = std.heap.MemoryPool(Node).empty;
    defer pool.deinit(allocator);

    const node1 = try pool.create(allocator);
    node1.* = .{ .value = 1, .next = null };

    const node2 = try pool.create(allocator);
    node2.* = .{ .value = 2, .next = node1 };

    std.debug.print("✅ MemoryPool: node2.value={d}, node1.value={d}\n", .{ node2.value, node1.value });

    try std.testing.expectEqual(@as(i32, 2), node2.value);
    try std.testing.expectEqual(@as(i32, 1), node1.value);

    pool.destroy(node2);
    pool.destroy(node1);

    std.debug.print("✅ MemoryPool: destroyed nodes\n", .{});
}

test "Usage Pattern - Standard Application Setup" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("LEAK");
    }
    const allocator = gpa.allocator();

    // Pass allocator to application
    var list = std.ArrayList([]const u8).empty;
    defer list.deinit(allocator);

    try list.append(allocator, "Hello");
    try list.append(allocator, "World");

    std.debug.print("✅ App pattern: {s} {s}\n", .{ list.items[0], list.items[1] });
    try std.testing.expectEqual(@as(usize, 2), list.items.len);
}

test "Usage Pattern - Request Handler with Arena" {
    const base_allocator = std.testing.allocator;

    // Simulate request handler
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Parse, process, format
    const parsed = try allocator.dupe(u8, "request_data");
    const response = try std.fmt.allocPrint(allocator, "Response: {s}", .{parsed});

    // Duplicate for caller (lives beyond arena)
    const final_response = try base_allocator.dupe(u8, response);
    defer base_allocator.free(final_response);

    std.debug.print("✅ Request handler: {s}\n", .{final_response});
    try std.testing.expect(std.mem.indexOf(u8, final_response, "Response") != null);
}

test "Usage Pattern - Bounded Stack-First Allocation" {
    var fallback = std.heap.stackFallback(1024, std.heap.page_allocator);
    const allocator = fallback.get();

    const input = "  command with spaces  \n";
    const trimmed = std.mem.trim(u8, input, " \t\n");
    const result = try allocator.dupe(u8, trimmed);
    defer allocator.free(result);

    std.debug.print("✅ Bounded alloc: '{s}'\n", .{result});
    try std.testing.expectEqualStrings("command with spaces", result);
}

test "Usage Pattern - Object Pool for Performance" {
    const allocator = std.heap.page_allocator;
    const Message = struct {
        id: u64,
        payload: [256]u8,
    };

    var message_pool = std.heap.MemoryPool(Message).empty;
    defer message_pool.deinit(allocator);

    const msg1 = try message_pool.create(allocator);
    msg1.* = .{ .id = 1, .payload = undefined };

    const msg2 = try message_pool.create(allocator);
    msg2.* = .{ .id = 2, .payload = undefined };

    std.debug.print("✅ Object pool: msg1.id={d}, msg2.id={d}\n", .{ msg1.id, msg2.id });

    try std.testing.expectEqual(@as(u64, 1), msg1.id);
    try std.testing.expectEqual(@as(u64, 2), msg2.id);

    message_pool.destroy(msg1);
    message_pool.destroy(msg2);
}

test "Allocator Interface - alloc" {
    const allocator = std.testing.allocator;

    const items = try allocator.alloc(i32, 10);
    defer allocator.free(items);

    std.debug.print("✅ Allocator.alloc: {d} items\n", .{items.len});
    try std.testing.expectEqual(@as(usize, 10), items.len);
}

test "Allocator Interface - create/destroy" {
    const allocator = std.testing.allocator;

    const Point = struct { x: i32, y: i32 };
    const ptr = try allocator.create(Point);
    defer allocator.destroy(ptr);

    ptr.* = .{ .x = 10, .y = 20 };

    std.debug.print("✅ Allocator.create: Point({d}, {d})\n", .{ ptr.x, ptr.y });
    try std.testing.expectEqual(@as(i32, 10), ptr.x);
}

test "Allocator Interface - dupeZ" {
    const allocator = std.testing.allocator;

    const original = "Hello";
    const duplicated = try allocator.dupeZ(u8, original);
    defer allocator.free(duplicated);

    std.debug.print("✅ Allocator.dupeZ: {s} (null-terminated)\n", .{duplicated});
    try std.testing.expectEqualStrings(original, duplicated);
    try std.testing.expectEqual(@as(u8, 0), duplicated[duplicated.len]); // Check sentinel
}

test "Performance - ArenaAllocator for Temporaries" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Many temporary allocations
    for (0..100) |i| {
        const temp = try std.fmt.allocPrint(allocator, "temp_{d}", .{i});
        _ = temp;
    }

    std.debug.print("✅ Performance: Arena handled 100 allocations\n", .{});
    // All freed in one shot by arena.deinit()
}

test "Performance - Pre-allocate Capacity" {
    const allocator = std.testing.allocator;

    var list = std.ArrayList(i32).empty;
    defer list.deinit(allocator);

    const expected_size = 1000;
    try list.ensureTotalCapacity(allocator, expected_size);

    std.debug.print("✅ Performance: pre-allocated capacity {d}\n", .{list.capacity});
    try std.testing.expect(list.capacity >= expected_size);
}

test "Error - OutOfMemory from FixedBufferAllocator" {
    var buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // This will succeed
    const small = try allocator.alloc(u8, 50);
    _ = small;

    // This will fail - not enough space
    const result = allocator.alloc(u8, 100);

    std.debug.print("✅ Error handling: caught OutOfMemory\n", .{});
    try std.testing.expectError(error.OutOfMemory, result);
}

test "Debug - Immediate defer pattern" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data); // ✅ Immediately after

    std.debug.print("✅ Debug: immediate defer prevents leaks\n", .{});
    try std.testing.expect(data.len == 100);
}

test "Page Size Constants" {
    std.debug.print("✅ page_size_min: {d} bytes\n", .{std.heap.page_size_min});
    std.debug.print("✅ page_size_max: {d} bytes\n", .{std.heap.page_size_max});
    std.debug.print("✅ pageSize(): {d} bytes\n", .{std.heap.pageSize()});

    try std.testing.expect(std.heap.page_size_min > 0);
    try std.testing.expect(std.heap.page_size_max >= std.heap.page_size_min);
}
