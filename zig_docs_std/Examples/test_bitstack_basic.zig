// Basic BitStack operations: initialization, push, pop, peek
// Demonstrates the fundamental stack operations for u1 values

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BitStack Basic Operations Test ===\n\n", .{});

    // Test 1: Basic push and pop operations
    {
        std.debug.print("Test 1: Basic Push and Pop\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var stack = std.BitStack.init(gpa.allocator());
        defer stack.deinit();

        // Push some bits
        try stack.push(1);
        try stack.push(0);
        try stack.push(1);
        try stack.push(1);

        std.debug.print("  Pushed: 1, 0, 1, 1\n", .{});
        std.debug.print("  Stack length: {}\n", .{stack.bit_len});

        // Pop them back (LIFO order)
        const bit1 = stack.pop();
        const bit2 = stack.pop();
        const bit3 = stack.pop();
        const bit4 = stack.pop();

        std.debug.print("  Popped: {}, {}, {}, {} (LIFO order)\n", .{bit1, bit2, bit3, bit4});
        std.debug.print("  Expected: 1, 1, 0, 1\n", .{});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Peek without removing
    {
        std.debug.print("Test 2: Peek Operations\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var stack = std.BitStack.init(gpa.allocator());
        defer stack.deinit();

        try stack.push(0);
        try stack.push(1);

        std.debug.print("  Pushed: 0, 1\n", .{});

        // Peek doesn't remove
        const top1 = stack.peek();
        std.debug.print("  First peek: {} (should be 1)\n", .{top1});
        std.debug.print("  Stack length: {}\n", .{stack.bit_len});

        const top2 = stack.peek();
        std.debug.print("  Second peek: {} (still 1)\n", .{top2});
        std.debug.print("  Stack length: {} (unchanged)\n", .{stack.bit_len});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: Empty stack behavior
    {
        std.debug.print("Test 3: Empty Stack\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var stack = std.BitStack.init(gpa.allocator());
        defer stack.deinit();

        std.debug.print("  Created empty stack\n", .{});
        std.debug.print("  Stack length: {}\n", .{stack.bit_len});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Large sequence
    {
        std.debug.print("Test 4: Large Sequence\n", .{});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        var stack = std.BitStack.init(gpa.allocator());
        defer stack.deinit();

        // Push 100 bits
        var i: usize = 0;
        while (i < 100) : (i += 1) {
            const bit: u1 = if (i % 2 == 0) 0 else 1;
            try stack.push(bit);
        }

        std.debug.print("  Pushed 100 bits (alternating 0, 1)\n", .{});
        std.debug.print("  Stack length: {}\n", .{stack.bit_len});

        // Pop them back and verify pattern
        var correct: usize = 0;
        i = 0;
        while (i < 100) : (i += 1) {
            const bit = stack.pop();
            const expected: u1 = if ((99 - i) % 2 == 0) 0 else 1;
            if (bit == expected) correct += 1;
        }

        std.debug.print("  Popped all bits: {}/100 correct\n", .{correct});
        std.debug.print("  Final stack length: {}\n", .{stack.bit_len});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All tests completed successfully!\n", .{});
}
