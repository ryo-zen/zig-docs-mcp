# std.json

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all JSON features

## Quick Start

### Most Common Patterns

**Parse JSON String into Struct**
```zig
const Person = struct { name: []const u8, age: u32 };

var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();

const json_str = "{\"name\":\"Alice\",\"age\":30}";
const parsed = try std.json.parseFromSlice(Person, da.allocator(), json_str, .{});
defer parsed.deinit();

std.debug.print("Name: {s}, Age: {d}\n", .{parsed.value.name, parsed.value.age});
```

**Parse into Dynamic Value**
```zig
const parsed = try std.json.parseFromSlice(std.json.Value, da.allocator(), json_str, .{});
defer parsed.deinit();

const name = parsed.value.object.get("name").?.string;
const age = parsed.value.object.get("age").?.integer;
```

**Stringify Struct to JSON**
```zig
const Point = struct { x: f32, y: f32 };
const point = Point{ .x = 10.5, .y = 20.3 };

var buffer: [256]u8 = undefined;
var writer = std.Io.Writer.fixed(&buffer);
try std.json.Stringify.value(point, .{}, &writer);
try writer.flush();

const json_output = writer.buffered();  // {"x":10.5,"y":20.299999237060547}
```

**Stringify to Heap-Allocated String**
```zig
var aw: std.Io.Writer.Allocating = .init(da.allocator());
defer aw.deinit();

try std.json.Stringify.value(point, .{}, &aw.writer);
const json_str = try aw.toOwnedSlice();
defer da.allocator().free(json_str);
```

**Arena Allocator Pattern (Recommended)**
```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();

// Parse without tracking individual allocations
const parsed = try std.json.parseFromSlice(MyType, arena.allocator(), json_str, .{});
// No need to call parsed.deinit() - arena.deinit() frees everything
```

### Common JSON Operations

| Operation | Function | Example |
|-----------|----------|---------|
| Parse to struct | `parseFromSlice()` | `parseFromSlice(T, allocator, json, .{})` |
| Parse to dynamic | `parseFromSlice(Value, ...)` | `parseFromSlice(Value, allocator, json, .{})` |
| Stringify | `Stringify.value()` | `Stringify.value(data, .{}, &writer)` |
| Validate JSON | `validate()` | `validate(allocator, json_string)` |
| Low-level parsing | `Scanner` | `Scanner.initCompleteInput(allocator, json)` |

### ⚠️ Critical: Memory Management
```zig
// WRONG - Memory leak! parsed owns allocated memory
const parsed = try std.json.parseFromSlice(T, allocator, json, .{});
// Missing: parsed.deinit()  ❌

// CORRECT - Always deinit after parsing
const parsed = try std.json.parseFromSlice(T, allocator, json, .{});
defer parsed.deinit();  // ✅

// ALTERNATIVE - Use ArenaAllocator for bulk parsing
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();  // Frees all at once
const parsed = try std.json.parseFromSlice(T, arena.allocator(), json, .{});
```

---

## Overview

`std.json` is Zig's JSON parsing and serialization namespace conforming to RFC 8259 (https://datatracker.ietf.org/doc/html/rfc8259). It provides both high-level APIs for deserializing JSON into Zig types and low-level scanning/tokenization for custom parsing needs.

**Key Characteristics:**
- **Type-safe deserialization** - Parse JSON directly into Zig structs with compile-time validation
- **Dynamic parsing** - `std.json.Value` for runtime-typed JSON inspection
- **Low-level scanner** - Token-based parsing for streaming or custom formats
- **Flexible stringification** - Serialize Zig types to JSON with formatting options
- **Security limits** - Default 4 MiB max string/number size to prevent DoS attacks
- **Comptime validation** - Struct field mapping validated at compile time

**When to use std.json:**
- Parsing configuration files (package.json, config.json)
- REST API request/response handling
- Data serialization for network protocols
- Reading/writing structured data files
- Interop with JSON-based tools and services

