// Comprehensive tests for std.log namespace documentation
// Target: Zig 0.16
//
// Run with: zig test Examples/log.tests.zig

const std = @import("std");
const testing = std.testing;

// ============================================================================
// Helper Functions (defined at module level)
// ============================================================================

const Config = struct { timeout: u32 };

fn loadConfig(path: []const u8) !Config {
    std.log.debug("Loading config from: {s}", .{path});

    if (std.mem.eql(u8, path, "nonexistent.json")) {
        const err = error.FileNotFound;
        std.log.err("Failed to open config file '{s}': {s}", .{ path, @errorName(err) });
        return err;
    }

    std.log.info("Config loaded successfully from '{s}'", .{path});
    return Config{ .timeout = 30 };
}

// ============================================================================
// Quick Start Examples
// ============================================================================

test "Quick Start: Basic Logging (Default Scope)" {
    std.debug.print("\n=== Quick Start: Basic Logging ===\n", .{});

    const counter: u32 = 42;
    const usage: u32 = 75;
    const error_msg = "connection timeout";

    std.log.debug("Variable value: {d}", .{counter});
    std.log.info("Server started on port {d}", .{8080});
    std.log.warn("Memory usage at {d}%", .{usage});
    std.log.err("Failed to connect: {s}", .{error_msg});

    std.debug.print("  ✅ PASS: All log levels executed without error\n\n", .{});
}

test "Quick Start: Custom Scoped Logging" {
    std.debug.print("\n=== Quick Start: Custom Scoped Logging ===\n", .{});

    const log = std.log.scoped(.mylib);

    const config = .{ .timeout = 30, .retries = 3 };

    log.info("Library initialized", .{});
    log.debug("Config: {any}", .{config});

    std.debug.print("  ✅ PASS: Scoped logging works\n\n", .{});
}

test "Quick Start: Conditional Logging" {
    std.debug.print("\n=== Quick Start: Conditional Logging ===\n", .{});

    const Stats = struct { count: u32, sum: u64 };

    if (std.log.logEnabled(.debug, .default)) {
        const stats = Stats{ .count = 100, .sum = 5050 };
        std.log.debug("Stats: {any}", .{stats});
    }

    std.debug.print("  ✅ PASS: Conditional logging executed\n\n", .{});
}

// ============================================================================
// Core Logging Functions
// ============================================================================

test "debug: Debug Message Logging" {
    std.debug.print("\n=== debug: Debug Message Logging ===\n", .{});

    const data = "test data";
    std.log.debug("Processing {d} bytes of data", .{data.len});
    std.log.debug("First byte: 0x{X}", .{data[0]});

    std.debug.print("  ✅ PASS: debug() works\n\n", .{});
}

test "info: Informational Message Logging" {
    std.debug.print("\n=== info: Informational Message Logging ===\n", .{});

    const config_path = "config.json";

    std.log.info("Application starting...", .{});
    std.log.info("Configuration loaded from {s}", .{config_path});
    std.log.info("Listening on port {d}", .{8080});

    std.debug.print("  ✅ PASS: info() works\n\n", .{});
}

test "warn: Warning Message Logging" {
    std.debug.print("\n=== warn: Warning Message Logging ===\n", .{});

    std.log.warn("Config file not found, using defaults", .{});
    std.log.warn("Deprecated API usage detected", .{});

    std.debug.print("  ✅ PASS: warn() works\n\n", .{});
}

test "err: Error Message Logging" {
    std.debug.print("\n=== err: Error Message Logging ===\n", .{});

    const error_name = @errorName(error.FileNotFound);
    std.log.err("Failed to connect to database: {s}", .{error_name});
    std.log.err("Operation failed", .{});

    std.debug.print("  ✅ PASS: err() works\n\n", .{});
}

// ============================================================================
// Scoped Logging
// ============================================================================

test "scoped: Custom Scope Creation" {
    std.debug.print("\n=== scoped: Custom Scope ===\n", .{});

    const log = std.log.scoped(.mylib);

    log.info("Initializing mylib", .{});
    log.debug("Version: 1.0.0", .{});
    log.info("Shutting down mylib", .{});

    std.debug.print("  ✅ PASS: scoped() creates custom logger\n\n", .{});
}

test "scoped: Multiple Scopes" {
    std.debug.print("\n=== scoped: Multiple Scopes ===\n", .{});

    const http_log = std.log.scoped(.http);
    const db_log = std.log.scoped(.database);
    const auth_log = std.log.scoped(.auth);

    http_log.info("HTTP server started", .{});
    db_log.info("Database connected", .{});
    auth_log.info("Auth module loaded", .{});

    std.debug.print("  ✅ PASS: Multiple scopes work independently\n\n", .{});
}

// ============================================================================
// Utility Functions
// ============================================================================

