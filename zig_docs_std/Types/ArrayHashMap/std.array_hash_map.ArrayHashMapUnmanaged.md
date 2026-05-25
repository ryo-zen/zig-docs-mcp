# std.ArrayHashMapUnmanaged

`std.ArrayHashMapUnmanaged` is a deprecated root alias for the canonical type function `std.array_hash_map.Custom`.

## Source Declaration

```zig
/// Deprecated; use `array_hash_map.Custom`.
pub const ArrayHashMapUnmanaged = array_hash_map.Custom;
```

## Replacement

New code should use `std.array_hash_map.Custom(K, V, Context, store_hash)` directly. This page exists for older code and searchability; the alias calls the same implementation.

The full field, value, and method surface is documented by the `std.array_hash_map.Custom` implementation.

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all ArrayHashMapUnmanaged features

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

var map = std.array_hash_map.ArrayHashMapUnmanaged(
    []const u8,
    i32,
    StringContext,
    true  // store_hash
){};
defer map.deinit(allocator);

try map.put(allocator, "key", 42);
```

**Empty Initialization**
```zig
// Preferred: use .empty
var map = std.array_hash_map.ArrayHashMapUnmanaged(K, V, Context, store_hash).empty;
defer map.deinit(allocator);

// Direct initialization also works
var map2: std.array_hash_map.ArrayHashMapUnmanaged(K, V, Context, store_hash) = .{};
defer map2.deinit(allocator);
```

**Iteration Pattern**
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{s} = {d}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

**getOrPut with Allocator**
```zig
const result = try map.getOrPut(allocator, key);
if (!result.found_existing) {
    result.value_ptr.* = default_value;
}
```

**Pre-allocation for Performance**
```zig
try map.ensureTotalCapacity(allocator, 1000);
for (items) |item| {
    map.putAssumeCapacity(item.key, item.value);  // No allocator needed!
}
```

### ⚠️ Critical: Always pass allocator and deinit!
```zig
var map = ArrayHashMapUnmanaged(...).empty;
defer map.deinit(allocator);  // ← REQUIRED! Pass the same allocator

// Every allocating function needs the allocator
try map.put(allocator, key, value);
try map.ensureTotalCapacity(allocator, 100);
```

---

## Overview

`ArrayHashMapUnmanaged` is a hash map that preserves insertion order and does NOT store an allocator internally. You must pass an `Allocator` to each function that needs it. This gives you more control over memory and reduces the size of the map struct itself.

**Key Characteristics:**
- **No stored allocator**: Pass `Allocator` as parameter to each allocating function
- **Insertion order preserved**: Iteration returns entries in insertion order
- **Custom Context required**: You define hash and equality functions
- **Backed by ArrayList**: Uses `std.MultiArrayList` for sequential storage
- **Fast small maps**: Linear scan for <9 entries (no hash table overhead)
- **O(1) lookups**: Hash-based indexing once size exceeds linear scan threshold
- **Minimal overhead**: Only 3 pointers + lock when empty, very cache-friendly
- **Store hash optional**: `store_hash` parameter controls whether hashes are cached

**When to use ArrayHashMapUnmanaged:**
- You need fine-grained control over memory allocation
- You're embedding maps in other data structures and want minimal size
- You need custom hash and equality logic for your key type
- You want insertion order preserved
- You're writing library code that shouldn't assume an allocator

**When NOT to use:**
- You want automatic hash/eql → Use `AutoArrayHashMapUnmanaged`
- You prefer convenience → Use `ArrayHashMap` (stores allocator)
- Order doesn't matter → Consider `std.HashMapUnmanaged`
- You need simple string keys → Use `AutoArrayHashMapUnmanaged([]const u8, V)`

## Parameters

### `K: type`
The key type. Can be any type, but you must provide appropriate `hash` and `eql` functions in the `Context`.

### `V: type`
The value type. Can be any type.

### `Context: type`
A namespace that provides hash and equality functions. Must have:

```zig
const MyContext = struct {
    pub fn hash(self: @This(), key: K) u32 {
  // Return u32 hash of key
    }

    pub fn eql(self: @This(), a: K, b: K, b_index: usize) bool {
  // Return true if a equals b
  // b_index is the position of b in the map (can be ignored unless needed)
    }
};
```

**Example Contexts:**
```zig
// For integers
const IntContext = std.array_hash_map.AutoContext(u64);

// For strings
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