**Related namespaces:**
- `std.zon` - ZON (Zig Object Notation) - Zig's native data format
- `std.fmt` - Lower-level string formatting utilities
- `std.mem` - Memory utilities for working with parsed slices

---

## High-Level Parsing Functions

### `pub fn parseFromSlice(comptime T: type, allocator: Allocator, s: []const u8, options: ParseOptions) ParseError(Scanner)!Parsed(T)`

Parses a complete JSON document from a string slice into a Zig value of type `T`. This is the primary function for JSON deserialization.

**Parameters:**
- `T` - Target type (struct, union, Value, or primitive)
- `allocator` - Allocator for dynamic memory (strings, arrays, objects)
- `s` - JSON string to parse (must be complete, not streaming)
- `options` - Parsing configuration (see `ParseOptions`)

**Returns:** `Parsed(T)` wrapper containing the parsed value and metadata

**Errors:**
- `error.SyntaxError` - Malformed JSON
- `error.UnexpectedEndOfInput` - Incomplete JSON document
- `error.UnknownField` - JSON key not in struct (unless `ignore_unknown_fields` is true)
- `error.OutOfMemory` - Allocation failure

**Memory Management:**
You **must** call `deinit()` on the returned `Parsed(T)` to free allocated memory, or use an `ArenaAllocator`.

**Example:**
```zig
const std = @import("std");

const Config = struct {
    port: u16,
    host: []const u8,
    debug: bool,
};

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

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
    std.debug.print("Server: {s}:{d} (debug={any})\n", .{config.host, config.port, config.debug});
}
```

------

### `pub fn parseFromSliceLeaky(comptime T: type, allocator: Allocator, s: []const u8, options: ParseOptions) ParseError(Scanner)!T`

Parses JSON without careful allocation tracking. Returns the value directly (not wrapped in `Parsed`).

**Use case:** When using `ArenaAllocator` or when you don't need individual cleanup.

**Example:**
```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();  // Bulk free

const value = try std.json.parseFromSliceLeaky(MyType, arena.allocator(), json, .{});
// No need to deinit `value` - arena handles everything
```

------

### `pub fn parseFromValue(comptime T: type, allocator: Allocator, source: Value, options: ParseOptions) ParseFromValueError!Parsed(T)`

Converts an already-parsed `std.json.Value` into a typed Zig value.

**Use case:** Two-stage parsing - first parse to `Value` for validation, then convert to typed struct.

**Example:**
```zig
// Stage 1: Parse to dynamic Value
const parsed_value = try std.json.parseFromSlice(std.json.Value, allocator, json, .{});
defer parsed_value.deinit();

// Stage 2: Validate or transform Value, then convert to type
if (parsed_value.value.object.get("version")) |ver| {
    if (ver.integer != 2) return error.UnsupportedVersion;
}

const parsed_config = try std.json.parseFromValue(Config, allocator, parsed_value.value, .{});
defer parsed_config.deinit();
```

------

### `pub fn validate(allocator: Allocator, s: []const u8) Allocator.Error!bool`

Validates JSON syntax without parsing into a type. Returns `false` on syntax errors, `true` if valid.

**Parameters:**
- `allocator` - Used for scanner buffer (unlikely to fail unless deeply nested)
- `s` - JSON string to validate

**Returns:** `true` if valid JSON, `false` on syntax error

**Errors:** `error.OutOfMemory` only (extremely rare, requires deep nesting)

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const valid_json = "{\"key\": \"value\"}";
    const invalid_json = "{key: value}";  // Missing quotes

    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    const is_valid = try std.json.validate(da.allocator(), valid_json);
    std.debug.print("Valid: {}\n", .{is_valid});  // true

    const is_invalid = try std.json.validate(da.allocator(), invalid_json);
    std.debug.print("Invalid: {}\n", .{is_invalid});  // false
}
```

------

## Stringification Functions

### `pub fn Stringify.value(v: anytype, options: Stringify.Options, writer: *Io.Writer) !void`

Serializes a Zig value to JSON, writing to the provided writer.

**Parameters:**
- `v` - Value to serialize (struct, array, primitive, etc.)
- `options` - Formatting options (see `Stringify.Options`)
- `writer` - Pointer to `Io.Writer` for output

**Supported types:**
- Primitives: integers, floats, booleans, `null`
- Strings: `[]const u8`, `[]u8`
- Arrays and slices
- Structs (fields become JSON object keys)
- Unions (tagged unions serialize as objects)
- Optionals (`null` or the unwrapped value)
- Enums (as strings or integers depending on options)

**Example:**
```zig
const std = @import("std");

