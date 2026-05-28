// Runnable checks for zig_docs/simple_timestamp_016.md
// Run with:
//   zig test zig_docs_std/Examples/simple_timestamp_016.tests.zig

const std = @import("std");
const testing = std.testing;

pub fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}

test "global single-threaded Io timestamp helper compiles and returns unix seconds" {
    const ts = getTime();
    try testing.expect(ts > 1_500_000_000);
}

test "explicit Io timestamp helper compiles and returns unix seconds" {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    try testing.expect(ts.toSeconds() > 1_500_000_000);
}