// For custom structs
const Point = struct { x: i32, y: i32 };
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
```

### `store_hash: bool`
When `false`, the map doesn't store hash values, saving memory but requiring rehashing on lookups. When `true`, hashes are cached.

**Guidelines:**
- Set to `false` if equality checks are cheap (integers, small types)
- Set to `true` if equality checks are expensive (strings, large structs)
- Trade-off: Memory usage vs. computation time

**Example:**
```zig
// Cheap eql → don't store hash
var int_map = ArrayHashMapUnmanaged(u64, V, AutoContext(u64), false).empty;

// Expensive eql → store hash
var string_map = ArrayHashMapUnmanaged([]const u8, V, StringContext, true).empty;
```

## Fields

### `entries: DataList = .{}`

The backing MultiArrayList that stores keys and values sequentially. It's permitted to access this field directly for advanced use cases. After modifying keys directly, call `reIndex()` to rebuild the hash table.

**Example:**
```zig
// Direct access to underlying data
const keys_slice = map.entries.items(.key);
const values_slice = map.entries.items(.value);
```

------

### `index_header: ?*IndexHeader = null`

When the map has fewer than `linear_scan_max` (9) entries, this remains `null` and lookups use linear scan. Once the map grows larger, this field points to an allocated hash index structure.

**Advanced:** The IndexHeader is followed by an array of `Index(I)` structs in memory, where `I` depends on the total number of index slots.

------

### `pointer_stability: std.debug.SafetyLock = .{}`

Used to detect memory safety violations in debug builds. When `lockPointers()` is called, this lock is engaged, and any operation that would invalidate existing pointers triggers an assertion.

## Types

- **Data** - The struct layout for MultiArrayList entries (contains key, value, and optionally hash fields)
- **DataList** - The MultiArrayList type backing this map (`std.MultiArrayList(Data)`)
- **Entry** - Pointers to a key and value in the map (mutable)
- **GetOrPutResult** - Result from `getOrPut` with `found_existing: bool` and entry pointers
- **Hash** - Either `u32` (if `store_hash == true`) or `void` (if `store_hash == false`)
- **Iterator** - Iterator over Entry pointers
- **KV** - A key-value pair copied out of the backing store
- **Managed** - The managed variant: `ArrayHashMap(K, V, Context, store_hash)`

## Values

|       |        |                                     |
|-------|--------|-------------------------------------|
| empty | `Self` | A map containing no keys or values. Preferred initialization method. |

**Example:**
```zig
var map = ArrayHashMapUnmanaged(K, V, Context, store_hash).empty;
```

## Initialization Functions

### `pub fn init(gpa: Allocator, key_list: []const K, value_list: []const V) Oom!Self`

Create a map initialized with parallel slices of keys and values. The slices must have the same length.

**Example:**
```zig
const keys = [_][]const u8{ "a", "b", "c" };
const values = [_]i32{ 1, 2, 3 };
var map = try ArrayHashMapUnmanaged([]const u8, i32, StringContext, true).init(
    allocator,
    &keys,
    &values
);
defer map.deinit(allocator);
```

------

### `pub fn reinit(self: *Self, gpa: Allocator, key_list: []const K, value_list: []const V) Oom!void`

Replace the map contents with new key-value pairs. An empty `value_list` may be passed, in which case values become `undefined`.

## Core Insertion Functions

### `pub fn put(self: *Self, gpa: Allocator, key: K, value: V) Oom!void`

Insert or update a key-value pair. If the key exists, its value is replaced (clobbered).

**Example:**
```zig
try map.put(allocator, "key", 42);
try map.put(allocator, "key", 99);  // Replaces 42 with 99
```

------

### `pub fn putContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!void`

Like `put` but uses a custom context instance. Useful if your Context has state.

**Example:**
```zig
const ctx = MyContext{ .seed = 12345 };
try map.putContext(allocator, key, value, ctx);
```

------

### `pub fn putNoClobber(self: *Self, gpa: Allocator, key: K, value: V) Oom!void`

Insert a key-value pair, asserting the key doesn't already exist. Debug builds trigger assertion if key exists.

**Example:**
```zig
try map.putNoClobber(allocator, "new_key", 10);
// try map.putNoClobber(allocator, "new_key", 20);  // ← Asserts in debug!
```

------

### `pub fn putNoClobberContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!void`

Like `putNoClobber` with custom context.

------

### `pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`

Insert or update without allocating. Asserts sufficient capacity. Use after `ensureTotalCapacity`.

**Example:**
```zig
try map.ensureTotalCapacity(allocator, 100);
map.putAssumeCapacity("key1", 1);  // No allocator needed!
map.putAssumeCapacity("key2", 2);
```

------

### `pub fn putAssumeCapacityContext(self: *Self, key: K, value: V, ctx: Context) void`

Like `putAssumeCapacity` with custom context.

------

### `pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`

Insert without allocating, asserting the key doesn't exist and capacity is sufficient.

------

### `pub fn putAssumeCapacityNoClobberContext(self: *Self, key: K, value: V, ctx: Context) void`

Like `putAssumeCapacityNoClobber` with custom context.

------

### `pub fn fetchPut(self: *Self, gpa: Allocator, key: K, value: V) Oom!?KV`

Insert or update, returning the previous key-value pair if it existed.

**Example:**
```zig
const prev = try map.fetchPut(allocator, "key", 99);
if (prev) |kv| {
    std.debug.print("Replaced: {s} = {d}\n", .{kv.key, kv.value});
}
```

------

### `pub fn fetchPutContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!?KV`

Like `fetchPut` with custom context.

------

### `pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`

Like `fetchPut` but assumes capacity. Returns previous KV if key existed.

------

### `pub fn fetchPutAssumeCapacityContext(self: *Self, key: K, value: V, ctx: Context) ?KV`

Like `fetchPutAssumeCapacity` with custom context.

## Lookup Functions

### `pub fn get(self: Self, key: K) ?V`

Get a copy of the value for a key, using the default context.

**Example:**
```zig
if (map.get("key")) |value| {
    std.debug.print("Value: {d}\n", .{value});
}
```

------

### `pub fn getContext(self: Self, key: K, ctx: Context) ?V`

Get a value using a custom context instance.

------

### `pub fn getPtr(self: Self, key: K) ?*V`

Get a mutable pointer to a value for in-place modification.

**Example:**
```zig
if (map.getPtr("counter")) |ptr| {
    ptr.* += 1;  // Modify in place
}
```

------

### `pub fn getPtrContext(self: Self, key: K, ctx: Context) ?*V`

Like `getPtr` with custom context.

------

### `pub fn getEntry(self: Self, key: K) ?Entry`

Get pointers to both key and value storage.

**Example:**
```zig
if (map.getEntry("key")) |entry| {
    std.debug.print("Key: {}, Value: {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
    entry.value_ptr.* = new_value;  // Modify value
}
```

------

### `pub fn getEntryContext(self: Self, key: K, ctx: Context) ?Entry`

Like `getEntry` with custom context.

------

### `pub fn getIndex(self: Self, key: K) ?usize`

Get the index in the `entries` array where a key is stored.

**Example:**
```zig
if (map.getIndex("key")) |index| {
    const keys_array = map.keys();
    std.debug.print("Key at index {d}: {}\n", .{index, keys_array[index]});
}
```

------

### `pub fn getIndexContext(self: Self, key: K, ctx: Context) ?usize`

Like `getIndex` with custom context.

------

### `pub fn getKey(self: Self, key: K) ?K`

Get a copy of the actual key stored in the map.

------

### `pub fn getKeyContext(self: Self, key: K, ctx: Context) ?K`

Like `getKey` with custom context.

------

### `pub fn getKeyPtr(self: Self, key: K) ?*K`

Get a pointer to the actual key stored in the map.

------

### `pub fn getKeyPtrContext(self: Self, key: K, ctx: Context) ?*K`

Like `getKeyPtr` with custom context.

------

### `pub fn contains(self: Self, key: K) bool`

Check if a key exists using the default context.

**Example:**
```zig
if (map.contains("key")) {
    std.debug.print("Found!\n", .{});
}
```

------

### `pub fn containsContext(self: Self, key: K, ctx: Context) bool`

Check if a key exists using a custom context.

------

### `pub fn getOrPut(self: *Self, gpa: Allocator, key: K) Oom!GetOrPutResult`

Get an existing entry or create a new one. Caller must initialize the value if `!found_existing`.

**Example:**
```zig
const result = try map.getOrPut(allocator, "counter");
if (!result.found_existing) {
    result.value_ptr.* = 0;  // Initialize
}
result.value_ptr.* += 1;
```

------

### `pub fn getOrPutContext(self: *Self, gpa: Allocator, key: K, ctx: Context) Oom!GetOrPutResult`

Like `getOrPut` with custom context.

------

### `pub fn getOrPutValue(self: *Self, gpa: Allocator, key: K, value: V) Oom!GetOrPutResult`

Get or create, initializing new entries with `value`.

**Example:**
```zig
const result = try map.getOrPutValue(allocator, "default", 42);
// Entry now exists with value 42 if it was new
```

------

### `pub fn getOrPutValueContext(self: *Self, gpa: Allocator, key: K, value: V, ctx: Context) Oom!GetOrPutResult`

Like `getOrPutValue` with custom context.

------

### `pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`

Like `getOrPut` but assumes capacity (no allocator needed).

**Example:**
```zig
try map.ensureUnusedCapacity(allocator, 10);
const result = map.getOrPutAssumeCapacity("key");
if (!result.found_existing) {
    result.value_ptr.* = default;
}
```

------

### `pub fn getOrPutAssumeCapacityContext(self: *Self, key: K, ctx: Context) GetOrPutResult`

Like `getOrPutAssumeCapacity` with custom context.

## Adapted Lookup Functions

These accept a key-like value of a different type with its own context. Useful for lookups without allocating a full key.

### `pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`
### `pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`
### `pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`
### `pub fn getIndexAdapted(self: Self, key: anytype, ctx: anytype) ?usize`
### `pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`
### `pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`
### `pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`
### `pub fn getOrPutAdapted(self: *Self, gpa: Allocator, key: anytype, key_ctx: anytype) Oom!GetOrPutResult`
### `pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`
### `pub fn getOrPutContextAdapted(self: *Self, gpa: Allocator, key: anytype, key_ctx: anytype, ctx: Context) Oom!GetOrPutResult`

**Example of Adapted Lookup:**
```zig
// Map stores owned strings, but lookup with string literals
const StringAdaptCtx = struct {
    pub fn hash(ctx: @This(), key: []const u8) u32 {
  _ = ctx;
  return std.array_hash_map.hashString(key);
    }
    pub fn eql(ctx: @This(), adapted: []const u8, stored: []const u8, stored_idx: usize) bool {
  _ = ctx;
  _ = stored_idx;
  return std.mem.eql(u8, adapted, stored);
    }
};

// Look up without allocating
if (map.getAdapted("literal_key", StringAdaptCtx{})) |value| {
    std.debug.print("Found: {}\n", .{value});
}
```

## Removal Functions

### `pub fn swapRemove(self: *Self, key: K) bool`

Remove an entry by swapping with the last entry (O(1)). Destroys insertion order.

**Example:**
```zig
if (map.swapRemove("key")) {
    std.debug.print("Removed\n", .{});
}
```

------

### `pub fn swapRemoveContext(self: *Self, key: K, ctx: Context) bool`

Like `swapRemove` with custom context.

------

### `pub fn swapRemoveAt(self: *Self, index: usize) void`

Remove entry at a specific index using swap removal.

------

### `pub fn swapRemoveAtContext(self: *Self, index: usize, ctx: Context) void`

Like `swapRemoveAt` with custom context.

------

### `pub fn orderedRemove(self: *Self, key: K) bool`

Remove entry by shifting all subsequent entries forward (O(N)). Preserves order.

**Example:**
```zig
_ = map.orderedRemove("key");  // Order preserved
```

------

### `pub fn orderedRemoveContext(self: *Self, key: K, ctx: Context) bool`

Like `orderedRemove` with custom context.

------

### `pub fn orderedRemoveAt(self: *Self, index: usize) void`

Remove entry at index, preserving order.

------

### `pub fn orderedRemoveAtContext(self: *Self, index: usize, ctx: Context) void`

Like `orderedRemoveAt` with custom context.

------

### `pub fn orderedRemoveAtMany(self: *Self, gpa: Allocator, sorted_indexes: []const usize) Oom!void`

Remove multiple entries by index. `sorted_indexes` must be sorted in ascending order and represent indices before any deletion.

**Example:**
```zig
const to_remove = [_]usize{ 2, 5, 8 };  // Must be sorted
try map.orderedRemoveAtMany(allocator, &to_remove);
```

------

### `pub fn orderedRemoveAtManyContext(self: *Self, gpa: Allocator, sorted_indexes: []const usize, ctx: Context) Oom!void`

Like `orderedRemoveAtMany` with custom context.

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

### `pub fn fetchSwapRemoveContext(self: *Self, key: K, ctx: Context) ?KV`

Like `fetchSwapRemove` with custom context.

------

### `pub fn fetchOrderedRemove(self: *Self, key: K) ?KV`

Remove and return the key-value pair, preserving order.

------

### `pub fn fetchOrderedRemoveContext(self: *Self, key: K, ctx: Context) ?KV`

Like `fetchOrderedRemove` with custom context.

------

### `pub fn fetchSwapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`

Remove using an adapted key.

------

### `pub fn fetchSwapRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) ?KV`

Remove using adapted key with both key context and map context.

------

### `pub fn fetchOrderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`

Remove (preserving order) using adapted key.

------

### `pub fn fetchOrderedRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) ?KV`

Like above with both contexts.

------

### `pub fn swapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`

Remove with adapted key (swap removal).

------

### `pub fn swapRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) bool`

Like above with both contexts.

------

### `pub fn orderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`

Remove with adapted key (ordered removal).

------

### `pub fn orderedRemoveContextAdapted(self: *Self, key: anytype, key_ctx: anytype, ctx: Context) bool`

Like above with both contexts.

------

### `pub fn pop(self: *Self) ?KV`

Remove and return the last inserted entry.

**Example:**
```zig
while (map.pop()) |kv| {
    std.debug.print("Popped: {} = {}\n", .{kv.key, kv.value});
}
```

------

### `pub fn popContext(self: *Self, ctx: Context) ?KV`

Like `pop` with custom context.

## Capacity Management Functions

### `pub fn capacity(self: Self) usize`

Get the current capacity (total entries storable without allocating).

------

### `pub fn ensureTotalCapacity(self: *Self, gpa: Allocator, new_capacity: usize) Oom!void`

Ensure the map can hold at least `new_capacity` total entries.

**Example:**
```zig
try map.ensureTotalCapacity(allocator, 1000);
for (0..1000) |i| {
    map.putAssumeCapacity(i, i * 2);  // No allocation
}
```

------

### `pub fn ensureTotalCapacityContext(self: *Self, gpa: Allocator, new_capacity: usize, ctx: Context) Oom!void`

Like `ensureTotalCapacity` with custom context.

------

### `pub fn ensureUnusedCapacity(self: *Self, gpa: Allocator, additional_capacity: usize) Oom!void`

Ensure space for `additional_capacity` more entries beyond current count.

**Example:**
```zig
try map.ensureUnusedCapacity(allocator, 100);
// Can add 100 more without allocating
```

------

### `pub fn ensureUnusedCapacityContext(self: *Self, gpa: Allocator, additional_capacity: usize, ctx: Context) Oom!void`

Like `ensureUnusedCapacity` with custom context.

------

### `pub fn clearRetainingCapacity(self: *Self) void`

Remove all entries but keep allocated memory.

**Example:**
```zig
map.clearRetainingCapacity();  // Fast clear, capacity preserved
```

------

### `pub fn clearAndFree(self: *Self, gpa: Allocator) void`

Remove all entries and free allocated memory.

**Example:**
```zig
map.clearAndFree(allocator);  // Back to empty
```

------

### `pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`

Discard entries beyond `new_len`, keep capacity.

------

### `pub fn shrinkRetainingCapacityContext(self: *Self, new_len: usize, ctx: Context) void`

Like `shrinkRetainingCapacity` with custom context.

------

### `pub fn shrinkAndFree(self: *Self, gpa: Allocator, new_len: usize) void`

Discard entries beyond `new_len` and reduce capacity.

------

### `pub fn shrinkAndFreeContext(self: *Self, gpa: Allocator, new_len: usize, ctx: Context) void`

Like `shrinkAndFree` with custom context.

## Iteration & Access Functions

### `pub fn iterator(self: Self) Iterator`

Get an iterator over all entries. Entries are returned in insertion order.

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

⚠️ **Warning:** Modifying keys in a way that changes their hash requires calling `reIndex()` afterward.

------

### `pub fn values(self: Self) []V`

Get direct access to the backing array of values. Safe to modify values.

**Example:**
```zig
const values_array = map.values();
for (values_array) |*value| {
    value.* = transform(value.*);
}
```

------

### `pub fn count(self: Self) usize`

Get the number of entries currently in the map.

**Example:**
```zig
std.debug.print("Map has {d} entries\n", .{map.count()});
```

## Advanced Functions

### `pub fn clone(self: Self, gpa: Allocator) Oom!Self`

Create a deep copy of the map. Uses the default context.

**Example:**
```zig
var map2 = try map.clone(allocator);
defer map2.deinit(allocator);
```

------

### `pub fn cloneContext(self: Self, gpa: Allocator, ctx: Context) Oom!Self`

Clone the map using a custom context instance.

------

### `pub fn move(self: *Self) Self`

Transfer ownership, leaving the original in an empty state.

**Example:**
```zig
const map2 = map.move();  // map is now empty
defer map2.deinit(allocator);
```

------

### `pub fn promote(self: Self, gpa: Allocator) Managed`

Convert to a managed map. The original unmanaged map should not be used afterward.

**Example:**
```zig
const managed = map.promote(allocator);
defer managed.deinit();
// Don't use 'map' anymore
```

------

### `pub fn promoteContext(self: Self, gpa: Allocator, ctx: Context) Managed`

Like `promote` with a custom context instance.

------

### `pub fn sort(self: *Self, sort_ctx: anytype) void`

Sort entries by custom comparison (stable sort).

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

### `pub fn sortContext(self: *Self, sort_ctx: anytype, ctx: Context) void`

Like `sort` with a map context for rebuilding the index.

------

### `pub fn sortUnstable(self: *Self, sort_ctx: anytype) void`

Sort entries using unstable sort (potentially faster).

------

### `pub fn sortUnstableContext(self: *Self, sort_ctx: anytype, ctx: Context) void`

Like `sortUnstable` with map context.

------

### `pub fn reIndex(self: *Self, gpa: Allocator) Oom!void`

Rebuild the hash index. Required after directly modifying keys.

**Example:**
```zig
const keys_array = map.keys();
keys_array[0] = new_key;  // Direct modification
try map.reIndex(allocator);  // Rebuild index
```

------

### `pub fn reIndexContext(self: *Self, gpa: Allocator, ctx: Context) Oom!void`

Like `reIndex` with custom context.

------

### `pub fn setKey(self: *Self, gpa: Allocator, index: usize, new_key: K) Oom!void`

Modify a key at a specific index without reordering entries. Automatically rebuilds index.

**Example:**
```zig
const idx = map.getIndex("old_key").?;
try map.setKey(allocator, idx, "new_key");
```

------

### `pub fn setKeyContext(self: *Self, gpa: Allocator, index: usize, new_key: K, ctx: Context) Oom!void`

Like `setKey` with custom context.

------

### `pub fn lockPointers(self: *Self) void`

Enable pointer stability checking. Operations that invalidate pointers will assert.

**Example:**
```zig
map.lockPointers();
const ptr = map.getPtr("key");
// map.put(...);  // ← Would assert! Pointer invalidation detected
map.unlockPointers();
```

------

### `pub fn unlockPointers(self: *Self) void`

Disable pointer stability checking.

------

### `pub fn deinit(self: *Self, gpa: Allocator) void`

Free all memory. Does NOT free keys or values if they're heap-allocated.

**Example:**
```zig
var map = ArrayHashMapUnmanaged(...).empty;
defer map.deinit(allocator);
```

## Usage Patterns

### Pattern 1: Word Counter with Custom Context

```zig
const std = @import("std");

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

