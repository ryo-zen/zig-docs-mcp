// Tests for std.process documentation examples (Zig 0.16)
// Run with: zig test Examples/std.process.tests.zig

const std = @import("std");

// Test 1: getCwd - get current directory
test "getCwd - basic usage" {
    std.debug.print("\n=== Test: getCwd ===\n", .{});

    var buf: [4096]u8 = undefined;
    const cwd = try std.process.getCwd(&buf);

    std.debug.print("  Current directory: {s}\n", .{cwd});
    try std.testing.expect(cwd.len > 0);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 2: getCwdAlloc - get current directory with allocation
test "getCwdAlloc - with allocator" {
    std.debug.print("\n=== Test: getCwdAlloc ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const cwd = try std.process.getCwdAlloc(allocator);
    defer allocator.free(cwd);

    std.debug.print("  CWD: {s}\n", .{cwd});
    try std.testing.expect(cwd.len > 0);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 3: process.run - run command and capture output
test "process.run - capture output" {
    std.debug.print("\n=== Test: process.run ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const result = try std.process.run(allocator, io, .{
        .argv = &[_][]const u8{ "echo", "Hello from test!" },
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    std.debug.print("  stdout: {s}", .{result.stdout});
    try std.testing.expect(result.term == .exited);
    try std.testing.expect(result.term.exited == 0);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 4: process.spawn - spawn child process
test "process.spawn - basic spawn and wait" {
    std.debug.print("\n=== Test: process.spawn ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var child = try std.process.spawn(io, .{
        .argv = &[_][]const u8{ "echo", "spawned" },
    });

    const term = try child.wait(io);
    try std.testing.expect(term == .exited);
    try std.testing.expect(term.exited == 0);

    std.debug.print("  Child process completed\n", .{});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 5: Child.kill - terminate child process
test "Child.kill - forcibly terminate" {
    std.debug.print("\n=== Test: Child.kill ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var child = try std.process.spawn(io, .{
        .argv = &[_][]const u8{ "sleep", "10" },
    });

    // Kill it immediately
    child.kill(io);

    std.debug.print("  Process killed\n", .{});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 6: COMMENTED OUT - posixGetUserInfo has bug in this Zig dev version
// See: ../Namespaces/process/KNOWN_BUGS.md
//
// test "getUserInfo - POSIX user lookup" {
//     std.debug.print("\n=== Test: getUserInfo ===\n", .{});
//
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();
//
//     var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
//     defer threaded.deinit();
//     const io = threaded.io();
//
//     // BUG: posixGetUserInfo calls file.reader(&buffer) but should be file.reader(io, &buffer)
//     const user_info = std.process.posixGetUserInfo(io, "root") catch |err| {
//         std.debug.print("  getUserInfo failed: {}\n", .{err});
//         return;
//     };
//
//     std.debug.print("  User 'root' - uid: {}, gid: {}\n", .{ user_info.uid, user_info.gid });
//     std.debug.print("  ✅ PASS\n\n", .{});
// }

// Test 7: Environ.Map - environment variable map
test "Environ.Map - create and manipulate" {
    std.debug.print("\n=== Test: Environ.Map ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create environment map
    var env_map = std.process.Environ.Map.init(allocator);
    defer env_map.deinit();

    try env_map.put("MY_VAR", "my_value");
    try env_map.put("TEST_VAR", "test_value");

    // Verify we can get values back
    const my_var = env_map.get("MY_VAR");
    try std.testing.expect(my_var != null);
    try std.testing.expectEqualStrings("my_value", my_var.?);

    std.debug.print("  Created environment map with custom variables\n", .{});
    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 8: process.run - check exit code
test "process.run - check Term variants" {
    std.debug.print("\n=== Test: process.run - Term checking ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Success case
    {
        const result = try std.process.run(allocator, io, .{
            .argv = &[_][]const u8{ "echo", "success" },
        });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        switch (result.term) {
            .exited => |code| {
                std.debug.print("  Exit code: {}\n", .{code});
                try std.testing.expect(code == 0);
            },
            else => return error.UnexpectedTermination,
        }
    }

    // Failure case (false command exits with 1)
    {
        const result = try std.process.run(allocator, io, .{
            .argv = &[_][]const u8{"false"},
        });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        switch (result.term) {
            .exited => |code| {
                std.debug.print("  'false' exit code: {}\n", .{code});
                try std.testing.expect(code != 0);
            },
            else => return error.UnexpectedTermination,
        }
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 9: Constants - can_spawn
test "Constants - can_spawn" {
    std.debug.print("\n=== Test: Constants ===\n", .{});

    std.debug.print("  can_spawn: {}\n", .{std.process.can_spawn});
    try std.testing.expect(std.process.can_spawn == true); // Should be true on most platforms

    std.debug.print("  ✅ PASS\n\n", .{});
}

// Test 10: process.run with max_output_bytes
test "process.run - max output bytes" {
    std.debug.print("\n=== Test: process.run - max_output_bytes ===\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const result = try std.process.run(allocator, io, .{
        .argv = &[_][]const u8{ "echo", "limited output" },
        .max_output_bytes = 1024,
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    std.debug.print("  Output: {s}", .{result.stdout});
    std.debug.print("  ✅ PASS\n\n", .{});
}
