// Runnable examples for std.zon.
// Run with: zig test zig_docs_std/Examples/std.zon.tests.zig

const std = @import("std");
const testing = std.testing;

test "parse ZON into a typed struct" {
    const Mode = enum { dev, prod };
    const Config = struct {
        port: u16,
        debug: bool,
        mode: Mode,
    };

    const source =
        \\.{
        \\    .port = 8080,
        \\    .debug = true,
        \\    .mode = .dev,
        \\}
    ;

    const config = try std.zon.parse.fromSlice(Config, testing.allocator, source, null, .{});

    try testing.expectEqual(@as(u16, 8080), config.port);
    try testing.expect(config.debug);
    try testing.expectEqual(Mode.dev, config.mode);
}

test "parse allocated ZON data and free it" {
    const Config = struct {
        name: []const u8,
        values: []const u32,
    };

    const source =
        \\.{
        \\    .name = "demo",
        \\    .values = .{ 1, 2, 3 },
        \\}
    ;

    const config = try std.zon.parse.fromSliceAlloc(Config, testing.allocator, source, null, .{});
    defer std.zon.parse.free(testing.allocator, config);

    try testing.expectEqualStrings("demo", config.name);
    try testing.expectEqualSlices(u32, &.{ 1, 2, 3 }, config.values);
}

test "serialize a typed value to ZON" {
    const Config = struct {
        port: u16,
        debug: bool,
    };

    const config = Config{ .port = 8080, .debug = false };

    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try std.zon.stringify.serialize(config, .{}, &writer);
    try writer.flush();

    const output = writer.buffered();
    try testing.expect(std.mem.indexOf(u8, output, ".port = 8080") != null);
    try testing.expect(std.mem.indexOf(u8, output, ".debug = false") != null);
}
