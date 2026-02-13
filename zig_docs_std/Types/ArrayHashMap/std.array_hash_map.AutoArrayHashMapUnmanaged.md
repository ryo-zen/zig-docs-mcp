# std.array_hash_map.AutoArrayHashMapUnmanaged

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all AutoArrayHashMapUnmanaged features

## ⚠️ IMPORTANT: String Keys in Zig 0.16

**For string keys, use `StringArrayHashMapUnmanaged` instead of `AutoArrayHashMapUnmanaged([]const u8, V)`:**

```zig
// ❌ WRONG - Does NOT compile in Zig 0.16:
var map = std.array_hash_map.AutoArrayHashMapUnmanaged([]const u8, i32).empty;

// ✅ CORRECT - Use StringArrayHashMapUnmanaged:
var map = std.StringArrayHashMapUnmanaged(i32){};
```

See [test_string_array_hash_map_unmanaged_comprehensive.zig](../../Examples/test_string_array_hash_map_unmanaged_comprehensive.zig) for working string examples.

## Quick Start

### Most Common Patterns

**Basic Usage (Integer Keys)**
```zig
const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

var map = std.array_hash_map.AutoArrayHashMapUnmanaged(u64, i32).empty;
defer map.deinit(allocator);

try map.put(allocator, 100, 42);
try map.put(allocator, 200, 99);

if (map.get(100)) |value| {
    std.debug.print("Found: {d}\n", .{value});
}
```

**Integer Keys**
```zig
var map = std.array_hash_map.AutoArrayHashMapUnmanaged(u64, []const u8).empty;
defer map.deinit(allocator);

try map.put(allocator, 100, "hundred");
try map.put(allocator, 200, "two hundred");
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
const result = try map.getOrPut(allocator, "counter");
if (!result.found_existing) {
    result.value_ptr.* = 0;
}
result.value_ptr.* += 1;
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
var map = AutoArrayHashMapUnmanaged(K, V).empty;
defer map.deinit(allocator);  // ← REQUIRED! Pass the same allocator

// Every allocating function needs the allocator
try map.put(allocator, key, value);
try map.ensureTotalCapacity(allocator, 100);
```

---

## Overview

`AutoArrayHashMapUnmanaged` is an order-preserving hash map that automatically provides hash and equality functions for common key types, and does NOT store an allocator. You get automatic hashing without the memory overhead of storing the allocator.

**Key Characteristics:**
- **Automatic hashing**: Works with integers, floats, pointers, enums, and simple structs
- **⚠️ NOT for string slices**: Does NOT work with `[]const u8` keys - use `StringArrayHashMapUnmanaged` instead
- **No stored allocator**: Pass `Allocator` as parameter to each allocating function
- **Insertion order preserved**: Iteration returns entries in insertion order
- **Backed by ArrayList**: Uses `std.MultiArrayList` for sequential storage
- **Fast small maps**: Linear scan for <9 entries (no hash table overhead)
- **O(1) lookups**: Hash-based indexing once size exceeds linear scan threshold
- **Minimal overhead**: Only 3 pointers + lock when empty
- **Smart hash storage**: Automatically stores hashes for expensive equality checks

**When to use AutoArrayHashMapUnmanaged:**
- You want automatic hash/eql for standard types (integers, floats, enums, simple structs)
- You need fine-grained control over memory allocation
- You're embedding maps in data structures and want minimal size
- You want insertion order preserved
- You're writing library code that shouldn't assume an allocator

**When NOT to use:**
- **You have string keys** → Use `StringArrayHashMapUnmanaged` instead
- You need custom hashing → Use `ArrayHashMapUnmanaged` with custom Context
- You prefer convenience → Use `AutoArrayHashMap` (stores allocator)
- Order doesn't matter → Consider `std.HashMapUnmanaged`

## Parameters

