# std.array_list

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all array_list features

## Quick Start

### Most Common Patterns

**Pattern 1: Basic Dynamic Array**
```zig
const std = @import("std");

var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();

var list: std.ArrayList(i32) = .empty;
defer list.deinit(da.allocator());

try list.append(da.allocator(), 42);
try list.append(da.allocator(), 100);
try list.append(da.allocator(), 7);

std.debug.print("Items: {any}\n", .{list.items}); // [42, 100, 7]
```

**Pattern 2: Pre-allocated Capacity**
```zig
var list = std.ArrayList(u8).empty;
defer list.deinit(allocator);

try list.ensureTotalCapacity(allocator, 1024);
list.appendAssumeCapacity('H');  // No allocation needed
list.appendAssumeCapacity('i');
```

**Pattern 3: String Building**
```zig
var string: std.ArrayList(u8) = .empty;
defer string.deinit(allocator);

try string.appendSlice(allocator, "Hello, ");
try string.appendSlice(allocator, "World!");
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Add single item | `append(alloc, item)` | `list.append(alloc, 42)` |
| Add multiple | `appendSlice(alloc, items)` | `list.appendSlice(alloc, &[_]i32{1,2,3})` |
| Insert at index | `insert(alloc, i, item)` | `list.insert(alloc, 0, 99)` |
| Remove at index | `orderedRemove(i)` | `list.orderedRemove(2)` |
| Remove last | `pop()` | `const last = list.pop().?` |
| Clear | `clearRetainingCapacity()` | `list.clearRetainingCapacity()` |
| Transfer ownership | `toOwnedSlice(alloc)` | `const owned = try list.toOwnedSlice(alloc)` |

### ⚠️ Critical: Zig 0.16 Unmanaged API

```zig
// WRONG - Old managed API (pre-0.16)
var list = std.ArrayList(i32).init(allocator);  // ❌ Removed in 0.16
defer list.deinit();                             // ❌ Missing allocator
try list.append(42);                             // ❌ Missing allocator

// CORRECT - New unmanaged API (0.16+)
var list: std.ArrayList(i32) = .empty;          // ✅ Use .empty
defer list.deinit(allocator);                    // ✅ Pass allocator to deinit
try list.append(allocator, 42);                  // ✅ Pass allocator to append
```

---

## Overview

`std.array_list` provides dynamic array types for Zig. In Zig 0.16+, these are **unmanaged** types that require explicit allocator passing, giving you full control over memory allocation.

**Key Characteristics:**
- **Explicit Memory Control** - All allocation operations require passing an allocator
- **Generic Types** - Work with any element type `T`
- **Custom Alignment** - Support for custom memory alignment requirements
- **Amortized O(1) Append** - Efficient growth with geometric capacity expansion
- **Direct Slice Access** - `items` field provides zero-cost slice view

**When to use std.array_list:**
- Building dynamic collections that grow/shrink over time
- String building with `ArrayList(u8)`
- When you need O(1) indexed access and efficient appends
- Collections where insertion order matters
- When you want explicit control over allocator usage

**Related namespaces:**
- `std.ArrayList(T)` - Convenience type alias for `array_list.Aligned(T, null)`
- `std.mem` - Slice manipulation utilities
- `std.heap` - Allocator implementations
- `std.MultiArrayList` - Struct-of-arrays layout

---

## Core Types

### `Aligned(comptime T: type, comptime alignment: ?mem.Alignment)`

The foundation type for all array lists. **This is what `std.ArrayList(T)` actually returns.**

**Parameters:**
- `T: type` - Element type to store
- `alignment: ?mem.Alignment` - Custom alignment, or `null` for default

**Fields:**
- `items: Slice` - Readable slice of current elements
- `capacity: usize` - Total elements that can fit without reallocation

**Key Constant:**
- `empty: Self` - Preferred initialization (replaces deprecated default initialization)

**Example:**
```zig
// Most common: use via std.ArrayList(T)
var list: std.ArrayList(i32) = .empty;  // Same as Aligned(i32, null).empty
defer list.deinit(allocator);

// Custom alignment for SIMD operations
var aligned_list: std.array_list.Aligned(f32, .@"16") = .empty;
defer aligned_list.deinit(allocator);
```

------

### `AlignedManaged(comptime T: type, comptime alignment: ?mem.Alignment)`

**Managed variant** that stores the allocator internally. Useful when you want to avoid passing allocators to every operation.

**Key Difference:** Constructor takes allocator once, methods don't require it

**Example:**
```zig
var list = std.array_list.AlignedManaged(i32, null).init(allocator);
defer list.deinit();  // No allocator needed - stored internally

