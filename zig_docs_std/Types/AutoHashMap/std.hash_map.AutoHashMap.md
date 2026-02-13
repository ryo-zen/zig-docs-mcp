# std.hash_map.AutoHashMap

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Working code examples demonstrating all AutoHashMap features

## Quick Start

### Most Common Patterns

**Basic Key-Value Storage**
```zig
const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

// For string keys, use StringHashMap (not AutoHashMap with []const u8)
var map = std.StringHashMap(i32).init(allocator);
defer map.deinit();

try map.put("score", 100);
try map.put("level", 5);

if (map.get("score")) |value| {
    std.debug.print("Score: {}\n", .{value});
}
```

**Pre-allocated Capacity**
```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit();

try map.ensureTotalCapacity(1000);  // Pre-allocate for 1000 entries
map.putAssumeCapacity(1, "one");    // No allocation needed
map.putAssumeCapacity(2, "two");
```

**Checking and Updating**
```zig
var map = std.StringHashMap(u32).init(allocator);
defer map.deinit();

const result = try map.getOrPut("counter");
if (result.found_existing) {
    result.value_ptr.* += 1;  // Increment existing
} else {
    result.value_ptr.* = 1;   // Initialize new
}
```

**Iterating Over Entries**
```zig
var map = std.StringHashMap(i32).init(allocator);
defer map.deinit();

try map.put("Alice", 25);
try map.put("Bob", 30);

var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{s}: {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

### Key Operations
- `put(key, value)` - Insert or update entry
- `get(key)` - Retrieve value (returns `?V`)
- `getOrPut(key)` - Insert if missing, return pointer to value
- `remove(key)` - Delete entry, returns `bool`
- `contains(key)` - Check for key existence
- `iterator()` - Iterate over all entries

### ⚠️ Critical: Memory Management
```zig
var map = std.AutoHashMap(K, V).init(allocator);
defer map.deinit();  // ← REQUIRED! Always deinit to free backing storage
```

**Important:** `deinit()` only frees the hash map's internal storage. If your keys or values are heap-allocated (e.g., strings that you allocated), you must free them separately before calling `deinit()`.

⚠️ **Critical for Zig 0.16:** You **cannot** use `std.AutoHashMap([]const u8, V)` for string keys. Use `std.StringHashMap(V)` instead! AutoHashMap with slice keys will fail to compile because the hashing intent is unclear.

---

## Overview

`std.hash_map.AutoHashMap(K, V)` is Zig's primary hash table implementation for automatic key hashing. It provides O(1) average-case lookup, insertion, and deletion operations with automatic memory management through a stored allocator.

**Key Characteristics:**
- **Generic Type**: Parameterized over key type `K` and value type `V`
- **Automatic Hashing**: Uses default hash and equality functions for the key type
- **Managed Allocator**: Stores allocator internally, simplifying API calls
- **Dynamic Growth**: Automatically resizes when load factor threshold is exceeded
- **Pointer Stability**: Pointers to keys/values may be invalidated by insertions that trigger growth
- **Open Addressing**: Uses linear probing for collision resolution

**When to use AutoHashMap:**
- General-purpose key-value storage with automatic hashing
- Counting occurrences (e.g., word frequency)
- Caching computed values by input
- Building lookup tables for fast access
- Any scenario where you need O(1) average lookup time

**Type Relationships:**
```zig
pub fn AutoHashMap(comptime K: type, comptime V: type) type {
    return HashMap(
  K,
  V,
  AutoContext(K),
  default_max_load_percentage,
    );
}
```

`AutoHashMap` is a convenience wrapper that automatically selects appropriate hash and equality functions for your key type. For custom hashing behavior, use `HashMap` directly with a custom context.

**Related Types:**
- `std.AutoHashMapUnmanaged(K, V)` - Requires passing allocator to each operation (use when you need fine control)
- `std.StringHashMap(V)` - Alias for `AutoHashMap([]const u8, V)` for string keys
- `std.AutoArrayHashMap(K, V)` - Maintains insertion order, provides indexed access

## Parameters

### `K: type`

The key type. Must be hashable using Zig's default auto-hashing. Supported types include:
- Integers (`u8`, `i32`, `usize`, etc.)
- Floats (`f32`, `f64`)
- Enums
- Pointers (hashed by address, not content)
- Arrays and slices of hashable types
- Structs containing only hashable fields

**Examples:**
```zig
std.AutoHashMap(u32, []const u8)           // Integer keys
std.AutoHashMap(enum { foo, bar }, i32)    // Enum keys
std.AutoHashMap(struct{x: i32, y: i32}, bool)  // Struct keys
```

**⚠️ IMPORTANT:** In Zig 0.16, you **cannot** use `std.AutoHashMap([]const u8, V)`. This will fail to compile! For string keys, **always use `std.StringHashMap(V)`** instead:

```zig
// ❌ WRONG - Will not compile in Zig 0.16
var map = std.StringHashMap(i32).init(allocator);