const User = struct {
    id: u32,
    name: []const u8,
    email: ?[]const u8 = null,
};

pub fn main() !void {
    const user = User{
  .id = 123,
  .name = "Alice",
  .email = "alice@example.com",
    };

    // Stringify to fixed buffer
    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try std.json.Stringify.value(user, .{}, &writer);
    try writer.flush();

    std.debug.print("{s}\n", .{writer.buffered()});
    // Output: {"id":123,"name":"Alice","email":"alice@example.com"}
}
```

------

### Helper: Stringify to Owned String

For convenience, you can use `Io.Writer.Allocating` to get an owned string:

**Example:**
```zig
const std = @import("std");

pub fn stringifyToOwned(value: anytype, allocator: std.mem.Allocator) ![]const u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    errdefer aw.deinit();

    try std.json.Stringify.value(value, .{}, &aw.writer);
    return try aw.toOwnedSlice();
}

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    const data = .{ .x = 10, .y = 20 };
    const json_str = try stringifyToOwned(data, da.allocator());
    defer da.allocator().free(json_str);

    std.debug.print("JSON: {s}\n", .{json_str});
}
```

------

## Low-Level Scanner API

### `Scanner`

Token-based JSON parser for streaming or custom parsing logic.

**Use cases:**
- Parsing JSON from network streams (incremental input)
- Custom deserialization logic
- Large files where you don't want to load everything into memory
- Extracting specific fields without parsing the entire document

**Key Methods:**
- `initCompleteInput(allocator, source)` - Initialize with complete JSON string
- `next()` - Get next token
- `nextAlloc()` - Get next token (allocates for strings/numbers)
- `peekNextTokenType()` - Look ahead without consuming

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

    const json = "{\"name\":\"Bob\",\"age\":25}";

    var scanner = std.json.Scanner.initCompleteInput(allocator, json);
    defer scanner.deinit();

    while (true) {
  const token = try scanner.next();
  std.debug.print("Token: {any}\n", .{token});

  if (token == .end_of_document) break;
    }
}
```

------

## Usage Patterns

### Pattern 1: REST API Response Parsing

```zig
const std = @import("std");

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

pub fn handleApiResponse(allocator: std.mem.Allocator, json_response: []const u8) !void {
    const parsed = try std.json.parseFromSlice(ApiResponse, allocator, json_response, .{});
    defer parsed.deinit();

    const response = parsed.value;

    if (!response.success) {
  std.debug.print("API Error: {s}\n", .{response.error_message.?});
  return error.ApiError;
    }

    if (response.data) |data| {
  std.debug.print("Received: {s} (ID: {d})\n", .{data.name, data.id});
    }
}
```

------

### Pattern 2: Configuration File Loading

```zig
const std = @import("std");

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

pub fn loadConfig(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !AppConfig {
    // Read file
    const content = try std.Io.Dir.cwd().readFileAlloc(
  io,
  path,
  allocator,
  .limited(1024 * 1024), // 1MB max
    );
    defer allocator.free(content);

    // Parse config
    const parsed = try std.json.parseFromSlice(AppConfig, allocator, content, .{});
    defer parsed.deinit();

    // Return a copy (since we're freeing the parsed data)
    // In practice, you'd want to manage this differently or use arena allocator
    return parsed.value;
}
```

------

### Pattern 3: Dynamic JSON Inspection

