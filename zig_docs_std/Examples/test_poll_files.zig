const std = @import("std");

const MyStreams = enum {
    dummy_file,
};

const MyPollFiles = std.Io.PollFiles(MyStreams);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Setup IO Context
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("🚀 Starting PollFiles/Poller Comprehensive Test\n", .{});

    // 2. Open the dummy file
    const dir = std.Io.Dir.cwd();
    const file = try dir.openFile(io, "zig_docs_std/Examples/data/dummy.txt", .{ .mode = .read_only });
    defer file.close(io);

    // 3. Prepare PollFiles
    var files: MyPollFiles = undefined;
    files.dummy_file = file;

    // 4. Create Poller
    // Note: In 0.16, poll() is often a method on the Io instance or a static helper
    // Based on std.io.md, it's: pub fn poll(gpa: Allocator, comptime StreamEnum: type, files: PollFiles(StreamEnum)) Poller(StreamEnum)
    var poller = std.Io.poll(allocator, MyStreams, files);
    defer poller.deinit();

    std.debug.print("✅ Poller initialized.\n", .{});

    // 5. Poll with timeout (100ms)
    // Poller.pollTimeout(nanoseconds)
    const has_data = try poller.pollTimeout(100 * std.time.ns_per_ms);

    if (has_data) {
        std.debug.print("✅ Data is ready to be read.\n", .{});

        // 6. Check buffered data and extract it using toOwnedSlice
        const reader = poller.reader(.dummy_file);
        const buffered = reader.bufferedLen();
        std.debug.print("✅ Buffered data: {d} bytes\n", .{buffered});

        if (buffered > 0) {
            const data = try poller.toOwnedSlice(.dummy_file);
            defer allocator.free(data);
            std.debug.print("✅ Read {d} bytes from poller: {s}\n", .{ data.len, data[0..@min(data.len, 50)] });
        }
    } else {
        std.debug.print("ℹ️ No data ready (timeout expired).\n", .{});
    }

    std.debug.print("✅ Test Complete.\n", .{});
}