// ✅ CORRECT - Use StringHashMap for string keys
var map = std.StringHashMap(i32).init(allocator);
```

------

### `V: type`

The value type. Can be any Zig type including void (for set-like behavior).

**Examples:**
```zig
std.AutoHashMap(u32, void)      // Set of integers
std.StringHashMap(User)         // User lookup by name (use StringHashMap for string keys!)
std.AutoHashMap(i32, []const u8)   // Integer to string mapping
```

## Fields

### `unmanaged: Unmanaged`

The underlying unmanaged hash map storage. This field contains the actual hash table data structures and implements all core operations.

**Direct Access:** Generally not needed - use the managed wrapper's methods instead. May be useful for advanced scenarios where you want to temporarily work with the unmanaged API.

------

### `allocator: Allocator`

The allocator used for all internal memory operations. Stored once during `init()` and used for all subsequent allocations.

**Example:**
```zig
var map = std.AutoHashMap(u32, i32).init(allocator);
std.debug.print("Using allocator: {any}\n", .{map.allocator});
```

------

### `ctx: Context`

The hashing and equality context. For `AutoHashMap`, this is automatically populated with `AutoContext(K)` which provides default implementations of `hash` and `eql` for the key type.

**Advanced Usage:** Access `ctx` to understand or debug hashing behavior, but generally you don't need to interact with this field directly.

## Types

### `Unmanaged`

The unmanaged variant (`std.hash_map.HashMapUnmanaged`). Contains all storage and logic, but requires passing allocator to each operation.

**Usage:** See `std.hash_map.AutoHashMapUnmanaged` for the unmanaged API.

------

### `Entry`

An entry containing pointers to a key and value stored in the map.

**Fields:**
- `key_ptr: *K` - Pointer to the key
- `value_ptr: *V` - Pointer to the value

**Returned by:** `getEntry()`, `getOrPut()`, `getOrPutValue()`

**Example:**
```zig
const entry = map.getEntry("key").?;
std.debug.print("Key: {s}, Value: {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
entry.value_ptr.* = 999;  // Modify in-place
```

------

### `GetOrPutResult`

Result type returned by `getOrPut` and related functions.

**Fields:**
- `key_ptr: *K` - Pointer to the key in the map
- `value_ptr: *V` - Pointer to the value in the map
- `found_existing: bool` - `true` if key was already present, `false` if newly inserted

**Example:**
```zig
const result = try map.getOrPut("counter");
if (result.found_existing) {
    result.value_ptr.* += 1;
} else {
    result.value_ptr.* = 1;
}
```

------

### `KV`

A copy of a key and value which are no longer in the map.

**Fields:**
- `key: K` - The key (owned copy)
- `value: V` - The value (owned copy)

**Returned by:** `fetchPut()`, `fetchRemove()`

**Example:**
```zig
if (map.fetchRemove("old_key")) |kv| {
    std.debug.print("Removed: {s} -> {}\n", .{kv.key, kv.value});
}
```

------

### `Iterator`

Iterator over entries in the map. Invalidated if the map is modified during iteration.

**Methods:**
- `next() ?Entry` - Returns next entry or `null` when exhausted

**Example:**
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{any}: {any}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

------

### `KeyIterator`

Iterator over keys only. More efficient than full iterator when you only need keys.

**Methods:**
- `next() ?*K` - Returns pointer to next key or `null`

------

### `ValueIterator`

Iterator over values only. More efficient than full iterator when you only need values.

**Methods:**
- `next() ?*V` - Returns pointer to next value or `null`

------

### `Hash`

The integer type used as the result of hashing keys (typically `u32` or `u64`).

------

### `Size`

The integer type used to store the size and capacity of the map (typically `u32` or `usize`).

## Initialization Functions

### `pub fn init(allocator: Allocator) Self`

Create a managed hash map with an empty context. This is the standard initialization for `AutoHashMap`.

**Example:**
```zig
var map = std.StringHashMap(i32).init(allocator);
defer map.deinit();
```

**Returns:** An empty hash map ready for use.

**Note:** If you need a custom context, use `initContext()` instead.

------

### `pub fn initContext(allocator: Allocator, ctx: Context) Self`

Create a managed hash map with a custom hashing context. Rarely needed for `AutoHashMap` since it uses automatic context.

**Example:**
```zig
const ctx = std.hash_map.AutoContext(u32){};
var map = std.AutoHashMap(u32, []const u8).initContext(allocator, ctx);
defer map.deinit();
```

## Core Operations

### `pub fn put(self: *Self, key: K, value: V) Allocator.Error!void`

Insert or update a key-value pair. If the key already exists, its value is replaced (clobbered).

**Parameters:**
- `key: K` - The key to insert or update
- `value: V` - The value to associate with the key

**Returns:** `Allocator.Error!void` - May fail if memory allocation is needed and fails

**Example:**
```zig
try map.put("name", "Alice");
try map.put("name", "Bob");  // Replaces "Alice" with "Bob"
```

**Performance:** O(1) average case, may trigger resize if load factor threshold exceeded

------

### `pub fn putNoClobber(self: *Self, key: K, value: V) Allocator.Error!void`

Insert a key-value pair, asserting that the key does not already exist. Useful for catching logic errors.

**Example:**
```zig
try map.putNoClobber("unique_id", 12345);
// try map.putNoClobber("unique_id", 67890);  // ← Assertion failure!
```

**Panics:** Asserts if the key is already present (debug builds)

------

### `pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`

Insert or update without checking capacity. Must ensure sufficient capacity beforehand using `ensureTotalCapacity()` or `ensureUnusedCapacity()`.

**Example:**
```zig
try map.ensureUnusedCapacity(10);  // Reserve space for 10 more entries
map.putAssumeCapacity(1, "one");
map.putAssumeCapacity(2, "two");
```

**Performance:** Never allocates, making it suitable for performance-critical code

**Panics:** Assertion failure if capacity is insufficient

------

### `pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`

Insert without checking capacity, asserting the key doesn't exist.

**Example:**
```zig
try map.ensureTotalCapacity(100);
for (0..10) |i| {
    map.putAssumeCapacityNoClobber(@intCast(i), i * 2);
}
```

**Panics:** Assertion failure if key exists or capacity insufficient

------

### `pub fn get(self: Self, key: K) ?V`

Retrieve the value associated with a key.

**Parameters:**
- `key: K` - The key to look up

**Returns:** `?V` - The value if found, `null` otherwise

**Example:**
```zig
try map.put("score", 100);

if (map.get("score")) |score| {
    std.debug.print("Score: {}\n", .{score});
} else {
    std.debug.print("Score not found\n", .{});
}
```

**Performance:** O(1) average case

**Note:** Returns a copy of the value. For large values or to modify in-place, use `getPtr()`.

------

### `pub fn getPtr(self: Self, key: K) ?*V`

Retrieve a pointer to the value associated with a key. Allows in-place modification.

**Returns:** `?*V` - Pointer to the value if found, `null` otherwise

**Example:**
```zig
if (map.getPtr("counter")) |counter_ptr| {
    counter_ptr.* += 1;  // Increment in-place
}
```

**Warning:** Pointer may be invalidated by subsequent insertions that trigger growth

------

### `pub fn getEntry(self: Self, key: K) ?Entry`

Retrieve both key and value pointers for a key.

**Returns:** `?Entry` - Entry with `key_ptr` and `value_ptr`, or `null`

**Example:**
```zig
if (map.getEntry("user")) |entry| {
    std.debug.print("Key: {s}, Value: {any}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

------

### `pub fn getKey(self: Self, key: K) ?K`

Retrieve the actual key stored in the map. Useful when key equality differs from key identity (e.g., string contents vs pointer).

**Returns:** `?K` - Copy of the stored key if found, `null` otherwise

**Example:**
```zig
// Useful for interned strings or custom equality
if (map.getKey(lookup_key)) |stored_key| {
    // stored_key is the actual key in the map
}
```

------

### `pub fn getKeyPtr(self: Self, key: K) ?*K`

Retrieve a pointer to the key stored in the map.

**Returns:** `?*K` - Pointer to the stored key, or `null`

------

### `pub fn contains(self: Self, key: K) bool`

Check if a key exists in the map without retrieving the value.

**Returns:** `bool` - `true` if key exists, `false` otherwise

**Example:**
```zig
if (map.contains("admin")) {
    std.debug.print("Admin access detected\n", .{});
}
```

**Performance:** O(1) average case, slightly faster than `get()` since it doesn't copy the value

------

### `pub fn getOrPut(self: *Self, key: K) Allocator.Error!GetOrPutResult`

Get an existing entry or create a new one with undefined value. The caller is responsible for initializing the value if a new entry was created.

**Returns:** `GetOrPutResult` with:
- `found_existing: bool` - Whether key was already present
- `value_ptr: *V` - Pointer to the value (initialize if `found_existing == false`)
- `key_ptr: *K` - Pointer to the key

**Example:**
```zig
const result = try map.getOrPut("counter");
if (result.found_existing) {
    result.value_ptr.* += 1;
} else {
    result.value_ptr.* = 1;  // Initialize for new entry
}
```

**Use Case:** Efficient when you need to update existing values or initialize new ones

------

### `pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult`

Like `getOrPut()` but assumes capacity has been pre-allocated. Never allocates.

**Example:**
```zig
try map.ensureUnusedCapacity(1);
const result = map.getOrPutAssumeCapacity("key");
result.value_ptr.* = 42;
```

------

### `pub fn getOrPutValue(self: *Self, key: K, value: V) Allocator.Error!Entry`

Get an existing entry or insert a new one with the provided value.

**Returns:** `Entry` - Always returns valid entry (existing or newly created)

**Example:**
```zig
const entry = try map.getOrPutValue("default", 0);
std.debug.print("Value: {}\n", .{entry.value_ptr.*});
```

------

### `pub fn fetchPut(self: *Self, key: K, value: V) Allocator.Error!?KV`

Insert a new entry and return the previous key-value pair if one existed.

**Returns:** `?KV` - Previous key and value if replaced, `null` if new insertion

**Example:**
```zig
if (try map.fetchPut("config", new_config)) |old| {
    std.debug.print("Replaced old config: {any}\n", .{old.value});
}
```

**Use Case:** Useful when you need to clean up the old value before replacement

------

### `pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV`

Like `fetchPut()` but assumes capacity is sufficient. Never allocates.

------

### `pub fn remove(self: *Self, key: K) bool`

Remove an entry by key.

**Returns:** `bool` - `true` if entry was removed, `false` if key not found

**Example:**
```zig
if (map.remove("temporary")) {
    std.debug.print("Removed temporary entry\n", .{});
}
```

**Performance:** O(1) average case

------

### `pub fn fetchRemove(self: *Self, key: K) ?KV`

Remove an entry and return its key-value pair.

**Returns:** `?KV` - Removed key and value, or `null` if not found

**Example:**
```zig
if (map.fetchRemove("cache_entry")) |kv| {
    std.debug.print("Removed: {s} -> {}\n", .{kv.key, kv.value});
    // Clean up if needed
    allocator.free(kv.value);
}
```

------

### `pub fn removeByPtr(self: *Self, key_ptr: *K) void`

Remove an entry by pointer to its key. The pointer must be valid and point to a key currently in the map.

**Example:**
```zig
if (map.getKeyPtr("target")) |key_ptr| {
    map.removeByPtr(key_ptr);
}
```

**Warning:** Undefined behavior if `key_ptr` is not a valid pointer to a key in this map

## Iteration Functions

### `pub fn iterator(self: *const Self) Iterator`

Create an iterator over all entries in the map. Order is not guaranteed.

**Returns:** `Iterator` - Iterator over `Entry` items

**Example:**
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{any}: {any}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

**Warning:** Iterator is invalidated if map is modified during iteration

------

### `pub fn keyIterator(self: Self) KeyIterator`

Create an iterator over keys only.

**Example:**
```zig
var iter = map.keyIterator();
while (iter.next()) |key_ptr| {
    std.debug.print("Key: {any}\n", .{key_ptr.*});
}
```

------

### `pub fn valueIterator(self: Self) ValueIterator`

Create an iterator over values only.

**Example:**
```zig
var sum: i32 = 0;
var iter = map.valueIterator();
while (iter.next()) |value_ptr| {
    sum += value_ptr.*;
}
```

## Capacity Management Functions

### `pub fn count(self: Self) Size`

Return the number of items currently in the map.

**Returns:** `Size` - Number of key-value pairs

**Example:**
```zig
std.debug.print("Map contains {} entries\n", .{map.count()});
```

**Performance:** O(1)

------

### `pub fn capacity(self: Self) Size`

Return the total number of entries the map can hold without allocating.

**Returns:** `Size` - Current capacity

**Example:**
```zig
std.debug.print("Capacity: {}, Count: {}\n", .{map.capacity(), map.count()});
```

------

### `pub fn ensureTotalCapacity(self: *Self, expected_count: Size) Allocator.Error!void`

Ensure the map can hold at least `expected_count` entries without further allocation.

**Example:**
```zig
try map.ensureTotalCapacity(1000);  // Prepare for 1000 entries
for (0..1000) |i| {
    map.putAssumeCapacity(@intCast(i), i * 2);  // No allocation
}
```

**Use Case:** Pre-allocate when you know the final size to avoid incremental growth

------

### `pub fn ensureUnusedCapacity(self: *Self, additional_count: Size) Allocator.Error!void`

Ensure the map can hold `additional_count` more entries beyond current count.

**Example:**
```zig
const current = map.count();
try map.ensureUnusedCapacity(100);  // Room for 100 more
// Next 100 insertions guaranteed not to allocate
```

------

### `pub fn clearRetainingCapacity(self: *Self) void`

Remove all entries but keep the allocated capacity for reuse.

**Example:**
```zig
map.clearRetainingCapacity();
std.debug.print("Count: {}, Capacity: {}\n", .{map.count(), map.capacity()});
// Output: Count: 0, Capacity: <previous capacity>
```

**Use Case:** Reusing a map in a loop without repeated allocation/deallocation

**Warning:** Does not free keys or values - you must handle that before calling

------

### `pub fn clearAndFree(self: *Self) void`

Remove all entries and free the backing allocation.

**Example:**
```zig
map.clearAndFree();
// Map is now empty with zero capacity
```

**Warning:** Does not free keys or values - you must handle that separately

------

### `pub fn deinit(self: *Self) void`

Free the map's backing storage. The map is invalidated and cannot be used afterward.

**Example:**
```zig
var map = std.AutoHashMap(u32, i32).init(allocator);
defer map.deinit();
```

**Critical:** Always call `deinit()` unless you've transferred ownership via `move()`

**Warning:** Does not free keys or values. If they are heap-allocated, free them first:
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    allocator.free(entry.value_ptr.*);  // Free values
}
map.deinit();  // Then free map structure
```

## Advanced Functions

### `pub fn clone(self: Self) Allocator.Error!Self`

Create a shallow copy of the map using the same allocator.

**Returns:** New map with copied entries (keys and values are copied, not deep-cloned)

**Example:**
```zig
const map_copy = try map.clone();
defer map_copy.deinit();
```

**Note:** For types like `[]const u8`, this copies pointers, not string contents

------

### `pub fn cloneWithAllocator(self: Self, new_allocator: Allocator) Allocator.Error!Self`

Create a shallow copy using a different allocator.

------

### `pub fn cloneWithContext(self: Self, new_ctx: anytype) Allocator.Error!HashMap(...)`

Create a copy with a different hashing context.

------

### `pub fn cloneWithAllocatorAndContext(self: Self, new_allocator: Allocator, new_ctx: anytype) Allocator.Error!HashMap(...)`

Create a copy with both different allocator and context.

------

### `pub fn move(self: *Self) Self`

Transfer ownership of the map's data to a new instance, leaving the original in an empty state.

**Returns:** New map instance owning the data

**Example:**
```zig
var map1 = std.AutoHashMap(u32, i32).init(allocator);
try map1.put(1, 100);

var map2 = map1.move();  // map1 is now empty, map2 owns the data
defer map2.deinit();
// No need to deinit map1 - it's empty
```

**Use Case:** Transferring ownership without cloning

------

### `pub fn rehash(self: *Self) void`

Rebuild the hash table in-place. Rarely needed, as the map maintains itself automatically.

------

### `pub fn lockPointers(self: *Self) void`

Enable pointer stability checking. After calling, any operation that would invalidate existing key/value pointers will trigger an assertion.

**Use Case:** Debugging pointer invalidation issues

------

### `pub fn unlockPointers(self: *Self) void`

Disable pointer stability checking.

## Adapted Key Functions

These functions allow lookups using a different key type than `K`, provided you supply a custom context with appropriate hash and equality functions.

### `pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`
### `pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`
### `pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`
### `pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K`
### `pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry`
### `pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`
### `pub fn getOrPutAdapted(self: *Self, key: anytype, ctx: anytype) Allocator.Error!GetOrPutResult`
### `pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult`
### `pub fn fetchRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV`
### `pub fn removeAdapted(self: *Self, key: anytype, ctx: anytype) bool`

**Example Use Case:**
```zig
// Map using []const u8 keys, but lookup with string literals
// Requires custom context with compatible hash/eql
const entry = map.getAdapted("lookup_string", custom_ctx);
```

**Note:** Advanced feature - most users should use standard functions

## Usage Patterns

### Word Frequency Counter

```zig
const std = @import("std");

pub fn countWords(allocator: std.mem.Allocator, text: []const u8) !std.StringHashMap(u32) {
    var counts = std.StringHashMap(u32).init(allocator);
    errdefer counts.deinit();

    var iter = std.mem.tokenize(u8, text, " \t\n");
    while (iter.next()) |word| {
  const result = try counts.getOrPut(word);
  if (result.found_existing) {
      result.value_ptr.* += 1;
  } else {
      result.value_ptr.* = 1;
  }
    }

    return counts;
}
```

### Caching Function Results

```zig
const Cache = std.AutoHashMap(u64, []const u8);

pub fn expensiveComputation(cache: *Cache, allocator: std.mem.Allocator, input: u64) ![]const u8 {
    if (cache.get(input)) |cached_result| {
  return cached_result;  // Return cached value
    }

    // Perform expensive computation
    const result = try allocator.alloc(u8, 100);
    // ... compute result ...

    try cache.put(input, result);
    return result;
}
```

### Building a Lookup Table

```zig
pub fn buildUserLookup(allocator: std.mem.Allocator, users: []const User) !std.AutoHashMap(u32, User) {
    var lookup = std.AutoHashMap(u32, User).init(allocator);
    errdefer lookup.deinit();

    try lookup.ensureTotalCapacity(@intCast(users.len));

    for (users) |user| {
  lookup.putAssumeCapacity(user.id, user);
    }

    return lookup;
}
```

### Removing Duplicates

```zig
pub fn removeDuplicates(allocator: std.mem.Allocator, items: []const i32) ![]const i32 {
    var seen = std.AutoHashMap(i32, void).init(allocator);
    defer seen.deinit();

    var result = std.ArrayList(i32).init(allocator);
    errdefer result.deinit();

    for (items) |item| {
  const gop = try seen.getOrPut(item);
  if (!gop.found_existing) {
      try result.append(item);
  }
    }

    return result.toOwnedSlice();
}
```

## Error Sets

`AutoHashMap` operations can return the following errors:

- **`Allocator.Error`** - Memory allocation failed
  - `OutOfMemory` - The allocator could not provide requested memory

Functions that may fail:
- `put()`, `putNoClobber()`
- `getOrPut()`, `getOrPutValue()`
- `fetchPut()`
- `ensureTotalCapacity()`, `ensureUnusedCapacity()`
- `clone()` and variants

**Functions that cannot fail:**
- All `AssumeCapacity` variants (after pre-allocation)
- `get()`, `getPtr()`, `contains()`
- `remove()`, `fetchRemove()`
- Iterators
- `deinit()`, `clearRetainingCapacity()`, `clearAndFree()`

## Debug Checklist

When debugging hash map issues, verify:

1. **Calling `deinit()` exactly once** - Missing `deinit()` causes memory leaks, double-deinit causes crashes
2. **Freeing heap-allocated keys/values before `deinit()`** - The map only frees internal storage, not your data
3. **Not using pointers after growth operations** - `put()`, `getOrPut()` may invalidate existing `*K` and `*V` pointers
4. **Not modifying map during iteration** - Iterators are invalidated by insertions/removals
5. **Initializing values after `getOrPut()`** - When `found_existing == false`, the value is undefined
6. **Using `AssumeCapacity` only after `ensure*Capacity`** - Otherwise triggers assertion failure
7. **Proper key equality for your use case** - For string keys, consider `std.StringHashMap` vs `AutoHashMap([]const u8, V)`
8. **Checking return values** - `get()` returns `?V`, not `V` - handle the null case
9. **Not storing pointers to stack-allocated keys** - Keys must outlive the map or be copied
10. **Using `errdefer` for cleanup on error paths** - Prevent leaks when initialization fails partway

## Performance Tips

1. **Pre-allocate when size is known** - Call `ensureTotalCapacity()` before bulk insertions to avoid incremental resizing:
   ```zig
   try map.ensureTotalCapacity(expected_size);
   ```

2. **Use `AssumeCapacity` variants in loops** - After pre-allocation, skip error handling:
   ```zig
   try map.ensureUnusedCapacity(items.len);
   for (items) |item| {
 map.putAssumeCapacity(item.id, item);  // No error handling needed
   }
   ```

3. **Reuse maps with `clearRetainingCapacity()`** - Avoid allocation churn when processing batches:
   ```zig
   for (batches) |batch| {
 defer map.clearRetainingCapacity();
 // Process batch with map
   }
   ```

4. **Prefer `contains()` over `get()` for existence checks** - Slightly faster when you don't need the value

5. **Use `getPtr()` for in-place modification** - Avoid copying large values:
   ```zig
   if (map.getPtr(key)) |value_ptr| {
 value_ptr.field += 1;  // Modify directly
   }
   ```

6. **Choose the right hash map variant**:
   - `AutoHashMap` - General use, stores allocator
   - `AutoHashMapUnmanaged` - When you need manual allocator control (saves 8 bytes per instance)
   - `StringHashMap` - For string keys with content-based hashing
   - `AutoArrayHashMap` - When you need insertion order or indexed access

7. **Consider load factor** - Default is 80%. Lower values waste memory, higher values hurt performance. The default is well-tuned for most cases.

8. **Batch removals** - If removing many entries, consider rebuilding the map from scratch if removal count is significant

## See Also

- **[std.hash_map.AutoHashMapUnmanaged](./std.hash_map.AutoHashMapUnmanaged.md)** - Unmanaged variant requiring allocator per call
- **std.StringHashMap(V)** - Alias for `AutoHashMap([]const u8, V)` with proper string hashing
- **std.AutoArrayHashMap(K, V)** - Hash map maintaining insertion order with indexed access
- **std.HashMap(K, V, Context, max_load)** - Base hash map with custom hashing context
- **std.hash_map** - Hash map module with additional utilities
- **std.mem.Allocator** - Memory allocator interface
