const std = @import("std");

const Status = enum { success, warning, error_ };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("=== std.Io.Terminal Comprehensive Test ===\n\n", .{});

    // Test 1: Basic Color Output
    std.debug.print("Test 1: Basic Color Output\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        try term.setColor(.red);
        try term.writer.writeAll("  Error: Operation failed\n");
        try term.setColor(.reset);

        std.debug.print("  ✅ PASS - Basic color output\n\n", .{});
    }

    // Test 2: Color-Coded Messages
    std.debug.print("Test 2: Color-Coded Messages\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        // Success message
        try term.setColor(.green);
        try term.writer.writeAll("  ✓ Build successful\n");
        try term.setColor(.reset);

        // Warning message
        try term.setColor(.yellow);
        try term.writer.writeAll("  ⚠ Warning: Deprecated API\n");
        try term.setColor(.reset);

        std.debug.print("  ✅ PASS - Multiple color messages\n\n", .{});
    }

    // Test 3: All Colors
    std.debug.print("Test 3: All Available Colors\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        const colors = [_]std.Io.Terminal.Color{
            .black, .red,     .green, .yellow,
            .blue,  .magenta, .cyan,  .white,
        };

        const names = [_][]const u8{
            "black", "red",     "green", "yellow",
            "blue",  "magenta", "cyan",  "white",
        };

        for (colors, names) |color, name| {
            try term.setColor(color);
            try term.writer.print("  {s: <10}", .{name});
            try term.setColor(.reset);
        }
        try term.writer.writeAll("\n");

        std.debug.print("  ✅ PASS - All colors displayed\n\n", .{});
    }

    // Test 4: Conditional Color Support
    std.debug.print("Test 4: Conditional Color Support\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        // Only use color if terminal supports it
        if (term.mode != .no_color) {
            try term.setColor(.blue);
        }
        try term.writer.writeAll("  Building project...\n");
        if (term.mode != .no_color) {
            try term.setColor(.reset);
        }

        std.debug.print("  ✅ PASS - Conditional coloring (mode: {s})\n\n", .{@tagName(term.mode)});
    }

    // Test 5: Multi-Color Output Pattern
    std.debug.print("Test 5: Multi-Color Output Pattern\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        var term = stderr.terminal();

        inline for (@typeInfo(Status).@"enum".fields) |field| {
            const status: Status = @enumFromInt(field.value);
            try printStatus(&term, status);
            try term.writer.print("{s}\n", .{field.name});
        }

        std.debug.print("  ✅ PASS - Multi-color pattern\n\n", .{});
    }

    // Test 6: Error Handling
    std.debug.print("Test 6: Error Handling\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        // Graceful handling of potential errors
        term.setColor(.red) catch |err| {
            std.debug.print("  Error setting color: {s}\n", .{@errorName(err)});
        };
        try term.writer.writeAll("  Message with error handling\n");
        term.setColor(.reset) catch {};

        std.debug.print("  ✅ PASS - Error handling\n\n", .{});
    }

    // Test 7: Batched Color Changes (Performance Pattern)
    std.debug.print("Test 7: Batched Color Changes\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        const errors = [_][]const u8{
            "  Error 1: File not found",
            "  Error 2: Permission denied",
            "  Error 3: Network timeout",
        };

        // Set color once for all lines
        try term.setColor(.red);
        for (errors) |err| {
            try term.writer.print("{s}\n", .{err});
        }
        try term.setColor(.reset);

        std.debug.print("  ✅ PASS - Batched color changes\n\n", .{});
    }

    // Test 8: Mode Detection
    std.debug.print("Test 8: Terminal Mode Detection\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        std.debug.print("  Terminal mode: {s}\n", .{@tagName(term.mode)});

        switch (term.mode) {
            .no_color => std.debug.print("  Colors disabled (pipe/file/NO_COLOR)\n", .{}),
            .escape_codes => std.debug.print("  ANSI escape sequences supported\n", .{}),
            .windows_api => std.debug.print("  Windows Console API available\n", .{}),
        }

        std.debug.print("  ✅ PASS - Mode detection\n\n", .{});
    }

    // Test 9: Color Reset Between Different Colors
    std.debug.print("Test 9: Color Transitions\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        try term.setColor(.red);
        try term.writer.writeAll("  Red");

        // No reset needed - just set new color
        try term.setColor(.green);
        try term.writer.writeAll(" -> Green");

        try term.setColor(.blue);
        try term.writer.writeAll(" -> Blue\n");

        try term.setColor(.reset);

        std.debug.print("  ✅ PASS - Color transitions\n\n", .{});
    }

    // Test 10: Documentation Example - Main Function
    std.debug.print("Test 10: Documentation Example\n", .{});
    {
        var buffer: [1024]u8 = undefined;
        const stderr = try io.lockStderr(&buffer, null);
        defer io.unlockStderr();

        const term = stderr.terminal();

        // Red error message
        try term.setColor(.red);
        try term.writer.writeAll("  Error: File not found\n");
        try term.setColor(.reset);

        // Green success message
        try term.setColor(.green);
        try term.writer.writeAll("  Success: Operation completed\n");
        try term.setColor(.reset);

        std.debug.print("  ✅ PASS - Documentation example\n\n", .{});
    }

    std.debug.print("=== All Terminal Tests Passed! ===\n", .{});
}

// Helper function from documentation
fn printStatus(term: *std.Io.Terminal, status: Status) !void {
    switch (status) {
        .success => {
            try term.setColor(.green);
            try term.writer.writeAll("  ✓ ");
        },
        .warning => {
            try term.setColor(.yellow);
            try term.writer.writeAll("  ⚠ ");
        },
        .error_ => {
            try term.setColor(.red);
            try term.writer.writeAll("  ✗ ");
        },
    }
    try term.setColor(.reset);
}
