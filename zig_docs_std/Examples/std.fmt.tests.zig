// Test file for std.fmt documentation examples
// Run with: zig test std.fmt.tests.zig

const std = @import("std");

test "Quick Start - Stack-Allocated Formatting" {
    var buffer: [1024]u8 = undefined;
    const result = try std.fmt.bufPrint(&buffer, "Hello, {s}! You have {} messages.", .{ "Alice", 42 });
    std.debug.print("\n✅ Stack formatting: {s}\n", .{result});
    try std.testing.expect(result.len > 0);
}

test "Quick Start - Heap-Allocated Formatting" {
    const allocator = std.testing.allocator;
    const message = try std.fmt.allocPrint(allocator, "User: {s}, Score: {d}", .{ "Bob", 9001 });
    defer allocator.free(message);
    std.debug.print("✅ Heap formatting: {s}\n", .{message});
    try std.testing.expect(message.len > 0);
}

test "Quick Start - Parsing Integers" {
    const num = try std.fmt.parseInt(i32, "42", 10); // Decimal
    const hex_num = try std.fmt.parseInt(u32, "FF", 16); // Hexadecimal
    const bin_num = try std.fmt.parseInt(u8, "1010", 2); // Binary

    std.debug.print("✅ parseInt decimal: {d}\n", .{num});
    std.debug.print("✅ parseInt hex: {d}\n", .{hex_num});
    std.debug.print("✅ parseInt binary: {d}\n", .{bin_num});

    try std.testing.expectEqual(@as(i32, 42), num);
    try std.testing.expectEqual(@as(u32, 255), hex_num);
    try std.testing.expectEqual(@as(u8, 10), bin_num);
}

test "Quick Start - Parsing Floats" {
    const pi = try std.fmt.parseFloat(f64, "3.14159");
    const sci = try std.fmt.parseFloat(f32, "1.5e-10");

    std.debug.print("✅ parseFloat pi: {d}\n", .{pi});
    std.debug.print("✅ parseFloat scientific: {e}\n", .{sci});

    try std.testing.expect(pi > 3.14 and pi < 3.15);
    try std.testing.expect(sci > 0.0 and sci < 1.0e-9);
}

test "Quick Start - Hex Encoding/Decoding" {
    const bytes = "Hello";
    const hex = std.fmt.bytesToHex(bytes, .lower);

    std.debug.print("✅ bytesToHex: {s}\n", .{hex});

    var decode_buf: [5]u8 = undefined;
    const decoded = try std.fmt.hexToBytes(&decode_buf, "48656c6c6f");

    std.debug.print("✅ hexToBytes: {s}\n", .{decoded});
    try std.testing.expectEqualStrings("Hello", decoded);
}

test "Format Specifiers - String Slice" {
    var buf: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "Name: {s}", .{"Alice"});
    std.debug.print("✅ {{s}} specifier: {s}\n", .{result});
    try std.testing.expectEqualStrings("Name: Alice", result);
}

test "Format Specifiers - Decimal Integer" {
    var buf1: [100]u8 = undefined;
    const result1 = try std.fmt.bufPrint(&buf1, "Count: {d}", .{42});
    std.debug.print("✅ {{d}} specifier: {s}\n", .{result1});
    try std.testing.expectEqualStrings("Count: 42", result1);

    var buf2: [100]u8 = undefined;
    const result2 = try std.fmt.bufPrint(&buf2, "Neg: {d}", .{-100});
    std.debug.print("✅ {{d}} negative: {s}\n", .{result2});
    try std.testing.expectEqualStrings("Neg: -100", result2);
}

test "Format Specifiers - Hexadecimal" {
    var buf1: [100]u8 = undefined;
    const result1 = try std.fmt.bufPrint(&buf1, "Hex: {x}", .{255});
    std.debug.print("✅ {{x}} lowercase: {s}\n", .{result1});
    try std.testing.expectEqualStrings("Hex: ff", result1);

    var buf2: [100]u8 = undefined;
    const result2 = try std.fmt.bufPrint(&buf2, "HEX: {X}", .{255});
    std.debug.print("✅ {{X}} uppercase: {s}\n", .{result2});
    try std.testing.expectEqualStrings("HEX: FF", result2);
}

