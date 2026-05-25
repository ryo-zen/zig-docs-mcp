# std.array_hash_map.Auto

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all AutoArrayHashMap features

## ⚠️ IMPORTANT: String Keys in Zig 0.16

**For string keys, use `StringArrayHashMap` instead of `AutoArrayHashMap([]const u8, V)`:**

```zig
// ❌ WRONG - Does NOT compile in Zig 0.16:
var map = std.array_hash_map.AutoArrayHashMap([]const u8, i32).init(allocator);

// ✅ CORRECT - Use StringArrayHashMap:
var map = std.StringArrayHashMap(i32).init(allocator);
```

See [test_string_array_hash_map_comprehensive.zig](../../Examples/test_string_array_hash_map_comprehensive.zig) for working string examples.

## Quick Start

### Most Common Patterns

**Basic Usage (Integer Keys)**
```zig
const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

var map = std.array_hash_map.AutoArrayHashMap(u64, i32).init(allocator);
defer map.deinit();

try map.put(100, 42);
try map.put(200, 99);

if (map.get(100)) |value| {
    std.debug.print("Found: {d}\n", .{value});
}
```

**Another Integer Example**
```zig
var map = std.array_hash_map.AutoArrayHashMap(u64, []const u8).init(allocator);
defer map.deinit();

try map.put(100, "hundred");
try map.put(200, "two hundred");

const value = map.get(100) orelse "not found";
```

**Iteration (Preserves Insertion Order)**
```zig
var map = std.array_hash_map.AutoArrayHashMap(u32, i32).init(allocator);
defer map.deinit();

try map.put(1, 10);
try map.put(2, 20);
try map.put(3, 30);

var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{d} = {d}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
// Prints in insertion order: 1, 2, 3
```

**getOrPut Pattern**
```zig
const result = try map.getOrPut("key");
if (!result.found_existing) {
    result.value_ptr.* = default_value;  // Initialize new entry
} else {
    result.value_ptr.* += 1;  // Update existing entry
}
```

### ⚠️ Critical: Remember to deinit!
```zig
var map = std.array_hash_map.AutoArrayHashMap(K, V).init(allocator);
defer map.deinit();  // ← REQUIRED! Frees backing memory
```

---

## Overview

`AutoArrayHashMap` is an order-preserving hash map that automatically provides hash and equality functions for common key types. It's the easiest ArrayHashMap variant to use because you don't need to provide a custom `Context`.

**Key Characteristics:**
- **Automatic hashing**: Works with integers, floats, pointers, enums, and structs without custom Context
- **⚠️ NOT for string slices**: Does NOT work with `[]const u8` keys - use `StringArrayHashMap` instead
- **Insertion order preserved**: Iteration returns entries in the order they were inserted
- **Backed by ArrayList**: Internally uses `std.MultiArrayList` for cache-friendly sequential storage
- **Stores allocator**: The allocator is stored in the map, so you don't pass it to each method
- **Fast small maps**: Uses linear scan for maps with <9 entries (no hash table overhead)
- **O(1) lookups**: Once the map grows beyond linear scan threshold, uses hash indexing

**When to use AutoArrayHashMap:**
- You need a simple hash map with standard key types (integers, floats, enums, simple structs)
- You want insertion order preserved for iteration
- You don't want to write custom hash/eql functions
- You prefer storing the allocator in the map for convenience