### `K: type`
The key type. Must be supported by `AutoContext`:
- Integers (`u8`, `u32`, `i64`, `usize`, etc.)
- Floats (`f32`, `f64`)
- Pointers (`*T`, `*const T`)
- Slices (`[]T`, `[]const T`)
- Arrays (`[N]T`)
- Structs (compared field-by-field)
- Enums
- Optional types
- Tagged unions

### `V: type`
The value type. Can be any type.

## Source Code

```zig
pub fn AutoArrayHashMapUnmanaged(comptime K: type, comptime V: type) type {
    return ArrayHashMapUnmanaged(K, V, AutoContext(K), !autoEqlIsCheap(K));
}
```

The `!autoEqlIsCheap(K)` determines `store_hash`:
- Cheap equality (integers, small types) → hashes NOT stored (`store_hash = false`)
- Expensive equality (strings, large structs) → hashes stored (`store_hash = true`)

## Fields

### `entries: DataList = .{}`

The backing MultiArrayList storing keys and values sequentially. Direct access permitted for advanced use. After modifying keys, call `reIndex()`.

**Example:**
```zig
const keys_slice = map.entries.items(.key);
const values_slice = map.entries.items(.value);
```

------

### `index_header: ?*IndexHeader = null`

When the map has <9 entries, this remains `null` and lookups use linear scan. Once larger, points to allocated hash index structure.

------

### `pointer_stability: std.debug.SafetyLock = .{}`

Used to detect memory safety violations in debug builds. Engaged by `lockPointers()`.

## Types

- **Data** - MultiArrayList entry structure (key, value, optionally hash)
- **DataList** - The MultiArrayList type backing this map
- **Entry** - Pointers to a key and value (mutable)
- **GetOrPutResult** - Result from `getOrPut` with `found_existing` flag and entry pointers
- **Hash** - Either `u32` or `void` depending on `autoEqlIsCheap(K)`
- **Iterator** - Iterator over Entry pointers
- **KV** - A key-value pair copied out of the backing store
- **Managed** - The managed variant: `AutoArrayHashMap(K, V)`

## Values

|       |        |                                     |
|-------|--------|-------------------------------------|
| empty | `Self` | A map containing no keys or values. Preferred initialization method. |

**Example:**
```zig
var map = AutoArrayHashMapUnmanaged(K, V).empty;
```

## Initialization Functions

### `pub fn init(gpa: Allocator, key_list: []const K, value_list: []const V) Oom!Self`

Create a map initialized with parallel slices of keys and values.

**Example:**
```zig
const keys = [_][]const u8{ "a", "b", "c" };
const values = [_]i32{ 1, 2, 3 };
var map = try AutoArrayHashMapUnmanaged([]const u8, i32).init(allocator, &keys, &values);
defer map.deinit(allocator);
```

------

### `pub fn reinit(self: *Self, gpa: Allocator, key_list: []const K, value_list: []const V) Oom!void`

Replace the map contents with new key-value pairs.

## Core Insertion Functions

### `pub fn put(self: *Self, gpa: Allocator, key: K, value: V) Oom!void`

Insert or update a key-value pair. Replaces existing value if key exists.

**Example:**
```zig
try map.put(allocator, "key", 42);
try map.put(allocator, "key", 99);  // Replaces 42
```

------

### `pub fn putNoClobber(self: *Self, gpa: Allocator, key: K, value: V) Oom!void`

Insert, asserting the key doesn't already exist.

**Example:**
```zig
try map.putNoClobber(allocator, "new_key", 10);
```

------

### `pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`

Insert or update without allocating. Asserts sufficient capacity.

**Example:**
```zig
try map.ensureTotalCapacity(allocator, 100);
map.putAssumeCapacity("key1", 1);  // No allocator!
map.putAssumeCapacity("key2", 2);
```

------

### `pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`

Insert without allocating, asserting key doesn't exist and capacity is sufficient.

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

### `pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`

Like `fetchPut` but assumes capacity.

## Lookup Functions

### `pub fn get(self: Self, key: K) ?V`