try list.append(42);         // No allocator parameter
try list.appendSlice(&[_]i32{1, 2, 3});
```

------

### `Managed(comptime T: type)`

**Convenience alias** for `AlignedManaged(T, null)`.

**Example:**
```zig
var list = std.array_list.Managed(i32).init(allocator);
defer list.deinit();
try list.append(100);
```

------

## Functions

All these types expose similar methods. See individual type documentation for complete API reference.

### Core Growth Functions

#### `append(allocator: Allocator, item: T) !void`

Add a single item to the end of the list. Automatically grows capacity if needed.

**Example:**
```zig
var list: std.ArrayList(i32) = .empty;
defer list.deinit(allocator);

try list.append(allocator, 42);
try list.append(allocator, 100);
std.debug.print("Length: {}\n", .{list.items.len}); // 2
```

------

#### `appendSlice(allocator: Allocator, items: []const T) !void`

Add multiple items efficiently.

**Example:**
```zig
var list: std.ArrayList(u8) = .empty;
defer list.deinit(allocator);

try list.appendSlice(allocator, "Hello");
try list.appendSlice(allocator, " World");
std.debug.print("{s}\n", .{list.items}); // "Hello World"
```

------

#### `insert(allocator: Allocator, index: usize, item: T) !void`

Insert item at specific index, shifting subsequent elements right.

**Example:**
```zig
var list: std.ArrayList(i32) = .empty;
defer list.deinit(allocator);

try list.appendSlice(allocator, &[_]i32{1, 2, 4});
try list.insert(allocator, 2, 3);  // Insert 3 at index 2
// list.items is now [1, 2, 3, 4]
```

------

### Core Removal Functions

#### `orderedRemove(index: usize) T`

Remove and return element at index, maintaining order of remaining elements.

**Performance:** O(n) - shifts all elements after index

**Example:**
```zig
var list: std.ArrayList(i32) = .empty;
defer list.deinit(allocator);

try list.appendSlice(allocator, &[_]i32{10, 20, 30, 40});
const removed = list.orderedRemove(1);  // removes 20
// list.items is now [10, 30, 40]
```

------

#### `swapRemove(index: usize) T`

Remove and return element at index by swapping with last element.

**Performance:** O(1) - no shifting needed
**Trade-off:** Doesn't preserve order

**Example:**
```zig
var list: std.ArrayList(i32) = .empty;
defer list.deinit(allocator);

try list.appendSlice(allocator, &[_]i32{10, 20, 30, 40});
const removed = list.swapRemove(1);  // removes 20
// list.items is now [10, 40, 30] - last element moved to removed position
```

------

#### `pop() ?T`

Remove and return last element, or null if list is empty.

**Example:**
```zig
var list: std.ArrayList(i32) = .empty;
defer list.deinit(allocator);

try list.append(allocator, 42);
const last = list.pop();  // Returns ?i32
if (last) |value| {
    std.debug.print("Popped: {}\n", .{value});  // 42
}
// list is now empty
```

------

### Memory Management Functions

#### `ensureTotalCapacity(allocator: Allocator, new_capacity: usize) !void`

Ensure the list can hold at least `new_capacity` items without reallocating.

**Example:**
```zig
var list: std.ArrayList(u8) = .empty;
defer list.deinit(allocator);

try list.ensureTotalCapacity(allocator, 1000);
for (0..1000) |i| {
    list.appendAssumeCapacity(@intCast(i % 256));  // No allocation
}
```

------

#### `toOwnedSlice(allocator: Allocator) ![]T`

Transfer ownership of the internal array to caller. The ArrayList is left empty but retains capacity of 0.

**Critical:** Caller must free the returned slice with `allocator.free(slice)`

**Example:**
```zig
var list: std.ArrayList(u8) = .empty;
defer list.deinit(allocator);

try list.appendSlice(allocator, "Hello");
const owned = try list.toOwnedSlice(allocator);
defer allocator.free(owned);  // ← Caller's responsibility

std.debug.print("{s}\n", .{owned});  // "Hello"
// list.items is now empty
```

------

#### `clearRetainingCapacity()`

Remove all elements but keep allocated memory for reuse.

**Example:**
```zig
var list: std.ArrayList(i32) = .empty;
defer list.deinit(allocator);

try list.ensureTotalCapacity(allocator, 100);
try list.appendSlice(allocator, &[_]i32{1, 2, 3});

const old_capacity = list.capacity;
list.clearRetainingCapacity();
// list.items.len is 0, but capacity unchanged
```

------

#### `clearAndFree(allocator: Allocator)`

Remove all elements and free allocated memory.

**Example:**
```zig
var list: std.ArrayList(i32) = .empty;
defer list.deinit(allocator);

try list.appendSlice(allocator, &[_]i32{1, 2, 3, 4, 5});
list.clearAndFree(allocator);
// list.items.len is 0 and list.capacity is 0
```

------

## Usage Patterns

### Pattern 1: String Building

```zig
const std = @import("std");