```zig
const std = @import("std");

pub fn inspectJson(allocator: std.mem.Allocator, json: []const u8) !void {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json, .{});
    defer parsed.deinit();

    const root = parsed.value;

    switch (root) {
  .object => |obj| {
      std.debug.print("JSON Object with {d} fields:\n", .{obj.count()});

      var iter = obj.iterator();
      while (iter.next()) |entry| {
          std.debug.print("  {s}: {s}\n", .{entry.key_ptr.*, @tagName(entry.value_ptr.*)});
      }
  },
  .array => |arr| {
      std.debug.print("JSON Array with {d} elements\n", .{arr.items.len});
  },
  .string => |s| std.debug.print("JSON String: {s}\n", .{s}),
  .integer => |i| std.debug.print("JSON Integer: {d}\n", .{i}),
  .float => |f| std.debug.print("JSON Float: {d}\n", .{f}),
  .bool => |b| std.debug.print("JSON Boolean: {}\n", .{b}),
  .null => std.debug.print("JSON Null\n", .{}),
    }
}
```

------

### Pattern 4: Write JSON to File

```zig
const std = @import("std");

pub fn writeJsonToFile(io: std.Io, allocator: std.mem.Allocator, data: anytype, path: []const u8) !void {
    const file = try std.Io.Dir.cwd(io).createFile(path, .{});
    defer file.close(io);

    // Use allocating writer to build JSON string first
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();

    const options = std.json.Stringify.Options{ .whitespace = .indent_4 };
    try std.json.Stringify.value(data, options, &aw.writer);

    const json_str = try aw.toOwnedSlice();
    defer allocator.free(json_str);

    try file.writeAll(io, json_str);
}
```

------

### Pattern 5: Custom JSON Parsing with jsonParse

```zig
const std = @import("std");

const Timestamp = struct {
    unix_seconds: i64,

    // Custom JSON parser - converts "2024-01-15T10:30:00Z" to unix timestamp
    pub fn jsonParse(
  allocator: std.mem.Allocator,
  source: anytype,
  options: std.json.ParseOptions,
    ) !Timestamp {
  _ = options;
  _ = allocator;

  const timestamp_str = try source.nextString();

  // In real code: parse ISO 8601 format to unix timestamp
  // Simplified here:
  _ = timestamp_str;
  return Timestamp{ .unix_seconds = 1705318200 };
    }

    // Custom JSON stringifier - converts unix timestamp to ISO 8601 string
    pub fn jsonStringify(
  self: Timestamp,
  options: std.json.StringifyOptions,
  writer: anytype,
    ) !void {
  _ = options;
  // In real code: format unix timestamp as ISO 8601
  // Simplified here:
  try writer.print("\"2024-01-15T10:30:00Z\"", .{});
  _ = self;
    }
};
```

------

## Types and Constants

### User-Facing Types

**`Value` (union)**
```zig
pub const Value = union(enum) {
    null,
    bool: bool,
    integer: i64,
    float: f64,
    string: []const u8,
    array: Array,
    object: ObjectMap,
};
```
Dynamic JSON value for runtime inspection. Use when you don't know the schema at compile time.

**Fields:**
- `.null` - JSON null value
- `.bool` - Boolean (true/false)
- `.integer` - Signed 64-bit integer
- `.float` - 64-bit floating point
- `.string` - UTF-8 string slice
- `.array` - JSON array (see `Array`)
- `.object` - JSON object (see `ObjectMap`)

**Example:**
```zig
const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json, .{});
defer parsed.deinit();

if (parsed.value.object.get("age")) |age_value| {
    if (age_value == .integer) {
  std.debug.print("Age: {d}\n", .{age_value.integer});
    }
}
```

------

**`Array` (type)**
```zig
pub const Array = std.ArrayList(Value);
```
Dynamic array of JSON values. Standard ArrayList interface.

**Methods:**
- `.items` - Slice of values
- `.append(allocator, value)` - Add value
- `.deinit(allocator)` - Free memory