pub fn countWords(allocator: std.mem.Allocator, text: []const u8) !std.array_hash_map.ArrayHashMapUnmanaged([]const u8, usize, StringContext, true) {
    var counts = std.array_hash_map.ArrayHashMapUnmanaged([]const u8, usize, StringContext, true).empty;

    var iter = std.mem.tokenizeAny(u8, text, " \t\n");
    while (iter.next()) |word| {
  const result = try counts.getOrPut(allocator, word);
  if (!result.found_existing) {
      result.value_ptr.* = 0;
  }
  result.value_ptr.* += 1;
    }

    return counts;
}
```

### Pattern 2: Embedding in a Struct

```zig
const std = @import("std");

const IntContext = std.array_hash_map.AutoContext(u64);

pub const Cache = struct {
    data: std.array_hash_map.ArrayHashMapUnmanaged(u64, []const u8, IntContext, false) = .{},
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Cache {
  return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Cache) void {
  self.data.deinit(self.allocator);
    }

    pub fn put(self: *Cache, key: u64, value: []const u8) !void {
  try self.data.put(self.allocator, key, value);
    }

    pub fn get(self: *Cache, key: u64) ?[]const u8 {
  return self.data.get(key);
    }
};
```

### Pattern 3: Batch Insert with Pre-allocation

```zig
const std = @import("std");

