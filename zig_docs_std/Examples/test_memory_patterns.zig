const std = @import("std");
const Allocator = std.mem.Allocator;

// Test: defer pattern
test "defer pattern" {
    const allocator = std.testing.allocator;
    const ptr = try allocator.create(i32);
    defer allocator.destroy(ptr);
    ptr.* = 42;
}

// Test: heap allocation for string
fn makeString(allocator: Allocator) ![]u8 {
    return allocator.dupe(u8, "hello");
}

test "makeString heap allocation" {
    const allocator = std.testing.allocator;
    const str = try makeString(allocator);
    defer allocator.free(str);
    try std.testing.expectEqualStrings("hello", str);
}

// Test: caller-provided buffer
fn makeStringBuffer(buffer: []u8) []u8 {
    const msg = "hello";
    @memcpy(buffer[0..msg.len], msg);
    return buffer[0..msg.len];
}

test "makeString with buffer" {
    var buffer: [100]u8 = undefined;
    const result = makeStringBuffer(&buffer);
    try std.testing.expectEqualStrings("hello", result);
}

// Test: arena pattern
test "arena pattern" {
    const child = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(child);
    defer arena.deinit();

    const ptr = try arena.allocator().create(i32);
    ptr.* = 42;
    // No manual free needed
}

// Test: GPA leak detection
test "GPA leak detection" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        _ = leaked;
    }
    const allocator = gpa.allocator();

    const ptr = try allocator.create(i32);
    defer allocator.destroy(ptr);
    ptr.* = 42;
}

// Test: explicit error handling
test "explicit error handling" {
    const allocator = std.testing.allocator;

    const ptr = allocator.create(i32) catch |err| {
        // Handle error
        return err;
    };
    defer allocator.destroy(ptr);
    ptr.* = 42;
}

// Test: zero-initialize
test "zero-initialize buffer" {
    var buffer = [_]u8{0} ** 100;
    try std.testing.expect(buffer[0] == 0);
    try std.testing.expect(buffer[99] == 0);
}

// Test: memset initialization
test "memset initialization" {
    var buffer: [100]u8 = undefined;
    @memset(&buffer, 0);
    try std.testing.expect(buffer[0] == 0);
    try std.testing.expect(buffer[99] == 0);
}

// Real-world pattern: request handler (simplified)
const Request = struct {
    body: []const u8,
};

const Response = struct {
    content: []const u8,

    pub fn clone(self: Response, allocator: Allocator) !Response {
        return Response{
            .content = try allocator.dupe(u8, self.content),
        };
    }

    pub fn deinit(self: *Response, allocator: Allocator) void {
        allocator.free(self.content);
    }
};

const ParsedData = struct {
    content: []const u8,
};

fn parseJson(allocator: Allocator, data: []const u8) !ParsedData {
    const parsed = try allocator.alloc(u8, data.len);
    @memcpy(parsed, data);
    return ParsedData{ .content = parsed };
}

fn buildResponse(allocator: Allocator, body: ParsedData) !Response {
    const content = try allocator.dupe(u8, body.content);
    return Response{ .content = content };
}

fn handleRequest(gpa: Allocator, request: Request) !Response {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    const body = try parseJson(allocator, request.body);
    const response = try buildResponse(allocator, body);

    return response.clone(gpa);
}

test "HTTP request handler pattern" {
    const allocator = std.testing.allocator;
    const request = Request{ .body = "test data" };

    var response = try handleRequest(allocator, request);
    defer response.deinit(allocator);

    try std.testing.expectEqualStrings("test data", response.content);
}

// Test: Fixed buffer allocator pattern
fn processCommand(command: []const u8) !void {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const copy = try allocator.dupe(u8, command);
    _ = copy;
}

test "fixed buffer pattern" {
    try processCommand("test command");
}

// Test: Library function pattern
const Config = struct {
    entries: []Entry,

    pub fn deinit(self: *Config, allocator: Allocator) void {
        allocator.free(self.entries);
    }
};

const Entry = struct {
    value: i32,
};

fn parseEntries(allocator: Allocator, content: []const u8) ![]Entry {
    _ = content;
    const entries = try allocator.alloc(Entry, 2);
    entries[0] = Entry{ .value = 1 };
    entries[1] = Entry{ .value = 2 };
    return entries;
}

test "library function pattern" {
    const allocator = std.testing.allocator;

    const file_content = "dummy content";
    var config = Config{
        .entries = try parseEntries(allocator, file_content),
    };
    defer config.deinit(allocator);

    try std.testing.expect(config.entries.len == 2);
}

// Test: multiple allocations in test
test "complex data structure" {
    const allocator = std.testing.allocator;

    var list: std.ArrayList(i32) = .{};
    defer list.deinit(allocator);

    const item1 = try allocator.create(i32);
    defer allocator.destroy(item1);

    const item2 = try allocator.create(i32);
    defer allocator.destroy(item2);

    item1.* = 10;
    item2.* = 20;
    try list.append(allocator, item1.*);
    try list.append(allocator, item2.*);

    try std.testing.expect(list.items[0] == 10);
    try std.testing.expect(list.items[1] == 20);
}
