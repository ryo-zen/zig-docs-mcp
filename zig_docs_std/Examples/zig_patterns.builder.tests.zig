// Builder Pattern in Zig
// Shows how to implement builder-style APIs using struct defaults and methods

const std = @import("std");

// Example 1: HTTP Request Builder
const HttpRequest = struct {
    method: []const u8 = "GET",
    url: []const u8,
    headers: std.StringHashMap([]const u8),
    body: ?[]const u8 = null,
    timeout_ms: u32 = 5000,
    follow_redirects: bool = true,

    pub fn init(allocator: std.mem.Allocator, url: []const u8) HttpRequest {
        return .{
            .url = url,
            .headers = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.headers.deinit();
    }

    // Builder-style methods
    pub fn withMethod(self: @This(), method: []const u8) @This() {
        var result = self;
        result.method = method;
        return result;
    }

    pub fn withTimeout(self: @This(), ms: u32) @This() {
        var result = self;
        result.timeout_ms = ms;
        return result;
    }

    pub fn withBody(self: @This(), body: []const u8) @This() {
        var result = self;
        result.body = body;
        return result;
    }

    pub fn noRedirects(self: @This()) @This() {
        var result = self;
        result.follow_redirects = false;
        return result;
    }
};

test "Builder Pattern: HTTP Request" {
    std.debug.print("\n🏗️  Test: HTTP Request Builder\n", .{});

    var request = HttpRequest.init(std.testing.allocator, "https://api.example.com/data");
    defer request.deinit();

    // Default values work
    try std.testing.expectEqualStrings("GET", request.method);
    try std.testing.expectEqual(5000, request.timeout_ms);
    try std.testing.expect(request.follow_redirects);

    std.debug.print("  ✅ Default values set correctly\n", .{});

    // Builder-style chaining
    request = request
        .withMethod("POST")
        .withTimeout(10000)
        .withBody("{\"key\": \"value\"}")
        .noRedirects();

    try std.testing.expectEqualStrings("POST", request.method);
    try std.testing.expectEqual(10000, request.timeout_ms);
    try std.testing.expectEqualStrings("{\"key\": \"value\"}", request.body.?);
    try std.testing.expect(!request.follow_redirects);

    std.debug.print("  ✅ PASS: Builder pattern provides fluent API\n", .{});
}

// Example 2: Query Builder
const Query = struct {
    table: []const u8,
    columns: []const []const u8 = &.{},
    where_clause: ?[]const u8 = null,
    order_by: ?[]const u8 = null,
    limit: ?usize = null,

    pub fn select(columns: []const []const u8, from_table: []const u8) Query {
        return .{
            .table = from_table,
            .columns = columns,
        };
    }

    pub fn where(self: @This(), clause: []const u8) Query {
        var result = self;
        result.where_clause = clause;
        return result;
    }

    pub fn orderBy(self: @This(), column: []const u8) Query {
        var result = self;
        result.order_by = column;
        return result;
    }

    pub fn limitTo(self: @This(), n: usize) Query {
        var result = self;
        result.limit = n;
        return result;
    }

    pub fn build(self: Query, allocator: std.mem.Allocator) ![]u8 {
        var sql: std.ArrayList(u8) = .empty;
        defer sql.deinit(allocator);

        try sql.appendSlice(allocator, "SELECT ");
        if (self.columns.len == 0) {
            try sql.appendSlice(allocator, "*");
        } else {
            for (self.columns, 0..) |col, i| {
                if (i > 0) try sql.appendSlice(allocator, ", ");
                try sql.appendSlice(allocator, col);
            }
        }

        try sql.appendSlice(allocator, " FROM ");
        try sql.appendSlice(allocator, self.table);

        if (self.where_clause) |clause| {
            try sql.appendSlice(allocator, " WHERE ");
            try sql.appendSlice(allocator, clause);
        }

        if (self.order_by) |col| {
            try sql.appendSlice(allocator, " ORDER BY ");
            try sql.appendSlice(allocator, col);
        }

        if (self.limit) |n| {
            var buf: [50]u8 = undefined;
            const limit_str = try std.fmt.bufPrint(&buf, " LIMIT {d}", .{n});
            try sql.appendSlice(allocator, limit_str);
        }

        return sql.toOwnedSlice(allocator);
    }
};

test "Builder Pattern: SQL Query Builder" {
    std.debug.print("\n🏗️  Test: SQL Query Builder\n", .{});

    const columns = [_][]const u8{ "name", "age", "email" };

    const query = Query.select(&columns, "users")
        .where("age > 18")
        .orderBy("name")
        .limitTo(10);

    const sql = try query.build(std.testing.allocator);
    defer std.testing.allocator.free(sql);

    const expected = "SELECT name, age, email FROM users WHERE age > 18 ORDER BY name LIMIT 10";
    try std.testing.expectEqualStrings(expected, sql);

    std.debug.print("  ✅ PASS: Query builder generates correct SQL\n", .{});
}

// Example 3: Configuration Builder
const ServerConfig = struct {
    host: []const u8 = "localhost",
    port: u16 = 8080,
    max_connections: usize = 100,
    read_timeout_ms: u32 = 5000,
    write_timeout_ms: u32 = 5000,
    enable_compression: bool = false,
    enable_keepalive: bool = true,
    log_level: LogLevel = .info,

    const LogLevel = enum { debug, info, warn, err };

    pub fn onPort(self: @This(), port: u16) @This() {
        var result = self;
        result.port = port;
        return result;
    }

    pub fn atHost(self: @This(), host: []const u8) @This() {
        var result = self;
        result.host = host;
        return result;
    }

    pub fn withMaxConnections(self: @This(), max: usize) @This() {
        var result = self;
        result.max_connections = max;
        return result;
    }

    pub fn withTimeouts(self: @This(), read_ms: u32, write_ms: u32) @This() {
        var result = self;
        result.read_timeout_ms = read_ms;
        result.write_timeout_ms = write_ms;
        return result;
    }

    pub fn withCompression(self: @This()) @This() {
        var result = self;
        result.enable_compression = true;
        return result;
    }

    pub fn withLogLevel(self: @This(), level: LogLevel) @This() {
        var result = self;
        result.log_level = level;
        return result;
    }
};

test "Builder Pattern: Server Configuration" {
    std.debug.print("\n🏗️  Test: Server Configuration Builder\n", .{});

    // Start with defaults
    const default_config: ServerConfig = .{};
    try std.testing.expectEqualStrings("localhost", default_config.host);
    try std.testing.expectEqual(8080, default_config.port);

    // Build custom configuration
    const base_config: ServerConfig = .{};
    const prod_config = base_config
        .atHost("0.0.0.0")
        .onPort(443)
        .withMaxConnections(1000)
        .withTimeouts(30000, 30000)
        .withCompression()
        .withLogLevel(.warn);

    try std.testing.expectEqualStrings("0.0.0.0", prod_config.host);
    try std.testing.expectEqual(443, prod_config.port);
    try std.testing.expectEqual(1000, prod_config.max_connections);
    try std.testing.expect(prod_config.enable_compression);
    try std.testing.expectEqual(.warn, prod_config.log_level);

    std.debug.print("  ✅ PASS: Configuration builder is flexible and clear\n", .{});
}

test "Builder Pattern: Summary" {
    std.debug.print("\n🏗️  Summary: Builder Pattern in Zig\n", .{});
    std.debug.print("  ✅ Use struct defaults for sensible initial values\n", .{});
    std.debug.print("  ✅ Provide builder methods that return modified copies\n", .{});
    std.debug.print("  ✅ Method chaining creates fluent, readable APIs\n", .{});
    std.debug.print("  ✅ No inheritance or complex builder classes needed\n", .{});
}