test "Format Specifiers - Binary" {
    var buf: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "Binary: {b}", .{5});
    std.debug.print("✅ {{b}} specifier: {s}\n", .{result});
    try std.testing.expectEqualStrings("Binary: 101", result);
}

test "Format Specifiers - Octal" {
    var buf: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "Octal: {o}", .{8});
    std.debug.print("✅ {{o}} specifier: {s}\n", .{result});
    try std.testing.expectEqualStrings("Octal: 10", result);
}

test "Format Specifiers - Character" {
    var buf: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "Char: {c}", .{65});
    std.debug.print("✅ {{c}} specifier: {s}\n", .{result});
    try std.testing.expectEqualStrings("Char: A", result);
}

test "Format Specifiers - Scientific Notation" {
    var buf: [100]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "Sci: {e}", .{1500.0});
    std.debug.print("✅ {{e}} specifier: {s}\n", .{result});
    // Scientific notation format (may be "e+" or just "e" depending on Zig version)
    try std.testing.expect(std.mem.indexOf(u8, result, "e") != null or std.mem.indexOf(u8, result, "E") != null);
}

test "Format Specifiers - Default Format" {
    var buf: [100]u8 = undefined;
    const result1 = try std.fmt.bufPrint(&buf, "Value: {}", .{42});
    const result2 = try std.fmt.bufPrint(&buf, "Float: {}", .{3.14});

    std.debug.print("✅ {{}} int: {s}\n", .{result1});
    std.debug.print("✅ {{}} float: {s}\n", .{result2});

    try std.testing.expect(result1.len > 0);
    try std.testing.expect(result2.len > 0);
}

test "Format Specifiers - Debug Format" {
    const Point = struct { x: i32, y: i32 };
    const p = Point{ .x = 10, .y = 20 };

    var buf: [200]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "Point: {any}", .{p});
    std.debug.print("✅ {{any}} specifier: {s}\n", .{result});
    try std.testing.expect(std.mem.indexOf(u8, result, "10") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "20") != null);
}

test "Format Options - Width and Padding" {
    var buf: [100]u8 = undefined;
    const result1 = try std.fmt.bufPrint(&buf, "|{d:5}|", .{42});
    const result2 = try std.fmt.bufPrint(&buf, "|{s:10}|", .{"hi"});

    std.debug.print("✅ Width padding int: {s}\n", .{result1});
    std.debug.print("✅ Width padding str: {s}\n", .{result2});

    try std.testing.expectEqual(@as(usize, 7), result1.len); // | + 5 chars + |
    try std.testing.expectEqual(@as(usize, 12), result2.len); // | + 10 chars + |
}

test "Format Options - Precision for Floats" {
    var buf: [100]u8 = undefined;
    const result1 = try std.fmt.bufPrint(&buf, "{d:.2}", .{3.14159});
    const result2 = try std.fmt.bufPrint(&buf, "{d:.4}", .{2.5});

    std.debug.print("✅ Precision .2: {s}\n", .{result1});
    std.debug.print("✅ Precision .4: {s}\n", .{result2});

    try std.testing.expect(result1.len > 0);
    try std.testing.expect(result2.len > 0);
}

test "bufPrint Function" {
    var buffer: [100]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buffer, "User {s} has {d} points", .{ "Alice", 42 });

    std.debug.print("✅ bufPrint: {s}\n", .{msg});
    std.debug.print("  Length: {d} bytes\n", .{msg.len});

    try std.testing.expect(std.mem.indexOf(u8, msg, "Alice") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "42") != null);
}

test "allocPrint Function" {
    const allocator = std.testing.allocator;
    const msg = try std.fmt.allocPrint(allocator, "Dynamic: {s} = {d}", .{ "answer", 42 });
    defer allocator.free(msg);

    std.debug.print("✅ allocPrint: {s}\n", .{msg});

    try std.testing.expect(std.mem.indexOf(u8, msg, "answer") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "42") != null);
}

