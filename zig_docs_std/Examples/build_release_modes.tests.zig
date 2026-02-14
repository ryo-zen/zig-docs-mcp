const std = @import("std");
const builtin = @import("builtin");

fn modeDescription(mode: std.builtin.OptimizeMode) []const u8 {
    return switch (mode) {
        .Debug => "safety-first development mode",
        .ReleaseSafe => "optimized with safety checks",
        .ReleaseFast => "maximum throughput, fewer safety checks",
        .ReleaseSmall => "size-focused optimization",
    };
}

test "active optimization mode is classified" {
    const text = modeDescription(builtin.mode);
    try std.testing.expect(text.len > 0);
}

test "target metadata is compile-time available" {
    comptime {
        _ = builtin.target.cpu.arch;
        _ = builtin.target.os.tag;
        _ = builtin.target.abi;
    }

    try std.testing.expect(true);
}
