const std = @import("std");

const IoError = error{ EndOfStream, WouldBlock, FrameTooLarge, TruncatedFrame, OutOfMemory };

const SliceReader = struct {
    data: []const u8,
    pos: usize = 0,
    max_chunk: usize,

    fn read(self: *SliceReader, out: []u8) IoError!usize {
        if (self.pos >= self.data.len) return error.EndOfStream;

        const remaining = self.data.len - self.pos;
        const n = @min(@min(out.len, self.max_chunk), remaining);
        @memcpy(out[0..n], self.data[self.pos .. self.pos + n]);
        self.pos += n;
        return n;
    }
};

const ShortWriter = struct {
    storage: []u8,
    pos: usize = 0,
    max_chunk: usize,

    fn write(self: *ShortWriter, input: []const u8) IoError!usize {
        if (self.pos >= self.storage.len) return error.WouldBlock;

        const room = self.storage.len - self.pos;
        const n = @min(@min(input.len, self.max_chunk), room);
        if (n == 0) return error.WouldBlock;

        @memcpy(self.storage[self.pos .. self.pos + n], input[0..n]);
        self.pos += n;
        return n;
    }
};

fn readExact(reader: *SliceReader, out: []u8) IoError!void {
    var filled: usize = 0;
    while (filled < out.len) {
        const n = reader.read(out[filled..]) catch |err| switch (err) {
            error.EndOfStream => return error.EndOfStream,
            else => return err,
        };
        filled += n;
    }
}

fn writeAll(writer: *ShortWriter, input: []const u8) IoError!void {
    var sent: usize = 0;
    var retries: usize = 0;

    while (sent < input.len) {
        const n = writer.write(input[sent..]) catch |err| switch (err) {
            error.WouldBlock => {
                retries += 1;
                if (retries > 4) return error.WouldBlock;
                continue;
            },
            else => return err,
        };

        retries = 0;
        sent += n;
    }
}

fn readLengthPrefixedFrame(reader: *SliceReader, allocator: std.mem.Allocator, max_frame: usize) IoError![]u8 {
    var len_buf: [2]u8 = undefined;
    try readExact(reader, &len_buf);

    const frame_len = std.mem.readInt(u16, &len_buf, .big);
    if (frame_len > max_frame) return error.FrameTooLarge;

    const frame = try allocator.alloc(u8, frame_len);
    errdefer allocator.free(frame);

    readExact(reader, frame) catch |err| switch (err) {
        error.EndOfStream => return error.TruncatedFrame,
        else => return err,
    };

    return frame;
}

test "reliable read loop handles partial reads" {
    var reader = SliceReader{ .data = "abcdef", .max_chunk = 2 };
    var out: [6]u8 = undefined;

    try readExact(&reader, &out);
    try std.testing.expectEqualStrings("abcdef", &out);
}

test "write loop handles short writes and backpressure" {
    var storage: [8]u8 = [_]u8{0} ** 8;
    var writer = ShortWriter{ .storage = &storage, .max_chunk = 3 };

    try writeAll(&writer, "zigdocs");
    try std.testing.expectEqualStrings("zigdocs", storage[0..7]);
}

test "framing rejects oversized message" {
    var reader = SliceReader{
        .data = &[_]u8{ 0x10, 0x00 }, // len=4096
        .max_chunk = 2,
    };

    try std.testing.expectError(
        error.FrameTooLarge,
        readLengthPrefixedFrame(&reader, std.testing.allocator, 1024),
    );
}

test "framing detects truncated payload" {
    var reader = SliceReader{
        .data = &[_]u8{ 0x00, 0x04, 'o', 'k' }, // claims 4 bytes, has 2
        .max_chunk = 2,
    };

    try std.testing.expectError(
        error.TruncatedFrame,
        readLengthPrefixedFrame(&reader, std.testing.allocator, 64),
    );
}

test "framing success path" {
    var reader = SliceReader{
        .data = &[_]u8{ 0x00, 0x03, 'a', 'b', 'c' },
        .max_chunk = 2,
    };

    const frame = try readLengthPrefixedFrame(&reader, std.testing.allocator, 64);
    defer std.testing.allocator.free(frame);

    try std.testing.expectEqualStrings("abc", frame);
}

test "std.Io.Queue provides bounded backpressure and closed drain semantics" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var backing: [2]u8 = undefined;
    var queue = std.Io.Queue(u8).init(&backing);
    defer queue.close(io);

    try std.testing.expectEqual(@as(usize, 2), try queue.put(io, &.{ 1, 2 }, 2));

    // With min = 0, a full queue reports no progress instead of blocking.
    try std.testing.expectEqual(@as(usize, 0), try queue.put(io, &.{3}, 0));

    queue.close(io);
    try std.testing.expectError(error.Closed, queue.put(io, &.{3}, 1));

    var out: [2]u8 = undefined;
    try std.testing.expectEqual(@as(usize, 2), try queue.get(io, &out, 1));
    try std.testing.expectEqualSlices(u8, &.{ 1, 2 }, &out);
    try std.testing.expectError(error.Closed, queue.get(io, &out, 1));
}
