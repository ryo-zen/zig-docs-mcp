// Lazy Initialization Pattern in Zig
// Shows how to defer expensive initialization until first use

const std = @import("std");

// Example 1: Simple lazy with optional
const LazyValue = struct {
    cached: ?i32 = null,
    computation_count: usize = 0,

    fn expensiveComputation(self: *@This()) i32 {
        self.computation_count += 1;
        // Simulate expensive work
        std.debug.print("    💤 Computing expensive value...\n", .{});
        return 42;
    }

    pub fn get(self: *@This()) i32 {
        if (self.cached) |value| {
            return value; // Already computed
        }

        // Lazy initialization on first access
        const value = self.expensiveComputation();
        self.cached = value;
        return value;
    }
};

test "Lazy Init: Simple optional-based caching" {
    std.debug.print("\n💤 Test: Simple lazy initialization\n", .{});

    var lazy = LazyValue{};

    // First access triggers computation
    const value1 = lazy.get();
    try std.testing.expectEqual(42, value1);
    try std.testing.expectEqual(1, lazy.computation_count);

    // Subsequent accesses use cached value
    const value2 = lazy.get();
    try std.testing.expectEqual(42, value2);
    try std.testing.expectEqual(1, lazy.computation_count); // Still 1!

    std.debug.print("  ✅ PASS: Expensive computation only happens once\n", .{});
}

// Example 2: Lazy with allocation
const LazyString = struct {
    allocator: std.mem.Allocator,
    cached: ?[]const u8 = null,
    call_count: u32 = 0,

    pub fn deinit(self: *@This()) void {
        if (self.cached) |str| {
            self.allocator.free(str);
        }
    }

    fn buildString(self: *@This()) ![]const u8 {
        // Simulate expensive string building
        self.call_count += 1;
        return try std.fmt.allocPrint(
            self.allocator,
            "Expensive result: {d}",
            .{self.call_count},
        );
    }

    pub fn get(self: *@This()) ![]const u8 {
        if (self.cached) |value| {
            return value;
        }

        const value = try self.buildString();
        self.cached = value;
        return value;
    }
};

test "Lazy Init: With memory allocation" {
    std.debug.print("\n💤 Test: Lazy initialization with allocation\n", .{});

    var lazy = LazyString{ .allocator = std.testing.allocator };
    defer lazy.deinit();

    // First access allocates
    const str1 = try lazy.get();
    try std.testing.expect(std.mem.startsWith(u8, str1, "Expensive result:"));

    // Second access returns same pointer
    const str2 = try lazy.get();
    try std.testing.expectEqual(@intFromPtr(str1.ptr), @intFromPtr(str2.ptr));

    std.debug.print("  ✅ PASS: Allocated value cached and reused\n", .{});
}

// Example 3: Lazy configuration loading
const Config = struct {
    database_url: []const u8,
    api_key: []const u8,
};

const ConfigManager = struct {
    allocator: std.mem.Allocator,
    config: ?Config = null,
    loaded: bool = false,

    pub fn deinit(self: *@This()) void {
        if (self.config) |cfg| {
            self.allocator.free(cfg.database_url);
            self.allocator.free(cfg.api_key);
        }
    }

    fn loadFromFile(self: *@This()) !Config {
        // Simulate reading from file
        std.debug.print("    📁 Loading config from file...\n", .{});

        return Config{
            .database_url = try self.allocator.dupe(u8, "postgres://localhost/db"),
            .api_key = try self.allocator.dupe(u8, "secret-key-123"),
        };
    }

    pub fn get(self: *@This()) !Config {
        if (self.config) |cfg| {
            return cfg;
        }

        const cfg = try self.loadFromFile();
        self.config = cfg;
        return cfg;
    }
};

test "Lazy Init: Configuration loading" {
    std.debug.print("\n💤 Test: Lazy configuration loading\n", .{});

    var manager = ConfigManager{ .allocator = std.testing.allocator };
    defer manager.deinit();

    // Config not loaded yet
    try std.testing.expect(manager.config == null);

    // First access loads config
    const cfg1 = try manager.get();
    try std.testing.expectEqualStrings("postgres://localhost/db", cfg1.database_url);

    // Second access returns cached config
    const cfg2 = try manager.get();
    try std.testing.expectEqual(@intFromPtr(cfg1.database_url.ptr), @intFromPtr(cfg2.database_url.ptr));

    std.debug.print("  ✅ PASS: Config loaded once, then cached\n", .{});
}