**When NOT to use:**
- **You have string keys** → Use `StringArrayHashMap` instead
- You need custom hashing logic → Use `ArrayHashMap` with custom Context
- You want to minimize memory → Use `AutoArrayHashMapUnmanaged` (doesn't store allocator)
- Order doesn't matter and you need maximum speed → Consider `std.HashMap`
- Keys are complex types requiring special comparison → Use `ArrayHashMap` with custom Context

## Parameters

`K: type` - The key type. Must be supported by `AutoContext` (integers, floats, pointers, slices, arrays, structs, enums, etc.)

`V: type` - The value type. Can be any type.

## Source Code

```zig
pub fn AutoArrayHashMap(comptime K: type, comptime V: type) type {
    return ArrayHashMap(K, V, AutoContext(K), !autoEqlIsCheap(K));
}
```

The `!autoEqlIsCheap(K)` determines whether to store hashes:
- If equality checks are cheap (integers, small types), hashes are NOT stored (`store_hash = false`)
- If equality checks are expensive (strings, large structs), hashes ARE stored (`store_hash = true`)

## Fields

`unmanaged: Unmanaged`

The underlying unmanaged map storage. Advanced users can access this directly for lower-level operations.

------

`allocator: Allocator`

The allocator used for all memory operations. Stored in the map for convenience.

------

`ctx: AutoContext(K)`

The automatically generated hash and equality context. Provides `hash()` and `eql()` functions.

## Types

- **Unmanaged** - The unmanaged variant (`AutoArrayHashMapUnmanaged(K, V)`)
- **Data** - The internal data structure for MultiArrayList storage
- **DataList** - The MultiArrayList type backing this map
- **Entry** - Pointers to a key and value in the map (returned by `getEntry`, `getOrPut`, etc.)
- **GetOrPutResult** - Result from `getOrPut` operations containing entry pointers and `found_existing` flag
- **Hash** - The stored hash type (either `u32` or `void` depending on `store_hash`)
- **Iterator** - Iterator over Entry pointers
- **KV** - A key-value pair copied out of the backing store

## Initialization Functions

### `pub fn init(allocator: Allocator) Self`

Create an empty AutoArrayHashMap that will use the specified allocator.

**Example:**
```zig
var map = std.array_hash_map.AutoArrayHashMap(u32, []const u8).init(allocator);
defer map.deinit();
```

## Core Insertion Functions

### `pub fn put(self: *Self, key: K, value: V) !void`

Insert or update a key-value pair. If the key already exists, its value is replaced (clobbered).

**Example:**
```zig
try map.put("key", 42);
try map.put("key", 99);  // Replaces 42 with 99
```

------

### `pub fn putNoClobber(self: *Self, key: K, value: V) !void`

Insert a key-value pair, asserting that the key doesn't already exist. Triggers assertion failure in debug mode if key exists.

**Example:**
```zig
try map.putNoClobber("new_key", 10);
// try map.putNoClobber("new_key", 20);  // ← Would assert in debug!
```

------

### `pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`

Insert or update without allocating. Asserts there's enough capacity. Use after `ensureTotalCapacity` or `ensureUnusedCapacity`.

**Example:**
```zig
try map.ensureTotalCapacity(100);  // Pre-allocate space
map.putAssumeCapacity("key1", 1);   // No allocation
map.putAssumeCapacity("key2", 2);   // No allocation
```

------

### `pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`

Insert without allocating, asserting the key doesn't exist and there's enough capacity.

**Example:**
```zig
try map.ensureUnusedCapacity(10);
map.putAssumeCapacityNoClobber("unique", 42);
```

## Lookup Functions

### `pub fn get(self: Self, key: K) ?V`

Get a copy of the value associated with a key, or `null` if not found.

**Example:**
```zig
if (map.get("key")) |value| {
    std.debug.print("Value: {d}\n", .{value});
} else {
    std.debug.print("Not found\n", .{});
}
```

------

### `pub fn getPtr(self: Self, key: K) ?*V`

Get a mutable pointer to the value associated with a key. Use this to modify values in place.

**Example:**
```zig
if (map.getPtr("counter")) |counter_ptr| {
    counter_ptr.* += 1;  // Increment in place
}
```

------

### `pub fn getEntry(self: Self, key: K) ?Entry`

Get pointers to both the key and value storage.

**Example:**
```zig
if (map.getEntry("key")) |entry| {
    std.debug.print("Key: {s}, Value: {d}\n", .{entry.key_ptr.*, entry.value_ptr.*});
    entry.value_ptr.* = 999;  // Can modify the value
}
```

------

### `pub fn getIndex(self: Self, key: K) ?usize`

Get the index in the backing array where a key is stored. Useful for direct array access.

**Example:**
```zig
if (map.getIndex("key")) |index| {
    const keys_array = map.keys();
    const values_array = map.values();
    std.debug.print("At index {d}: {s} = {d}\n",
  .{index, keys_array[index], values_array[index]});
}
```

------

### `pub fn getKey(self: Self, key: K) ?K`

Get a copy of the actual key stored in the map. Useful when key comparison is different from key storage.

------

### `pub fn getKeyPtr(self: Self, key: K) ?*K`

Get a pointer to the actual key stored in the map.

------

### `pub fn contains(self: Self, key: K) bool`

Check if a key exists in the map.

**Example:**
```zig
if (map.contains("key")) {
    std.debug.print("Map contains key\n", .{});
}
```

------

### `pub fn getOrPut(self: *Self, key: K) !GetOrPutResult`

Get an existing entry or create a new one with undefined value. The caller must initialize the value if it's a new entry.

**Example:**
```zig
const result = try map.getOrPut("counter");
if (!result.found_existing) {
    result.value_ptr.* = 0;  // Initialize new entry
}
result.value_ptr.* += 1;  // Increment
```

------

### `pub fn getOrPutValue(self: *Self, key: K, value: V) !GetOrPutResult`

Get an existing entry or create a new one initialized with `value`.

**Example:**
```zig
const result = try map.getOrPutValue("default_key", 42);
// If key didn't exist, it now has value 42
```

------

### `pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`

Like `getOrPut` but assumes sufficient capacity. Use after pre-allocating.

**Example:**
```zig
try map.ensureUnusedCapacity(10);
const result = map.getOrPutAssumeCapacity("key");
if (!result.found_existing) {
    result.value_ptr.* = default_value;
}
```

## Removal Functions

### `pub fn swapRemove(self: *Self, key: K) bool`

Remove an entry by swapping it with the last entry (O(1)). Destroys insertion order. Returns true if an entry was removed.

**Example:**
```zig
if (map.swapRemove("key")) {
    std.debug.print("Removed\n", .{});
} else {
    std.debug.print("Key not found\n", .{});
}
```

------

### `pub fn orderedRemove(self: *Self, key: K) bool`

Remove an entry by shifting all subsequent entries forward (O(N)). Preserves insertion order.

**Example:**
```zig
_ = map.orderedRemove("first");  // Other entries keep their order
```

------

### `pub fn swapRemoveAt(self: *Self, index: usize) void`

Remove the entry at a specific index using swap removal.

**Example:**
```zig
if (map.getIndex("key")) |index| {
    map.swapRemoveAt(index);
}
```

------

### `pub fn orderedRemoveAt(self: *Self, index: usize) void`

Remove the entry at a specific index, preserving order.

------

### `pub fn fetchSwapRemove(self: *Self, key: K) ?KV`

Remove and return the key-value pair using swap removal.

**Example:**
```zig
if (map.fetchSwapRemove("key")) |kv| {
    std.debug.print("Removed: {s} = {d}\n", .{kv.key, kv.value});
}
```

------

### `pub fn fetchOrderedRemove(self: *Self, key: K) ?KV`

Remove and return the key-value pair, preserving order.

------

### `pub fn pop(self: *Self) ?KV`

Remove and return the last inserted entry.

**Example:**
```zig
while (map.pop()) |kv| {
    std.debug.print("Popped: {s} = {d}\n", .{kv.key, kv.value});
}
```

## Capacity Management Functions

### `pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) !void`

Ensure the map can hold at least `new_capacity` total entries without allocating.

**Example:**
```zig
try map.ensureTotalCapacity(1000);  // Pre-allocate for 1000 entries
for (0..1000) |i| {
    map.putAssumeCapacity(i, i * 2);  // No allocation
}
```

------

### `pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) !void`

Ensure space for `additional_count` more entries beyond current count.

**Example:**
```zig
const current = map.count();
try map.ensureUnusedCapacity(100);  // Room for 100 more
// Can now add 100 entries without allocation
```

------

### `pub fn capacity(self: Self) usize`

Get the current capacity (total entries that can be stored without allocating).

------

### `pub fn clearRetainingCapacity(self: *Self) void`

Remove all entries but keep allocated memory for reuse.

**Example:**
```zig
map.clearRetainingCapacity();  // Entries gone, capacity remains
```

------

### `pub fn clearAndFree(self: *Self) void`

Remove all entries and free allocated memory.

**Example:**
```zig
map.clearAndFree();  // Back to empty, no allocation
```

------

### `pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`

Discard entries beyond `new_len`, keeping allocated capacity.

------

### `pub fn shrinkAndFree(self: *Self, new_len: usize) void`

Discard entries beyond `new_len` and reduce allocated capacity.

## Iteration & Access Functions

### `pub fn iterator(self: *const Self) Iterator`

Get an iterator over all entries.

**Example:**
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{s}: {d}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

------

### `pub fn keys(self: Self) []K`

Get direct access to the backing array of keys.

**Example:**
```zig
const keys_array = map.keys();
for (keys_array) |key| {
    std.debug.print("Key: {s}\n", .{key});
}
```

------

### `pub fn values(self: Self) []V`

Get direct access to the backing array of values. Values can be modified.

**Example:**
```zig
const values_array = map.values();
for (values_array) |*value| {
    value.* *= 2;  // Double all values
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

### `pub fn clone(self: Self) !Self`

Create a deep copy of the map using the same allocator.

**Example:**
```zig
var map2 = try map.clone();
defer map2.deinit();
```

------

### `pub fn cloneWithAllocator(self: Self, allocator: Allocator) !Self`

Clone the map using a different allocator.

------

### `pub fn move(self: *Self) Self`

Transfer ownership of the map, leaving the original in an empty state.

**Example:**
```zig
const map2 = map.move();  // map is now empty, map2 owns data
defer map2.deinit();
```

------

### `pub fn sort(self: *Self, sort_ctx: anytype) void`

Sort entries by a custom comparison function (stable sort).

**Example:**
```zig
// For integer keys:
const SortCtx = struct {
    keys: []const u64,
    pub fn lessThan(ctx: @This(), a_idx: usize, b_idx: usize) bool {
  return ctx.keys[a_idx] < ctx.keys[b_idx];
    }
};

map.sort(SortCtx{ .keys = map.keys() });

// For string keys, use StringArrayHashMap - see test_string_array_hash_map_comprehensive.zig
```

------

### `pub fn sortUnstable(self: *Self, sort_ctx: anytype) void`

Sort entries using an unstable sort (potentially faster).

------

### `pub fn reIndex(self: *Self) !void`

Rebuild the hash index. Required if you directly modify keys in a way that changes their hash.

**Example:**
```zig
const keys_array = map.keys();
keys_array[0] = new_key;  // Directly modified key
try map.reIndex();  // Rebuild hash index
```

------

### `pub fn lockPointers(self: *Self) void`

Enable pointer stability checking. Any operation that would invalidate pointers triggers an assertion.

------

### `pub fn unlockPointers(self: *Self) void`

Disable pointer stability checking.

------

### `pub fn deinit(self: *Self) void`

Free all memory associated with the map. Does NOT free keys or values themselves (if they're heap-allocated).

**Example:**
```zig
var map = std.array_hash_map.AutoArrayHashMap([]const u8, i32).init(allocator);
defer map.deinit();
```

## Adapted Lookup Functions

These functions accept a key-like value with a different type than `K`, along with a custom comparison context. Useful for string lookups without allocation.

### `pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`
### `pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`
### `pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`
### `pub fn getIndexAdapted(self: Self, key: anytype, ctx: anytype) ?usize`
### `pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`
### `pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`
### `pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`
### `pub fn getOrPutAdapted(self: *Self, key: anytype, ctx: anytype) !GetOrPutResult`
### `pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`
### `pub fn fetchSwapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`
### `pub fn fetchOrderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`
### `pub fn swapRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`
### `pub fn orderedRemoveAdapted(self: *Self, key: anytype, ctx: anytype) bool`

**Example of Adapted Lookup:**
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

// Look up with a string literal without allocating
if (map.getAdapted("key", AdaptCtx{})) |value| {
    std.debug.print("Found: {d}\n", .{value});
}
```

## Usage Patterns

### Pattern 1: Word Frequency Counter (Use StringArrayHashMap!)

```zig
const std = @import("std");

// NOTE: For string keys, use StringArrayHashMap, NOT AutoArrayHashMap([]const u8, ...)
pub fn countWords(allocator: std.mem.Allocator, text: []const u8) !std.StringArrayHashMap(usize) {
    var counts = std.StringArrayHashMap(usize).init(allocator);

    var iter = std.mem.tokenizeAny(u8, text, " \t\n");
    while (iter.next()) |word| {
  const result = try counts.getOrPut(word);
  if (!result.found_existing) {
      result.value_ptr.* = 0;
  }
  result.value_ptr.* += 1;
    }

    return counts;
}
```

### Pattern 2: Cache with Insertion-Order Eviction

```zig
const std = @import("std");

pub fn LRUCache(comptime K: type, comptime V: type, comptime max_size: usize) type {
    return struct {
  map: std.array_hash_map.AutoArrayHashMap(K, V),

  pub fn init(allocator: std.mem.Allocator) !@This() {
      return .{
          .map = std.array_hash_map.AutoArrayHashMap(K, V).init(allocator),
      };
  }

  pub fn deinit(self: *@This()) void {
      self.map.deinit();
  }

  pub fn put(self: *@This(), key: K, value: V) !void {
      // Evict oldest if at capacity
      if (self.map.count() >= max_size and !self.map.contains(key)) {
          _ = self.map.swapRemoveAt(0);  // Remove oldest
      }
      try self.map.put(key, value);
  }

  pub fn get(self: *@This(), key: K) ?V {
      return self.map.get(key);
  }
    };
}
```

### Pattern 3: Grouping Data

```zig
const std = @import("std");

pub fn groupByCategory(
    allocator: std.mem.Allocator,
    items: []const Item,
) !std.array_hash_map.AutoArrayHashMap(Category, std.ArrayList(Item)) {
    var groups = std.array_hash_map.AutoArrayHashMap(Category, std.ArrayList(Item)).init(allocator);

    for (items) |item| {
  const result = try groups.getOrPut(item.category);
  if (!result.found_existing) {
      result.value_ptr.* = std.ArrayList(Item).init(allocator);
  }
  try result.value_ptr.append(item);
    }

    return groups;
}
```

## Error Sets

Functions that can fail return one of these error types:

- **`Allocator.Error`** (aliased as `Oom` in some contexts):
  - `OutOfMemory` - Allocation failed

Functions that can fail:
- `put`, `putNoClobber` - Can allocate when growing
- `getOrPut`, `getOrPutValue` - Can allocate for new entries
- `ensureTotalCapacity`, `ensureUnusedCapacity` - Explicit allocation
- `clone`, `cloneWithAllocator` - Deep copy allocation
- `reIndex` - May allocate for hash table rebuild
- `sort`, `sortUnstable` - May allocate temporary storage

## Debug Checklist

When debugging AutoArrayHashMap issues, verify:

1. ✅ **Called `deinit()`** - Memory leak if forgotten
2. ✅ **Not using pointers after modification** - `getPtr()`, `getEntry()` results are invalidated by insertion/removal
3. ✅ **Key type has value semantics** - String keys should be owned, not borrowed (map doesn't deep-copy keys)
4. ✅ **Freeing keys/values separately** - `deinit()` doesn't free heap-allocated keys or values
5. ✅ **Not modifying keys directly** - If you modify keys via `keys()`, call `reIndex()` afterward
6. ✅ **Using correct removal function** - `swapRemove()` destroys order, `orderedRemove()` preserves it
7. ✅ **Pre-allocated with `ensureTotalCapacity`** - When using `AssumeCapacity` variants
8. ✅ **Iterator invalidation** - Don't insert/remove while iterating (though Zig allows it, behavior is subtle)
9. ✅ **Checking `found_existing` in `getOrPut`** - Initialize value only when false
10. ✅ **Key type supported by AutoContext** - Custom types may need explicit `ArrayHashMap` with custom Context

## Performance Tips

1. **Pre-allocate for known sizes** - Call `ensureTotalCapacity(n)` before bulk insertions to avoid repeated reallocations
   ```zig
   try map.ensureTotalCapacity(1000);
   for (items) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

2. **Use `swapRemove` when order doesn't matter** - O(1) vs O(N) for `orderedRemove`

3. **Reuse cleared maps** - `clearRetainingCapacity()` keeps allocation for next use
   ```zig
   map.clearRetainingCapacity();  // Faster than deinit + init
   ```

4. **Access arrays directly for bulk operations** - `keys()` and `values()` avoid iterator overhead
   ```zig
   const values_array = map.values();
   for (values_array) |*v| v.* += 1;  // Faster than iterator
   ```

5. **Use `getPtr` for in-place modification** - Avoids copying large values
   ```zig
   if (map.getPtr("key")) |ptr| {
 ptr.* = new_value;  // No copy
   }
   ```

6. **Batch operations with `ensureUnusedCapacity`** - Amortize allocation checks
   ```zig
   try map.ensureUnusedCapacity(batch.len);
   for (batch) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

7. **Small maps stay linear scan** - Don't worry about hash overhead for <9 entries

8. **Consider Unmanaged variant for tight loops** - `AutoArrayHashMapUnmanaged` saves allocator field space

9. **Use adapted lookups for temporary keys** - Avoid allocation for string comparison
   ```zig
   // Instead of allocating a string to look up
   const value = map.getAdapted(temp_string, AdaptCtx{});
   ```

10. **Shrink after bulk removal** - `shrinkAndFree(new_len)` reclaims memory after many removals

## See Also

- **std.array_hash_map.AutoArrayHashMapUnmanaged** - Unmanaged variant (doesn't store allocator)
- **std.array_hash_map.ArrayHashMap** - Generic variant with custom Context for custom hash/eql
- **std.array_hash_map.ArrayHashMapUnmanaged** - Unmanaged generic variant
- **std.HashMap** - Unordered hash map (may be faster when order doesn't matter)
- **std.ArrayList** - For simple sequential storage without key lookup
- **std.StringHashMap** - Specialized for string keys (deprecated in favor of AutoArrayHashMap)
