# std.hash_map

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all hash_map features

## Quick Start

### Most Common Patterns

**Pattern 1: String Keys (Most Common)**
```zig
const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

// For string keys, ALWAYS use StringHashMap
var map = std.StringHashMap(i32).init(gpa.allocator());
defer map.deinit();

try map.put("score", 100);
try map.put("level", 5);

if (map.get("score")) |value| {
    std.debug.print("Score: {}\n", .{value});  // 100
}
```

**Pattern 2: Integer/Enum Keys**
```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit();

try map.put(1, "one");
try map.put(2, "two");

const value = map.get(1) orelse "not found";
std.debug.print("{s}\n", .{value});  // "one"
```

**Pattern 3: Counting/Frequency Map**
```zig
var counts = std.StringHashMap(usize).init(allocator);
defer counts.deinit();

const words = [_][]const u8{"foo", "bar", "foo", "baz", "foo"};
for (words) |word| {
    const result = try counts.getOrPut(word);
    if (result.found_existing) {
        result.value_ptr.* += 1;
    } else {
        result.value_ptr.* = 1;
    }
}
// counts: foo=3, bar=1, baz=1
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Insert/update | `put(key, val)` | `map.put("key", 42)` |
| Retrieve | `get(key)` | `map.get("key") orelse 0` |
| Get or create | `getOrPut(key)` | `try map.getOrPut("key")` |
| Remove | `remove(key)` | `_ = map.remove("key")` |
| Check existence | `contains(key)` | `if (map.contains("key"))` |
| Clear all | `clearAndFree()` | `map.clearAndFree()` |
| Iterate | `iterator()` | `var it = map.iterator()` |

### ⚠️ Critical: String Keys

```zig
// WRONG - Do NOT use AutoHashMap with string keys
var bad = std.AutoHashMap([]const u8, i32).init(alloc);  // ❌ Won't compile in 0.16+

// CORRECT - Use StringHashMap for string keys
var good = std.StringHashMap(i32).init(alloc);           // ✅ Proper string hashing
defer good.deinit();
```

**Why:** `AutoHashMap` with slice types is ambiguous about hashing intent. Use `StringHashMap` for content-based hashing or `AutoHashMap(*const []const u8)` for pointer-based identity.

---

## Overview

`std.hash_map` provides hash table implementations for Zig. Hash tables offer O(1) average-case lookup, insertion, and deletion operations, making them ideal for key-value storage, caching, and set operations.

**Key Characteristics:**
- **Multiple Variants** - Managed, unmanaged, string-specialized, and custom context types
- **Automatic Hashing** - Built-in hash functions for common types (integers, enums, pointers)
- **String Support** - Dedicated `StringHashMap` for string keys with content-based hashing
- **Open Addressing** - Uses linear probing for efficient memory layout and cache performance
- **Load Factor Control** - Automatic resizing maintains ~70% max load for performance

**When to use std.hash_map:**
- Fast key-based lookups (dictionaries, caches, indexes)
- Counting/frequency analysis
- Deduplication and set operations
- Memoization of expensive computations
- Associative data structures

**Related namespaces:**
- `std.array_hash_map` - Preserves insertion order, better iteration performance
- `std.mem` - Memory utilities, includes `eql` for comparisons
- `std.hash` - Low-level hash functions (Wyhash, CityHash, etc.)

---

## Core Types

### `AutoHashMap(comptime K: type, comptime V: type)`

**Managed hash map** with automatic hashing for common key types. Stores allocator internally.

**Type Signature:**
```zig
pub fn AutoHashMap(comptime K: type, comptime V: type) type {
    return HashMap(K, V, AutoContext(K), default_max_load_percentage);
}
```

**When to use:**
- Integer keys (`u32`, `i64`, etc.)
- Enum keys
- Pointer keys (identity-based, not content-based)
- Simple struct keys (auto-generated hash/eql)

**Example:**
```zig
var map = std.AutoHashMap(u32, []const u8).init(allocator);
defer map.deinit();

try map.put(42, "answer");
const val = map.get(42);  // "answer"
```

------

### `AutoHashMapUnmanaged(comptime K: type, comptime V: type)`

**Unmanaged variant** that requires passing allocator to all operations.

**When to use:**
- When you want explicit control over allocator usage
- Building allocator-generic abstractions
- Performance-critical code where you want to minimize indirection

**Example:**
```zig
var map: std.AutoHashMapUnmanaged(u32, i32) = .{};
defer map.deinit(allocator);

