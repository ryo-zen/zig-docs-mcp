# std.array_hash_map.ArrayHashMap

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all ArrayHashMap features

## Quick Start

### Most Common Patterns

**Basic Usage with Custom Context**
```zig
const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

// Define custom hash context
const StringContext = struct {
    pub fn hash(ctx: @This(), key: []const u8) u32 {
  _ = ctx;
  return std.array_hash_map.hashString(key);
    }
    pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return std.mem.eql(u8, a, b);
    }
};

var map = std.array_hash_map.ArrayHashMap(
    []const u8,
    i32,
    StringContext,
    true  // store_hash
).init(allocator);
defer map.deinit();

try map.put("key", 42);
if (map.get("key")) |value| {
    std.debug.print("Value: {d}\n", .{value});
}
```

**Initialization with Context Instance**
```zig
const MyContext = struct {
    seed: u64,

    pub fn hash(ctx: @This(), key: u64) u32 {
  var hasher = std.hash.Wyhash.init(ctx.seed);
  std.hash.autoHash(&hasher, key);
  return @truncate(hasher.final());
    }

    pub fn eql(ctx: @This(), a: u64, b: u64, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return a == b;
    }
};

const ctx = MyContext{ .seed = 12345 };
var map = std.array_hash_map.ArrayHashMap(u64, []const u8, MyContext, false).initContext(allocator, ctx);
defer map.deinit();
```

**Iteration Pattern**
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{s} = {d}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

**getOrPut Pattern**
```zig
const result = try map.getOrPut("counter");
if (!result.found_existing) {
    result.value_ptr.* = 0;
}
result.value_ptr.* += 1;
```

### ⚠️ Critical: Always deinit!
```zig
var map = ArrayHashMap(...).init(allocator);
defer map.deinit();  // ← REQUIRED! Frees backing memory

// No need to pass allocator to each function - it's stored!
try map.put(key, value);
try map.ensureTotalCapacity(100);
```

---

## Overview

`ArrayHashMap` is a hash map that preserves insertion order, stores an allocator internally, and requires a custom `Context` for hash and equality functions. This is the "managed" variant that provides convenience over the unmanaged version.

**Key Characteristics:**
- **Stores allocator**: No need to pass `Allocator` to each function
- **Stores context**: Context instance embedded in the map
- **Insertion order preserved**: Iteration returns entries in insertion order
- **Custom Context required**: You define hash and equality functions
- **Backed by ArrayList**: Uses `std.MultiArrayList` for sequential storage
- **Fast small maps**: Linear scan for <9 entries (no hash table overhead)
- **O(1) lookups**: Hash-based indexing once size exceeds linear scan threshold
- **Store hash optional**: `store_hash` parameter controls whether hashes are cached

**When to use ArrayHashMap:**
- You want the convenience of stored allocator/context
- You need custom hash and equality logic for your key type
- You want insertion order preserved
- You prefer simpler API over minimal memory footprint

**When NOT to use:**
- You want automatic hash/eql → Use `AutoArrayHashMap`
- You need minimal struct size → Use `ArrayHashMapUnmanaged`
- Order doesn't matter → Consider `std.HashMap`
- You're writing library code that shouldn't assume an allocator → Use unmanaged variant

## Parameters

### `K: type`
The key type. Can be any type, but you must provide appropriate `hash` and `eql` functions in the `Context`.

### `V: type`
The value type. Can be any type.

### `Context: type`
A namespace that provides hash and equality functions. Must have:

```zig
const MyContext = struct {
    // Optional: can have state fields
    seed: u64,

    pub fn hash(self: @This(), key: K) u32 {
  // Return u32 hash of key
  // Can use self.seed or other state
    }

    pub fn eql(self: @This(), a: K, b: K, b_index: usize) bool {
  // Return true if a equals b
  // b_index is the position of b in the map
    }
};
```

**Example Contexts:**

```zig
// Stateless context for strings
const StringContext = struct {
    pub fn hash(ctx: @This(), key: []const u8) u32 {
  _ = ctx;
  return std.array_hash_map.hashString(key);
    }
    pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return std.mem.eql(u8, a, b);
    }
};

// Stateful context with seed
const SeededIntContext = struct {
    seed: u64,

    pub fn hash(ctx: @This(), key: u64) u32 {
  var hasher = std.hash.Wyhash.init(ctx.seed);
  std.hash.autoHash(&hasher, key);
  return @truncate(hasher.final());
    }

    pub fn eql(ctx: @This(), a: u64, b: u64, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return a == b;
    }
};

// Case-insensitive string context
const CaseInsensitiveContext = struct {
    pub fn hash(ctx: @This(), key: []const u8) u32 {
  _ = ctx;
  var hasher = std.hash.Wyhash.init(0);
  for (key) |c| {
      std.hash.autoHash(&hasher, std.ascii.toLower(c));
  }
  return @truncate(hasher.final());
    }

    pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return std.ascii.eqlIgnoreCase(a, b);
    }
};
```

