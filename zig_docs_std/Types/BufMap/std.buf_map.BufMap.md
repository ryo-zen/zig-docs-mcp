# std.buf_map.BufMap

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Working code demonstrating all BufMap operations: `test_bufmap_basic.zig`, `test_bufmap_iteration.zig`, `test_bufmap_ownership.zig`

## Quick Start

**Basic Key-Value Storage**
```zig
const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

var map = std.BufMap.init(gpa.allocator());
defer map.deinit();

try map.put("name", "Alice");
try map.put("city", "Portland");

const name = map.get("name"); // Returns "Alice"
const missing = map.get("none"); // Returns null
```

**Iteration Over Entries**
```zig
var map = std.BufMap.init(allocator);
defer map.deinit();

try map.put("key1", "value1");
try map.put("key2", "value2");

var it = map.iterator();
while (it.next()) |entry| {
    std.debug.print("{s} = {s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

**Ownership Transfer with putMove**
```zig
var map = std.BufMap.init(allocator);
defer map.deinit();

// Allocate strings that we want to transfer
const key = try allocator.dupe(u8, "config");
const value = try allocator.dupe(u8, "enabled");

// Transfer ownership - BufMap will free these
try map.putMove(key, value);
// Do NOT free key or value - BufMap owns them now
```

### ⚠️ Critical: String Ownership

BufMap **copies** strings passed to `put()`, so callers retain ownership and must manage their own memory. With `putMove()`, ownership **transfers** to the map, and the caller must NOT free the strings.

---

## Overview

`std.BufMap` is a hash map specialized for string-to-string mappings where the map takes ownership of the key and value strings. Unlike generic hash maps that store values directly, BufMap always copies strings passed to `put()` or takes ownership of pre-allocated strings with `putMove()`. This makes it ideal for configuration maps, environment variables, and other string-based key-value stores where automatic memory management is desired.

The "Buf" prefix refers to "buffer" - BufMap manages string buffers internally. All keys and values are copied into the map's allocator and freed automatically when removed or when `deinit()` is called. This simplifies memory management for string-heavy data structures.

**Key Characteristics:**
- **Automatic string ownership** - Copies strings on `put()`, manages their lifetime
- **String-to-string only** - Both keys and values must be `[]const u8`
- **Safe after input freed** - Copied strings remain valid even if source is freed
- **Transfer ownership option** - `putMove()` avoids copying pre-allocated strings
- **Iteration support** - Iterate over key-value pairs in arbitrary order

**When to use:**
- Configuration maps where keys and values are strings
- Environment variable storage
- HTTP headers or query parameters
- Any string-to-string mapping needing automatic memory management
- When you want the map to own and manage string lifetimes

**When NOT to use:**
- Non-string keys or values (use `std.StringHashMap` or `std.AutoHashMap`)
- Large strings where copying overhead matters (consider reference counting)
- Ordered iteration required (BufMap iteration order is arbitrary)

---

## Fields

`hash_map: BufMapHashMap`

The underlying hash map implementation. This is a StringHashMap specialized for storing owned string slices. Direct access to this field is generally not needed - use the BufMap methods instead.

---

## Core Functions

### `pub fn init(allocator: Allocator) BufMap`

Creates a new empty BufMap backed by the given allocator. The allocator will be used for all internal storage and string copies.

**Example:**
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

var map = std.BufMap.init(gpa.allocator());
defer map.deinit();
```

------

### `pub fn deinit(self: *BufMap) void`

Frees all memory allocated by the BufMap, including all stored keys and values. After calling `deinit()`, the map is in an undefined state and must not be used.

**Example:**
```zig
var map = std.BufMap.init(allocator);
defer map.deinit(); // Frees all keys and values

try map.put("key", "value");
// ... use map ...
// deinit called automatically on scope exit
```

------

### `pub fn put(self: *BufMap, key: []const u8, value: []const u8) !void`

Inserts or updates a key-value pair in the map. Both the key and value are **copied** into the map's internal storage. If the key already exists, its old value is freed and replaced.

**Parameters:**
- `key: []const u8` - The key to insert (will be copied)
- `value: []const u8` - The value to associate with the key (will be copied)