try map.put(allocator, 1, 100);
try map.put(allocator, 2, 200);
```

------

### `StringHashMap(comptime V: type)`

**Specialized hash map for string keys** with content-based hashing.

**Type Signature:**
```zig
pub fn StringHashMap(comptime V: type) type {
    return HashMap([]const u8, V, StringContext, default_max_load_percentage);
}
```

**Critical:** This is the **only correct way** to use string keys in Zig 0.16+.

**Example:**
```zig
var map = std.StringHashMap(i32).init(allocator);
defer map.deinit();

try map.put("Alice", 25);
try map.put("Bob", 30);
```

------

### `StringHashMapUnmanaged(comptime V: type)`

**Unmanaged variant** of StringHashMap.

**Example:**
```zig
var map: std.StringHashMapUnmanaged(i32) = .{};
defer map.deinit(allocator);

try map.put(allocator, "key", 42);
```

------

### `HashMap(comptime K, comptime V, comptime Context, comptime max_load_percentage)`

**Low-level generic hash map** with custom hash/equality context.

**When to use:**
- Custom hashing strategies
- Complex key types
- Tuning load factor for specific use cases

**Example:**
```zig
const MyContext = struct {
    pub fn hash(self: @This(), key: MyKey) u64 {
        _ = self;
        return std.hash.Wyhash.hash(0, std.mem.asBytes(&key));
    }
    pub fn eql(self: @This(), a: MyKey, b: MyKey) bool {
        _ = self;
        return a.id == b.id;
    }
};

var map = std.HashMap(MyKey, MyValue, MyContext, 80).init(allocator);
defer map.deinit();
```

------

### `HashMapUnmanaged(comptime K, comptime V, comptime Context, comptime max_load_percentage)`

**Unmanaged variant** of generic HashMap.

------

## Context Types

### `AutoContext(comptime K: type)`

Provides automatic hash and equality functions for common types.

**Supported key types:**
- Integers: `u8`, `u32`, `i64`, etc.
- Enums
- Pointers (identity-based comparison)
- Simple structs (auto-generates hash/eql from fields)

**Functions:**
- `hash(self: AutoContext(K), key: K) u64` - Generate hash for key
- `eql(self: AutoContext(K), a: K, b: K) bool` - Test equality

------

### `StringContext`

Provides content-based hashing for string slices.

**Functions:**
- `hash(self: StringContext, s: []const u8) u64` - Hash string contents
- `eql(self: StringContext, a: []const u8, b: []const u8) bool` - Compare string contents

------

### `StringIndexContext`

Context for using string slices as indices into an array.

------

### `StringIndexAdapter`

Adapter for hash maps that store string indices instead of full strings.

------

## Utility Functions

### `pub fn hashString(s: []const u8) u64`

Hash a string slice using the default string hash function.

**Example:**
```zig
const hash1 = std.hash_map.hashString("hello");
const hash2 = std.hash_map.hashString("hello");
// hash1 == hash2
```

------

### `pub fn eqlString(a: []const u8, b: []const u8) bool`

Compare two string slices for equality.

**Example:**
```zig
const equal = std.hash_map.eqlString("foo", "foo");  // true
```

------

### `pub fn getAutoHashFn(comptime K: type, comptime Context: type) (fn (Context, K) u64)`

Get the auto-generated hash function for a key type.

------

### `pub fn getAutoEqlFn(comptime K: type, comptime Context: type) (fn (Context, K, K) bool)`

Get the auto-generated equality function for a key type.

------

## Usage Patterns

### Pattern 1: Word Frequency Counter

```zig
const std = @import("std");

pub fn countWords(allocator: std.mem.Allocator, text: []const u8) !std.StringHashMap(usize) {
    var counts = std.StringHashMap(usize).init(allocator);
    errdefer counts.deinit();

    var iter = std.mem.tokenizeAny(u8, text, " \t\n,.");
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var counts = try countWords(gpa.allocator(), "foo bar foo baz foo");
    defer counts.deinit();

    var iter = counts.iterator();
    while (iter.next()) |entry| {
        std.debug.print("{s}: {}\n", .{entry.key_ptr.*, entry.value_ptr.*});
    }
}
```

**Explanation:**
1. Use `StringHashMap` for string keys
2. `getOrPut()` returns pointer to value location
3. Check `found_existing` to increment or initialize
4. Caller owns the returned map and must deinit

------

### Pattern 2: Memoization Cache

```zig
const std = @import("std");

const FibCache = std.AutoHashMap(u64, u64);

