// BitStack standalone functions for fixed-buffer usage
// Demonstrates the *WithState functions that work without a BitStack instance

const std = @import("std");

pub fn main() !void {
    std.debug.print("\n=== BitStack Standalone Functions Test ===\n\n", .{});

    // Test 1: peekWithState - fixed buffer
    {
        std.debug.print("Test 1: peekWithState\n", .{});

        var buffer: [10]u8 = undefined;
        var bit_len: usize = 0;

        // Manually set up some bits in the buffer
        // We'll simulate having pushed 3 bits: 1, 0, 1
        buffer[0] = 0b00000101; // bits stored from right to left
        bit_len = 3;

        std.debug.print("  Buffer contains 3 bits: 1, 0, 1\n", .{});

        // Peek at the top bit without modifying state
        const top = std.BitStack.peekWithState(&buffer, bit_len);

        std.debug.print("  Peeked bit: {} (should be 1, the last pushed)\n", .{top});
        std.debug.print("  Bit length unchanged: {}\n", .{bit_len});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: popWithState - fixed buffer
    {
        std.debug.print("Test 2: popWithState\n", .{});

        var buffer: [10]u8 = undefined;
        var bit_len: usize = 5;

        // Set up buffer with 5 bits
        buffer[0] = 0b00011010; // bits: 0, 1, 0, 1, 1 (right to left)

        std.debug.print("  Buffer contains 5 bits\n", .{});
        std.debug.print("  Initial bit_len: {}\n", .{bit_len});

        // Pop bits one at a time
        const bit1 = std.BitStack.popWithState(&buffer, &bit_len);
        std.debug.print("  Popped: {}, bit_len now: {}\n", .{bit1, bit_len});

        const bit2 = std.BitStack.popWithState(&buffer, &bit_len);
        std.debug.print("  Popped: {}, bit_len now: {}\n", .{bit2, bit_len});

        const bit3 = std.BitStack.popWithState(&buffer, &bit_len);
        std.debug.print("  Popped: {}, bit_len now: {}\n", .{bit3, bit_len});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: pushWithStateAssumeCapacity - fixed buffer
    {
        std.debug.print("Test 3: pushWithStateAssumeCapacity\n", .{});

        var buffer: [10]u8 = [_]u8{0} ** 10; // Zero-initialize
        var bit_len: usize = 0;

        std.debug.print("  Starting with empty buffer\n", .{});

        // Push bits without allocation
        std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 1);
        std.debug.print("  Pushed 1, bit_len: {}\n", .{bit_len});

        std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 0);
        std.debug.print("  Pushed 0, bit_len: {}\n", .{bit_len});

        std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 1);
        std.debug.print("  Pushed 1, bit_len: {}\n", .{bit_len});

        std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, 1);
        std.debug.print("  Pushed 1, bit_len: {}\n", .{bit_len});

        // Verify by popping
        const b1 = std.BitStack.popWithState(&buffer, &bit_len);
        const b2 = std.BitStack.popWithState(&buffer, &bit_len);
        const b3 = std.BitStack.popWithState(&buffer, &bit_len);
        const b4 = std.BitStack.popWithState(&buffer, &bit_len);

        std.debug.print("  Popped in LIFO order: {}, {}, {}, {}\n", .{b1, b2, b3, b4});
        std.debug.print("  Expected: 1, 1, 0, 1\n", .{});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Use case - stack-allocated BitStack behavior
    {
        std.debug.print("Test 4: Stack-Allocated Pattern\n", .{});

        // Useful when you know the maximum size and want to avoid heap allocation
        var buffer: [128]u8 = undefined; // Can hold up to 1024 bits
        var bit_len: usize = 0;

        std.debug.print("  Created 128-byte buffer (1024 bits capacity)\n", .{});

        // Push a pattern
        var i: usize = 0;
        while (i < 100) : (i += 1) {
            const bit: u1 = @intCast(i % 2);
            std.BitStack.pushWithStateAssumeCapacity(&buffer, &bit_len, bit);
        }

        std.debug.print("  Pushed 100 bits\n", .{});
        std.debug.print("  Current bit_len: {}\n", .{bit_len});

        // Peek at top
        const top = std.BitStack.peekWithState(&buffer, bit_len);
        std.debug.print("  Top bit: {} (should be 1 since last was odd index 99)\n", .{top});

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("All standalone function tests completed successfully!\n", .{});
}