test "comptimePrint Function" {
    const version = std.fmt.comptimePrint("v{d}.{d}.{d}", .{ 1, 2, 3 });
    std.debug.print("✅ comptimePrint: {s}\n", .{version});
    try std.testing.expectEqualStrings("v1.2.3", version);
}

test "count Function" {
    const needed = comptime std.fmt.count("Value: {d}", .{12345});
    std.debug.print("✅ count: {d} bytes needed\n", .{needed});

    var buffer: [needed]u8 = undefined;
    const result = std.fmt.bufPrint(&buffer, "Value: {d}", .{12345}) catch unreachable;

    std.debug.print("  Result: {s}\n", .{result});
    try std.testing.expectEqual(needed, result.len);
}

test "parseInt Function - Multiple Bases" {
    const dec = try std.fmt.parseInt(i32, "42", 10);
    std.debug.print("✅ parseInt decimal: {d}\n", .{dec});
    try std.testing.expectEqual(@as(i32, 42), dec);

    const hex = try std.fmt.parseInt(u32, "DEADBEEF", 16);
    std.debug.print("✅ parseInt hex: 0x{X}\n", .{hex});
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), hex);

    const bin = try std.fmt.parseInt(u8, "11010", 2);
    std.debug.print("✅ parseInt binary: {d}\n", .{bin});
    try std.testing.expectEqual(@as(u8, 26), bin);

    const neg = try std.fmt.parseInt(i32, "-123", 10);
    std.debug.print("✅ parseInt negative: {d}\n", .{neg});
    try std.testing.expectEqual(@as(i32, -123), neg);
}

test "parseUnsigned Function" {
    const val = try std.fmt.parseUnsigned(u32, "12345", 10);
    std.debug.print("✅ parseUnsigned: {d}\n", .{val});
    try std.testing.expectEqual(@as(u32, 12345), val);

    const bad = std.fmt.parseUnsigned(u32, "-100", 10);
    std.debug.print("✅ parseUnsigned rejects negative\n", .{});
    try std.testing.expectError(error.InvalidCharacter, bad);
}

test "parseFloat Function" {
    const pi = try std.fmt.parseFloat(f64, "3.14159");
    std.debug.print("✅ parseFloat pi: {d}\n", .{pi});
    try std.testing.expect(pi > 3.14 and pi < 3.15);

    const sci = try std.fmt.parseFloat(f32, "6.022e23");
    std.debug.print("✅ parseFloat scientific: {e}\n", .{sci});
    try std.testing.expect(sci > 6.0e23 and sci < 6.1e23);

    const inf = try std.fmt.parseFloat(f64, "inf");
    std.debug.print("✅ parseFloat infinity: {d}\n", .{inf});
    try std.testing.expect(std.math.isInf(inf));
}

test "bytesToHex Function" {
    const bytes = "Hi";
    const hex_lower = std.fmt.bytesToHex(bytes, .lower);
    const hex_upper = std.fmt.bytesToHex(bytes, .upper);

    std.debug.print("✅ bytesToHex lower: {s}\n", .{hex_lower});
    std.debug.print("✅ bytesToHex upper: {s}\n", .{hex_upper});

    try std.testing.expectEqualStrings("4869", &hex_lower);
    try std.testing.expectEqualStrings("4869", &hex_upper);
}

test "hexToBytes Function" {
    var buffer: [10]u8 = undefined;
    const decoded = try std.fmt.hexToBytes(&buffer, "48656C6C6F");
    std.debug.print("✅ hexToBytes: {s}\n", .{decoded});
    try std.testing.expectEqualStrings("Hello", decoded);
}

