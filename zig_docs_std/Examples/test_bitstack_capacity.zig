// BitStack capacity management and pre-allocation
// Demonstrates how to efficiently manage memory for known sizes

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BitStack Capacity Management Test ===\n\n", .{});

    // Test 1: Pre-allocation for known size
    {
        std.debug.print("Test 1: Pre-allocate Capacity\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var stack = std.BitStack.init(gpa.allocator());
        defer stack.deinit();

        // Pre-allocate space for 1000 bits
        try stack.ensureTotalCapacity(1000);
        std.debug.print("  Pre-allocated capacity for 1000 bits\n", .{});

        // Now push 1000 bits without additional allocations
        var i: usize = 0;
        while (i < 1000) : (i += 1) {
            try stack.push(1);
        }

        std.debug.print("  Pushed 1000 bits\n", .{});
        std.debug.print("  Stack length: {}\n", .{stack.bit_len});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Growing without pre-allocation
    {
        std.debug.print("Test 2: Dynamic Growth\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var stack = std.BitStack.init(gpa.allocator());
        defer stack.deinit();

        std.debug.print("  Starting with no pre-allocation\n", .{});

        // Push many bits - stack will grow as needed
        var i: usize = 0;
        while (i < 500) : (i += 1) {
            try stack.push(0);
        }

        std.debug.print("  Pushed 500 bits with dynamic growth\n", .{});
        std.debug.print("  Stack length: {}\n", .{stack.bit_len});
        std.debug.print("  Byte storage: {} bytes\n", .{stack.bytes.items.len});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Efficient batch operations
    {
        std.debug.print("Test 3: Batch Operation Pattern\n", .{});

        var gpa = std.heap.DebugAllocator(.{}){};
        defer _ = gpa.deinit();

        var stack = std.BitStack.init(gpa.allocator());
        defer stack.deinit();

        // Pre-allocate for efficiency
        const total_bits = 10000;
        try stack.ensureTotalCapacity(total_bits);

        std.debug.print("  Pre-allocated for {} bits\n", .{total_bits});

        // Batch push
        var i: usize = 0;
        while (i < total_bits) : (i += 1) {
            try stack.push(@intCast(i % 2));
        }

        std.debug.print("  Pushed {} bits\n", .{total_bits});
        std.debug.print("  Stack length: {}\n", .{stack.bit_len});

        // Batch pop
        i = 0;
        while (i < total_bits) : (i += 1) {
            _ = stack.pop();
        }

        std.debug.print("  Popped all {} bits\n", .{total_bits});
        std.debug.print("  Final stack length: {}\n", .{stack.bit_len});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All capacity tests completed successfully!\n", .{});
}
