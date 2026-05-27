# std.hash_map.AutoHashMapUnmanaged

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Working code examples demonstrating all AutoHashMapUnmanaged features:
- **[test_autohashmap_unmanaged_basic.zig](../../Examples/test_autohashmap_unmanaged_basic.zig)** - Basic operations, getOrPut, modifications
- **[test_autohashmap_unmanaged_capacity.zig](../../Examples/test_autohashmap_unmanaged_capacity.zig)** - Capacity management, pre-allocation patterns
- **[test_autohashmap_unmanaged_iterators.zig](../../Examples/test_autohashmap_unmanaged_iterators.zig)** - All iterator types and patterns
- **[test_autohashmap_unmanaged_patterns.zig](../../Examples/test_autohashmap_unmanaged_patterns.zig)** - Real-world usage patterns
- **[test_autohashmap_unmanaged_advanced.zig](../../Examples/test_autohashmap_unmanaged_advanced.zig)** - Advanced features and techniques

## Quick Start

### Most Common Patterns

**Basic Key-Value Storage**
```zig
var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();
const allocator = da.allocator();

// Unmanaged version requires passing allocator to each operation
var map = std.AutoHashMapUnmanaged(u32, []const u8){};
defer map.deinit(allocator);

try map.put(allocator, 1, "one");
try map.put(allocator, 2, "two");

if (map.get(1)) |value| {
    std.debug.print("Value: {s}\n", .{value});
}
```

**Pre-allocated Capacity**
```zig
var map = std.AutoHashMapUnmanaged(u32, i32){};
defer map.deinit(allocator);

// Pre-allocate for 1000 entries
try map.ensureTotalCapacity(allocator, 1000);

// Now insert without allocation
for (0..1000) |i| {
    map.putAssumeCapacity(@intCast(i), @intCast(i * 2));
}
```

**getOrPut Pattern**
```zig
var map = std.StringHashMapUnmanaged(u32){};
defer map.deinit(allocator);

const result = try map.getOrPut(allocator, "counter");
if (result.found_existing) {
    result.value_ptr.* += 1;  // Increment existing
} else {
    result.value_ptr.* = 1;   // Initialize new
}
```

**Iterating Over Entries**
```zig
var map = std.AutoHashMapUnmanaged(u32, []const u8){};
defer map.deinit(allocator);

try map.put(allocator, 1, "one");
try map.put(allocator, 2, "two");

var iter = map.iterator();
while (iter.next()) |entry| {
    std.debug.print("{}: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

### Key Operations
- `put(allocator, key, value)` - Insert or update entry
- `get(key)` - Retrieve value (returns `?V`)
- `getOrPut(allocator, key)` - Insert if missing, return pointer to value
- `remove(key)` - Delete entry, returns `bool`
- `contains(key)` - Check for key existence
- `iterator()` - Iterate over all entries
- `deinit(allocator)` - Free backing storage

### ⚠️ Critical: Memory Management
```zig
var map = std.AutoHashMapUnmanaged(K, V){};
defer map.deinit(allocator);  // ← REQUIRED! Must pass allocator to deinit
```

**Important:** Unlike `AutoHashMap`, the unmanaged version:
- Does **NOT** store the allocator internally
- Requires passing `allocator` to every operation that may allocate
- Saves 8-16 bytes of memory per instance
- Provides more control over memory management

⚠️ **Critical for Zig 0.16:** You **cannot** use `std.AutoHashMapUnmanaged([]const u8, V)` for string keys. Use `std.StringHashMapUnmanaged(V)` instead!

---

## Overview

`std.hash_map.AutoHashMapUnmanaged(K, V)` is the unmanaged variant of `AutoHashMap`, providing O(1) average-case hash table operations without storing an allocator internally. This gives you maximum control over memory management at the cost of more verbose API calls.

**Key Characteristics:**
- **No Stored Allocator**: Allocator passed to each operation, not stored in struct
- **Smaller Memory Footprint**: Saves 8-16 bytes per instance compared to managed variant
- **Explicit Control**: You explicitly manage when and how allocations occur
- **Generic Type**: Parameterized over key type `K` and value type `V`
- **Automatic Hashing**: Uses default hash and equality functions for the key type
- **Dynamic Growth**: Automatically resizes when load factor threshold is exceeded
- **Pointer Instability**: Pointers to keys/values may be invalidated by insertions that trigger growth
- **Open Addressing**: Uses linear probing for collision resolution

**When to use AutoHashMapUnmanaged:**
- Embedding hash maps in structs (no allocator field bloat)
- Managing multiple maps with a single allocator
- Fine-grained control over when allocations occur
- Performance-critical code where you want explicit allocation control
- Library code that shouldn't assume allocator storage

**When to use managed AutoHashMap instead:**
- Simpler API (no allocator parameter on every call)
- Standalone maps where the extra 8-16 bytes don't matter
- Prototyping and quick development
- When you want the convenience of stored allocator

**Type Relationships:**
```zig
// Unmanaged: no allocator stored
pub fn AutoHashMapUnmanaged(comptime K: type, comptime V: type) type {
    return HashMapUnmanaged(
  K,
  V,
  AutoContext(K),
  default_max_load_percentage,
    );
}