fn fibonacci(cache: *FibCache, n: u64) !u64 {
    if (n <= 1) return n;

    // Check cache
    if (cache.get(n)) |cached| {
        return cached;
    }

    // Compute and cache
    const result = try fibonacci(cache, n - 1) + try fibonacci(cache, n - 2);
    try cache.put(n, result);
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var cache = FibCache.init(gpa.allocator());
    defer cache.deinit();

    const result = try fibonacci(&cache, 50);
    std.debug.print("fib(50) = {}\n", .{result});
}
```

**Explanation:**
1. Use `AutoHashMap` for integer keys
2. Check cache with `get()` before computing
3. Store result with `put()` for future lookups
4. Dramatic performance improvement for recursive functions

------

### Pattern 3: Configuration Map with Pre-allocation

```zig
const std = @import("std");

pub fn loadConfig(allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var config = std.StringHashMap([]const u8).init(allocator);
    errdefer config.deinit();

    // Pre-allocate for known number of entries
    try config.ensureTotalCapacity(10);

    // No allocation needed for these puts
    config.putAssumeCapacity("host", "localhost");
    config.putAssumeCapacity("port", "8080");
    config.putAssumeCapacity("timeout", "30");

    return config;
}
```

**Explanation:**
Pre-allocating with `ensureTotalCapacity()` eliminates allocation overhead when the number of entries is known upfront.

------

### Pattern 4: Unmanaged Map for Explicit Control

```zig
const std = @import("std");

const Cache = struct {
    map: std.AutoHashMapUnmanaged(u32, []const u8) = .{},
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Cache {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Cache) void {
        self.map.deinit(self.allocator);
    }

    pub fn put(self: *Cache, key: u32, value: []const u8) !void {
        try self.map.put(self.allocator, key, value);
    }

    pub fn get(self: *Cache, key: u32) ?[]const u8 {
        return self.map.get(key);
    }
};
```

**Explanation:**
Unmanaged maps give you full control over allocator passing, useful when building wrapper types or allocator-generic abstractions.

------

## Error Sets

### `Allocator.Error`
- `error.OutOfMemory` - Allocator failed to provide requested memory

All allocation functions (`put`, `getOrPut`, `ensureTotalCapacity`, etc.) can return `Allocator.Error`.

------

## Debug Checklist

✅ **Use `StringHashMap` for string keys** - Never `AutoHashMap([]const u8, V)`

✅ **Always call `deinit()`** - Hash maps allocate internal storage that must be freed

✅ **Free heap-allocated keys/values separately** - `deinit()` only frees internal structure

✅ **Check `found_existing` after `getOrPut()`** - Don't blindly overwrite existing values

✅ **Handle pointer invalidation** - Insertions may invalidate pointers from previous `getPtr()` calls

✅ **Pre-allocate when size is known** - Use `ensureTotalCapacity()` to avoid incremental resizing

✅ **Use `errdefer` for cleanup** - When building maps in functions that return errors

------

## Performance Tips

1. **Pre-allocate capacity when size is known** - Eliminates incremental resizing:
   ```zig
   var map = std.AutoHashMap(usize, i32).init(allocator);
   defer map.deinit();

   try map.ensureTotalCapacity(1000);  // No resizing for first 1000 entries
   for (0..1000) |i| {
       map.putAssumeCapacity(i, @intCast(i));
   }
   ```

2. **Use `getPtr()` to avoid double lookup** - When you need to read and modify:
   ```zig
   // Good - single lookup
   if (map.getPtr(key)) |value_ptr| {
       value_ptr.* += 1;
   }

   // Bad - two lookups
   if (map.contains(key)) {
       const old = map.get(key).?;
       try map.put(key, old + 1);
   }
   ```

3. **Use `putAssumeCapacity()` after pre-allocation** - Zero allocation overhead:
   ```zig
   var map = std.AutoHashMap(u32, i32).init(allocator);
   defer map.deinit();

   try map.ensureTotalCapacity(100);
   for (0..100) |i| {
       map.putAssumeCapacity(@intCast(i), @intCast(i * 2));  // No allocation
   }
   ```

4. **Reuse maps with `clearRetainingCapacity()`** - Keep allocated memory:
   ```zig
   var cache = std.StringHashMap(i32).init(allocator);
   defer cache.deinit();

   for (requests) |req| {
       cache.clearRetainingCapacity();  // Keep buffer
       try processRequest(&cache, req);
   }
   ```

5. **Use unmanaged variants for zero-sized contexts** - Slightly smaller memory footprint when you already have allocator access nearby.

6. **Consider `ArrayHashMap` for iteration-heavy workloads** - Better cache locality when you iterate more than you lookup.

------

## See Also

- **std.StringHashMap(V)** - String-keyed hash map (most common variant)
- **std.AutoHashMap(K, V)** - Auto-hashing hash map for integers/enums/pointers
- **std.array_hash_map** - Insertion-order preserving hash maps
- **std.hash** - Low-level hash functions (Wyhash, CityHash, etc.)
- **std.mem.eql** - Generic equality comparison
