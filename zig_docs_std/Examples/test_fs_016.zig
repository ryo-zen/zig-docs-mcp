const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const dir = std.Io.Dir.cwd();
    const test_dir = "test_mkdir_016/sub";
    
    // createDirPath corresponds to makePath
    dir.createDirPath(io, test_dir) catch |err| {
        std.debug.print("Err: {}\n", .{err});
    };
    
    std.debug.print("Done\n", .{});
}