Get a copy of the value for a key.

**Example:**
```zig
if (map.get("key")) |value| {
    std.debug.print("Value: {d}\n", .{value});
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
    std.debug.print("At {d}: {s}\n", .{index, keys_array[index]});
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

### `pub fn getOrPut(self: *Self, gpa: Allocator, key: K) Oom!GetOrPutResult`

Get an existing entry or create a new one. Caller must initialize value if `!found_existing`.

**Example:**
```zig
const result = try map.getOrPut(allocator, "counter");
if (!result.found_existing) {
    result.value_ptr.* = 0;
}
result.value_ptr.* += 1;
```

------

### `pub fn getOrPutValue(self: *Self, gpa: Allocator, key: K, value: V) Oom!GetOrPutResult`

Get or create, initializing new entries with `value`.

**Example:**
```zig
const result = try map.getOrPutValue(allocator, "default", 42);
```

------

### `pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`

Like `getOrPut` but assumes capacity (no allocator needed).

**Example:**
```zig
try map.ensureUnusedCapacity(allocator, 10);
const result = map.getOrPutAssumeCapacity("key");
if (!result.found_existing) {
    result.value_ptr.* = default_value;
}
```

## Adapted Lookup Functions

These accept a key-like value of a different type with its own context.

### `pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`
### `pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`
### `pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`
### `pub fn getIndexAdapted(self: Self, key: anytype, ctx: anytype) ?usize`
### `pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`
### `pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`
### `pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`
### `pub fn getOrPutAdapted(self: *Self, gpa: Allocator, key: anytype, key_ctx: anytype) Oom!GetOrPutResult`
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

### `pub fn orderedRemoveAtMany(self: *Self, gpa: Allocator, sorted_indexes: []const usize) Oom!void`

Remove multiple entries by index. `sorted_indexes` must be sorted and represent indices before deletion.

**Example:**
```zig
const to_remove = [_]usize{ 2, 5, 8 };
try map.orderedRemoveAtMany(allocator, &to_remove);
```

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
    std.debug.print("Popped: {s} = {d}\n", .{kv.key, kv.value});
}
```

## Capacity Management Functions

### `pub fn capacity(self: Self) usize`

Get the current capacity.

------

### `pub fn ensureTotalCapacity(self: *Self, gpa: Allocator, new_capacity: usize) Oom!void`

Ensure the map can hold at least `new_capacity` total entries.

**Example:**
```zig
try map.ensureTotalCapacity(allocator, 1000);
for (0..1000) |i| {
    map.putAssumeCapacity(i, i * 2);
}
```

------

### `pub fn ensureUnusedCapacity(self: *Self, gpa: Allocator, additional_capacity: usize) Oom!void`

Ensure space for `additional_capacity` more entries.

**Example:**
```zig
try map.ensureUnusedCapacity(allocator, 100);
```

------

### `pub fn clearRetainingCapacity(self: *Self) void`

Remove all entries but keep allocated memory.

**Example:**
```zig
map.clearRetainingCapacity();
```

------

### `pub fn clearAndFree(self: *Self, gpa: Allocator) void`

Remove all entries and free allocated memory.

**Example:**
```zig
map.clearAndFree(allocator);
```

------

### `pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`

Discard entries beyond `new_len`, keep capacity.

------

### `pub fn shrinkAndFree(self: *Self, gpa: Allocator, new_len: usize) void`

Discard entries beyond `new_len` and reduce capacity.

## Iteration & Access Functions

### `pub fn iterator(self: Self) Iterator`

Get an iterator over all entries in insertion order.

**Example:**
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{s} = {d}\n", .{entry.key_ptr.*, entry.value_ptr.*});
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

⚠️ **Warning:** Modifying keys requires calling `reIndex()` afterward.

------

### `pub fn values(self: Self) []V`

Get direct access to the backing array of values. Safe to modify.

