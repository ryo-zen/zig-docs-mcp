// Regression coverage for zig_docs/errors.md and zig_docs/optionals.md.
// Run with:
//   zig test zig_docs_std/Examples/errors_optionals_language.tests.zig

const std = @import("std");
const testing = std.testing;
const maxInt = std.math.maxInt;

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error{
    OutOfMemory,
};

fn widenError(err: AllocationError) FileOpenError {
    return err;
}

pub fn parseU64(buf: []const u8, radix: u8) !u64 {
    var x: u64 = 0;

    for (buf) |c| {
        const digit = charToDigit(c);

        if (digit >= radix) {
            return error.InvalidChar;
        }

        var ov = @mulWithOverflow(x, radix);
        if (ov[1] != 0) return error.OverFlow;

        ov = @addWithOverflow(ov[0], digit);
        if (ov[1] != 0) return error.OverFlow;
        x = ov[0];
    }

    return x;
}

fn charToDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'A'...'Z' => c - 'A' + 10,
        'a'...'z' => c - 'a' + 10,
        else => maxInt(u8),
    };
}

fn doSomethingWithNumber(number: u64) void {
    _ = number;
}

fn handleAllParseErrors(str: []const u8) void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |err| switch (err) {
        error.OverFlow => {},
        error.InvalidChar => {},
    }
}

fn handleSomeParseErrors(str: []const u8) error{InvalidChar}!void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |err| switch (err) {
        error.OverFlow => {},
        else => |leftover_err| return leftover_err,
    }
}

fn captureError(captured: *?anyerror) !void {
    errdefer |err| {
        captured.* = err;
    }
    return error.GeneralFailure;
}

const A = error{
    NotDir,
    PathNotFound,
};

const B = error{
    OutOfMemory,
    PathNotFound,
};

const C = A || B;

fn mergedErrorSetExample() C!void {
    return error.NotDir;
}

pub fn addInferred(comptime T: type, a: T, b: T) !T {
    const ov = @addWithOverflow(a, b);
    if (ov[1] != 0) return error.Overflow;
    return ov[0];
}

const AddError = error{
    Overflow,
};

pub fn addExplicit(comptime T: type, a: T, b: T) AddError!T {
    const ov = @addWithOverflow(a, b);
    if (ov[1] != 0) return error.Overflow;
    return ov[0];
}

const Foo = struct {
    value: i32,
};

fn doSomethingWithFoo(foo: *Foo) void {
    foo.value += 1;
}

fn useOptionalFoo(optional_foo: ?*Foo) i32 {
    if (optional_foo) |foo| {
        doSomethingWithFoo(foo);
        return foo.value;
    }

    return 0;
}

test "error set subset coerces to superset" {
    const err = widenError(AllocationError.OutOfMemory);
    try testing.expectEqual(FileOpenError.OutOfMemory, err);
}

test "error union parser examples handle declared errors" {
    try testing.expectEqual(@as(u64, 1234), try parseU64("1234", 10));
    try testing.expectError(error.InvalidChar, parseU64("nope", 10));
    try testing.expectError(error.OverFlow, parseU64("18446744073709551616", 10));

    handleAllParseErrors("18446744073709551616");
    try testing.expectError(error.InvalidChar, handleSomeParseErrors("nope"));
}

test "errdefer captures the returned error" {
    var captured: ?anyerror = null;

    if (captureError(&captured)) unreachable else |err| {
        try testing.expectEqual(error.GeneralFailure, captured.?);
        try testing.expectEqual(error.GeneralFailure, err);
    }
}

test "error union reflection and merged error set examples" {
    var foo: anyerror!i32 = undefined;
    foo = 1234;
    foo = error.SomeError;

    try comptime testing.expectEqual(i32, @typeInfo(@TypeOf(foo)).error_union.payload);
    try comptime testing.expectEqual(anyerror, @typeInfo(@TypeOf(foo)).error_union.error_set);

    if (mergedErrorSetExample()) {
        @panic("unexpected");
    } else |err| switch (err) {
        error.OutOfMemory => @panic("unexpected"),
        error.PathNotFound => @panic("unexpected"),
        error.NotDir => {},
    }
}

test "inferred and explicit error set examples" {
    if (addInferred(u8, 255, 1)) |_| unreachable else |err| switch (err) {
        error.Overflow => {},
    }

    try testing.expectError(error.Overflow, addExplicit(u8, 255, 1));
}

test "optional type reflection and pointer unwrapping examples" {
    var foo: ?i32 = null;
    foo = 1234;
    try comptime testing.expectEqual(i32, @typeInfo(@TypeOf(foo)).optional.child);

    var ptr: ?*i32 = null;
    var x: i32 = 1;
    ptr = &x;

    try testing.expectEqual(@as(i32, 1), ptr.?.*);
    try testing.expectEqual(@sizeOf(?*i32), @sizeOf(*i32));

    var thing = Foo{ .value = 41 };
    try testing.expectEqual(@as(i32, 42), useOptionalFoo(&thing));
    try testing.expectEqual(@as(i32, 0), useOptionalFoo(null));
}
