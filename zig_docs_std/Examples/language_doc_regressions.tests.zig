// Regression tests for repaired zig_docs language examples.
// Run with:
//   zig test zig_docs_std/Examples/language_doc_regressions.tests.zig

const std = @import("std");
const testing = std.testing;

test "while examples preserve comparison operators" {
    var i: usize = 0;
    while (i < 10) : (i += 1) {}
    try testing.expectEqual(@as(usize, 10), i);

    var j: usize = 1;
    var k: usize = 1;
    while (j * k < 2000) : ({
        j *= 2;
        k *= 3;
    }) {
        try testing.expect(j * k < 2000);
    }
}

test "integer to float coercion example marks runtime var by address" {
    var int: u8 = 123;
    _ = &int;
    const float: f32 = int;
    const int_from_float: u8 = @intFromFloat(float);
    try testing.expectEqual(int, int_from_float);
}

test "separate block scopes can reuse a name" {
    {
        const pi = 3.14;
        _ = pi;
    }
    {
        var pi: bool = true;
        _ = &pi;
    }
}