**Example:**
```zig
const values_array = map.values();
for (values_array) |*value| {
    value.* *= 2;
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

### `pub fn clone(self: Self, gpa: Allocator) Oom!Self`

Create a deep copy of the map.

**Example:**
```zig
var map2 = try map.clone(allocator);
defer map2.deinit(allocator);
```

------

### `pub fn move(self: *Self) Self`

Transfer ownership, leaving the original empty.

**Example:**
```zig
const map2 = map.move();
defer map2.deinit(allocator);
```

------

### `pub fn promote(self: Self, gpa: Allocator) Managed`

Convert to a managed map. Don't use the original afterward.

**Example:**
```zig
const managed = map.promote(allocator);
defer managed.deinit();
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

### `pub fn reIndex(self: *Self, gpa: Allocator) Oom!void`

Rebuild the hash index after direct key modifications.

**Example:**
```zig
const keys_array = map.keys();
keys_array[0] = new_key;
try map.reIndex(allocator);
```

------

### `pub fn setKey(self: *Self, gpa: Allocator, index: usize, new_key: K) Oom!void`

Modify a key at a specific index, automatically rebuilding index.

**Example:**
```zig
const idx = map.getIndex("old").?;
try map.setKey(allocator, idx, "new");
```

------

### `pub fn lockPointers(self: *Self) void`

Enable pointer stability checking.

------

### `pub fn unlockPointers(self: *Self) void`

Disable pointer stability checking.

------

### `pub fn deinit(self: *Self, gpa: Allocator) void`

Free all memory. Does NOT free heap-allocated keys or values.

**Example:**
```zig
var map = AutoArrayHashMapUnmanaged(K, V).empty;
defer map.deinit(allocator);
```

## Usage Patterns

### Pattern 1: Word Frequency Counter (Use StringArrayHashMapUnmanaged!)

```zig
const std = @import("std");

// NOTE: For string keys, use StringArrayHashMapUnmanaged, NOT AutoArrayHashMapUnmanaged([]const u8, ...)
pub fn countWords(
    allocator: std.mem.Allocator,
    text: []const u8,
) !std.StringArrayHashMapUnmanaged(usize) {
    var counts = std.StringArrayHashMapUnmanaged(usize){};

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

### Pattern 2: Embedding in a Struct (Minimal Overhead)

```zig
const std = @import("std");

pub const IdCache = struct {
    data: std.array_hash_map.AutoArrayHashMapUnmanaged(u64, []const u8) = .{},

    pub fn deinit(self: *IdCache, allocator: std.mem.Allocator) void {
  self.data.deinit(allocator);
    }

    pub fn put(self: *IdCache, allocator: std.mem.Allocator, id: u64, name: []const u8) !void {
  try self.data.put(allocator, id, name);
    }

    pub fn get(self: *IdCache, id: u64) ?[]const u8 {
  return self.data.get(id);
    }

    pub fn count(self: *IdCache) usize {
  return self.data.count();
    }
};
```

### Pattern 3: Batch Insert with Pre-allocation

```zig
const std = @import("std");

pub fn bulkInsert(
    map: *std.array_hash_map.AutoArrayHashMapUnmanaged(u64, f64),
    allocator: std.mem.Allocator,
    pairs: []const struct { key: u64, value: f64 },
) !void {
    try map.ensureUnusedCapacity(allocator, pairs.len);

    for (pairs) |pair| {
  map.putAssumeCapacity(pair.key, pair.value);
    }
}
```

### Pattern 4: String Deduplication

```zig
const std = @import("std");