pub fn bulkInsert(
    map: *std.array_hash_map.ArrayHashMapUnmanaged(u64, f64, std.array_hash_map.AutoContext(u64), false),
    allocator: std.mem.Allocator,
    pairs: []const struct { key: u64, value: f64 },
) !void {
    // Pre-allocate to avoid reallocation during insertion
    try map.ensureUnusedCapacity(allocator, pairs.len);

    for (pairs) |pair| {
  map.putAssumeCapacity(pair.key, pair.value);
    }
}
```

## Error Sets

Functions that can fail return:

- **`Allocator.Error`** (aliased as `Oom`):
  - `OutOfMemory` - Allocation failed

Functions that allocate:
- `put`, `putNoClobber`, `putContext`, `putNoClobberContext`
- `fetchPut`, `fetchPutContext`
- `getOrPut`, `getOrPutContext`, `getOrPutValue`, `getOrPutValueContext`
- `getOrPutAdapted`, `getOrPutContextAdapted`
- `ensureTotalCapacity`, `ensureTotalCapacityContext`
- `ensureUnusedCapacity`, `ensureUnusedCapacityContext`
- `clone`, `cloneContext`
- `reIndex`, `reIndexContext`
- `setKey`, `setKeyContext`
- `sort`, `sortContext`, `sortUnstable`, `sortUnstableContext`
- `init`, `reinit`
- `orderedRemoveAtMany`, `orderedRemoveAtManyContext`

## Debug Checklist

When debugging ArrayHashMapUnmanaged issues:

1. ✅ **Passed correct allocator to deinit** - Must be the same allocator used for allocations
2. ✅ **Called deinit** - Memory leak if forgotten
3. ✅ **Context hash/eql functions correct** - Incorrect implementations cause lookup failures
4. ✅ **Not using pointers after modification** - Insertions/removals invalidate entry pointers
5. ✅ **Freeing keys/values separately** - `deinit()` only frees the map structure
6. ✅ **Not modifying keys without reIndex** - Direct key modification breaks hash table
7. ✅ **Using correct removal function** - `swapRemove` vs `orderedRemove` have different semantics
8. ✅ **Pre-allocated before AssumeCapacity** - `AssumeCapacity` functions assert on overflow
9. ✅ **Checking found_existing in getOrPut** - Initialize value only when false
10. ✅ **store_hash matches eql cost** - `false` for cheap eql, `true` for expensive
11. ✅ **Context instance has correct state** - If Context has fields, ensure they're initialized
12. ✅ **Adapted key context matches** - hash/eql for adapted keys must be compatible

## Performance Tips

1. **Pre-allocate for known sizes**
   ```zig
   try map.ensureTotalCapacity(allocator, expected_size);
   for (items) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

