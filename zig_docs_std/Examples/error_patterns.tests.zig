const std = @import("std");

const PatternError = error{
    InvalidFormat,
    InvalidValue,
    ConnectFailed,
    OutOfMemory,
};

const Thing = struct {
    value: i32,

    fn deinit(self: *@This()) void {
        self.value = 0;
    }
};

fn mutateOptionalPayload(maybe: *?Thing) void {
    if (maybe.*) |*thing| {
        thing.value += 1;
    }
}

fn createThing() PatternError!Thing {
    return .{ .value = 41 };
}

fn connectThing(_: *Thing) PatternError!void {
    return error.ConnectFailed;
}

fn buildThing(cleaned: *bool) PatternError!Thing {
    var partial: ?Thing = null;
    errdefer if (partial) |*thing| {
        thing.deinit();
        cleaned.* = true;
    };

    partial = try createThing();
    try connectThing(&partial.?);
    return partial.?;
}

fn countDelimitedLines(data: []const u8) !usize {
    var reader = std.Io.Reader.fixed(data);
    var count: usize = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        _ = line;
        count += 1;
    }

    return count;
}

fn parseAsInt(input: []const u8) PatternError!i32 {
    return std.fmt.parseInt(i32, input, 10) catch return error.InvalidFormat;
}

fn parseAsFloat(input: []const u8) PatternError!f32 {
    return std.fmt.parseFloat(f32, input) catch return error.InvalidFormat;
}

fn parseNumberLossy(input: []const u8) PatternError!i32 {
    return parseAsInt(input) catch |err| switch (err) {
        error.InvalidFormat => blk: {
            const value = try parseAsFloat(input);
            break :blk @intFromFloat(value);
        },
        else => return err,
    };
}

const WorkItem = struct {
    should_fail: bool,

    fn process(item: WorkItem) PatternError!void {
        if (item.should_fail) return error.InvalidValue;
    }
};

const ProcessSummary = struct {
    succeeded: usize,
    failed: usize,
};

fn processAll(items: []const WorkItem) ProcessSummary {
    var summary = ProcessSummary{ .succeeded = 0, .failed = 0 };

    for (items) |item| {
        item.process() catch {
            summary.failed += 1;
            continue;
        };
        summary.succeeded += 1;
    }

    return summary;
}

const Bundle = struct {
    a: []u8,
    b: []u8,

    fn deinit(bundle: Bundle, allocator: std.mem.Allocator) void {
        allocator.free(bundle.b);
        allocator.free(bundle.a);
    }
};

fn makeBundle(allocator: std.mem.Allocator) !Bundle {
    const a = try allocator.alloc(u8, 8);
    errdefer allocator.free(a);

    const b = try allocator.alloc(u8, 16);
    errdefer allocator.free(b);

    return .{ .a = a, .b = b };
}

test "optional pointer capture mutates mutable optional payload" {
    var maybe: ?Thing = .{ .value = 41 };
    mutateOptionalPayload(&maybe);
    try std.testing.expectEqual(@as(i32, 42), maybe.?.value);
}

test "errdefer cleans optional partial initialization on later error" {
    var cleaned = false;
    try std.testing.expectError(error.ConnectFailed, buildThing(&cleaned));
    try std.testing.expect(cleaned);
}

test "reader delimiter loop treats EOF as normal completion" {
    try std.testing.expectEqual(@as(usize, 3), try countDelimitedLines("a\nb\nc"));
    try std.testing.expectEqual(@as(usize, 0), try countDelimitedLines(""));
}

test "catch block can fall back to another parser" {
    try std.testing.expectEqual(@as(i32, 42), try parseNumberLossy("42"));
    try std.testing.expectEqual(@as(i32, 3), try parseNumberLossy("3.9"));
    try std.testing.expectError(error.InvalidFormat, parseNumberLossy("nope"));
}

test "accumulate failures without aborting whole batch" {
    const items = [_]WorkItem{
        .{ .should_fail = false },
        .{ .should_fail = true },
        .{ .should_fail = false },
    };

    const summary = processAll(&items);
    try std.testing.expectEqual(@as(usize, 2), summary.succeeded);
    try std.testing.expectEqual(@as(usize, 1), summary.failed);
}

test "progressive errdefer cleans earlier allocations on failure" {
    var failing = std.testing.FailingAllocator.init(
        std.testing.allocator,
        .{ .fail_index = 1 },
    );

    try std.testing.expectError(error.OutOfMemory, makeBundle(failing.allocator()));
    try std.testing.expect(failing.has_induced_failure);
}

test "progressive errdefer transfers ownership on success" {
    const bundle = try makeBundle(std.testing.allocator);
    defer bundle.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 8), bundle.a.len);
    try std.testing.expectEqual(@as(usize, 16), bundle.b.len);
}