**Ownership:** Caller retains ownership of input strings. The map makes its own copies.

**Example:**
```zig
var map = std.BufMap.init(allocator);
defer map.deinit();

const my_key = "setting";
const my_value = "enabled";

try map.put(my_key, my_value);
// my_key and my_value can be safely freed or reused
// Map has its own copies
```

------

### `pub fn putMove(self: *BufMap, key: []u8, value: []u8) !void`

Inserts or updates a key-value pair, transferring ownership of the key and value strings to the map. Unlike `put()`, this does NOT copy the strings - the map takes over responsibility for freeing them.

If `putMove()` fails (returns an error), ownership does NOT transfer and the caller must free the strings.

**Parameters:**
- `key: []u8` - Pre-allocated key (ownership transfers on success)
- `value: []u8` - Pre-allocated value (ownership transfers on success)

**Ownership:** On success, map takes ownership. On error, caller retains ownership.

**Example:**
```zig
var map = std.BufMap.init(allocator);
defer map.deinit();

const key = try allocator.dupe(u8, "config");
const value = try allocator.dupe(u8, "production");

try map.putMove(key, value);
// Do NOT free key or value - map owns them now

// On error, caller must free:
const key2 = try allocator.dupe(u8, "other");
const value2 = try allocator.dupe(u8, "data");
if (map.putMove(key2, value2)) {
    // Success - map owns them
} else |err| {
    // Failed - we still own them
    allocator.free(key2);
    allocator.free(value2);
    return err;
}
```

------

### `pub fn get(self: BufMap, key: []const u8) ?[]const u8`

Retrieves the value associated with a key. Returns `null` if the key is not found. The returned string is owned by the map and is invalidated if the key is removed or the map is resized.

**Parameters:**
- `key: []const u8` - The key to look up

**Returns:** `?[]const u8` - The associated value, or `null` if not found.

**Example:**
```zig
try map.put("port", "8080");

if (map.get("port")) |value| {
    std.debug.print("Port: {s}\n", .{value});
} else {
    std.debug.print("Port not configured\n", .{});
}

const missing = map.get("nonexistent"); // Returns null
```

------

### `pub fn getPtr(self: BufMap, key: []const u8) ?*[]const u8`

Returns a pointer to the value associated with a key. This allows checking for existence without copying the string. The pointer is invalidated if the map resizes (e.g., from adding new entries).

**Parameters:**
- `key: []const u8` - The key to look up

**Returns:** `?*[]const u8` - Pointer to the value, or `null` if not found.

**Example:**
```zig
try map.put("setting", "value");

if (map.getPtr("setting")) |ptr| {
    std.debug.print("Found: {s}\n", .{ptr.*});
    // Note: Cannot modify ptr.* directly without invalidating map invariants
}
```

------

### `pub fn remove(self: *BufMap, key: []const u8) void`

Removes a key-value pair from the map and frees both the key and value strings. If the key doesn't exist, this is a no-op.

**Parameters:**
- `key: []const u8` - The key to remove

**Example:**
```zig
try map.put("temp", "data");
map.remove("temp"); // Frees both "temp" and "data"

map.remove("nonexistent"); // Safe - does nothing
```

------

### `pub fn count(self: BufMap) BufMapHashMap.Size`

Returns the number of key-value pairs currently stored in the map.

**Returns:** The count of entries.

**Example:**
```zig
var map = std.BufMap.init(allocator);
defer map.deinit();

std.debug.print("Count: {}\n", .{map.count()}); // 0

try map.put("a", "1");
try map.put("b", "2");
std.debug.print("Count: {}\n", .{map.count()}); // 2
```

---

## Iteration Functions

### `pub fn iterator(self: *const BufMap) BufMapHashMap.Iterator`

Returns an iterator over all key-value pairs in the map. Iteration order is arbitrary and may change when entries are added or removed.

**Returns:** An iterator that yields `Entry` structs with `key_ptr` and `value_ptr` fields.

