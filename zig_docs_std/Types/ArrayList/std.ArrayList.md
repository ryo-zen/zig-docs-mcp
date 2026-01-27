# std.ArrayList

## Quick Start

### Most Common Patterns

**Basic Dynamic Array**
```zig
var list: std.ArrayList(i32) = .{};
defer list.deinit(allocator);
try list.append(allocator, 42);
try list.append(allocator, 100);
std.debug.print("Items: {any}\n", .{list.items});
```

**Pre-allocated Capacity**
```zig
var list = try std.ArrayList(u8).initCapacity(allocator, 1024);
defer list.deinit(allocator);
list.appendAssumeCapacity('a');  // No allocation needed
```

**String Building**
```zig
var string: std.ArrayList(u8) = .{};
defer string.deinit(allocator);
try string.appendSlice(allocator, "Hello, ");
try string.print(allocator, "{s}!", .{"World"});
```

### Key Operations
- `append(allocator, item)` - Add single item
- `appendSlice(allocator, items)` - Add multiple
- `insert(allocator, i, item)` - Insert at index
- `orderedRemove(i)` - Remove at index (maintains order)
- `pop()` - Remove and return last
- `toOwnedSlice(allocator)` - Transfer ownership

### ⚠️ Critical: Memory Management
```zig
var list: std.ArrayList(T) = .{};
defer list.deinit(allocator);  // ← REQUIRED! Always deinit or use toOwnedSlice
```

---

## Overview

`std.ArrayList(T)` is Zig's most commonly used dynamic array type. It is a **type alias** for `array_list.Aligned(T, null)`, which means it uses the default alignment for type `T`.

**Key Characteristics:**
- **Generic Type**: Parameterized over element type `T`
- **Default Alignment**: Uses `@alignOf(T)` automatically
- **Dynamic Growth**: Automatically grows with amortized O(1) append operations
- **Direct Access**: `items` field provides direct slice access to elements
- **Manual Memory Management**: Requires explicit `deinit()` or `toOwnedSlice()`

**When to use ArrayList:**
- General-purpose dynamic arrays (most common use case)
- Building strings dynamically
- Collections where you don't need custom alignment
- When you want the simplest, most straightforward API

**Type Relationships:**
```zig
pub fn ArrayList(comptime T: type) type {
    return array_list.Aligned(T, null);
}
```

This means `std.ArrayList(i32)` is equivalent to `std.array_list.Aligned(i32, null)`.

## Parameters

### `T: type`

The element type stored in the list. Can be any Zig type.

**Examples:**
```zig
std.ArrayList(u8)      // Byte array / string builder
std.ArrayList(i32)     // Integer list
std.ArrayList(MyStruct) // Custom struct list
```

## Complete Documentation

Since `std.ArrayList(T)` is an alias for `array_list.Aligned(T, null)`, all functions, fields, and behavior are documented in:

📚 **[std.array_list.Aligned Documentation](./std.array_list.Aligned.md)** - Complete API reference with all functions, examples, and usage patterns

## Common Use Cases

### Building Strings

The most common use of `ArrayList(u8)` is as a string builder:

```zig
var string: std.ArrayList(u8) = .{};
defer string.deinit(allocator);

try string.appendSlice(allocator, "Hello, ");
try string.print(allocator, "{}!", .{"World"});
try string.print(allocator, " Count: {d}", .{42});

const result = string.items;  // Access as slice
```

### Dynamic Collections

```zig
var numbers: std.ArrayList(i32) = .{};
defer numbers.deinit(allocator);

for (0..10) |i| {
    try numbers.append(allocator, @intCast(i * i));
}

// Access via slice
for (numbers.items) |num| {
    std.debug.print("{} ", .{num});
}
```

### Building and Returning Slices

```zig
fn buildMessage(allocator: std.mem.Allocator, name: []const u8) ![]const u8 {
    var msg: std.ArrayList(u8) = .{};
    try msg.print(allocator, "Hello, {s}!", .{name});
    return msg.toOwnedSlice(allocator);  // Caller owns the memory
}

// Usage
const message = try buildMessage(allocator, "Zig");
defer allocator.free(message);
```

## Zig 0.16 API Changes

If you're migrating from earlier versions:

### Initialization
```zig
// Old (pre-0.16)
var list = std.ArrayList(T).init(allocator);

// New (0.16+)
var list: std.ArrayList(T) = .{};
```

### Function Calls
```zig
// Old (pre-0.16)
try list.append(item);
list.deinit();

// New (0.16+)
try list.append(allocator, item);
list.deinit(allocator);
```

### Key Changes
- Allocator is now passed to each function rather than stored in the struct
- Empty initialization uses `.{}` instead of `.init(allocator)`
- All allocating functions now require `allocator` parameter
- `deinit()` requires the allocator parameter

## Performance Tips

1. **Pre-allocate when size is known**: Use `initCapacity` to avoid reallocations
2. **Use `AssumeCapacity` after pre-allocation**: Skip error handling in tight loops
3. **Prefer `swapRemove` over `orderedRemove`**: O(1) vs O(N) when order doesn't matter
4. **Reuse with `clearRetainingCapacity`**: Avoid repeated alloc/free cycles
5. **Batch operations**: Call `ensureUnusedCapacity` once, then multiple `AssumeCapacity` calls

## Example Files

The following runnable examples demonstrate ArrayList features (all examples work with both `std.ArrayList` and `std.array_list.Aligned`):

### Basic Operations
**[test_arraylist_aligned_basic.zig](../../Examples/test_arraylist_aligned_basic.zig)** - Initialization, appending, accessing items

### Capacity Management
**[test_arraylist_aligned_capacity.zig](../../Examples/test_arraylist_aligned_capacity.zig)** - Pre-allocation and `AssumeCapacity` variants

### Insertion & Removal
**[test_arraylist_aligned_insertion.zig](../../Examples/test_arraylist_aligned_insertion.zig)** - Insert operations
**[test_arraylist_aligned_removal.zig](../../Examples/test_arraylist_aligned_removal.zig)** - Pop, orderedRemove, swapRemove

### Memory Management
**[test_arraylist_aligned_memory.zig](../../Examples/test_arraylist_aligned_memory.zig)** - toOwnedSlice, clone, ownership transfer

### Advanced Usage
**[test_arraylist_aligned_string_builder.zig](../../Examples/test_arraylist_aligned_string_builder.zig)** - String building with print()
**[test_arraylist_aligned_buffer.zig](../../Examples/test_arraylist_aligned_buffer.zig)** - Stack-allocated buffers
**[test_arraylist_aligned_performance.zig](../../Examples/test_arraylist_aligned_performance.zig)** - Performance optimization patterns
**[test_arraylist_aligned_replaceRange.zig](../../Examples/test_arraylist_aligned_replaceRange.zig)** - Range modifications

## See Also

- **[std.array_list.Aligned](./std.array_list.Aligned.md)** - Full API documentation (all functions)
- `std.ArrayListUnmanaged(T)` - Unmanaged variant requiring allocator per call
- `std.MultiArrayList(T)` - Structure-of-arrays layout for better cache performance
- `std.BoundedArray(T, capacity)` - Fixed-capacity array without allocator
- `std.mem.Allocator` - Memory allocator interface
