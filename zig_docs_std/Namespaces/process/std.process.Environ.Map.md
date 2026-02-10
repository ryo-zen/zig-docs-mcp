# std.process.Environ.Map

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating environment variable manipulation.

## Quick Start

### Basic Map Operations

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // 1. Get a value
    const path = init.environ_map.get("PATH") orelse "/bin:/usr/bin";
    
    // 2. Add or update a value
    try init.environ_map.put("MY_VAR", "my_value");
    
    // 3. Remove a value
    _ = init.environ_map.swapRemove("OLD_VAR");
    
    // 4. Create a child process with this map
    var child = try std.process.spawn(init.io, .{
        .argv = &[_][]const u8{"sh", "-c", "echo $MY_VAR"},
        .environ_map = init.environ_map,
    });
    _ = try child.wait(init.io);
}
```

### Manual Map Initialization

```zig
var map = std.process.Environ.Map.init(allocator);
defer map.deinit();

try map.put("K1", "V1");
```

---

## Overview

`std.process.Environ.Map` is a high-level hash map designed for managing environment variables. It abstracts platform-specific details such as case-insensitivity on Windows and memory management of environment strings.

In Zig 0.16, a pre-populated `Environ.Map` is provided to the `main` function via `std.process.Init.environ_map`.

**Key Characteristics:**
- **Case-Insensitive on Windows**: Keys are compared case-insensitively on Windows to match OS behavior, but case-sensitively on other platforms.
- **Owned Strings**: The map stores its own copies of keys and values (unless `putMove` is used).
- **Iteration Support**: Maintains insertion order for predictable iteration.

---

## Fields

`array_hash_map: ArrayHashMap`
------
The underlying storage, using `std.ArrayHashMapUnmanaged` with a platform-specific hash context.

`allocator: Allocator`
------
The allocator used for internal map storage and for copying key/value strings.

---

## Types

### `Size`
Equivalent to `usize`.

---

## Functions

### `pub fn init(allocator: Allocator) Map`
Creates an empty environment map using the provided allocator.

------

### `pub fn deinit(self: *Map) void`
Frees all internal storage and all copies of keys and values stored in the map.

------

### `pub fn get(self: Map, key: []const u8) ?[]const u8`
Returns the value associated with a key, or `null` if not found. The returned slice is valid until the key is removed or the map is deinitialized.

------

### `pub fn put(self: *Map, key: []const u8, value: []const u8) !void`
Copies both `key` and `value` into the map. If the key already exists, its previous value is freed and replaced.

------

### `pub fn putMove(self: *Map, key: []u8, value: []u8) !void`
Like `put`, but takes ownership of the provided `key` and `value` slices. They must have been allocated with the same allocator as the Map.

------

### `pub fn swapRemove(self: *Map, key: []const u8) bool`
Removes an entry from the map. Does not preserve insertion order (faster than `orderedRemove`). Returns `true` if a key was found and removed.

------

### `pub fn orderedRemove(self: *Map, key: []const u8) bool`
Removes an entry while preserving the insertion order of other elements.

------

### `pub fn iterator(self: *const Map) Iterator`
Returns an iterator over the entries in the map. Entries are returned in insertion order.

------

### `pub fn clone(m: *const Map, gpa: Allocator) !Map`
Creates a deep copy of the map using a new allocator.

---

## Debug Checklist

✅ **Call `deinit()`** - Mandatory for maps you initialize yourself.

✅ **Handle `put` Errors** - `put` can fail with `error.OutOfMemory`.

✅ **Use `swapRemove` for Speed** - Unless you specifically need to preserve environment variable order, `swapRemove` is more efficient than `orderedRemove`.

✅ **Avoid Manual String Management** - The map handles string copies; don't free strings you've passed to `put`.

---

## Performance Tips

1. **Use `init.environ_map`** - Avoid re-parsing the environment block by using the map already provided by the runtime.
2. **Batch Updates** - If you are adding many variables, ensure the allocator (like an Arena) is efficient.
3. **Use `putMove` for Pre-Allocated Strings** - If you've already allocated keys/values with the map's allocator, `putMove` avoids an extra copy.

---

## See Also

- **std.process.Init** - Provides the process's default `environ_map`.
- **std.process.Environ** - The raw environment data source.
- **std.ArrayHashMap** - The underlying data structure.
