# std.buf_set.BufSet

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Working code demonstrating all BufSet operations: `test_bufset_basic.zig`, `test_bufset_iteration.zig`, `test_bufset_clone.zig`

## Quick Start

**Basic Set Operations**
```zig
const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

var set = std.BufSet.init(gpa.allocator());
defer set.deinit();

try set.insert("apple");
try set.insert("banana");
try set.insert("apple"); // Duplicate - no effect

std.debug.print("Contains apple: {}\n", .{set.contains("apple")}); // true
std.debug.print("Count: {}\n", .{set.count()}); // 2
```

**Iteration Over Members**
```zig
var set = std.BufSet.init(allocator);
defer set.deinit();

try set.insert("red");
try set.insert("green");
try set.insert("blue");

var it = set.iterator();
while (it.next()) |value| {
    std.debug.print("{s}\n", .{value.*});
}
```

**Cloning Sets**
```zig
var original = std.BufSet.init(allocator);
defer original.deinit();

try original.insert("data");

// Clone with same allocator
var copy = try original.clone();
defer copy.deinit();

// Or clone with different allocator
var copy2 = try original.cloneWithAllocator(other_allocator);
defer copy2.deinit();
```

---

## Overview

`std.BufSet` is a set data structure specialized for storing unique strings. Like `BufMap`, it automatically manages string memory by copying all inserted strings into its own storage. This makes it ideal for tracking unique string values like tags, keywords, or identifiers where automatic memory management and duplicate prevention are desired.

The "Buf" prefix refers to "buffer" - BufSet manages string buffers internally. All strings are copied on `insert()` and freed automatically when removed or when `deinit()` is called. The set guarantees uniqueness: inserting the same string multiple times has no effect after the first insertion.

**Key Characteristics:**
- **Automatic string ownership** - Copies strings on insert, manages their lifetime
- **Uniqueness guaranteed** - Duplicate inserts are idempotent (no-op)
- **String-only** - Members must be `[]const u8`
- **Safe after input freed** - Copied strings remain valid even if source is freed
- **Iteration support** - Iterate over members in arbitrary order
- **Cloneable** - Can create deep copies with same or different allocators

**When to use:**
- Tracking unique strings (tags, categories, identifiers)
- Deduplication of string collections
- Membership testing for string values
- Building lists of unique items from various sources
- When you need set semantics with automatic string management

**When NOT to use:**
- Non-string values (use `std.AutoHashMap(T, void)` or `std.EnumSet`)
- Ordered iteration required (BufSet iteration order is arbitrary)
- Very large strings where copying overhead matters
- When you need associated values (use `BufMap` instead)

---

## Fields

`hash_map: BufSetHashMap`

The underlying hash map implementation that stores the strings. Internally, this is a StringHashMap with void values - the keys are the set members. Direct access to this field is generally not needed - use the BufSet methods instead.

---

## Types

- **`Iterator`** - Iterator type returned by `iterator()`. Yields pointers to stored strings. See the Iteration Functions section for usage.

---

## Core Functions

### `pub fn init(a: Allocator) BufSet`

Creates a new empty BufSet backed by the given allocator. The allocator will be used for all internal storage and string copies.

**Example:**
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

var set = std.BufSet.init(gpa.allocator());
defer set.deinit();
```

------

### `pub fn deinit(self: *BufSet) void`

Frees all memory allocated by the BufSet, including all stored strings. After calling `deinit()`, the set is in an undefined state and must not be used.

**Example:**
```zig
var set = std.BufSet.init(allocator);
defer set.deinit(); // Frees all stored strings

try set.insert("value");
// ... use set ...
// deinit called automatically on scope exit
```

------

### `pub fn insert(self: *BufSet, value: []const u8) !void`

Inserts a string into the set. The string is **copied** into the set's internal storage. If the string already exists in the set, this is a no-op (idempotent operation).

**Parameters:**
- `value: []const u8` - The string to insert (will be copied)

**Ownership:** Caller retains ownership of the input string. The set makes its own copy.

**Example:**
```zig
var set = std.BufSet.init(allocator);
defer set.deinit();

try set.insert("hello");
try set.insert("world");
try set.insert("hello"); // No effect - already in set

