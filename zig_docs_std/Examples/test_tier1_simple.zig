const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Setup I/O backend
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const dir = std.Io.Dir.cwd();

    // WRITE: Create file and write to it
    {
        const file = try dir.createFile(io, "test_tier1.txt", .{});
        defer file.close(io);

        const data = "Hello from Tier 1!\nThe answer is 42\n";
        try file.writeStreamingAll(io, data);
    }

    std.debug.print("✅ Wrote to file\n", .{});

    // READ: Open file and read from it
    {
        const file = try dir.openFile(io, "test_tier1.txt", .{});
        defer file.close(io);

        var buffer: [1024]u8 = undefined;
        const bytes_read = try file.readStreaming(io, &[_][]u8{&buffer});

        std.debug.print("✅ Read {} bytes from file\n", .{bytes_read});
        std.debug.print("Content:\n{s}", .{buffer[0..bytes_read]});
    }

    std.debug.print("\n🎉 Tier 1 test complete!\n", .{});
}
