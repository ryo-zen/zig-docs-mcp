//! Comprehensive test suite for std.Io.Dir covering file operations,
//! directory creation, rename, access checks, and convenience read functions.

const std = @import("std");
const testing = std.testing;

test "Dir openFile and createFile" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_dir_open.txt";
    defer cwd.deleteFile(io, filename) catch {};

    // Create and write
    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "dir open test");
    }

    // Open and read back
    {
        const file = try cwd.openFile(io, filename, .{});
        defer file.close(io);

        var buf: [256]u8 = undefined;
        const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
        try testing.expectEqualStrings("dir open test", buf[0..bytes_read]);
    }
}

test "Dir readFile with preallocated buffer" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_dir_readfile.txt";
    defer cwd.deleteFile(io, filename) catch {};

    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "readFile test content");
    }

    var buf: [256]u8 = undefined;
    const data = try cwd.readFile(io, filename, &buf);
    try testing.expectEqualStrings("readFile test content", data);
}

test "Dir readFileAlloc" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_dir_readalloc.txt";
    defer cwd.deleteFile(io, filename) catch {};

    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "allocated read content");
    }

    const data = try cwd.readFileAlloc(io, filename, allocator, .unlimited);
    defer allocator.free(data);
    try testing.expectEqualStrings("allocated read content", data);
}

test "Dir createDirPath and openDir" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const dirname = "temp_test_dir_016/sub";
    defer cwd.deleteTree(io, "temp_test_dir_016") catch {};

    try cwd.createDirPath(io, dirname);

    const sub = try cwd.openDir(io, dirname, .{});
    defer sub.close(io);

    // Write a file inside the subdirectory to confirm it's usable
    const file = try sub.createFile(io, "inner.txt", .{});
    defer file.close(io);
    try file.writeStreamingAll(io, "nested file content");
}

test "Dir rename" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const old_name = "temp_test_dir_rename_old.txt";
    const new_name = "temp_test_dir_rename_new.txt";
    defer cwd.deleteFile(io, new_name) catch {};

    {
        const file = try cwd.createFile(io, old_name, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "rename me");
    }

    try std.Io.Dir.rename(cwd, old_name, cwd, new_name, io);

    var buf: [256]u8 = undefined;
    const data = try cwd.readFile(io, new_name, &buf);
    try testing.expectEqualStrings("rename me", data);
}

test "Dir access checks existence" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const filename = "temp_test_dir_access.txt";
    defer cwd.deleteFile(io, filename) catch {};

    {
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "access check");
    }

    // Should succeed — file exists
    try cwd.access(io, filename, .{});

    // Should fail — file does not exist
    const result = cwd.access(io, "nonexistent_file_xyz_016.txt", .{});
    try testing.expectError(error.FileNotFound, result);
}

test "Dir deleteTree removes nested structure" {
    const allocator = testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const cwd = std.Io.Dir.cwd();
    const tree_root = "temp_test_dir_tree";

    try cwd.createDirPath(io, "temp_test_dir_tree/a/b");

    {
        const sub = try cwd.openDir(io, "temp_test_dir_tree/a", .{});
        defer sub.close(io);
        const file = try sub.createFile(io, "leaf.txt", .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "leaf");
    }

    // deleteTree should remove everything without error
    try cwd.deleteTree(io, tree_root);

    // Confirm it's gone
    const result = cwd.access(io, tree_root, .{});
    try testing.expectError(error.FileNotFound, result);
}
