const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Example: Using custom alignment for SIMD operations
    // 16-byte alignment is common for SSE/NEON vector operations
    const Vec4f = @Vector(4, f32);

    // Create a 16-byte aligned ArrayList
    var list: std.ArrayList(Vec4f) = .empty;
    defer list.deinit(allocator);

    // Add some vectors
    try list.append(allocator, Vec4f{ 1.0, 2.0, 3.0, 4.0 });
    try list.append(allocator, Vec4f{ 5.0, 6.0, 7.0, 8.0 });
    try list.append(allocator, Vec4f{ 9.0, 10.0, 11.0, 12.0 });

    std.debug.print("Stored {} vectors\n", .{list.items.len});

    // Process vectors (SIMD-friendly)
    for (list.items, 0..) |vec, i| {
        const sum = @reduce(.Add, vec);
        std.debug.print("Vector {}: sum = {d:.1}\n", .{ i, sum });
    }

    // Demonstrate alignment
    const ptr = @intFromPtr(list.items.ptr);
    const alignment = @alignOf(Vec4f);
    std.debug.print("Address: 0x{x}, Alignment: {} bytes\n", .{ ptr, alignment });
    std.debug.print("Is aligned: {}\n", .{ptr % alignment == 0});
}
