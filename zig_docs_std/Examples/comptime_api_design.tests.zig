const std = @import("std");

fn parsePositiveBoundedU16(comptime max_value: comptime_int, value: u16) !u16 {
    comptime {
        if (max_value <= 0 or max_value > std.math.maxInt(u16)) {
            @compileError("max_value must be between 1 and maxInt(u16)");
        }
    }

    if (value == 0 or value > max_value) return error.OutOfRange;
    return value;
}

fn sumSlice(comptime T: type, items: []const T) T {
    var total: T = 0;
    for (items) |item| total += item;
    return total;
}

fn IdFormatter(comptime with_prefix: bool) type {
    return struct {
        fn format(value: u32, out: *[32]u8) []const u8 {
            if (with_prefix) {
                return std.fmt.bufPrint(out, "id-{d}", .{value}) catch unreachable;
            }
            return std.fmt.bufPrint(out, "{d}", .{value}) catch unreachable;
        }
    };
}

test "compile-time validation guards invalid API configuration" {
    try std.testing.expectEqual(@as(u16, 5), try parsePositiveBoundedU16(10, 5));
    try std.testing.expectError(error.OutOfRange, parsePositiveBoundedU16(10, 11));
}

test "generic API remains ergonomic at callsite" {
    const ints = [_]u32{ 1, 2, 3, 4 };
    const floats = [_]f64{ 1.5, 2.5 };

    try std.testing.expectEqual(@as(u32, 10), sumSlice(u32, &ints));
    try std.testing.expect(sumSlice(f64, &floats) > 3.9);
}

test "specialization tradeoff example" {
    var prefixed_buf: [32]u8 = undefined;
    var plain_buf: [32]u8 = undefined;

    const Prefixed = IdFormatter(true);
    const Plain = IdFormatter(false);

    const prefixed = Prefixed.format(42, &prefixed_buf);
    const plain = Plain.format(42, &plain_buf);

    try std.testing.expectEqualStrings("id-42", prefixed);
    try std.testing.expectEqualStrings("42", plain);
}