### `store_hash: bool`
When `false`, the map doesn't store hash values, saving memory but requiring rehashing on lookups. When `true`, hashes are cached.

**Guidelines:**
- Set to `false` if equality checks are cheap (integers, small types)
- Set to `true` if equality checks are expensive (strings, large structs)
- Trade-off: Memory usage vs. computation time

## Fields

### `unmanaged: Unmanaged`

The underlying unmanaged map. Advanced users can access this for lower-level operations, but must then manage the allocator manually.

------

### `allocator: Allocator`

The allocator used for all memory operations. Stored for convenience.

------

### `ctx: Context`

The context instance providing hash and equality functions. If Context has state, this is where it's stored.

## Types

- **Unmanaged** - The unmanaged variant: `ArrayHashMapUnmanaged(K, V, Context, store_hash)`
- **Data** - The MultiArrayList entry structure
- **DataList** - The MultiArrayList type backing this map
- **Entry** - Pointers to a key and value (mutable)
- **GetOrPutResult** - Result from `getOrPut` with `found_existing` flag and entry pointers
- **Hash** - Either `u32` (if `store_hash == true`) or `void`
- **Iterator** - Iterator over Entry pointers
- **KV** - A key-value pair copied from the map

## Initialization Functions

### `pub fn init(allocator: Allocator) Self`

Create an empty map with default-initialized context.

**Example:**
```zig
var map = std.array_hash_map.ArrayHashMap(u64, []const u8, IntContext, false).init(allocator);
defer map.deinit();
```

------

### `pub fn initContext(allocator: Allocator, ctx: Context) Self`

Create an empty map with a specific context instance (useful if Context has state).

**Example:**
```zig
const ctx = SeededContext{ .seed = 42 };
var map = std.array_hash_map.ArrayHashMap(K, V, SeededContext, true).initContext(allocator, ctx);
defer map.deinit();
```

## Core Insertion Functions

### `pub fn put(self: *Self, key: K, value: V) !void`

Insert or update a key-value pair. Replaces existing value if key exists.

**Example:**
```zig
try map.put("key", 42);
try map.put("key", 99);  // Replaces 42 with 99
```

------

### `pub fn putNoClobber(self: *Self, key: K, value: V) !void`

Insert a key-value pair, asserting the key doesn't already exist.

**Example:**
```zig
try map.putNoClobber("new_key", 10);
// try map.putNoClobber("new_key", 20);  // ← Asserts in debug!
```

------

### `pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`

Insert or update without allocating. Asserts sufficient capacity.

**Example:**
```zig
try map.ensureTotalCapacity(100);
map.putAssumeCapacity("key1", 1);
map.putAssumeCapacity("key2", 2);
```

------

### `pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`

Insert without allocating, asserting key doesn't exist and capacity is sufficient.

------

### `pub fn fetchPut(self: *Self, key: K, value: V) !?KV`

Insert or update, returning the previous key-value pair if it existed.

**Example:**
```zig
const prev = try map.fetchPut("key", 99);
if (prev) |kv| {
    std.debug.print("Replaced: {} = {}\n", .{kv.key, kv.value});
}
```

------

### `pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`

Like `fetchPut` but assumes capacity.

## Lookup Functions

### `pub fn get(self: Self, key: K) ?V`

Get a copy of the value for a key.

**Example:**
```zig
if (map.get("key")) |value| {
    std.debug.print("Value: {}\n", .{value});
}
```

------

### `pub fn getPtr(self: Self, key: K) ?*V`

Get a mutable pointer to a value for in-place modification.

**Example:**
```zig
if (map.getPtr("counter")) |ptr| {
    ptr.* += 1;
}
```

------

### `pub fn getEntry(self: Self, key: K) ?Entry`

Get pointers to both key and value storage.

**Example:**
```zig
if (map.getEntry("key")) |entry| {
    entry.value_ptr.* = new_value;
}
```

------

### `pub fn getIndex(self: Self, key: K) ?usize`

Get the index in the backing array where a key is stored.

**Example:**
```zig
if (map.getIndex("key")) |index| {
    const keys_array = map.keys();
    std.debug.print("Key at {d}: {}\n", .{index, keys_array[index]});
}
```

------

### `pub fn getKey(self: Self, key: K) ?K`