2. **Use swapRemove when order doesn't matter** - O(1) vs O(N)

3. **Set store_hash appropriately**
   - `false` for integers and small types (cheap equality)
   - `true` for strings and large types (expensive equality)

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
 ptr.* = new_value;  // No copy
   }
   ```

7. **Batch operations with ensureUnusedCapacity**
   ```zig
   try map.ensureUnusedCapacity(allocator, batch.len);
   for (batch) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

8. **Small maps stay linear** - Don't worry about overhead for <9 entries

9. **Use adapted lookups for temporary keys**
   ```zig
   const value = map.getAdapted(temp_key, AdaptCtx{});
   ```

10. **Minimize Context state** - Context is passed by value, keep it small

11. **Consider AutoArrayHashMapUnmanaged** - If you don't need custom hash/eql

12. **Use move() for ownership transfer** - Zero-cost transfer without cloning

## See Also

- **std.array_hash_map.AutoArrayHashMapUnmanaged** - Unmanaged with automatic hash/eql
- **std.array_hash_map.ArrayHashMap** - Managed variant (stores allocator and context)
- **std.array_hash_map.AutoArrayHashMap** - Managed with automatic hash/eql
- **std.HashMapUnmanaged** - Unordered hash map (doesn't preserve insertion order)
- **std.MultiArrayList** - The underlying sequential storage structure
- **std.array_hash_map.AutoContext** - Helper for creating automatic hash contexts
- **std.array_hash_map.hashString** - Utility for hashing strings
