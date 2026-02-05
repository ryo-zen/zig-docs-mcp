// Comprehensive tests demonstrating std.mem.Alignment usage
// Shows conversion, address rounding, and comparison operations

const std = @import("std");
const Alignment = std.mem.Alignment;

test "Alignment conversion between power-of-two and byte units" {
    std.debug.print("\n🧪 Test: Alignment conversions\n", .{});

    // Power-of-two to byte units using enum values
    const a0: Alignment = @enumFromInt(0);
    try std.testing.expectEqual(1, a0.toByteUnits());

    const a1: Alignment = @enumFromInt(1);
    try std.testing.expectEqual(2, a1.toByteUnits());

    const a2: Alignment = @enumFromInt(2);
    try std.testing.expectEqual(4, a2.toByteUnits());

    const a3: Alignment = @enumFromInt(3);
    try std.testing.expectEqual(8, a3.toByteUnits());

    const a4: Alignment = @enumFromInt(4);
    try std.testing.expectEqual(16, a4.toByteUnits());

    const a6: Alignment = @enumFromInt(6);
    try std.testing.expectEqual(64, a6.toByteUnits());

    // Byte units to power-of-two
    try std.testing.expectEqual(@as(u32, 0), @intFromEnum(Alignment.fromByteUnits(1)));
    try std.testing.expectEqual(@as(u32, 2), @intFromEnum(Alignment.fromByteUnits(4)));
    try std.testing.expectEqual(@as(u32, 3), @intFromEnum(Alignment.fromByteUnits(8)));
    try std.testing.expectEqual(@as(u32, 4), @intFromEnum(Alignment.fromByteUnits(16)));

    std.debug.print("  ✅ PASS: Conversions between power-of-two and byte units work correctly\n", .{});
}

test "Alignment.of() returns correct alignment for types" {
    std.debug.print("\n🧪 Test: Alignment.of() for various types\n", .{});

    // Basic types
    const u8_align = Alignment.of(u8);
    try std.testing.expectEqual(1, u8_align.toByteUnits());

    const u32_align = Alignment.of(u32);
    try std.testing.expectEqual(4, u32_align.toByteUnits());

    const u64_align = Alignment.of(u64);
    try std.testing.expectEqual(8, u64_align.toByteUnits());

    // Struct alignment (determined by largest field)
    const MyStruct = struct {
        a: u8,
        b: u64,
        c: u16,
    };
    const struct_align = Alignment.of(MyStruct);
    // Alignment should be at least as strict as u64 (8 bytes)
    try std.testing.expect(struct_align.toByteUnits() >= 8);

    std.debug.print("  ✅ PASS: Type alignments correctly determined\n", .{});
}

test "Alignment.forward() rounds up to next aligned address" {
    std.debug.print("\n🧪 Test: Alignment.forward()\n", .{});

    const align_8: Alignment = @enumFromInt(3); // 8-byte alignment

    // Already aligned
    try std.testing.expectEqual(0x1000, align_8.forward(0x1000));
    try std.testing.expectEqual(0x1008, align_8.forward(0x1008));

    // Needs rounding up
    try std.testing.expectEqual(0x1008, align_8.forward(0x1001));
    try std.testing.expectEqual(0x1008, align_8.forward(0x1005));
    try std.testing.expectEqual(0x1008, align_8.forward(0x1007));

    // 16-byte alignment
    const align_16: Alignment = @enumFromInt(4);
    try std.testing.expectEqual(0x1010, align_16.forward(0x1001));
    try std.testing.expectEqual(0x1010, align_16.forward(0x1010));

    std.debug.print("  ✅ PASS: Addresses correctly rounded up to alignment\n", .{});
}

test "Alignment.backward() rounds down to previous aligned address" {
    std.debug.print("\n🧪 Test: Alignment.backward()\n", .{});

    const align_8: Alignment = @enumFromInt(3); // 8-byte alignment

    // Already aligned
    try std.testing.expectEqual(0x1000, align_8.backward(0x1000));
    try std.testing.expectEqual(0x1008, align_8.backward(0x1008));

    // Needs rounding down
    try std.testing.expectEqual(0x1000, align_8.backward(0x1001));
    try std.testing.expectEqual(0x1000, align_8.backward(0x1005));
    try std.testing.expectEqual(0x1000, align_8.backward(0x1007));
    try std.testing.expectEqual(0x1008, align_8.backward(0x1009));

    std.debug.print("  ✅ PASS: Addresses correctly rounded down to alignment\n", .{});
}

test "Alignment.check() validates address alignment" {
    std.debug.print("\n🧪 Test: Alignment.check()\n", .{});

    const align_4: Alignment = @enumFromInt(2); // 4-byte alignment

    // Aligned addresses
    try std.testing.expect(align_4.check(0));
    try std.testing.expect(align_4.check(4));
    try std.testing.expect(align_4.check(8));
    try std.testing.expect(align_4.check(0x1000));
    try std.testing.expect(align_4.check(0x1004));

    // Unaligned addresses
    try std.testing.expect(!align_4.check(1));
    try std.testing.expect(!align_4.check(2));
    try std.testing.expect(!align_4.check(3));
    try std.testing.expect(!align_4.check(5));
    try std.testing.expect(!align_4.check(0x1001));

    std.debug.print("  ✅ PASS: Alignment checking works correctly\n", .{});
}

test "Alignment comparison operations" {
    std.debug.print("\n🧪 Test: Alignment comparisons\n", .{});

    const align_4 = Alignment.@"4";
    const align_8 = Alignment.@"8";
    const align_16 = Alignment.@"16";

    // max() returns stricter alignment
    try std.testing.expectEqual(align_8, Alignment.max(align_4, align_8));
    try std.testing.expectEqual(align_16, Alignment.max(align_8, align_16));

    // min() returns weaker alignment
    try std.testing.expectEqual(align_4, Alignment.min(align_4, align_8));
    try std.testing.expectEqual(align_8, Alignment.min(align_8, align_16));

    // order() comparison
    try std.testing.expectEqual(std.math.Order.lt, align_4.order(align_8));
    try std.testing.expectEqual(std.math.Order.eq, align_8.order(align_8));
    try std.testing.expectEqual(std.math.Order.gt, align_16.order(align_8));

    // compare() with operators
    try std.testing.expect(align_4.compare(.lt, align_8));
    try std.testing.expect(align_8.compare(.eq, align_8));
    try std.testing.expect(align_16.compare(.gt, align_8));

    std.debug.print("  ✅ PASS: All comparison operations work correctly\n", .{});
}

test "Real-world scenario: buffer alignment for SIMD" {
    std.debug.print("\n🧪 Test: Practical alignment usage\n", .{});

    // Allocate buffer and check if it's suitable for SIMD operations
    var buffer: [64]u8 align(32) = undefined;
    const buffer_addr = @intFromPtr(&buffer);

    // Check 32-byte alignment for AVX operations
    const simd_align: Alignment = @enumFromInt(5); // 2^5 = 32 bytes
    try std.testing.expect(simd_align.check(buffer_addr));

    std.debug.print("  ✅ Buffer at 0x{x} is 32-byte aligned for SIMD\n", .{buffer_addr});

    // Find next aligned address from arbitrary pointer
    const unaligned_addr: usize = 0x1003;
    const aligned_addr = simd_align.forward(unaligned_addr);
    try std.testing.expectEqual(0x1020, aligned_addr);
    try std.testing.expect(simd_align.check(aligned_addr));

    std.debug.print("  ✅ PASS: Alignment checking useful for SIMD operations\n", .{});
}