------

**`ObjectMap` (type)**
```zig
pub const ObjectMap = std.ArrayHashMap([]const u8, Value, ...);
```
JSON object (string → Value mapping). Preserves insertion order.

**Methods:**
- `.get(key)` - Lookup value by key (returns `?Value`)
- `.put(allocator, key, value)` - Insert/update key-value pair
- `.count()` - Number of fields
- `.iterator()` - Iterate over entries
- `.deinit(allocator)` - Free memory

------

**`ParseOptions` (struct)**
```zig
pub const ParseOptions = struct {
    ignore_unknown_fields: bool = false,
    allocate: AllocWhen = .alloc_if_needed,
    max_value_len: ?usize = null,
};
```
Configuration for JSON parsing.

**Fields:**
- `ignore_unknown_fields` - If `false`, returns error on extra JSON fields not in struct
- `allocate` - When to allocate for string/number tokens (usually leave default)
- `max_value_len` - Maximum size for single string/number value (default: 4 MiB for security)

**Example:**
```zig
const options = std.json.ParseOptions{
    .ignore_unknown_fields = true,  // Ignore extra JSON fields
};
const parsed = try std.json.parseFromSlice(MyStruct, allocator, json, options);
```

------

**`Stringify.Options` (struct)**
```zig
pub const Options = struct {
    whitespace: Whitespace = .minified,
    escape_unicode: bool = false,
    emit_null_optional_fields: bool = true,
};
```
Configuration for JSON stringification.

**Fields:**
- `whitespace` - Formatting style (`.minified`, `.indent_2`, `.indent_4`, `.indent_tab`)
- `escape_unicode` - Escape non-ASCII characters (e.g., `\u0041` instead of `A`)
- `emit_null_optional_fields` - Include `null` for optional fields that are null

**Example:**
```zig
const options = std.json.Stringify.Options{
    .whitespace = .indent_2,
    .emit_null_optional_fields = false,  // Omit null fields
};
try std.json.Stringify.value(data, options, writer);
```

------

**`Parsed(T)` (struct)**
```zig
pub fn Parsed(comptime T: type) type {
    return struct {
  arena: *std.heap.ArenaAllocator,
  value: T,

  pub fn deinit(self: @This()) void { ... }
    };
}
```
Wrapper for parsed values. Contains an arena allocator and the parsed value.

**Fields:**
- `arena` - Internal arena allocator holding all allocated memory
- `value` - The parsed value of type `T`

**Methods:**
- `deinit()` - Frees all memory associated with parsing

------

### Scanner Types

**`Scanner.Token` (union)**
```zig
pub const Token = union(TokenType) {
    object_begin,
    object_end,
    array_begin,
    array_end,
    true,
    false,
    null,
    number: []const u8,
    string: []const u8,
    allocated_number: []const u8,
    allocated_string: []const u8,
    end_of_document,
};
```
Token emitted by low-level Scanner.

------

**`Scanner.AllocWhen` (enum)**
```zig
pub const AllocWhen = enum {
    alloc_if_needed,
    alloc_always,
};
```
Controls when Scanner allocates for string/number tokens.

------

### Constants

**`default_max_value_len: ?usize`**
Maximum size for a single JSON string or number value. Default is 4 MiB (4,194,304 bytes) for security.

**Security rationale:** Prevents attackers from sending huge JSON strings that consume all memory.

------

**`default_buffer_size: usize`**
Default buffer size for `json.Reader` when parsing from streaming sources.

------

## Error Sets

### `ParseError(ScannerType)`
- `error.SyntaxError` - Malformed JSON syntax
- `error.UnexpectedEndOfInput` - JSON document is incomplete
- `error.UnknownField` - JSON object has field not in target struct
- `error.InvalidNumber` - Number format is invalid
- `error.InvalidCharacter` - Invalid character in JSON
- `error.DuplicateField` - JSON object has duplicate keys
- `error.OutOfMemory` - Memory allocation failed
- `error.BufferUnderrun` - Scanner buffer too small (streaming only)