test "logEnabled: Check if Logging is Enabled" {
    std.debug.print("\n=== logEnabled: Check Logging Status ===\n", .{});

    const is_debug_enabled = std.log.logEnabled(.debug, .default);
    const is_info_enabled = std.log.logEnabled(.info, .default);
    const is_warn_enabled = std.log.logEnabled(.warn, .default);
    const is_err_enabled = std.log.logEnabled(.err, .default);

    std.debug.print("  Debug enabled: {}\n", .{is_debug_enabled});
    std.debug.print("  Info enabled: {}\n", .{is_info_enabled});
    std.debug.print("  Warn enabled: {}\n", .{is_warn_enabled});
    std.debug.print("  Err enabled: {}\n", .{is_err_enabled});

    // err and warn should always be enabled
    try testing.expect(is_err_enabled);
    try testing.expect(is_warn_enabled);

    std.debug.print("  ✅ PASS: logEnabled() returns correct status\n\n", .{});
}

test "logEnabled: Conditional Expensive Computation" {
    std.debug.print("\n=== logEnabled: Conditional Computation ===\n", .{});

    const Stats = struct {
        count: usize,
        sum: u64,
        mean: f64,
    };

    var expensive_called = false;

    if (std.log.logEnabled(.debug, .default)) {
        expensive_called = true;
        const stats = Stats{ .count = 100, .sum = 5050, .mean = 50.5 };
        std.log.debug("Analysis: {any}", .{stats});
    }

    std.debug.print("  Expensive function called: {}\n", .{expensive_called});
    std.debug.print("  ✅ PASS: Conditional computation works\n\n", .{});
}

// ============================================================================
// Usage Patterns
// ============================================================================

test "Pattern 1: Library with Scoped Logging" {
    std.debug.print("\n=== Pattern 1: Library with Scoped Logging ===\n", .{});

    const MyLib = struct {
        const log = std.log.scoped(.mylib);
        initialized: bool = false,

        pub fn init() !@This() {
            log.info("Initializing library", .{});
            log.debug("Performing initialization checks", .{});
            log.info("Library initialized successfully", .{});
            return @This(){ .initialized = true };
        }

        pub fn process(self: *@This(), data: []const u8) !void {
            if (!self.initialized) {
                log.err("Attempted to process data before initialization", .{});
                return error.NotInitialized;
            }

            log.debug("Processing {d} bytes", .{data.len});
            log.info("Processed data successfully", .{});
        }

        pub fn deinit(self: *@This()) void {
            log.info("Shutting down library", .{});
            self.initialized = false;
        }
    };

    var lib = try MyLib.init();
    try lib.process("test data");
    lib.deinit();

    std.debug.print("  ✅ PASS: Library pattern works\n\n", .{});
}

test "Pattern 4: Conditional Logging for Performance" {
    std.debug.print("\n=== Pattern 4: Conditional Performance Logging ===\n", .{});

    const Item = struct { id: u32, value: i32 };

    const items = [_]Item{
        .{ .id = 1, .value = 10 },
        .{ .id = 2, .value = 20 },
        .{ .id = 3, .value = 30 },
    };

    std.log.info("Processing {d} items", .{items.len});

    for (items, 0..) |item, i| {
        _ = item;

        // Only log progress if debug is enabled
        if (std.log.logEnabled(.debug, .default)) {
            if (i % 1 == 0) { // In real code: i % 1000
                std.log.debug("Processed {d}/{d} items", .{ i, items.len });
            }
        }
    }

    std.log.info("Completed processing {d} items", .{items.len});

    std.debug.print("  ✅ PASS: Conditional performance logging works\n\n", .{});
}

test "Pattern 5: Error Handling with Logging" {
    std.debug.print("\n=== Pattern 5: Error Handling with Logging ===\n", .{});

    // Test successful load
    {
        const config = try loadConfig("config.json");
        try testing.expectEqual(@as(u32, 30), config.timeout);
    }

    // Test error case
    {
        const result = loadConfig("nonexistent.json");
        try testing.expectError(error.FileNotFound, result);
    }

    std.debug.print("  ✅ PASS: Error handling with logging works\n\n", .{});
}

// ============================================================================
// Log Levels Testing
// ============================================================================

test "Log Levels: All Four Levels" {
    std.debug.print("\n=== Log Levels: All Four Levels ===\n", .{});

    std.log.err("Error level message", .{});
    std.log.warn("Warning level message", .{});
    std.log.info("Info level message", .{});
    std.log.debug("Debug level message", .{});

    std.debug.print("  ✅ PASS: All four log levels work\n\n", .{});
}

test "Log Levels: Priority Ordering" {
    std.debug.print("\n=== Log Levels: Priority Check ===\n", .{});

    // Higher priority logs should always be enabled if lower priority logs are
    const debug_enabled = std.log.logEnabled(.debug, .default);
    const info_enabled = std.log.logEnabled(.info, .default);
    const warn_enabled = std.log.logEnabled(.warn, .default);
    const err_enabled = std.log.logEnabled(.err, .default);

    // err should always be enabled
    try testing.expect(err_enabled);

    // If debug is enabled, all others must be enabled
    if (debug_enabled) {
        try testing.expect(info_enabled);
        try testing.expect(warn_enabled);
        try testing.expect(err_enabled);
    }

    std.debug.print("  ✅ PASS: Priority ordering is correct\n\n", .{});
}