pub fn buildGreeting(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    var string: std.ArrayList(u8) = .empty;
    errdefer string.deinit(allocator);

    try string.appendSlice(allocator, "Hello, ");
    try string.appendSlice(allocator, name);
    try string.append(allocator, '!');

    return string.toOwnedSlice(allocator);
}

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    const greeting = try buildGreeting(da.allocator(), "Zig");
    defer da.allocator().free(greeting);

    std.debug.print("{s}\n", .{greeting});  // "Hello, Zig!"
}
```

**Explanation:**
1. Create empty ArrayList(u8) for building strings
2. Use `errdefer` to cleanup on error
3. Append string slices and individual characters
4. Transfer ownership with `toOwnedSlice()` - caller must free

------

### Pattern 2: Pre-allocated Buffer for Known Size

```zig
const std = @import("std");

pub fn processItems(allocator: std.mem.Allocator, count: usize) !void {
    var results: std.ArrayList(i32) = .empty;
    defer results.deinit(allocator);

    // Pre-allocate if we know the size
    try results.ensureTotalCapacity(allocator, count);

    for (0..count) |i| {
        // No allocation - we pre-sized
        results.appendAssumeCapacity(@intCast(i * 2));
    }

    std.debug.print("Processed {} items\n", .{results.items.len});
}
```

**Explanation:**
1. Pre-allocate exact capacity needed with `ensureTotalCapacity()`
2. Use `appendAssumeCapacity()` for guaranteed no-allocation appends
3. Significant performance gain when size is known upfront

------

### Pattern 3: Filtering with Managed Variant

```zig
const std = @import("std");

pub fn filterEven(allocator: std.mem.Allocator, numbers: []const i32) ![]i32 {
    // Use Managed variant to avoid passing allocator repeatedly
    var filtered = std.array_list.Managed(i32).init(allocator);
    errdefer filtered.deinit();

    for (numbers) |num| {
        if (@rem(num, 2) == 0) {
            try filtered.append(num);  // No allocator parameter needed
        }
    }

    return filtered.toOwnedSlice();  // No allocator parameter needed
}
```

**Explanation:**
When you need to call append/insert many times, `Managed` variants reduce boilerplate by storing allocator internally.

------

## Error Sets

### `Allocator.Error`
- `error.OutOfMemory` - Allocator failed to provide requested memory

All allocation functions (`append`, `insert`, `ensureTotalCapacity`, etc.) can return `Allocator.Error`.

------

## Debug Checklist

✅ **Always call `deinit(allocator)` or use `toOwnedSlice(allocator)`** - Forgetting this leaks memory

✅ **Pass allocator to deinit** - `list.deinit(allocator)` not `list.deinit()` (0.16+ API)

✅ **Pass allocator to append/insert** - `list.append(allocator, item)` not `list.append(item)`

✅ **Use `.empty` for initialization** - `var list: ArrayList(T) = .empty;` not default `{}`

✅ **Check capacity before `appendAssumeCapacity()`** - Will crash if capacity insufficient

✅ **Free slices from `toOwnedSlice()`** - Caller must `allocator.free(slice)`

✅ **Use `errdefer` for cleanup** - When building in functions that return errors

------

## Performance Tips

1. **Pre-allocate when size is known** - Use `ensureTotalCapacity()` before loops:
   ```zig
   var list: std.ArrayList(i32) = .empty;
   defer list.deinit(allocator);

   try list.ensureTotalCapacity(allocator, 1000);
   for (0..1000) |i| {
       list.appendAssumeCapacity(@intCast(i));  // 10-100x faster
   }
   ```

2. **Use `swapRemove()` when order doesn't matter** - O(1) vs O(n) for `orderedRemove()`:
   ```zig
   // If element order doesn't matter
   _ = list.swapRemove(index);  // Much faster
   ```

3. **Reuse capacity with `clearRetainingCapacity()`** - Avoid repeated allocations:
   ```zig
   var batch: std.ArrayList(i32) = .empty;
   defer batch.deinit(allocator);

   for (batches) |b| {
       batch.clearRetainingCapacity();  // Keep buffer, reset length
       try processBatch(&batch, b);
   }
   ```

4. **Use `appendSlice()` instead of loop with `append()`** - Single allocation vs multiple:
   ```zig
   // Good - single allocation
   try list.appendSlice(allocator, &[_]i32{1, 2, 3, 4, 5});

   // Bad - potentially 5 allocations
   for (&[_]i32{1, 2, 3, 4, 5}) |item| {
       try list.append(allocator, item);
   }
   ```

5. **Consider `Managed` variants for allocation-heavy code** - Reduces parameter passing overhead and makes code cleaner when you do many operations.

------

## See Also

- **std.ArrayList(T)** - Convenient type alias for `Aligned(T, null)`
- **std.MultiArrayList** - Struct-of-arrays layout for better cache locality
- **std.BoundedArray** - Fixed-capacity array without allocator
- **std.mem** - Slice manipulation utilities (concat, copy, eql)
- **std.heap** - Allocator implementations