// Example 4: Lazy with error handling
const LazyResource = struct {
    allocator: std.mem.Allocator,
    resource: ?[]u8 = null,
    error_occurred: bool = false,

    pub fn deinit(self: *@This()) void {
        if (self.resource) |res| {
            self.allocator.free(res);
        }
    }

    fn initialize(self: *@This(), fail: bool) ![]u8 {
        if (fail) {
            self.error_occurred = true;
            return error.InitializationFailed;
        }

        return try self.allocator.alloc(u8, 100);
    }

    pub fn get(self: *@This(), fail: bool) ![]u8 {
        // If previous initialization failed, retry
        if (self.error_occurred) {
            self.error_occurred = false;
            self.resource = null;
        }

        if (self.resource) |res| {
            return res;
        }

        const res = try self.initialize(fail);
        self.resource = res;
        return res;
    }
};

test "Lazy Init: With error handling and retry" {
    std.debug.print("\n💤 Test: Lazy initialization with errors\n", .{});

    var lazy = LazyResource{ .allocator = std.testing.allocator };
    defer lazy.deinit();

    // First attempt fails
    const result1 = lazy.get(true);
    try std.testing.expectError(error.InitializationFailed, result1);

    // Retry succeeds
    const result2 = try lazy.get(false);
    try std.testing.expectEqual(100, result2.len);

    // Subsequent calls use cached value
    const result3 = try lazy.get(true); // Even though fail=true, uses cache
    try std.testing.expectEqual(@intFromPtr(result2.ptr), @intFromPtr(result3.ptr));

    std.debug.print("  ✅ PASS: Failed initialization can be retried\n", .{});
}

// Example 5: Thread-safe lazy (simplified for demonstration)
const ThreadSafeLazy = struct {
    value: ?i32 = null,
    mutex: std.Io.Mutex = .init,

    pub fn get(self: *@This()) i32 {
        // Check without lock first (double-checked locking)
        if (self.value) |v| return v;

        const io = std.testing.io;
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        // Check again after acquiring lock
        if (self.value) |v| return v;

        // Initialize under lock
        const v = 42; // Expensive computation
        self.value = v;
        return v;
    }
};

test "Lazy Init: Thread-safe pattern" {
    std.debug.print("\n💤 Test: Thread-safe lazy initialization\n", .{});

    var lazy = ThreadSafeLazy{};

    const v1 = lazy.get();
    const v2 = lazy.get();

    try std.testing.expectEqual(42, v1);
    try std.testing.expectEqual(v1, v2);

    std.debug.print("  ✅ PASS: Double-checked locking pattern demonstrated\n", .{});
}

// Example 6: Lazy with dependencies
const CachedData = struct {
    allocator: std.mem.Allocator,
    input_hash: u64,
    cached_result: ?[]u8 = null,
    cached_hash: ?u64 = null,

    pub fn deinit(self: *@This()) void {
        if (self.cached_result) |res| {
            self.allocator.free(res);
        }
    }

    pub fn get(self: *@This(), input: []const u8) ![]u8 {
        const hash = std.hash.Wyhash.hash(0, input);

        // Invalidate cache if input changed
        if (self.cached_hash) |cached| {
            if (cached != hash) {
                if (self.cached_result) |res| {
                    self.allocator.free(res);
                }
                self.cached_result = null;
                self.cached_hash = null;
            }
        }

        if (self.cached_result) |res| {
            return res;
        }

        // Compute new result
        const result = try self.allocator.dupe(u8, input);
        self.cached_result = result;
        self.cached_hash = hash;
        return result;
    }
};

test "Lazy Init: With dependency invalidation" {
    std.debug.print("\n💤 Test: Lazy with cache invalidation\n", .{});

    var cache = CachedData{
        .allocator = std.testing.allocator,
        .input_hash = 0,
    };
    defer cache.deinit();

    // First computation
    const result1 = try cache.get("hello");
    try std.testing.expectEqualStrings("hello", result1);
    const ptr1 = @intFromPtr(result1.ptr);

    // Same input, uses cache
    const result2 = try cache.get("hello");
    try std.testing.expectEqual(ptr1, @intFromPtr(result2.ptr));

    // Different input, invalidates cache and computes new result
    const result3 = try cache.get("world");
    try std.testing.expectEqualStrings("world", result3);
    // Note: Can't reliably test pointer difference as allocator may reuse memory

    std.debug.print("  ✅ PASS: Cache invalidates on dependency change\n", .{});
}

test "Lazy Init: Summary" {
    std.debug.print("\n💤 Summary: Lazy Initialization Patterns\n", .{});
    std.debug.print("  ✅ Use optional types (?T) for nullable lazy values\n", .{});
    std.debug.print("  ✅ Check cached value before computing\n", .{});
    std.debug.print("  ✅ Handle allocation with proper cleanup\n", .{});
    std.debug.print("  ✅ Consider thread safety for concurrent access\n", .{});
    std.debug.print("  ✅ Support cache invalidation when dependencies change\n", .{});
}
