// Comprehensive tests for zig_docs/defer.md examples.
// Run with:
//   zig test zig_docs_std/Examples/defer.tests.zig

const std = @import("std");
const testing = std.testing;

fn deferExample() !usize {
    var a: usize = 1;

    {
        defer a = 2;
        a = 1;
    }
    try testing.expectEqual(2, a);

    a = 5;
    return a;
}

test "defer executes at scope exit" {
    try testing.expectEqual(5, try deferExample());
}

test "defer expressions run in reverse order" {
    var log = [_]u8{0} ** 2;
    var len: usize = 0;

    {
        defer {
            log[len] = '1';
            len += 1;
        }
        defer {
            log[len] = '2';
            len += 1;
        }
    }

    try testing.expectEqualStrings("21", log[0..len]);
}

test "defer is not run if the defer statement is never executed" {
    var ran = false;
    var execute_branch = false;
    _ = &execute_branch;

    {
        if (execute_branch) {
            defer ran = true;
        }
    }

    try testing.expect(!ran);
}

test "defer executes on early return" {
    var ran = false;
    const value = returnEarly(&ran);

    try testing.expectEqual(42, value);
    try testing.expect(ran);
}

fn returnEarly(ran: *bool) u8 {
    defer ran.* = true;
    return 42;
}

test "defer executes when breaking out of a block" {
    var cleaned_up = false;

    const value = blk: {
        defer cleaned_up = true;
        break :blk @as(u8, 7);
    };

    try testing.expectEqual(7, value);
    try testing.expect(cleaned_up);
}
