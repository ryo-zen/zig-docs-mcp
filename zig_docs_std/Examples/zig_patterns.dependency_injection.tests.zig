// Dependency Injection Pattern in Zig
// Shows how to pass dependencies explicitly for testability and flexibility

const std = @import("std");

// Example 1: Allocator Injection (most common DI in Zig)
fn processData(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    // Function receives allocator, doesn't create it
    const result = try allocator.alloc(u8, input.len);
    @memcpy(result, input);
    return result;
}

test "DI: Allocator injection for testability" {
    std.debug.print("\n💉 Test: Allocator injection\n", .{});

    // Test with leak-detecting allocator
    const result = try processData(std.testing.allocator, "hello");
    defer std.testing.allocator.free(result);

    try std.testing.expectEqualStrings("hello", result);

    std.debug.print("  ✅ PASS: Function receives allocator, caller controls strategy\n", .{});
}

// Example 2: Interface Injection with fat pointers
const Logger = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        log: *const fn (ptr: *anyopaque, message: []const u8) void,
    };

    pub fn log(self: Logger, message: []const u8) void {
        self.vtable.log(self.ptr, message);
    }
};

const ConsoleLogger = struct {
    prefix: []const u8,

    pub fn logger(self: *ConsoleLogger) Logger {
        return .{
            .ptr = self,
            .vtable = &.{
                .log = logImpl,
            },
        };
    }

    fn logImpl(ptr: *anyopaque, message: []const u8) void {
        const self: *ConsoleLogger = @ptrCast(@alignCast(ptr));
        std.debug.print("[{s}] {s}\n", .{ self.prefix, message });
    }
};

const TestLogger = struct {
    messages: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) TestLogger {
        return .{
            .messages = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *TestLogger) void {
        for (self.messages.items) |msg| {
            self.allocator.free(msg);
        }
        self.messages.deinit(self.allocator);
    }

    pub fn logger(self: *TestLogger) Logger {
        return .{
            .ptr = self,
            .vtable = &.{
                .log = logImpl,
            },
        };
    }

    fn logImpl(ptr: *anyopaque, message: []const u8) void {
        const self: *TestLogger = @ptrCast(@alignCast(ptr));
        const owned = self.allocator.dupe(u8, message) catch unreachable;
        self.messages.append(self.allocator, owned) catch unreachable;
    }
};

fn performTask(logger: Logger, task_name: []const u8) void {
    logger.log("Task started");
    // Do work...
    var buf: [100]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "Task '{s}' completed", .{task_name}) catch unreachable;
    logger.log(msg);
}

test "DI: Logger interface injection" {
    std.debug.print("\n💉 Test: Interface injection\n", .{});

    // Test with capturing logger
    var test_logger = TestLogger.init(std.testing.allocator);
    defer test_logger.deinit();

    performTask(test_logger.logger(), "data_processing");

    // Verify logged messages
    try std.testing.expectEqual(2, test_logger.messages.items.len);
    try std.testing.expectEqualStrings("Task started", test_logger.messages.items[0]);
    try std.testing.expect(std.mem.indexOf(u8, test_logger.messages.items[1], "completed") != null);

    std.debug.print("  ✅ PASS: Interface injection enables testing with test double\n", .{});
}

// Example 3: Configuration Injection
const ApiClient = struct {
    allocator: std.mem.Allocator,
    base_url: []const u8,
    timeout_ms: u32,

    pub fn init(allocator: std.mem.Allocator, config: Config) ApiClient {
        return .{
            .allocator = allocator,
            .base_url = config.base_url,
            .timeout_ms = config.timeout_ms,
        };
    }

    pub fn get(self: ApiClient, path: []const u8) ![]u8 {
        // Simulate HTTP GET
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}{s}",
            .{ self.base_url, path },
        );
        defer self.allocator.free(url);

        return try self.allocator.dupe(u8, url);
    }

    const Config = struct {
        base_url: []const u8,
        timeout_ms: u32 = 5000,
    };
};

test "DI: Configuration injection" {
    std.debug.print("\n💉 Test: Configuration injection\n", .{});

    // Production config
    const prod_config = ApiClient.Config{
        .base_url = "https://api.production.com",
        .timeout_ms = 10000,
    };

    var prod_client = ApiClient.init(std.testing.allocator, prod_config);
    const prod_url = try prod_client.get("/users");
    defer std.testing.allocator.free(prod_url);

    try std.testing.expectEqualStrings("https://api.production.com/users", prod_url);

    // Test config
    const test_config = ApiClient.Config{
        .base_url = "http://localhost:8080",
    };

    var test_client = ApiClient.init(std.testing.allocator, test_config);
    const test_url = try test_client.get("/users");
    defer std.testing.allocator.free(test_url);

    try std.testing.expectEqualStrings("http://localhost:8080/users", test_url);

    std.debug.print("  ✅ PASS: Configuration injection allows environment-specific behavior\n", .{});
}

// Example 4: Service Injection
const Database = struct {
    pub fn query(self: *Database, sql: []const u8) ![][]const u8 {
        _ = self;
        _ = sql;
        // Stub implementation
        return &[_][]const u8{};
    }
};

const UserService = struct {
    db: *Database,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, db: *Database) UserService {
        return .{
            .db = db,
            .allocator = allocator,
        };
    }

    pub fn findUser(self: *UserService, id: u32) !?[]const u8 {
        const sql = try std.fmt.allocPrint(
            self.allocator,
            "SELECT * FROM users WHERE id = {d}",
            .{id},
        );
        defer self.allocator.free(sql);

        _ = try self.db.query(sql);

        // Stub: just return the query
        return try self.allocator.dupe(u8, sql);
    }
};

test "DI: Service injection for composition" {
    std.debug.print("\n💉 Test: Service injection\n", .{});

    var db = Database{};

    var user_service = UserService.init(std.testing.allocator, &db);
    const query = try user_service.findUser(123);
    defer if (query) |q| std.testing.allocator.free(q);

    try std.testing.expect(query != null);
    try std.testing.expect(std.mem.indexOf(u8, query.?, "123") != null);

    std.debug.print("  ✅ PASS: Service injection enables composable architecture\n", .{});
}

test "DI: Benefits summary" {
    std.debug.print("\n💉 Summary: Dependency Injection Benefits\n", .{});
    std.debug.print("  ✅ Testability: Inject test doubles for testing\n", .{});
    std.debug.print("  ✅ Flexibility: Caller controls implementation\n", .{});
    std.debug.print("  ✅ Composability: Build complex systems from simple parts\n", .{});
    std.debug.print("  ✅ No global state: Explicit dependencies, no singletons\n", .{});
}