test "charToDigit Function" {
    const val = try std.fmt.charToDigit('F', 16);
    const dec = try std.fmt.charToDigit('7', 10);

    std.debug.print("✅ charToDigit 'F' base 16: {d}\n", .{val});
    std.debug.print("✅ charToDigit '7' base 10: {d}\n", .{dec});

    try std.testing.expectEqual(@as(u8, 15), val);
    try std.testing.expectEqual(@as(u8, 7), dec);
}

test "digitToChar Function" {
    const c = std.fmt.digitToChar(15, .lower);
    const C = std.fmt.digitToChar(15, .upper);

    std.debug.print("✅ digitToChar 15 lower: {c}\n", .{c});
    std.debug.print("✅ digitToChar 15 upper: {c}\n", .{C});

    try std.testing.expectEqual(@as(u8, 'f'), c);
    try std.testing.expectEqual(@as(u8, 'F'), C);
}

test "Usage Pattern - Command-Line Argument Parsing" {
    // Simulating command-line args
    const fake_args = [_][]const u8{ "program", "123" };

    if (fake_args.len < 2) {
        return error.NotEnoughArgs;
    }

    const num = try std.fmt.parseInt(i32, fake_args[1], 10);
    std.debug.print("✅ CLI parsing: {d}\n", .{num});
    std.debug.print("  Doubled: {d}\n", .{num * 2});

    try std.testing.expectEqual(@as(i32, 123), num);
}

test "Usage Pattern - Building Formatted Strings" {
    const allocator = std.testing.allocator;

    const name = "Alice";
    const score = 95;
    const grade = 'A';

    const report = try std.fmt.allocPrint(allocator,
        \\--- Student Report ---
        \\Name:  {s}
        \\Score: {d}
        \\Grade: {c}
        \\Status: {s}
    , .{ name, score, grade, if (score >= 90) "Excellent" else "Good" });
    defer allocator.free(report);

    std.debug.print("✅ Multi-line report:\n{s}\n", .{report});

    try std.testing.expect(std.mem.indexOf(u8, report, "Alice") != null);
    try std.testing.expect(std.mem.indexOf(u8, report, "95") != null);
    try std.testing.expect(std.mem.indexOf(u8, report, "Excellent") != null);
}

test "Usage Pattern - Safe Buffer Formatting" {
    var buf: [100]u8 = undefined;

    const name = "TestUser";
    const value: i32 = 42;

    const needed = std.fmt.count("Name: {s}, Value: {d}", .{ name, value });
    std.debug.print("✅ Safe formatting - needed: {d} bytes\n", .{needed});

    if (needed > buf.len) {
        return error.BufferTooSmall;
    }

    const result = try std.fmt.bufPrint(&buf, "Name: {s}, Value: {d}", .{ name, value });
    std.debug.print("  Result: {s}\n", .{result});

    try std.testing.expectEqual(needed, result.len);
}

test "Buffer Size Error Handling" {
    var tiny: [5]u8 = undefined;
    const result = std.fmt.bufPrint(&tiny, "Hello, World!", .{});

    std.debug.print("✅ Small buffer returns NoSpaceLeft\n", .{});
    try std.testing.expectError(error.NoSpaceLeft, result);
}

test "parseInt Overflow Handling" {
    const result = std.fmt.parseInt(u8, "999", 10);

    std.debug.print("✅ parseInt overflow detection\n", .{});
    try std.testing.expectError(error.Overflow, result);
}

test "Performance - Buffer Reuse" {
    var buffer: [1024]u8 = undefined;

    // Simulating multiple format operations with buffer reuse
    for (0..5) |i| {
        const msg = try std.fmt.bufPrint(&buffer, "Item: {d}", .{i});
        std.debug.print("✅ Reused buffer [{d}]: {s}\n", .{ i, msg });
        try std.testing.expect(msg.len > 0);
    }
}

test "Performance - comptimePrint Zero Cost" {
    const version = std.fmt.comptimePrint("v{d}.{d}", .{ 1, 0 });
    std.debug.print("✅ comptimePrint (compile-time constant): {s}\n", .{version});
    try std.testing.expectEqualStrings("v1.0", version);
}
