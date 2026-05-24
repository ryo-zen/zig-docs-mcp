const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("🚀 Starting Timeout/Duration Comprehensive Test\n", .{});

    // 1. Test Duration Construction
    const d1 = std.Io.Duration.fromSeconds(1);
    const d2 = std.Io.Duration.fromMilliseconds(500);
    std.debug.print("✅ Durations: 1s = {d}ns, 500ms = {d}ns\n", .{ d1.nanoseconds, d2.nanoseconds });

    // 2. Test Timeout Sleep (Duration)
    const start = std.Io.Clock.awake.now(io);
    const t_duration = std.Io.Timeout{
        .duration = .{ .raw = d2, .clock = .awake },
    };
    std.debug.print("⏳ Sleeping for 500ms (Relative)...\n", .{});
    try t_duration.sleep(io);
    const end = std.Io.Clock.awake.now(io);
    const elapsed = start.durationTo(end);
    std.debug.print("✅ Slept for {d}ms\n", .{elapsed.toMilliseconds()});

    // 3. Test Timeout Sleep (Deadline)
    const now = std.Io.Clock.awake.now(io);
    const deadline = now.addDuration(std.Io.Duration.fromMilliseconds(250));
    const t_deadline = std.Io.Timeout{
        .deadline = .{ .raw = deadline, .clock = .awake },
    };
    std.debug.print("⏳ Sleeping for 250ms (Absolute Deadline)...\n", .{});
    try t_deadline.sleep(io);
    const end2 = std.Io.Clock.awake.now(io);
    std.debug.print("✅ Slept until deadline. Total elapsed: {d}ms\n", .{now.durationTo(end2).toMilliseconds()});

    // 4. Conversion tests
    const converted_deadline = t_duration.toDeadline(io);
    if (converted_deadline == .deadline) {
        const cd = converted_deadline.deadline;
        std.debug.print("✅ Converted 500ms duration to deadline: {d}\n", .{cd.raw.toNanoseconds()});
    }

    std.debug.print("✅ Timeout test complete.\n", .{});
}
