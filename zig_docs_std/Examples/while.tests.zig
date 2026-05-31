// Comprehensive tests for zig_docs/while.md examples.
// Run with:
//   zig test zig_docs_std/Examples/while.tests.zig

const std = @import("std");
const testing = std.testing;

test "while basic" {
    var i: usize = 0;
    while (i < 10) {
        i += 1;
    }
    try testing.expectEqual(10, i);
}

test "while break" {
    var i: usize = 0;
    while (true) {
        if (i == 10)
            break;
        i += 1;
    }
    try testing.expectEqual(10, i);
}

test "while continue" {
    var i: usize = 0;
    while (true) {
        i += 1;
        if (i < 10)
            continue;
        break;
    }
    try testing.expectEqual(10, i);
}

test "while loop continue expression" {
    var i: usize = 0;
    while (i < 10) : (i += 1) {}
    try testing.expectEqual(10, i);
}

test "while loop continue expression, more complicated" {
    var i: usize = 1;
    var j: usize = 1;
    while (i * j < 2000) : ({
        i *= 2;
        j *= 3;
    }) {
        const my_ij = i * j;
        try testing.expect(my_ij < 2000);
    }
}

test "while else" {
    try testing.expect(rangeHasNumber(0, 10, 5));
    try testing.expect(!rangeHasNumber(0, 10, 15));
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "nested break and continue" {
    outer_break: while (true) {
        while (true) {
            break :outer_break;
        }
    }

    var i: usize = 0;
    outer_continue: while (i < 10) : (i += 1) {
        while (true) {
            continue :outer_continue;
        }
    }
    try testing.expectEqual(10, i);
}

test "while null capture" {
    var state = OptionalSequence{ .numbers_left = 3 };
    var sum1: u32 = 0;
    while (state.next()) |value| {
        sum1 += value;
    }
    try testing.expectEqual(3, sum1);

    state = .{ .numbers_left = 3 };
    var sum2: u32 = 0;
    while (state.next()) |value| {
        sum2 += value;
    } else {
        try testing.expectEqual(3, sum2);
    }

    state = .{ .numbers_left = 3 };
    var count: u32 = 0;
    var sum3: u32 = 0;
    while (state.next()) |value| : (count += 1) {
        sum3 += value;
    }
    try testing.expectEqual(3, count);
    try testing.expectEqual(3, sum3);
}

const OptionalSequence = struct {
    numbers_left: u32,

    fn next(self: *OptionalSequence) ?u32 {
        return if (self.numbers_left == 0) null else blk: {
            self.numbers_left -= 1;
            break :blk self.numbers_left;
        };
    }
};

test "while error union capture" {
    var state = ErrorSequence{ .numbers_left = 3 };
    var sum1: u32 = 0;
    while (state.next()) |value| {
        sum1 += value;
    } else |err| {
        try testing.expectEqual(error.ReachedZero, err);
    }
    try testing.expectEqual(3, sum1);
}

const ErrorSequence = struct {
    numbers_left: u32,

    fn next(self: *ErrorSequence) anyerror!u32 {
        return if (self.numbers_left == 0) error.ReachedZero else blk: {
            self.numbers_left -= 1;
            break :blk self.numbers_left;
        };
    }
};

test "inline while loop" {
    comptime var i = 0;
    var sum: usize = 0;
    inline while (i < 3) : (i += 1) {
        const T = switch (i) {
            0 => f32,
            1 => i8,
            2 => bool,
            else => unreachable,
        };
        sum += typeNameLength(T);
    }
    try testing.expectEqual(9, sum);
}

fn typeNameLength(comptime T: type) usize {
    return @typeName(T).len;
}