Get a copy of the actual key stored in the map.

------

### `pub fn getKeyPtr(self: Self, key: K) ?*K`

Get a pointer to the actual key.

------

### `pub fn contains(self: Self, key: K) bool`

Check if a key exists.

**Example:**
```zig
if (map.contains("key")) {
    std.debug.print("Found!\n", .{});
}
```

------

### `pub fn getOrPut(self: *Self, key: K) !GetOrPutResult`

Get an existing entry or create a new one. Caller must initialize value if `!found_existing`.

**Example:**
```zig
const result = try map.getOrPut("counter");
if (!result.found_existing) {
    result.value_ptr.* = 0;
}
result.value_ptr.* += 1;
```

------

### `pub fn getOrPutValue(self: *Self, key: K, value: V) !GetOrPutResult`

Get or create, initializing new entries with `value`.

**Example:**
```zig
const result = try map.getOrPutValue("default", 42);
```

------

### `pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`

Like `getOrPut` but assumes capacity.

## Adapted Lookup Functions

These accept a key-like value of a different type with its own context.

### `pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`
### `pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`
### `pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`
### `pub fn getIndexAdapted(self: Self, key: anytype, ctx: anytype) ?usize`
### `pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`
### `pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`
### `pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`
### `pub fn getOrPutAdapted(self: *Self, key: anytype, ctx: anytype) !GetOrPutResult`
### `pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`

**Example:**
```zig
const AdaptCtx = struct {
    pub fn hash(ctx: @This(), key: []const u8) u32 {
  _ = ctx;
  return std.array_hash_map.hashString(key);
    }
    pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return std.mem.eql(u8, a, b);
    }
};

if (map.getAdapted("literal", AdaptCtx{})) |value| {
    std.debug.print("Found: {}\n", .{value});
}
```

## Removal Functions

### `pub fn swapRemove(self: *Self, key: K) bool`

Remove by swapping with last entry (O(1)). Destroys order.

**Example:**
```zig
if (map.swapRemove("key")) {
    std.debug.print("Removed\n", .{});
}
```

------

### `pub fn swapRemoveAt(self: *Self, index: usize) void`

Remove entry at index using swap removal.

------

### `pub fn orderedRemove(self: *Self, key: K) bool`

Remove by shifting entries forward (O(N)). Preserves order.

**Example:**
```zig
_ = map.orderedRemove("key");
```

------

### `pub fn orderedRemoveAt(self: *Self, index: usize) void`

Remove entry at index, preserving order.

------

### `pub fn fetchSwapRemove(self: *Self, key: K) ?KV`

Remove and return the key-value pair using swap removal.

**Example:**
```zig
if (map.fetchSwapRemove("key")) |kv| {
    std.debug.print("Removed: {} = {}\n", .{kv.key, kv.value});
}
```

------

### `pub fn fetchOrderedRemove(self: *Self, key: K) ?KV`

Remove and return the key-value pair, preserving order.

------

### `pub fn fetchSwapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`

Remove using an adapted key.

------

### `pub fn fetchOrderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`

Remove (preserving order) using an adapted key.

------

### `pub fn swapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`

Remove with adapted key (swap removal).

------

### `pub fn orderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`

Remove with adapted key (ordered removal).

------

### `pub fn pop(self: *Self) ?KV`

Remove and return the last inserted entry.

**Example:**
```zig
while (map.pop()) |kv| {
    std.debug.print("Popped: {} = {}\n", .{kv.key, kv.value});
}
```

## Capacity Management Functions

### `pub fn capacity(self: Self) usize`

Get the current capacity.

------

### `pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) !void`

Ensure the map can hold at least `new_capacity` total entries.

**Example:**
```zig
try map.ensureTotalCapacity(1000);
for (0..1000) |i| {
    map.putAssumeCapacity(i, i * 2);
}
```

------

### `pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) !void`

Ensure space for `additional_count` more entries.

**Example:**
```zig
try map.ensureUnusedCapacity(100);
// Can add 100 more without allocating
```

------

### `pub fn clearRetainingCapacity(self: *Self) void`

Remove all entries but keep allocated memory.

**Example:**
```zig
map.clearRetainingCapacity();
```

------

### `pub fn clearAndFree(self: *Self) void`

Remove all entries and free allocated memory.

**Example:**
```zig
map.clearAndFree();
```

------

### `pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`

Discard entries beyond `new_len`, keep capacity.

------

### `pub fn shrinkAndFree(self: *Self, new_len: usize) void`

Discard entries beyond `new_len` and reduce capacity.

## Iteration & Access Functions

