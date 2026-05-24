const std = @import("std");

pub fn main(init: std.process.Init) !void {
    std.debug.print("--- Testing std.process.Init and Args ---\n", .{});
    
    // 1. Test Argument Iteration
    var args = try init.minimal.args.iterateAllocator(init.gpa);
    defer args.deinit();

    const prog_name = args.next() orelse "unknown";
    std.debug.print("Program Name: {s}\n", .{prog_name});

    var arg_count: usize = 0;
    while (args.next()) |arg| {
        std.debug.print("Arg {}: {s}\n", .{arg_count, arg});
        arg_count += 1;
    }

    // 2. Test Environment Map Manipulation
    std.debug.print("\n--- Testing Environ.Map Manipulation ---\n", .{});
    
    // Get
    if (init.environ_map.get("PATH")) |_| {
        std.debug.print("✅ Found PATH\n", .{});
    }

    // Put
    try init.environ_map.put("ZIG_TEST_VAR", "12345");
    if (init.environ_map.get("ZIG_TEST_VAR")) |val| {
        if (std.mem.eql(u8, val, "12345")) {
            std.debug.print("✅ Put successful\n", .{});
        }
    }

    // Iterator
    var env_it = init.environ_map.iterator();
    var found_test_var = false;
    while (env_it.next()) |entry| {
        if (std.mem.eql(u8, entry.key_ptr.*, "ZIG_TEST_VAR")) {
            found_test_var = true;
            break;
        }
    }
    if (found_test_var) std.debug.print("✅ Iterator found test var\n", .{});

    // Remove
    if (init.environ_map.swapRemove("ZIG_TEST_VAR")) {
        if (init.environ_map.get("ZIG_TEST_VAR") == null) {
            std.debug.print("✅ swapRemove successful\n", .{});
        }
    }

    // 3. Test UserInfo - SKIPPED (Broken in current stdlib dev build)
    // std.process.posixGetUserInfo(init.io, "root") currently causes a compiler error in this build.
    std.debug.print("\n--- Testing UserInfo (SKIPPED) ---\n", .{});

    // 4. Test std.process.run
    std.debug.print("\n--- Testing std.process.run ---\n", .{});
    const run_result = try std.process.run(init.gpa, init.io, .{
        .argv = &[_][]const u8{ "echo", "Zig 0.16 Process Test" },
    });
    defer init.gpa.free(run_result.stdout);
    defer init.gpa.free(run_result.stderr);

    // Test Term variant matching
    switch (run_result.term) {
        .exited => |code| std.debug.print("✅ run successful (exited {}): {s}", .{ code, run_result.stdout }),
        else => |t| std.debug.print("❌ run unexpected term: {}\n", .{t}),
    }

    // 5. Test std.process.spawn with piping
    std.debug.print("\n--- Testing std.process.spawn with piping ---\n", .{});
    var child = try std.process.spawn(init.io, .{
        .argv = &[_][]const u8{ "cat" },
        .stdin = .pipe,
        .stdout = .pipe,
        .stderr = .pipe,
    });
    
    const test_input = "Piping through cat works!\n";
    try child.stdin.?.writeStreamingAll(init.io, test_input);
    child.stdin.?.close(init.io);
    child.stdin = null;

    var stdout_list: std.ArrayList(u8) = .empty;
    defer stdout_list.deinit(init.gpa);
    var stderr_list: std.ArrayList(u8) = .empty;
    defer stderr_list.deinit(init.gpa);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_reader = child.stdout.?.readerStreaming(init.io, &stdout_buffer);
    try stdout_reader.interface.appendRemaining(init.gpa, &stdout_list, .limited(1024));

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_reader = child.stderr.?.readerStreaming(init.io, &stderr_buffer);
    try stderr_reader.interface.appendRemaining(init.gpa, &stderr_list, .limited(1024));

    const term = try child.wait(init.io);
    if (term == .exited and term.exited == 0 and std.mem.eql(u8, stdout_list.items, test_input)) {
        std.debug.print("✅ spawn/pipe successful: {s}", .{stdout_list.items});
    } else {
        std.debug.print("❌ spawn/pipe failed\n", .{});
    }

    std.debug.print("\n--- All 0.16 Process tests completed! ---\n", .{});
}