// Managed: stores allocator
pub fn AutoHashMap(comptime K: type, comptime V: type) type {
    return HashMap(K, V, AutoContext(K), default_max_load_percentage);
}
```

**Related Types:**
- **[std.hash_map.AutoHashMap](./std.hash_map.AutoHashMap.md)** - Managed variant with stored allocator
- `std.StringHashMapUnmanaged(V)` - For string keys (required in Zig 0.16)
- `std.AutoArrayHashMapUnmanaged(K, V)` - Maintains insertion order, provides indexed access

## Parameters

### `K: type`

The key type. Must be hashable using Zig's default auto-hashing. Supported types include:
- Integers (`u8`, `i32`, `usize`, etc.)
- Floats (`f32`, `f64`)
- Enums
- Pointers (hashed by address, not content)
- Arrays of hashable types
- Structs containing only hashable fields

**Examples:**
```zig
std.AutoHashMapUnmanaged(u32, []const u8)           // Integer keys
std.AutoHashMapUnmanaged(enum { foo, bar }, i32)    // Enum keys
std.AutoHashMapUnmanaged(struct{x: i32, y: i32}, bool)  // Struct keys
```

**⚠️ IMPORTANT:** In Zig 0.16, you **cannot** use `std.AutoHashMapUnmanaged([]const u8, V)`. This will fail to compile! For string keys, **always use `std.StringHashMapUnmanaged(V)`** instead:

```zig
// ❌ WRONG - Will not compile in Zig 0.16
var map = std.AutoHashMapUnmanaged([]const u8, i32){};

// ✅ CORRECT - Use StringHashMapUnmanaged for string keys
var map = std.StringHashMapUnmanaged(i32){};
```

------

### `V: type`

The value type. Can be any Zig type including `void` (for set-like behavior).

**Examples:**
```zig
std.AutoHashMapUnmanaged(u32, void)      // Set of integers
std.StringHashMapUnmanaged(User)         // User lookup by name
std.AutoHashMapUnmanaged(i32, []const u8)   // Integer to string mapping
```

## Fields

### `metadata: ?[*]Metadata = null`

Pointer to the metadata array. This is an internal field used for the hash table implementation. **Do not modify directly.**

------

### `size: Size = 0`

Current number of elements in the hashmap. Use `count()` method to access this safely.

**Example:**
```zig
var map = std.AutoHashMapUnmanaged(u32, i32){};
defer map.deinit(allocator);