**Example:**
```zig
try map.put("apple", "red");
try map.put("banana", "yellow");
try map.put("grape", "purple");

var it = map.iterator();
while (it.next()) |entry| {
    std.debug.print("{s} is {s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

---

## Usage Patterns

### Pattern 1: Configuration Map

```zig
fn loadConfig(allocator: Allocator) !std.BufMap {
    var config = std.BufMap.init(allocator);
    errdefer config.deinit();

    try config.put("database.host", "localhost");
    try config.put("database.port", "5432");
    try config.put("app.debug", "true");
    try config.put("app.log_level", "info");

    return config;
}

fn getConfigValue(config: *const std.BufMap, key: []const u8, default: []const u8) []const u8 {
    return config.get(key) orelse default;
}
```

### Pattern 2: Environment Variables

```zig
fn captureEnvironment(allocator: Allocator, environ: [][*:0]u8) !std.BufMap {
    var env_map = std.BufMap.init(allocator);
    errdefer env_map.deinit();

    for (environ) |entry| {
        const line = std.mem.span(entry);
        if (std.mem.indexOfScalar(u8, line, '=')) |eq_index| {
            const key = line[0..eq_index];
            const value = line[eq_index + 1 ..];
            try env_map.put(key, value);
        }
    }

    return env_map;
}
```

### Pattern 3: HTTP Headers

```zig
fn parseHeaders(allocator: Allocator, header_lines: []const []const u8) !std.BufMap {
    var headers = std.BufMap.init(allocator);
    errdefer headers.deinit();

    for (header_lines) |line| {
        if (std.mem.indexOfScalar(u8, line, ':')) |colon_index| {
            const key = std.mem.trim(u8, line[0..colon_index], " \t");
            const value = std.mem.trim(u8, line[colon_index + 1 ..], " \t");
            try headers.put(key, value);
        }
    }

    return headers;
}
```

### Pattern 4: Building from Existing Allocations

```zig
fn buildMapEfficiently(allocator: Allocator, data: []const KeyValue) !std.BufMap {
    var map = std.BufMap.init(allocator);
    errdefer map.deinit();

    for (data) |kv| {
        // Allocate once and transfer ownership
        const key = try allocator.dupe(u8, kv.key);
        errdefer allocator.free(key);

        const value = try allocator.dupe(u8, kv.value);
        errdefer allocator.free(value);

        // Transfer ownership - avoid double copy
        try map.putMove(key, value);
    }

    return map;
}
```

---

## Error Sets

`Allocator.Error`

Returned by `put()` and `putMove()` when memory allocation fails. Common errors:
- `OutOfMemory` - The allocator cannot provide more memory for map storage or string copies

---

## Debug Checklist

✅ **Remember to call deinit()** - BufMap owns all keys and values. Use `defer map.deinit();` immediately after init.

✅ **Don't free strings after putMove()** - On success, the map owns the strings. Only free on error.

✅ **Don't free strings from get()** - The returned value is owned by the map, not the caller.

✅ **getPtr() pointers can be invalidated** - Adding entries may resize the map, invalidating pointers from `getPtr()`.

✅ **Strings passed to put() can be freed** - `put()` copies the strings, so you can reuse or free the input buffers immediately.

✅ **Check for null on get()** - Missing keys return `null`, not an error.

✅ **Remove is safe for missing keys** - No need to check existence before removing.

✅ **Iteration order is arbitrary** - Don't depend on any particular order when iterating.

---

## Performance Tips

1. **Use putMove() for pre-allocated strings** - Avoids double-copying when you've already allocated the strings. Particularly useful when parsing or formatting values.

2. **Pre-size if you know the count** - While BufMap doesn't expose capacity hints, consider using a different hash map if you're adding thousands of entries and performance matters.

3. **Reuse key strings for lookups** - `get()` takes a `[]const u8`, so you can use string literals or const buffers for lookups without allocation.

4. **Batch operations** - If adding many entries, prepare all key-value pairs first, then insert them to minimize allocator contention.

5. **Consider StringHashMap for large values** - BufMap copies all strings. For large values, consider `StringHashMap(*[]u8)` with manual management.

---

## See Also

- **`std.StringHashMap`** - Generic hash map with string keys but any value type
- **`std.AutoHashMap`** - Generic hash map with automatic hashing for any key type
- **`std.BufSet`** - Set of strings with similar ownership semantics
- **`std.process.EnvMap`** - Specialized map for environment variables (may wrap BufMap)