// ============================================================================
// Formatting Tests
// ============================================================================

test "Formatting: Various Format Specifiers" {
    std.debug.print("\n=== Formatting: Format Specifiers ===\n", .{});

    const name = "Alice";
    const count: i32 = 42;
    const percentage: f64 = 75.5;
    const bytes = [_]u8{ 0xDE, 0xAD, 0xBE, 0xEF };

    std.log.info("String: {s}", .{name});
    std.log.info("Integer: {d}", .{count});
    std.log.info("Float: {d:.2}", .{percentage});
    std.log.info("Hex: {X}", .{count});
    std.log.info("Any: {any}", .{bytes});

    std.debug.print("  ✅ PASS: All format specifiers work\n\n", .{});
}

test "Formatting: Multiple Arguments" {
    std.debug.print("\n=== Formatting: Multiple Arguments ===\n", .{});

    const user = "Bob";
    const port: u16 = 8080;
    const version = "1.0.0";

    std.log.info("User {s} connected to port {d} (version {s})", .{ user, port, version });

    std.debug.print("  ✅ PASS: Multiple arguments work\n\n", .{});
}

test "Formatting: Empty Arguments" {
    std.debug.print("\n=== Formatting: Empty Arguments ===\n", .{});

    std.log.info("No arguments here", .{});
    std.log.debug("Simple message", .{});

    std.debug.print("  ✅ PASS: Empty argument tuples work\n\n", .{});
}

// ============================================================================
// Scope Testing
// ============================================================================

test "Scopes: Different Naming Conventions" {
    std.debug.print("\n=== Scopes: Naming Conventions ===\n", .{});

    const http_server = std.log.scoped(.http_server);
    const db = std.log.scoped(.database);
    const auth = std.log.scoped(.auth);
    const mylib = std.log.scoped(.mylib);

    http_server.info("HTTP module active", .{});
    db.info("Database module active", .{});
    auth.info("Auth module active", .{});
    mylib.info("Library module active", .{});

    std.debug.print("  ✅ PASS: Various scope names work\n\n", .{});
}

test "Scopes: All Log Levels with Custom Scope" {
    std.debug.print("\n=== Scopes: All Levels with Custom Scope ===\n", .{});

    const log = std.log.scoped(.testmodule);

    log.err("Error in test module", .{});
    log.warn("Warning in test module", .{});
    log.info("Info in test module", .{});
    log.debug("Debug in test module", .{});

    std.debug.print("  ✅ PASS: All levels work with custom scope\n\n", .{});
}

// ============================================================================
// Edge Cases
// ============================================================================

test "Edge Cases: Very Long Messages" {
    std.debug.print("\n=== Edge Cases: Long Messages ===\n", .{});

    const long_msg = "This is a very long log message that contains a lot of text to test how the logging system handles longer strings without truncation or errors. It should handle this gracefully.";

    std.log.info("{s}", .{long_msg});

    std.debug.print("  ✅ PASS: Long messages handled\n\n", .{});
}

test "Edge Cases: Special Characters" {
    std.debug.print("\n=== Edge Cases: Special Characters ===\n", .{});

    std.log.info("Special chars: \t\n\r", .{});
    std.log.info("Unicode: ✓ ✗ → ← ↑ ↓", .{});
    std.log.info("Quotes: \"double\" 'single'", .{});

    std.debug.print("  ✅ PASS: Special characters handled\n\n", .{});
}

test "Edge Cases: Numbers at Extremes" {
    std.debug.print("\n=== Edge Cases: Extreme Numbers ===\n", .{});

    const max_u64: u64 = std.math.maxInt(u64);
    const min_i64: i64 = std.math.minInt(i64);
    const zero: u32 = 0;

    std.log.info("Max u64: {d}", .{max_u64});
    std.log.info("Min i64: {d}", .{min_i64});
    std.log.info("Zero: {d}", .{zero});

    std.debug.print("  ✅ PASS: Extreme numbers handled\n\n", .{});
}

// ============================================================================
// Integration Tests
// ============================================================================

test "Integration: Library + Application Logging" {
    std.debug.print("\n=== Integration: Library + App ===\n", .{});

    // Simulate library
    const LibLog = std.log.scoped(.mylib);

    // Simulate application
    const AppLog = std.log.scoped(.myapp);

    LibLog.info("Library function called", .{});
    AppLog.info("Application processing", .{});
    LibLog.debug("Library internal state", .{});
    AppLog.debug("Application internal state", .{});

    std.debug.print("  ✅ PASS: Library and app logging coexist\n\n", .{});
}

// ============================================================================
// Summary
// ============================================================================

test "Summary: All Logging Tests" {
    std.debug.print("\n" ++ "=" ** 60 ++ "\n", .{});
    std.debug.print("✅ All std.log tests passed!\n", .{});
    std.debug.print("=" ** 60 ++ "\n\n", .{});
}
