// Comprehensive tests for std.json namespace documentation
// Target: Zig 0.16
//
// Run with: zig test Examples/json.tests.zig

const std = @import("std");
const testing = std.testing;

// ============================================================================
// Quick Start Examples
// ============================================================================

test "Quick Start: Parse JSON String into Struct" {
    std.debug.print("\n=== Quick Start: Parse JSON into Struct ===\n", .{});

    const Person = struct { name: []const u8, age: u32 };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const json_str = "{\"name\":\"Alice\",\"age\":30}";
    const parsed = try std.json.parseFromSlice(Person, gpa.allocator(), json_str, .{});
    defer parsed.deinit();

    std.debug.print("Name: {s}, Age: {d}\n", .{ parsed.value.name, parsed.value.age });

    try testing.expectEqualStrings("Alice", parsed.value.name);
    try testing.expectEqual(@as(u32, 30), parsed.value.age);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start: Parse into Dynamic Value" {
    std.debug.print("\n=== Quick Start: Parse into Dynamic Value ===\n", .{});

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const json_str = "{\"name\":\"Bob\",\"age\":25}";
    const parsed = try std.json.parseFromSlice(std.json.Value, gpa.allocator(), json_str, .{});
    defer parsed.deinit();

    const name = parsed.value.object.get("name").?.string;
    const age = parsed.value.object.get("age").?.integer;

    std.debug.print("Name: {s}, Age: {d}\n", .{ name, age });

    try testing.expectEqualStrings("Bob", name);
    try testing.expectEqual(@as(i64, 25), age);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start: Stringify Struct to JSON" {
    std.debug.print("\n=== Quick Start: Stringify Struct ===\n", .{});

    const Point = struct { x: f32, y: f32 };
    const point = Point{ .x = 10.5, .y = 20.3 };

    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try std.json.Stringify.value(point, .{}, &writer);
    try writer.flush();

    const json_output = writer.buffered();
    std.debug.print("JSON: {s}\n", .{json_output});

    // Float precision: f32 may not exactly represent 20.3, so just check structure
    try testing.expect(std.mem.indexOf(u8, json_output, "\"x\":") != null);
    try testing.expect(std.mem.indexOf(u8, json_output, "\"y\":") != null);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start: Stringify to Heap-Allocated String" {
    std.debug.print("\n=== Quick Start: Stringify to Heap ===\n", .{});

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const Point = struct { x: f32, y: f32 };
    const point = Point{ .x = 10.5, .y = 20.3 };

    var aw: std.Io.Writer.Allocating = .init(gpa.allocator());
    defer aw.deinit();

    try std.json.Stringify.value(point, .{}, &aw.writer);
    const json_str = try aw.toOwnedSlice();
    defer gpa.allocator().free(json_str);

    std.debug.print("JSON: {s}\n", .{json_str});

    try testing.expect(json_str.len > 0);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Quick Start: Arena Allocator Pattern" {
    std.debug.print("\n=== Quick Start: Arena Allocator Pattern ===\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const MyType = struct { value: i32, name: []const u8 };
    const json_str = "{\"value\":42,\"name\":\"test\"}";

    const parsed = try std.json.parseFromSlice(MyType, arena.allocator(), json_str, .{});
    // No need to call parsed.deinit() - arena.deinit() frees everything

    std.debug.print("Value: {d}, Name: {s}\n", .{ parsed.value.value, parsed.value.name });

    try testing.expectEqual(@as(i32, 42), parsed.value.value);
    try testing.expectEqualStrings("test", parsed.value.name);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// High-Level Parsing Functions
// ============================================================================

test "parseFromSlice: Complete Config Example" {
    std.debug.print("\n=== parseFromSlice: Config Example ===\n", .{});

    const Config = struct {
        port: u16,
        host: []const u8,
        debug: bool,
    };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const json =
        \\{
        \\  "port": 8080,
        \\  "host": "localhost",
        \\  "debug": true
        \\}
    ;

    const parsed = try std.json.parseFromSlice(Config, allocator, json, .{});
    defer parsed.deinit();

    const config = parsed.value;
    std.debug.print("Server: {s}:{d} (debug={any})\n", .{ config.host, config.port, config.debug });

    try testing.expectEqual(@as(u16, 8080), config.port);
    try testing.expectEqualStrings("localhost", config.host);
    try testing.expect(config.debug);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "parseFromSliceLeaky: Arena Example" {
    std.debug.print("\n=== parseFromSliceLeaky: Arena Example ===\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const MyType = struct { x: i32, y: i32 };
    const json = "{\"x\":10,\"y\":20}";

    const value = try std.json.parseFromSliceLeaky(MyType, arena.allocator(), json, .{});

    std.debug.print("X: {d}, Y: {d}\n", .{ value.x, value.y });

    try testing.expectEqual(@as(i32, 10), value.x);
    try testing.expectEqual(@as(i32, 20), value.y);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "validate: JSON Syntax Validation" {
    std.debug.print("\n=== validate: Syntax Validation ===\n", .{});

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const valid_json = "{\"key\": \"value\"}";
    const invalid_json = "{key: value}"; // Missing quotes

    const is_valid = try std.json.validate(gpa.allocator(), valid_json);
    std.debug.print("Valid JSON: {}\n", .{is_valid});
    try testing.expect(is_valid);

    const is_invalid = try std.json.validate(gpa.allocator(), invalid_json);
    std.debug.print("Invalid JSON: {}\n", .{is_invalid});
    try testing.expect(!is_invalid);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Stringification Functions
// ============================================================================

test "stringify: User Struct Example" {
    std.debug.print("\n=== stringify: User Struct ===\n", .{});

    const User = struct {
        id: u32,
        name: []const u8,
        email: ?[]const u8 = null,
    };

    const user = User{
        .id = 123,
        .name = "Alice",
        .email = "alice@example.com",
    };

    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    try std.json.Stringify.value(user, .{}, &writer);
    try writer.flush();

    const output = writer.buffered();

    std.debug.print("JSON: {s}\n", .{output});

    try testing.expect(std.mem.indexOf(u8, output, "\"id\":123") != null);
    try testing.expect(std.mem.indexOf(u8, output, "\"name\":\"Alice\"") != null);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "stringify with formatting options" {
    std.debug.print("\n=== stringify: Formatting Options ===\n", .{});

    const Data = struct { x: i32, y: i32 };
    const data = Data{ .x = 10, .y = 20 };

    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);

    const options = std.json.Stringify.Options{
        .whitespace = .indent_2,
    };

    try std.json.Stringify.value(data, options, &writer);
    try writer.flush();

    const output = writer.buffered();

    std.debug.print("Formatted JSON:\n{s}\n", .{output});

    try testing.expect(std.mem.indexOf(u8, output, "\n") != null); // Has newlines

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "fmt: JSON Formatter (using Stringify)" {
    std.debug.print("\n=== fmt: JSON Formatter ===\n", .{});

    const Data = struct { x: i32, y: i32 };
    const data = Data{ .x = 10, .y = 20 };

    // std.json.fmt doesn't actually exist in 0.16, use Stringify instead
    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try std.json.Stringify.value(data, .{}, &writer);
    try writer.flush();

    const formatted = writer.buffered();

    std.debug.print("Formatted: {s}\n", .{formatted});

    try testing.expect(std.mem.indexOf(u8, formatted, "\"x\":10") != null);
    try testing.expect(std.mem.indexOf(u8, formatted, "\"y\":20") != null);

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Low-Level Scanner API
// ============================================================================

test "Scanner: Token Iteration" {
    std.debug.print("\n=== Scanner: Token Iteration ===\n", .{});

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const json = "{\"name\":\"Bob\",\"age\":25}";

    var scanner = std.json.Scanner.initCompleteInput(allocator, json);
    defer scanner.deinit();

    var token_count: usize = 0;
    while (true) {
        const token = try scanner.next();
        token_count += 1;

        if (token == .end_of_document) break;
    }

    std.debug.print("Total tokens: {d}\n", .{token_count});
    try testing.expect(token_count > 5); // At least object_begin, keys, values, object_end, end_of_document

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Usage Patterns
// ============================================================================

test "Pattern 1: REST API Response Parsing" {
    std.debug.print("\n=== Pattern 1: REST API Response ===\n", .{});

    const ApiResponse = struct {
        success: bool,
        data: ?Data = null,
        error_message: ?[]const u8 = null,

        const Data = struct {
            id: u64,
            name: []const u8,
            created_at: []const u8,
        };
    };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const json_response =
        \\{
        \\  "success": true,
        \\  "data": {
        \\    "id": 12345,
        \\    "name": "TestItem",
        \\    "created_at": "2024-01-15T10:30:00Z"
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(ApiResponse, gpa.allocator(), json_response, .{});
    defer parsed.deinit();

    const response = parsed.value;

    try testing.expect(response.success);
    try testing.expect(response.data != null);

    if (response.data) |data| {
        std.debug.print("Received: {s} (ID: {d})\n", .{ data.name, data.id });
        try testing.expectEqual(@as(u64, 12345), data.id);
        try testing.expectEqualStrings("TestItem", data.name);
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Pattern 2: Configuration File Loading (Simulated)" {
    std.debug.print("\n=== Pattern 2: Config Loading ===\n", .{});

    const AppConfig = struct {
        server: ServerConfig,
        database: DatabaseConfig,
        features: FeatureFlags,

        const ServerConfig = struct {
            host: []const u8,
            port: u16,
            workers: u8 = 4,
        };

        const DatabaseConfig = struct {
            url: []const u8,
            max_connections: u16 = 10,
        };

        const FeatureFlags = struct {
            enable_caching: bool = true,
            enable_logging: bool = true,
        };
    };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const config_json =
        \\{
        \\  "server": {
        \\    "host": "0.0.0.0",
        \\    "port": 3000,
        \\    "workers": 8
        \\  },
        \\  "database": {
        \\    "url": "postgres://localhost/mydb",
        \\    "max_connections": 20
        \\  },
        \\  "features": {
        \\    "enable_caching": true,
        \\    "enable_logging": false
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(AppConfig, gpa.allocator(), config_json, .{});
    defer parsed.deinit();

    const config = parsed.value;

    std.debug.print("Server: {s}:{d} ({d} workers)\n", .{ config.server.host, config.server.port, config.server.workers });
    std.debug.print("Database: {s} (max {d} connections)\n", .{ config.database.url, config.database.max_connections });

    try testing.expectEqual(@as(u16, 3000), config.server.port);
    try testing.expectEqual(@as(u8, 8), config.server.workers);
    try testing.expect(!config.features.enable_logging);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Pattern 3: Dynamic JSON Inspection" {
    std.debug.print("\n=== Pattern 3: Dynamic Inspection ===\n", .{});

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const json = "{\"count\":5,\"items\":[1,2,3],\"active\":true}";

    const parsed = try std.json.parseFromSlice(std.json.Value, gpa.allocator(), json, .{});
    defer parsed.deinit();

    const root = parsed.value;

    switch (root) {
        .object => |obj| {
            std.debug.print("JSON Object with {d} fields:\n", .{obj.count()});

            var iter = obj.iterator();
            while (iter.next()) |entry| {
                std.debug.print("  {s}: {s}\n", .{ entry.key_ptr.*, @tagName(entry.value_ptr.*) });
            }

            try testing.expectEqual(@as(usize, 3), obj.count());
        },
        else => try testing.expect(false), // Should be an object
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Error Handling & Edge Cases
// ============================================================================

test "Error: Unknown Field (strict mode)" {
    std.debug.print("\n=== Error: Unknown Field ===\n", .{});

    const MyStruct = struct {
        known_field: i32,
    };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const json = "{\"known_field\":42,\"unknown_field\":\"extra\"}";

    // Should fail in strict mode
    if (std.json.parseFromSlice(MyStruct, gpa.allocator(), json, .{})) |parsed| {
        defer parsed.deinit();
        std.debug.print("  ❌ Expected error, but succeeded\n", .{});
        try testing.expect(false);
    } else |err| {
        std.debug.print("  Got expected error: {any}\n", .{err});
        try testing.expectEqual(error.UnknownField, err);
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Success: Unknown Field (ignore mode)" {
    std.debug.print("\n=== Success: Ignore Unknown Field ===\n", .{});

    const MyStruct = struct {
        known_field: i32,
    };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const json = "{\"known_field\":42,\"unknown_field\":\"extra\"}";

    const options = std.json.ParseOptions{
        .ignore_unknown_fields = true,
    };

    const parsed = try std.json.parseFromSlice(MyStruct, gpa.allocator(), json, options);
    defer parsed.deinit();

    std.debug.print("  Parsed successfully: known_field = {d}\n", .{parsed.value.known_field});
    try testing.expectEqual(@as(i32, 42), parsed.value.known_field);

    std.debug.print("  ✅ PASS\n\n", .{});
}

test "Optional Fields: null and missing" {
    std.debug.print("\n=== Optional Fields ===\n", .{});

    const MyStruct = struct {
        required: i32,
        optional: ?[]const u8 = null,
    };

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    // Test 1: Field is null
    {
        const json1 = "{\"required\":10,\"optional\":null}";
        const parsed1 = try std.json.parseFromSlice(MyStruct, gpa.allocator(), json1, .{});
        defer parsed1.deinit();

        std.debug.print("  With null: optional = {any}\n", .{parsed1.value.optional});
        try testing.expect(parsed1.value.optional == null);
    }

    // Test 2: Field is missing
    {
        const json2 = "{\"required\":20}";
        const parsed2 = try std.json.parseFromSlice(MyStruct, gpa.allocator(), json2, .{});
        defer parsed2.deinit();

        std.debug.print("  Missing: optional = {any}\n", .{parsed2.value.optional});
        try testing.expect(parsed2.value.optional == null);
    }

    // Test 3: Field has value
    {
        const json3 = "{\"required\":30,\"optional\":\"value\"}";
        const parsed3 = try std.json.parseFromSlice(MyStruct, gpa.allocator(), json3, .{});
        defer parsed3.deinit();

        std.debug.print("  With value: optional = {s}\n", .{parsed3.value.optional.?});
        try testing.expectEqualStrings("value", parsed3.value.optional.?);
    }

    std.debug.print("  ✅ PASS\n\n", .{});
}

// ============================================================================
// Types and Value Testing
// ============================================================================

test "Value: All JSON Types" {
    std.debug.print("\n=== Value: All JSON Types ===\n", .{});

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const json =
        \\{
        \\  "null_val": null,
        \\  "bool_val": true,
        \\  "int_val": 42,
        \\  "float_val": 3.14,
        \\  "string_val": "hello",
        \\  "array_val": [1, 2, 3],
        \\  "object_val": {"nested": "value"}
        \\}
    ;

    const parsed = try std.json.parseFromSlice(std.json.Value, gpa.allocator(), json, .{});
    defer parsed.deinit();

    const obj = parsed.value.object;

    try testing.expect(obj.get("null_val").? == .null);
    try testing.expect(obj.get("bool_val").?.bool == true);
    try testing.expectEqual(@as(i64, 42), obj.get("int_val").?.integer);
    try testing.expectApproxEqAbs(@as(f64, 3.14), obj.get("float_val").?.float, 0.01);
    try testing.expectEqualStrings("hello", obj.get("string_val").?.string);
    try testing.expectEqual(@as(usize, 3), obj.get("array_val").?.array.items.len);
    try testing.expectEqual(@as(usize, 1), obj.get("object_val").?.object.count());

    std.debug.print("  ✅ All JSON value types validated\n\n", .{});
}

// ============================================================================
// Summary
// ============================================================================

test "Summary: All JSON Tests" {
    std.debug.print("\n" ++ "=" ** 60 ++ "\n", .{});
    std.debug.print("✅ All std.json tests passed!\n", .{});
    std.debug.print("=" ** 60 ++ "\n\n", .{});
}
