const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create Threaded Io instance with empty environ
    var threaded = std.Io.Threaded.init(allocator, .{
        .environ = .empty,  // Use empty environ
    });
    defer threaded.deinit();

    // Get Io interface
    const io = threaded.io();

    // Now use it for file operations
    const dir = std.Io.Dir.cwd();
    const file = try dir.openFile(io, "test_arraylist_016.zig", .{});
    defer file.close(io);

    // Read some data
    var buf: [100]u8 = undefined;
    const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});

    std.debug.print("✅ Successfully read {} bytes using Io.Threaded!\n", .{bytes_read});
}