pub const StringPool = struct {
    strings: std.array_hash_map.AutoArrayHashMapUnmanaged([]const u8, void) = .{},
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) StringPool {
  return .{ .allocator = allocator };
    }

    pub fn deinit(self: *StringPool) void {
  // Free all interned strings
  const keys = self.strings.keys();
  for (keys) |key| {
      self.allocator.free(key);
  }
  self.strings.deinit(self.allocator);
    }

    pub fn intern(self: *StringPool, str: []const u8) ![]const u8 {
  const result = try self.strings.getOrPut(self.allocator, str);
  if (!result.found_existing) {
      // Allocate and store owned copy
      const owned = try self.allocator.dupe(u8, str);
      result.key_ptr.* = owned;
  }
  return result.key_ptr.*;
    }
};
```

## Error Sets

Functions that can fail return:

- **`Allocator.Error`** (aliased as `Oom`):
  - `OutOfMemory` - Allocation failed

Functions that allocate:
- `put`, `putNoClobber`
- `fetchPut`
- `getOrPut`, `getOrPutValue`, `getOrPutAdapted`
- `ensureTotalCapacity`, `ensureUnusedCapacity`
- `clone`
- `reIndex`
- `setKey`
- `sort`, `sortUnstable`
- `init`, `reinit`
- `orderedRemoveAtMany`

## Debug Checklist

When debugging AutoArrayHashMapUnmanaged issues:

1. ✅ **Passed correct allocator to deinit** - Must be the same allocator used for allocations
2. ✅ **Called deinit** - Memory leak if forgotten
3. ✅ **Not using pointers after modification** - Insertions/removals invalidate entry pointers
4. ✅ **Freeing keys/values separately** - `deinit()` only frees the map structure
5. ✅ **Not modifying keys without reIndex** - Direct key modification breaks hash table
6. ✅ **Using correct removal function** - `swapRemove` vs `orderedRemove` semantics
7. ✅ **Pre-allocated before AssumeCapacity** - `AssumeCapacity` functions assert on overflow
8. ✅ **Checking found_existing in getOrPut** - Initialize value only when false
9. ✅ **Key type supported by AutoContext** - Custom types may need explicit `ArrayHashMapUnmanaged`
10. ✅ **String keys are owned** - If storing string slices, ensure they outlive the map or duplicate them

## Performance Tips

1. **Pre-allocate for known sizes**
   ```zig
   try map.ensureTotalCapacity(allocator, expected_size);
   for (items) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

2. **Use swapRemove when order doesn't matter** - O(1) vs O(N)

3. **Reuse cleared maps**
   ```zig
   map.clearRetainingCapacity();  // Faster than deinit + init
   ```

4. **Access arrays directly for bulk operations**
   ```zig
   const values = map.values();
   for (values) |*v| v.* = transform(v.*);
   ```

5. **Use getPtr for in-place modification**
   ```zig
   if (map.getPtr(key)) |ptr| {
 ptr.* = new_value;
   }
   ```

6. **Batch operations with ensureUnusedCapacity**
   ```zig
   try map.ensureUnusedCapacity(allocator, batch.len);
   for (batch) |item| {
 map.putAssumeCapacity(item.key, item.value);
   }
   ```

7. **Small maps stay linear** - No hash overhead for <9 entries

8. **Use adapted lookups for temporary keys**
   ```zig
   const value = map.getAdapted(temp_key, AdaptCtx{});
   ```

9. **Automatic hash storage is smart** - No need to manually configure `store_hash`

10. **Use move() for ownership transfer** - Zero-cost without cloning

11. **Minimal struct size** - Perfect for embedding in other structures

12. **Shrink after bulk removal** - `shrinkAndFree(allocator, new_len)` reclaims memory

## See Also

- **std.array_hash_map.AutoArrayHashMap** - Managed variant (stores allocator)
- **std.array_hash_map.ArrayHashMapUnmanaged** - Unmanaged with custom Context
- **std.array_hash_map.ArrayHashMap** - Managed with custom Context
- **std.HashMapUnmanaged** - Unordered hash map (doesn't preserve insertion order)
- **std.ArrayList** - For simple sequential storage without key lookup
- **std.MultiArrayList** - The underlying sequential storage structure
- **std.array_hash_map.AutoContext** - Helper for automatic hash contexts
- **std.array_hash_map.hashString** - Utility for hashing strings
