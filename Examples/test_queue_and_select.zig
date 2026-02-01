// Test examples from TypeErasedQueue, Select, and SelectUnion documentation
const std = @import("std");

test "TypeErasedQueue - initialization" {
    var backing_buffer: [1024]u8 = undefined;
    var queue = std.Io.TypeErasedQueue.init(&backing_buffer);

    // Verify it initialized
    _ = &queue;
}

test "TypeErasedQueue - basic put and get" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var backing_buffer: [1024]u8 = undefined;
    var queue = std.Io.TypeErasedQueue.init(&backing_buffer);
    defer queue.close(io);

    // Put data
    const data = "Hello, Queue!";
    const written = try queue.put(io, data, data.len);
    try std.testing.expect(written >= data.len);

    // Get data
    var result: [128]u8 = undefined;
    const received = try queue.get(io, &result, 1);
    try std.testing.expect(received >= 1);
}

test "SelectUnion - type generation" {
    // Define struct of Future pointers
    const Futures = struct {
        task_a: *std.Io.Future(u32),
        task_b: *std.Io.Future([]const u8),
    };

    // Generate union type
    const ResultUnion = std.Io.SelectUnion(Futures);

    // Verify the union type exists and has correct fields
    const test_union: ResultUnion = .{ .task_a = 42 };
    try std.testing.expect(test_union.task_a == 42);
}

test "Select - result union types" {
    // Define a simple result union
    const Result = union(enum) {
        operation_a: u32,
        operation_b: []const u8,
    };

    // Verify union values work
    const result_a: Result = .{ .operation_a = 123 };
    try std.testing.expect(result_a.operation_a == 123);

    const result_b: Result = .{ .operation_b = "test" };
    try std.testing.expectEqualStrings("test", result_b.operation_b);
}

test "Select - init" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const Result = union(enum) {
        task: u32,
    };

    var buffer: [4]Result = undefined;
    var select_obj = std.Io.Select(Result).init(io, &buffer);

    // Verify it initialized
    _ = &select_obj;
}