std.debug.print("Count: {}\n", .{set.count()}); // 2
```

------

### `pub fn contains(self: BufSet, value: []const u8) bool`

Checks whether a string is a member of the set.

**Parameters:**
- `value: []const u8` - The string to check for membership

**Returns:** `true` if the string is in the set, `false` otherwise.

**Example:**
```zig
try set.insert("apple");

if (set.contains("apple")) {
    std.debug.print("Found apple\n", .{});
}

if (!set.contains("banana")) {
    std.debug.print("No banana\n", .{});
}
```

------

### `pub fn remove(self: *BufSet, value: []const u8) void`

Removes a string from the set and frees its memory. If the string is not in the set, this is a no-op.

**Parameters:**
- `value: []const u8` - The string to remove

**Example:**
```zig
try set.insert("temp");
set.remove("temp"); // Frees "temp"

set.remove("nonexistent"); // Safe - does nothing
```

------

### `pub fn count(self: *const BufSet) usize`

Returns the number of unique strings currently stored in the set.

**Returns:** The count of set members.

**Example:**
```zig
var set = std.BufSet.init(allocator);
defer set.deinit();

std.debug.print("Count: {}\n", .{set.count()}); // 0

try set.insert("a");
try set.insert("b");
try set.insert("a"); // Duplicate - no effect
std.debug.print("Count: {}\n", .{set.count()}); // 2
```

------

### `pub fn allocator(self: *const BufSet) Allocator`

Returns the allocator used by this set. Useful when you need to perform allocations using the same allocator as the set.

**Returns:** The `Allocator` instance.

**Example:**
```zig
var set = std.BufSet.init(gpa.allocator());
defer set.deinit();

const set_allocator = set.allocator();
const temp_string = try std.fmt.allocPrint(set_allocator, "item_{}", .{42});
defer set_allocator.free(temp_string);
```

---

## Cloning Functions

### `pub fn clone(self: *const BufSet) Allocator.Error!BufSet`

Creates a deep copy of the set using the same allocator. All strings are duplicated, so modifications to the clone do not affect the original.

**Returns:** A new BufSet containing copies of all strings.

**Example:**
```zig
var original = std.BufSet.init(allocator);
defer original.deinit();

try original.insert("data");

var copy = try original.clone();
defer copy.deinit();

// Modifications are independent
try copy.insert("more");
std.debug.print("Original: {}\n", .{original.count()}); // 1
std.debug.print("Copy: {}\n", .{copy.count()}); // 2
```

------

### `pub fn cloneWithAllocator(self: *const BufSet, new_allocator: Allocator) Allocator.Error!BufSet`

Creates a deep copy of the set using a different allocator. This is useful when transferring set ownership across allocator boundaries.

**Parameters:**
- `new_allocator: Allocator` - The allocator for the cloned set

**Returns:** A new BufSet containing copies of all strings, managed by `new_allocator`.

**Example:**
```zig
var gpa1 = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa1.deinit();

var gpa2 = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa2.deinit();

var original = std.BufSet.init(gpa1.allocator());
defer original.deinit();

try original.insert("value");

// Clone to different allocator
var copy = try original.cloneWithAllocator(gpa2.allocator());
defer copy.deinit();
```

---

## Iteration Functions

### `pub fn iterator(self: *const BufSet) Iterator`

Returns an iterator over all strings in the set. Iteration order is arbitrary and may change when items are added or removed.

**Returns:** An `Iterator` that yields `*[]const u8` (pointers to stored strings).

**Example:**
```zig
try set.insert("red");
try set.insert("green");
try set.insert("blue");

var it = set.iterator();
while (it.next()) |value_ptr| {
    std.debug.print("{s}\n", .{value_ptr.*});
}
```

---

## Usage Patterns

### Pattern 1: Deduplication

```zig
fn getUniqueWords(allocator: Allocator, text: []const u8) !std.BufSet {
    var unique = std.BufSet.init(allocator);
    errdefer unique.deinit();

    var it = std.mem.tokenizeScalar(u8, text, ' ');
    while (it.next()) |word| {
  try unique.insert(word);
    }

    return unique;
}

// Usage:
const text = "the quick brown fox jumps over the lazy dog";
var words = try getUniqueWords(allocator, text);
defer words.deinit();

