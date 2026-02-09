// Test file for std.debug namespace documentation examples
// Target: Zig 0.16+

const std = @import("std");

// Test 1: Basic debug printing
test "debug.print - basic usage" {
    std.debug.print("\n=== Test 1: Basic debug printing ===\n", .{});

    const x = 42;
    const name = "Alice";

    std.debug.print("User: {s}, Score: {d}\n", .{ name, x });
    std.debug.print("Hex: 0x{x:0>4}\n", .{x});
    std.debug.print("Binary: 0b{b}\n", .{x});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 2: Runtime assertions
test "debug.assert - runtime checks" {
    std.debug.print("\n=== Test 2: Runtime assertions ===\n", .{});

    const items = [_]i32{ 1, 2, 3 };
    std.debug.assert(items.len > 0);
    std.debug.assert(items.len == 3);

    std.debug.print("  Assertions passed\n", .{});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 3: Hex dump
test "debug.dumpHex - binary data inspection" {
    std.debug.print("\n=== Test 3: Hex dump ===\n", .{});

    const packet = [_]u8{
        0x00, 0x01, 0x02, 0x03,
        0xDE, 0xAD, 0xBE, 0xEF,
        0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
    };

    std.debug.print("Packet dump:\n", .{});
    std.debug.dumpHex(&packet);
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 4: Stack trace capture
test "debug.captureCurrentStackTrace - stack capture" {
    std.debug.print("\n=== Test 4: Stack trace capture ===\n", .{});

    var addrs: [32]usize = undefined;
    const trace = std.debug.captureCurrentStackTrace(.{
        .first_address = @returnAddress(),
    }, &addrs);

    std.debug.print("Captured {d} stack frames\n", .{trace.index});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 5: Source location
test "debug.SourceLocation - @src() usage" {
    std.debug.print("\n=== Test 5: Source location ===\n", .{});

    const src = @src();
    std.debug.print("Function: {s}\n", .{src.fn_name});
    std.debug.print("File: {s}\n", .{src.file});
    std.debug.print("Line: {d}, Column: {d}\n", .{ src.line, src.column });
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 6: Alignment checking
test "debug.assertAligned - pointer alignment" {
    std.debug.print("\n=== Test 6: Alignment checking ===\n", .{});

    var buffer: [64]u8 align(16) = undefined;
    std.debug.assertAligned(buffer[0..].ptr, @as(std.mem.Alignment, @enumFromInt(4)));

    std.debug.print("  16-byte alignment verified\n", .{});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 7: Formatted panic (commented out - would terminate test)
test "debug.panic - formatted panic (demo only)" {
    std.debug.print("\n=== Test 7: Formatted panic ===\n", .{});
    std.debug.print("  (Would panic with formatted message - skipped)\n", .{});
    std.debug.print("  ✅ PASS (skipped)\n\n", .{});

    // Uncomment to test (will fail the test):
    // std.debug.panic("Test panic: {s} = {d}", .{ "value", 42 });
}

// Test 8: Stack trace dumping
test "debug.dumpCurrentStackTrace - trace output" {
    std.debug.print("\n=== Test 8: Stack trace dumping ===\n", .{});
    std.debug.print("Current stack trace:\n", .{});
    std.debug.dumpCurrentStackTrace(.{});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 9: Error handling with stack traces
const TestError = error{
    InvalidInput,
    ProcessingFailed,
};

fn riskyOperation(value: i32) TestError!i32 {
    if (value < 0) return error.InvalidInput;
    if (value > 100) return error.ProcessingFailed;
    return value * 2;
}

test "debug - error handling pattern" {
    std.debug.print("\n=== Test 9: Error handling with traces ===\n", .{});

    // Test valid input
    const result1 = try riskyOperation(42);
    std.debug.print("Valid result: {d}\n", .{result1});

    // Test error case
    const result2 = riskyOperation(-5) catch |err| blk: {
        std.debug.print("Error caught: {s}\n", .{@errorName(err)});
        break :blk 0;
    };
    _ = result2;

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 10: Locked stderr for atomic output
test "debug.lockStderr - atomic output" {
    std.debug.print("\n=== Test 10: Locked stderr ===\n", .{});

    var buffer: [256]u8 = undefined;
    const locked = std.debug.lockStderr(&buffer);
    defer std.debug.unlockStderr();

    const term = locked.terminal();
    const writer = term.writer;
    writer.writeAll("  Atomic line 1\n") catch {};
    writer.writeAll("  Atomic line 2\n") catch {};
    writer.writeAll("  Atomic line 3\n") catch {};

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 11: Binary packet parsing with debug output
test "debug - binary packet inspection" {
    std.debug.print("\n=== Test 11: Binary packet parsing ===\n", .{});

    const valid = [_]u8{ 0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x02 };

    std.debug.print("Packet header:\n", .{});
    std.debug.dumpHex(valid[0..4]);

    const magic = std.mem.readInt(u32, valid[0..4], .big);
    if (magic == 0xDEADBEEF) {
        std.debug.print("  Valid magic number: 0x{x}\n", .{magic});
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 12: Valgrind detection
test "debug.inValgrind - runtime detection" {
    std.debug.print("\n=== Test 12: Valgrind detection ===\n", .{});

    if (std.debug.inValgrind()) {
        std.debug.print("  Running under Valgrind\n", .{});
    } else {
        std.debug.print("  Running natively\n", .{});
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 13: Platform capabilities
test "debug - platform capabilities" {
    std.debug.print("\n=== Test 13: Platform capabilities ===\n", .{});

    std.debug.print("  Stack traces supported: {}\n", .{std.debug.sys_can_stack_trace});
    std.debug.print("  Segfault handling: {}\n", .{std.debug.have_segfault_handling_support});

    std.debug.print("  ✅ PASS\n\n", .{});
}
