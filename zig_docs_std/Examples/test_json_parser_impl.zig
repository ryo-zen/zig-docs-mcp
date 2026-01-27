const std = @import("std");

pub const JsonParser = struct {
    /// Parse JSON from a file reader
    /// Returns std.json.Parsed(T) - caller must call deinit()
    pub fn parseFromFile(comptime T: type, allocator: std.mem.Allocator, io: std.Io, file: std.Io.File) !std.json.Parsed(T) {
        // Read file into buffer
        var buf: [4096]u8 = undefined;
        const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
        const contents = buf[0..bytes_read];

        // Parse JSON - returns owned result
        return try std.json.parseFromSlice(T, allocator, contents, .{});
    }

    /// Parse JSON from a byte slice
    /// Returns std.json.Parsed(T) - caller must call deinit()
    pub fn parseFromSlice(comptime T: type, allocator: std.mem.Allocator, slice: []const u8) !std.json.Parsed(T) {
        return std.json.parseFromSlice(T, allocator, slice, .{});
    }

    /// Stringify a value to JSON string
    /// Returns owned string - caller must call allocator.free()
    pub fn stringify(value: anytype, allocator: std.mem.Allocator) ![]const u8 {
        var aw: std.Io.Writer.Allocating = .init(allocator);
        errdefer aw.deinit();

        try std.json.Stringify.value(value, .{}, &aw.writer);

        return try aw.toOwnedSlice();
    }
};