### `pub fn iterator(self: *const Self) Iterator`

Get an iterator over all entries.

**Example:**
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{} = {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

------

### `pub fn keys(self: Self) []K`

Get direct access to the backing array of keys.

**Example:**
```zig
const keys_array = map.keys();
for (keys_array) |key| {
    std.debug.print("Key: {}\n", .{key});
}
```

⚠️ **Warning:** Modifying keys requires calling `reIndex()` afterward.

------

### `pub fn values(self: Self) []V`

Get direct access to the backing array of values.

**Example:**
```zig
const values_array = map.values();
for (values_array) |*value| {
    value.* = transform(value.*);
}
```

------

### `pub fn count(self: Self) usize`

Get the number of entries.

**Example:**
```zig
std.debug.print("Map has {d} entries\n", .{map.count()});
```

## Advanced Functions

### `pub fn clone(self: Self) !Self`

Create a deep copy using the same allocator and context.

**Example:**
```zig
var map2 = try map.clone();
defer map2.deinit();
```

------

### `pub fn cloneWithAllocator(self: Self, allocator: Allocator) !Self`

Clone with a different allocator.

------

### `pub fn cloneWithContext(self: Self, ctx: anytype) !ArrayHashMap(K, V, @TypeOf(ctx), store_hash)`

Clone with a different context type.

------

### `pub fn cloneWithAllocatorAndContext(self: Self, allocator: Allocator, ctx: anytype) !ArrayHashMap(K, V, @TypeOf(ctx), store_hash)`

Clone with different allocator and context.

------

### `pub fn move(self: *Self) Self`

Transfer ownership, leaving original empty.

**Example:**
```zig
const map2 = map.move();
defer map2.deinit();
```

------

### `pub fn sort(self: *Self, sort_ctx: anytype) void`

Sort entries by custom comparison (stable).

**Example:**
```zig
const SortCtx = struct {
    keys: []const K,
    pub fn lessThan(ctx: @This(), a_idx: usize, b_idx: usize) bool {
  return ctx.keys[a_idx] < ctx.keys[b_idx];
    }
};

map.sort(SortCtx{ .keys = map.keys() });
```

------

### `pub fn sortUnstable(self: *Self, sort_ctx: anytype) void`

Sort entries using unstable sort (potentially faster).

------

### `pub fn reIndex(self: *Self) !void`

Rebuild the hash index after direct key modifications.

**Example:**
```zig
const keys_array = map.keys();
keys_array[0] = new_key;
try map.reIndex();
```

------

### `pub fn lockPointers(self: *Self) void`

Enable pointer stability checking.

------

### `pub fn unlockPointers(self: *Self) void`

Disable pointer stability checking.

------

### `pub fn deinit(self: *Self) void`

Free all memory. Does NOT free heap-allocated keys or values.

**Example:**
```zig
var map = ArrayHashMap(...).init(allocator);
defer map.deinit();
```

## Usage Patterns

### Pattern 1: Case-Insensitive String Map

```zig
const std = @import("std");

const CaseInsensitiveContext = struct {
    pub fn hash(ctx: @This(), key: []const u8) u32 {
  _ = ctx;
  var hasher = std.hash.Wyhash.init(0);
  for (key) |c| {
      std.hash.autoHash(&hasher, std.ascii.toLower(c));
  }
  return @truncate(hasher.final());
    }

    pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return std.ascii.eqlIgnoreCase(a, b);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var map = std.array_hash_map.ArrayHashMap(
  []const u8,
  i32,
  CaseInsensitiveContext,
  true
    ).init(gpa.allocator());
    defer map.deinit();

    try map.put("Hello", 1);

    // Case-insensitive lookup
    const value = map.get("HELLO");  // Returns 1
}
```

### Pattern 2: Seeded Hash Map for Security

```zig
const std = @import("std");

const SeededStringContext = struct {
    seed: u64,

    pub fn hash(ctx: @This(), key: []const u8) u32 {
  var hasher = std.hash.Wyhash.init(ctx.seed);
  hasher.update(key);
  return @truncate(hasher.final());
    }

    pub fn eql(ctx: @This(), a: []const u8, b: []const u8, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return std.mem.eql(u8, a, b);
    }
};

pub fn createSecureMap(allocator: std.mem.Allocator, io: std.Io) !std.array_hash_map.ArrayHashMap([]const u8, []const u8, SeededStringContext, true) {
    // Random seed to prevent hash collision attacks
    var seed: u64 = undefined;
    try io.randomSecure(std.mem.asBytes(&seed));

    const ctx = SeededStringContext{ .seed = seed };
    return std.array_hash_map.ArrayHashMap(
  []const u8,
  []const u8,
  SeededStringContext,
  true
    ).initContext(allocator, ctx);
}
```

### Pattern 3: Custom Struct Keys

```zig
const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,
};

const PointContext = struct {
    pub fn hash(ctx: @This(), p: Point) u32 {
  _ = ctx;
  var hasher = std.hash.Wyhash.init(0);
  std.hash.autoHash(&hasher, p.x);
  std.hash.autoHash(&hasher, p.y);
  return @truncate(hasher.final());
    }

    pub fn eql(ctx: @This(), a: Point, b: Point, b_index: usize) bool {
  _ = ctx;
  _ = b_index;
  return a.x == b.x and a.y == b.y;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var map = std.array_hash_map.ArrayHashMap(
  Point,
  []const u8,
  PointContext,
  false
    ).init(gpa.allocator());
    defer map.deinit();

    try map.put(Point{ .x = 10, .y = 20 }, "A");
    try map.put(Point{ .x = 30, .y = 40 }, "B");

    if (map.get(Point{ .x = 10, .y = 20 })) |label| {
  std.debug.print("Point labeled: {s}\n", .{label});
    }
}
```

## Error Sets

Functions that can fail return:

- **`Allocator.Error`**:
  - `OutOfMemory` - Allocation failed

Functions that allocate:
- `put`, `putNoClobber`
- `fetchPut`
- `getOrPut`, `getOrPutValue`, `getOrPutAdapted`
- `ensureTotalCapacity`, `ensureUnusedCapacity`
- `clone`, `cloneWithAllocator`, `cloneWithContext`, `cloneWithAllocatorAndContext`
- `reIndex`
- `sort`, `sortUnstable`

## Debug Checklist

When debugging ArrayHashMap issues:

1. ✅ **Called `deinit()`** - Memory leak if forgotten
2. ✅ **Context hash/eql correct** - Incorrect implementations cause lookup failures
3. ✅ **Not using pointers after modification** - Insertions/removals invalidate entry pointers
4. ✅ **Freeing keys/values separately** - `deinit()` only frees the map structure
5. ✅ **Not modifying keys without reIndex** - Direct key modification breaks hash table
6. ✅ **Using correct removal function** - `swapRemove` vs `orderedRemove` semantics
7. ✅ **Pre-allocated before AssumeCapacity** - `AssumeCapacity` functions assert on overflow
8. ✅ **Checking found_existing in getOrPut** - Initialize value only when false
9. ✅ **store_hash matches eql cost** - `false` for cheap eql, `true` for expensive
10. ✅ **Context instance initialized** - If Context has state fields
11. ✅ **Adapted key context compatible** - hash/eql for adapted keys must match

## Performance Tips

1. **Pre-allocate for known sizes**
   ```zig
   try map.ensureTotalCapacity(expected_size);
   for (items) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

2. **Use swapRemove when order doesn't matter** - O(1) vs O(N)

3. **Set store_hash appropriately**
   - `false` for cheap equality (integers, small types)
   - `true` for expensive equality (strings, large structs)

4. **Reuse cleared maps**
   ```zig
   map.clearRetainingCapacity();  // Faster than deinit + init
   ```

5. **Access arrays directly for bulk operations**
   ```zig
   const values = map.values();
   for (values) |*v| v.* = transform(v.*);
   ```

6. **Use getPtr for in-place modification**
   ```zig
   if (map.getPtr(key)) |ptr| {
 ptr.* = new_value;
   }
   ```

7. **Batch operations with ensureUnusedCapacity**
   ```zig
   try map.ensureUnusedCapacity(batch.len);
   for (batch) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

8. **Small maps stay linear** - No hash overhead for <9 entries

9. **Use adapted lookups for temporary keys** - Avoid allocation

10. **Consider AutoArrayHashMap** - If you don't need custom hash/eql

11. **Use move() for ownership transfer** - Zero-cost without cloning

12. **Keep Context lightweight** - It's stored in every map instance

## See Also

- **std.array_hash_map.AutoArrayHashMap** - Managed with automatic hash/eql
- **std.array_hash_map.ArrayHashMapUnmanaged** - Unmanaged variant (more control, less convenience)
- **std.array_hash_map.AutoArrayHashMapUnmanaged** - Unmanaged with automatic hash/eql
- **std.HashMap** - Unordered hash map (doesn't preserve insertion order)
- **std.MultiArrayList** - The underlying sequential storage structure
- **std.array_hash_map.AutoContext** - Helper for creating automatic hash contexts
- **std.array_hash_map.hashString** - Utility for hashing strings
