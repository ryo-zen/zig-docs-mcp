//! This test file demonstrates top-level doc comments for a module.

// Representative tests for zig_docs/comments.md examples.
// Run with:
//   zig test zig_docs_std/Examples/comments.tests.zig

const std = @import("std");
const testing = std.testing;

/// A structure for storing a timestamp, with nanosecond precision (this is a
/// multiline doc comment).
const Timestamp = struct {
    /// The number of seconds since the epoch (this is also a doc comment).
    seconds: i64,
    /// The number of nanoseconds past the second (doc comment again).
    nanos: u32,

    /// Returns a `Timestamp` struct representing the Unix epoch; that is, the
    /// moment of 1970 Jan 1 00:00:00 UTC (this is a doc comment too).
    pub fn unixEpoch() Timestamp {
        return Timestamp{
            .seconds = 0,
            .nanos = 0,
        };
    }
};

const S = struct {
    //! Top level comments are allowed inside a container other than a module,
    //! but it is not very useful. Currently, when producing the package
    //! documentation, these comments are ignored.
};

test "normal comments are ignored" {
    const executed = false;
    // executed = true;
    try testing.expect(!executed);
}

test "doc comment example returns unix epoch" {
    const epoch = Timestamp.unixEpoch();
    try testing.expectEqual(@as(i64, 0), epoch.seconds);
    try testing.expectEqual(@as(u32, 0), epoch.nanos);
}

test "container with top-level doc comments compiles" {
    try testing.expectEqual(0, @sizeOf(S));
}
