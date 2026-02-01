// Test examples from Kqueue documentation
// Note: Kqueue is only available on macOS and BSD systems
const std = @import("std");
const builtin = @import("builtin");

const is_bsd = switch (builtin.os.tag) {
    .macos, .freebsd, .openbsd, .netbsd, .dragonfly => true,
    else => false,
};

test "Kqueue - init (platform-specific)" {
    if (!is_bsd) return error.SkipZigTest;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var kq: std.Io.Kqueue = undefined;
    try kq.init(gpa.allocator(), .{});
    defer kq.deinit();

    const io = kq.io();
    _ = io;
}

test "Kqueue - InitOptions exists" {
    // Just verify the type exists
    const OptionsType = std.Io.Kqueue.InitOptions;
    _ = OptionsType;
}
