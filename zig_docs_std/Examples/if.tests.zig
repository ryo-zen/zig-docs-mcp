// Comprehensive tests for zig_docs/if.md examples.
// Run with:
//   zig test zig_docs_std/Examples/if.tests.zig

const std = @import("std");
const testing = std.testing;

test "if expression" {
    const a: u32 = 5;
    const b: u32 = 4;
    const result = if (a != b) 47 else 3089;
    try testing.expectEqual(result, 47);
}

test "if boolean" {
    const a: u32 = 5;
    const b: u32 = 4;
    if (a != b) {
        try testing.expect(true);
    } else if (a == 9) {
        unreachable;
    } else {
        unreachable;
    }
}

test "if error union" {
    const a: anyerror!u32 = 0;
    if (a) |value| {
        try testing.expectEqual(value, 0);
    } else |err| {
        _ = err;
        unreachable;
    }

    const b: anyerror!u32 = error.BadValue;
    if (b) |value| {
        _ = value;
        unreachable;
    } else |err| {
        try testing.expectEqual(err, error.BadValue);
    }

    if (a) |value| {
        try testing.expectEqual(value, 0);
    } else |_| {}

    if (b) |_| {} else |err| {
        try testing.expectEqual(err, error.BadValue);
    }

    var c: anyerror!u32 = 3;
    if (c) |*value| {
        value.* = 9;
    } else |_| {
        unreachable;
    }

    if (c) |value| {
        try testing.expectEqual(value, 9);
    } else |_| {
        unreachable;
    }
}

test "if optional" {
    const a: ?u32 = 0;
    if (a) |value| {
        try testing.expectEqual(0, value);
    } else {
        unreachable;
    }

    const b: ?u32 = null;
    if (b) |_| {
        unreachable;
    } else {
        try testing.expect(true);
    }

    if (a) |value| {
        try testing.expectEqual(0, value);
    }

    if (b == null) {
        try testing.expect(true);
    }

    var c: ?u32 = 3;
    if (c) |*value| {
        value.* = 2;
    }

    if (c) |value| {
        try testing.expectEqual(2, value);
    } else {
        unreachable;
    }
}

test "if error union with optional" {
    const a: anyerror!?u32 = 0;
    if (a) |optional_value| {
        try testing.expectEqual(0, optional_value.?);
    } else |err| {
        _ = err;
        unreachable;
    }

    const b: anyerror!?u32 = null;
    if (b) |optional_value| {
        try testing.expectEqual(null, optional_value);
    } else |_| {
        unreachable;
    }

    const c: anyerror!?u32 = error.BadValue;
    if (c) |optional_value| {
        _ = optional_value;
        unreachable;
    } else |err| {
        try testing.expectEqual(error.BadValue, err);
    }

    var d: anyerror!?u32 = 3;
    if (d) |*optional_value| {
        if (optional_value.*) |*value| {
            value.* = 9;
        }
    } else |_| {
        unreachable;
    }

    if (d) |optional_value| {
        try testing.expectEqual(9, optional_value.?);
    } else |_| {
        unreachable;
    }
}