std.debug.print("Unique words: {}\n", .{words.count()});
```

### Pattern 2: Tag System

```zig
const Article = struct {
    title: []const u8,
    tags: std.BufSet,

    fn init(allocator: Allocator, title: []const u8) Article {
  return .{
      .title = title,
      .tags = std.BufSet.init(allocator),
  };
    }

    fn deinit(self: *Article) void {
  self.tags.deinit();
    }

    fn addTag(self: *Article, tag: []const u8) !void {
  try self.tags.insert(tag);
    }

    fn hasTag(self: *const Article, tag: []const u8) bool {
  return self.tags.contains(tag);
    }
};
```

### Pattern 3: Collecting Unique Items from Multiple Sources

```zig
fn mergeUniqueSources(allocator: Allocator, sources: []const []const []const u8) !std.BufSet {
    var combined = std.BufSet.init(allocator);
    errdefer combined.deinit();

    for (sources) |source| {
  for (source) |item| {
      try combined.insert(item);
  }
    }

    return combined;
}

// Usage:
const source1 = &[_][]const u8{ "a", "b", "c" };
const source2 = &[_][]const u8{ "b", "c", "d" };
const source3 = &[_][]const u8{ "c", "d", "e" };

const sources = &[_][]const []const u8{ source1, source2, source3 };
var unique = try mergeUniqueSources(allocator, sources);
defer unique.deinit();
// Result: { "a", "b", "c", "d", "e" }
```

### Pattern 4: Set Operations

```zig
fn setDifference(allocator: Allocator, a: *const std.BufSet, b: *const std.BufSet) !std.BufSet {
    var result = std.BufSet.init(allocator);
    errdefer result.deinit();

    var it = a.iterator();
    while (it.next()) |value| {
  if (!b.contains(value.*)) {
      try result.insert(value.*);
  }
    }

    return result;
}

fn setIntersection(allocator: Allocator, a: *const std.BufSet, b: *const std.BufSet) !std.BufSet {
    var result = std.BufSet.init(allocator);
    errdefer result.deinit();

    var it = a.iterator();
    while (it.next()) |value| {
  if (b.contains(value.*)) {
      try result.insert(value.*);
  }
    }

    return result;
}
```

---

## Error Sets

`Allocator.Error`

Returned by `insert()`, `clone()`, and `cloneWithAllocator()` when memory allocation fails. Common errors:
- `OutOfMemory` - The allocator cannot provide more memory for set storage or string copies

---

## Debug Checklist

✅ **Remember to call deinit()** - BufSet owns all strings. Use `defer set.deinit();` immediately after init.

✅ **Don't free strings from iterator** - Strings returned by iteration are owned by the set, not the caller.

✅ **insert() is idempotent** - Inserting the same string multiple times is safe and has no effect after the first.

✅ **contains() doesn't allocate** - Safe to call repeatedly for membership tests.

✅ **remove is safe for missing values** - No need to check contains() before removing.

✅ **Iteration order is arbitrary** - Don't depend on any particular order when iterating.

✅ **clone() creates independent copies** - Modifications to the clone don't affect the original.

✅ **Strings passed to insert() can be freed** - `insert()` copies the strings, so you can reuse or free input buffers immediately.

---

## Performance Tips

1. **Pre-allocate for large sets** - While BufSet doesn't expose capacity hints, consider the underlying hash map growth if you're inserting thousands of items.

2. **Use contains() before insert() sparingly** - `insert()` already checks for duplicates internally. Checking first adds overhead unless you need to branch on the result.

3. **Batch inserts** - If building a set from many sources, collect items first then insert in a loop to minimize allocator contention.

4. **Reuse strings for contains()** - `contains()` takes a `[]const u8`, so you can use string literals or const buffers for membership tests without allocation.

5. **Consider alternatives for large strings** - BufSet copies all strings. For very large strings, consider a `StringHashMap(void)` with manual string management or reference counting.

6. **Use clone() judiciously** - Cloning copies all strings. For read-only sharing, consider passing `*const BufSet` references instead.

---

## See Also

- **`std.BufMap`** - Map version with string keys and string values
- **`std.StringHashMap`** - Generic hash map with string keys and any value type
- **`std.AutoHashMap`** - Generic hash map for non-string types
- **`std.EnumSet`** - Compile-time set for enum values
- **`std.DynamicBitSet`** - Set for integer indices stored as bits