try map.put(allocator, 1, 100);
std.debug.print("Size: {}\n", .{map.size});  // Direct access
std.debug.print("Count: {}\n", .{map.count()});  // Recommended method
```

------

### `available: Size = 0`

Number of available slots before a grow is needed to satisfy the `max_load_percentage`. Internal field - use `capacity()` method instead.

------

### `pointer_stability: std.debug.SafetyLock = .{}`

Used to detect memory safety violations in debug builds. Tracks whether pointer stability assertions are enabled via `lockPointers()` / `unlockPointers()`.

## Types

### `Entry`

An entry containing pointers to a key and value stored in the map.

**Fields:**
- `key_ptr: *K` - Pointer to the key
- `value_ptr: *V` - Pointer to the value

**Returned by:** `getEntry()`, `getOrPut()`, `getOrPutValue()`

**Example:**
```zig
if (map.getEntry(42)) |entry| {
    std.debug.print("Key: {}, Value: {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
    entry.value_ptr.* = 999;  // Modify in-place
}
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
const result = try map.getOrPut(allocator, "counter");
if (result.found_existing) {
    result.value_ptr.* += 1;
} else {
    result.value_ptr.* = 1;  // Initialize new entry
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
if (map.fetchRemove(old_key)) |kv| {
    std.debug.print("Removed: {} -> {}\n", .{kv.key, kv.value});
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

### `Managed`

The managed variant (`std.hash_map.HashMap`) that stores an allocator. Returned by `promote()`.

------

### `Hash`

The integer type used as the result of hashing keys (typically `u32` or `u64`).

------

### `Size`

The integer type used to store the size and capacity of the map (typically `u32` or `usize`).

## Values

### `empty: Self`

A map containing no keys or values. Equivalent to zero-initialization.

**Example:**
```zig
var map: std.AutoHashMapUnmanaged(u32, i32) = .empty;
defer map.deinit(allocator);
```

## Core Operations

### `pub fn put(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!void`

Insert or update a key-value pair. If the key already exists, its value is replaced (clobbered). May allocate memory to grow the map.

**Parameters:**
- `allocator: Allocator` - Allocator to use for potential growth
- `key: K` - The key to insert or update
- `value: V` - The value to associate with the key

**Returns:** `Allocator.Error!void` - May fail if memory allocation fails

**Example:**
```zig
var map = std.AutoHashMapUnmanaged(u32, []const u8){};
defer map.deinit(allocator);

try map.put(allocator, 1, "first");
try map.put(allocator, 1, "updated");  // Replaces "first"
```

**Performance:** O(1) average case, may trigger resize if load factor threshold exceeded

------

### `pub fn putNoClobber(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!void`

Insert a key-value pair, asserting that the key does not already exist. Useful for catching logic errors.

**Example:**
```zig
try map.putNoClobber(allocator, 1, 100);
// try map.putNoClobber(allocator, 1, 200);  // ← Assertion failure in debug!
```

**Panics:** Asserts if the key is already present (debug builds)

------

### `pub fn putAssumeCapacity(self: *Self, key: K, value: V) void`

Insert or update without checking capacity. Must ensure sufficient capacity beforehand using `ensureTotalCapacity()` or `ensureUnusedCapacity()`.

**Example:**
```zig
try map.ensureTotalCapacity(allocator, 100);
for (0..100) |i| {
    map.putAssumeCapacity(@intCast(i), @intCast(i * 2));
}
```

**Performance:** Never allocates, making it suitable for performance-critical code

**Panics:** Assertion failure if capacity is insufficient

------

### `pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void`

Insert without checking capacity, asserting the key doesn't exist.

**Panics:** Assertion failure if key exists or capacity insufficient

------

### `pub fn get(self: Self, key: K) ?V`

Retrieve the value associated with a key.

**Parameters:**
- `key: K` - The key to look up

**Returns:** `?V` - The value if found, `null` otherwise

**Example:**
```zig
if (map.get(42)) |value| {
    std.debug.print("Value: {}\n", .{value});
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
if (map.getPtr(42)) |value_ptr| {
    value_ptr.* += 100;  // Modify in-place
}
```

**Warning:** Pointer may be invalidated by subsequent insertions that trigger growth

------

### `pub fn getEntry(self: Self, key: K) ?Entry`

Retrieve both key and value pointers for a key.

**Returns:** `?Entry` - Entry with `key_ptr` and `value_ptr`, or `null`

**Example:**
```zig
if (map.getEntry(42)) |entry| {
    entry.value_ptr.* = 999;
}
```

------

### `pub fn getKey(self: Self, key: K) ?K`

Retrieve the actual key stored in the map. Useful when key equality differs from key identity.

**Returns:** `?K` - Copy of the stored key if found, `null` otherwise

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
if (map.contains(42)) {
    std.debug.print("Key 42 exists\n", .{});
}
```

**Performance:** O(1) average case, slightly faster than `get()` since it doesn't copy the value

------

### `pub fn getOrPut(self: *Self, allocator: Allocator, key: K) Allocator.Error!GetOrPutResult`

Get an existing entry or create a new one with undefined value. The caller is responsible for initializing the value if a new entry was created.

**Returns:** `GetOrPutResult` with:
- `found_existing: bool` - Whether key was already present
- `value_ptr: *V` - Pointer to the value (initialize if `found_existing == false`)
- `key_ptr: *K` - Pointer to the key

**Example:**
```zig
const result = try map.getOrPut(allocator, "counter");
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
try map.ensureUnusedCapacity(allocator, 1);
const result = map.getOrPutAssumeCapacity(42);
result.value_ptr.* = 100;
```

------

### `pub fn getOrPutValue(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!Entry`

Get an existing entry or insert a new one with the provided value.

**Returns:** `Entry` - Always returns valid entry (existing or newly created)

**Example:**
```zig
const entry = try map.getOrPutValue(allocator, "default", 0);
std.debug.print("Value: {}\n", .{entry.value_ptr.*});
```

------

### `pub fn fetchPut(self: *Self, allocator: Allocator, key: K, value: V) Allocator.Error!?KV`

Insert a new entry and return the previous key-value pair if one existed.

**Returns:** `?KV` - Previous key and value if replaced, `null` if new insertion

**Example:**
```zig
if (try map.fetchPut(allocator, 42, new_value)) |old| {
    std.debug.print("Replaced old value: {}\n", .{old.value});
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
if (map.remove(42)) {
    std.debug.print("Removed entry\n", .{});
}
```

**Performance:** O(1) average case

------

### `pub fn fetchRemove(self: *Self, key: K) ?KV`

Remove an entry and return its key-value pair.

**Returns:** `?KV` - Removed key and value, or `null` if not found

**Example:**
```zig
if (map.fetchRemove(42)) |kv| {
    std.debug.print("Removed: {} -> {}\n", .{kv.key, kv.value});
}
```

------

### `pub fn removeByPtr(self: *Self, key_ptr: *K) void`

Remove an entry by pointer to its key. The pointer must be valid and point to a key currently in the map.

**Example:**
```zig
if (map.getKeyPtr(42)) |key_ptr| {
    map.removeByPtr(key_ptr);
}
```

**Warning:** Undefined behavior if `key_ptr` is not a valid pointer to a key in this map

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

### `pub fn ensureTotalCapacity(self: *Self, allocator: Allocator, new_capacity: Size) Allocator.Error!void`

Ensure the map can hold at least `new_capacity` entries without further allocation.

**Example:**
```zig
try map.ensureTotalCapacity(allocator, 1000);
for (0..1000) |i| {
    map.putAssumeCapacity(@intCast(i), @intCast(i * 2));  // No allocation
}
```

**Use Case:** Pre-allocate when you know the final size to avoid incremental growth

------

### `pub fn ensureUnusedCapacity(self: *Self, allocator: Allocator, additional_count: Size) Allocator.Error!void`

Ensure the map can hold `additional_count` more entries beyond current count.

**Example:**
```zig
const current = map.count();
try map.ensureUnusedCapacity(allocator, 100);  // Room for 100 more
```

------

### `pub fn clearRetainingCapacity(self: *Self) void`

Remove all entries but keep the allocated capacity for reuse.

**Example:**
```zig
map.clearRetainingCapacity();
std.debug.print("Count: {}, Capacity: {}\n", .{map.count(), map.capacity()});
```

**Use Case:** Reusing a map in a loop without repeated allocation/deallocation

**Warning:** Does not free keys or values - you must handle that before calling

------

### `pub fn clearAndFree(self: *Self, allocator: Allocator) void`

Remove all entries and free the backing allocation.

**Example:**
```zig
map.clearAndFree(allocator);
// Map is now empty with zero capacity
```

**Warning:** Does not free keys or values - you must handle that separately

------

### `pub fn deinit(self: *Self, allocator: Allocator) void`

Free the map's backing storage. The map is invalidated and cannot be used afterward.

**Example:**
```zig
var map = std.AutoHashMapUnmanaged(u32, i32){};
defer map.deinit(allocator);
```

**Critical:** Always call `deinit()` unless you've transferred ownership via `move()`

**Warning:** Does not free keys or values. If they are heap-allocated, free them first:
```zig
var iter = map.iterator();
while (iter.next()) |entry| {
    allocator.free(entry.value_ptr.*);  // Free values
}
map.deinit(allocator);  // Then free map structure
```

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

## Advanced Functions

### `pub fn clone(self: Self, allocator: Allocator) Allocator.Error!Self`

Create a shallow copy of the map using the same allocator.

**Returns:** New map with copied entries (keys and values are copied, not deep-cloned)

**Example:**
```zig
var copy = try map.clone(allocator);
defer copy.deinit(allocator);
```

**Note:** For types like `[]const u8`, this copies pointers, not string contents

------

### `pub fn move(self: *Self) Self`

Transfer ownership of the map's data to a new instance, leaving the original in an empty state.

**Returns:** New map instance owning the data

**Example:**
```zig
var map1 = std.AutoHashMapUnmanaged(u32, i32){};
try map1.put(allocator, 1, 100);

var map2 = map1.move();  // map1 is now empty, map2 owns the data
defer map2.deinit(allocator);
// No need to deinit map1 - it's empty
```

**Use Case:** Transferring ownership without cloning

------

### `pub fn promote(self: Self, allocator: Allocator) Managed`

Convert to a managed hash map that stores the allocator internally. The unmanaged map's data is wrapped, not copied.

**Returns:** Managed `AutoHashMap` wrapping this map's data

**Example:**
```zig
var unmanaged = std.AutoHashMapUnmanaged(u32, i32){};
try unmanaged.put(allocator, 1, 100);

var managed = unmanaged.promote(allocator);
defer managed.deinit();

// Managed can use simplified API (no allocator parameter)
try managed.put(2, 200);
```

------

### `pub fn rehash(self: *Self, ctx: anytype) void`

Rebuild the hash table in-place. Rarely needed, as the map maintains itself automatically.

------

### `pub fn lockPointers(self: *Self) void`

Enable pointer stability checking. After calling, any operation that would invalidate existing key/value pointers will trigger an assertion.

**Use Case:** Debugging pointer invalidation issues

------

### `pub fn unlockPointers(self: *Self) void`

Disable pointer stability checking.

## Context-Aware Functions

These functions allow you to provide a custom hashing/equality context explicitly:

- `pub fn putContext(self: *Self, allocator: Allocator, key: K, value: V, ctx: Context) Allocator.Error!void`
- `pub fn getContext(self: Self, key: K, ctx: Context) ?V`
- `pub fn getOrPutContext(self: *Self, allocator: Allocator, key: K, ctx: Context) Allocator.Error!GetOrPutResult`
- `pub fn removeContext(self: *Self, key: K, ctx: Context) bool`
- And more...

**Use Case:** Advanced scenarios where you need explicit control over hashing behavior

## Adapted Key Functions

These functions allow lookups using a different key type than `K`, provided you supply a custom context with appropriate hash and equality functions:

- `pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V`
- `pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V`
- `pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K`
- `pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool`
- And more...

**Use Case:** Advanced feature for heterogeneous lookups

## Usage Patterns

### Word Frequency Counter

```zig
var counts = std.StringHashMapUnmanaged(u32){};
defer counts.deinit(allocator);

const text = "the quick brown fox jumps over the lazy dog";
var iter = std.mem.tokenizeScalar(u8, text, ' ');
while (iter.next()) |word| {
    const result = try counts.getOrPut(allocator, word);
    if (result.found_existing) {
  result.value_ptr.* += 1;
    } else {
  result.value_ptr.* = 1;
    }
}
```

### Caching Expensive Computations

```zig
var cache = std.AutoHashMapUnmanaged(u64, u64){};
defer cache.deinit(allocator);

fn fibonacci(n: u64, c: *std.AutoHashMapUnmanaged(u64, u64), alloc: std.mem.Allocator) !u64 {
    if (n <= 1) return n;

    if (c.get(n)) |cached| return cached;

    const result = try fibonacci(n - 1, c, alloc) + try fibonacci(n - 2, c, alloc);
    try c.put(alloc, n, result);
    return result;
}
```

### Set Operations with void Values

```zig
var set = std.AutoHashMapUnmanaged(u32, void){};
defer set.deinit(allocator);

try set.put(allocator, 1, {});
try set.put(allocator, 2, {});
try set.put(allocator, 3, {});

if (set.contains(2)) {
    std.debug.print("Set contains 2\n", .{});
}
```

### Building Lookup Table

```zig
const User = struct { id: u32, name: []const u8, age: u32 };

var lookup = std.AutoHashMapUnmanaged(u32, User){};
defer lookup.deinit(allocator);

const users = [_]User{
    .{ .id = 1, .name = "Alice", .age = 25 },
    .{ .id = 2, .name = "Bob", .age = 30 },
};

try lookup.ensureTotalCapacity(allocator, users.len);
for (users) |user| {
    lookup.putAssumeCapacity(user.id, user);
}
```

### Batch Processing with clearRetainingCapacity

```zig
var map = std.AutoHashMapUnmanaged(u32, i32){};
defer map.deinit(allocator);

for (0..10) |batch_num| {
    defer map.clearRetainingCapacity();

    try map.ensureUnusedCapacity(allocator, 100);
    for (0..100) |i| {
  map.putAssumeCapacity(@intCast(i), @intCast(batch_num));
    }

    // Process batch...
}
```

### Struct with Embedded Unmanaged Map

```zig
const Cache = struct {
    data: std.AutoHashMapUnmanaged(u32, []const u8) = .{},

    fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
  self.data.deinit(alloc);
    }

    fn put(self: *@This(), alloc: std.mem.Allocator, key: u32, value: []const u8) !void {
  try self.data.put(alloc, key, value);
    }

    fn get(self: *const @This(), key: u32) ?[]const u8 {
  return self.data.get(key);
    }
};
```

## Error Sets

`AutoHashMapUnmanaged` operations can return the following errors:

- **`Allocator.Error`** - Memory allocation failed
  - `OutOfMemory` - The allocator could not provide requested memory

**Functions that may fail:**
- `put()`, `putNoClobber()`
- `getOrPut()`, `getOrPutValue()`
- `fetchPut()`
- `ensureTotalCapacity()`, `ensureUnusedCapacity()`
- `clone()`

**Functions that cannot fail:**
- All `AssumeCapacity` variants (after pre-allocation)
- `get()`, `getPtr()`, `contains()`
- `remove()`, `fetchRemove()`
- Iterators
- `deinit()`, `clearRetainingCapacity()`, `clearAndFree()`

## Debug Checklist

When debugging unmanaged hash map issues, verify:

1. ✅ **Passing allocator to every operation** - Unlike managed variant, every operation needs allocator parameter
2. ✅ **Calling `deinit(allocator)` exactly once** - Missing causes memory leaks, double-deinit causes crashes
3. ✅ **Freeing heap-allocated keys/values before `deinit()`** - The map only frees internal storage, not your data
4. ✅ **Not using pointers after growth operations** - `put()`, `getOrPut()` may invalidate existing `*K` and `*V` pointers
5. ✅ **Not modifying map during iteration** - Iterators are invalidated by insertions/removals
6. ✅ **Initializing values after `getOrPut()`** - When `found_existing == false`, the value is undefined
7. ✅ **Using `AssumeCapacity` only after `ensure*Capacity`** - Otherwise triggers assertion failure
8. ✅ **Using `StringHashMapUnmanaged` for string keys** - Cannot use `AutoHashMapUnmanaged([]const u8, V)` in Zig 0.16
9. ✅ **Checking return values** - `get()` returns `?V`, not `V` - handle the null case
10. ✅ **Not storing pointers to stack-allocated keys** - Keys must outlive the map or be copied
11. ✅ **Using `errdefer` for cleanup on error paths** - Prevent leaks when initialization fails partway
12. ✅ **Passing correct allocator to `deinit()`** - Must be same allocator used for allocations

## Performance Tips

1. **Pre-allocate when size is known** - Call `ensureTotalCapacity()` before bulk insertions to avoid incremental resizing:
   ```zig
   try map.ensureTotalCapacity(allocator, expected_size);
   ```

2. **Use `AssumeCapacity` variants in loops** - After pre-allocation, skip error handling:
   ```zig
   try map.ensureUnusedCapacity(allocator, items.len);
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
   - `AutoHashMapUnmanaged` - Maximum control, smallest memory footprint
   - `AutoHashMap` - Convenience of stored allocator
   - `StringHashMapUnmanaged` - For string keys with content-based hashing
   - `AutoArrayHashMapUnmanaged` - When you need insertion order or indexed access

7. **Embed in structs for memory efficiency** - Unmanaged variant saves 8-16 bytes per instance:
   ```zig
   const MyStruct = struct {
 map: std.AutoHashMapUnmanaged(u32, i32) = .{},
 // No allocator field needed
   };
   ```

8. **Batch allocations with single allocator** - Multiple unmanaged maps can efficiently share one allocator:
   ```zig
   var map1 = std.AutoHashMapUnmanaged(u32, i32){};
   var map2 = std.AutoHashMapUnmanaged(u64, []const u8){};
   // Both use same allocator - more efficient than storing allocator twice
   ```

9. **Consider load factor** - Default is 80%. Lower values waste memory, higher values hurt performance. The default is well-tuned for most cases.

10. **Profile before optimizing** - The unmanaged variant adds complexity. Only use it when the benefits (memory savings, explicit control) justify the more verbose API.

## See Also

- **[std.hash_map.AutoHashMap](./std.hash_map.AutoHashMap.md)** - Managed variant with stored allocator (simpler API)
- `std.StringHashMapUnmanaged(V)` - For string keys (required in Zig 0.16)
- `std.AutoArrayHashMapUnmanaged(K, V)` - Hash map maintaining insertion order with indexed access
- `std.HashMap(K, V, Context, max_load)` - Base hash map with custom hashing context
- `std.hash_map` - Hash map module with additional utilities
- `std.mem.Allocator` - Memory allocator interface