### `ParseFromValueError`
- `error.UnexpectedToken` - Value type doesn't match target type
- `error.MissingField` - Required struct field not in JSON
- `error.UnknownField` - JSON has extra field not in struct
- `error.Overflow` - Number too large for target integer type
- `error.InvalidCharacter` - Invalid value encountered
- `error.OutOfMemory` - Memory allocation failed

------

## Debug Checklist

✅ **Call deinit() on parsed values** - `parseFromSlice` allocates memory; must call `parsed.deinit()` or use ArenaAllocator

✅ **JSON is valid RFC 8259** - Use `std.json.validate()` to check syntax before parsing if source is untrusted

✅ **Struct fields match JSON keys** - Field names must exactly match JSON object keys (case-sensitive)

✅ **Optional fields use ?T syntax** - JSON fields that might be missing or null should be `?[]const u8` or similar

✅ **Ignore unknown fields if needed** - Set `options.ignore_unknown_fields = true` for flexible parsing

✅ **Handle missing fields** - Non-optional struct fields will error if JSON object doesn't have them

✅ **Flush after stringify to buffered writer** - Always call `buffered.flush()` after stringifying to buffered output

✅ **String slices reference parsed data** - Parsed strings point into the JSON document; copy if you need to outlive the parse

✅ **Use Arena for bulk parsing** - If parsing many objects, ArenaAllocator is more efficient than individual deinit calls

✅ **Check for duplicate keys** - JSON spec allows duplicates, but std.json will error by default

------

## Performance Tips

1. **Use ArenaAllocator for batch parsing** - If you're parsing multiple JSON documents or don't need fine-grained cleanup:
   ```zig
   var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
   defer arena.deinit();

   const parsed = try std.json.parseFromSlice(T, arena.allocator(), json, .{});
   // No parsed.deinit() needed
   ```

2. **Prefer parseFromSliceLeaky with Arena** - Skip `Parsed` wrapper overhead:
   ```zig
   const value = try std.json.parseFromSliceLeaky(T, arena.allocator(), json, .{});
   ```

3. **Reuse Scanner for multiple documents** - If parsing many JSON documents from the same source, reuse the Scanner:
   ```zig
   var scanner = std.json.Scanner.initCompleteInput(allocator, json);
   defer scanner.deinit();
   // Parse multiple values...
   ```

4. **Use Scanner for selective parsing** - Don't parse the entire document if you only need specific fields:
   ```zig
   var scanner = std.json.Scanner.initCompleteInput(allocator, json);
   while (try scanner.next() != .end_of_document) {
 // Skip to the field you care about
   }
   ```

5. **Avoid parseFromValue unless necessary** - Parsing directly to typed struct is faster than JSON string → Value → struct

6. **Pre-allocate stringify buffer** - For fixed-size output, use a stack buffer instead of ArrayList:
   ```zig
   var buffer: [4096]u8 = undefined;
   var writer = std.Io.Writer.fixed(&buffer);
   try std.json.Stringify.value(data, .{}, &writer);
   ```

7. **Use .minified whitespace for production** - Smaller output size and faster serialization:
   ```zig
   try std.json.Stringify.value(data, .{ .whitespace = .minified }, writer);
   ```

8. **Increase max_value_len if needed** - Default 4 MiB limit may be too small for legitimate large strings:
   ```zig
   const options = .{ .max_value_len = 100 * 1024 * 1024 };  // 100 MiB
   ```

------

## See Also

- **std.fmt** - String formatting and parsing primitives
- **std.zon** - ZON (Zig Object Notation) - Zig's native data format
- **std.mem** - Memory utilities for slice manipulation
- **std.Io.Reader/Writer** - Streaming I/O interfaces used by JSON
- **std.ArrayList** - Dynamic arrays (used for JSON arrays)
- **std.ArrayHashMap** - Hash maps (used for JSON objects)
