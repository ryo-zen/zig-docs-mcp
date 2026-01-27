# std.array_list.Aligned

## Quick Start

### Most Common Patterns

**Basic Dynamic Array**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.append(42);
try list.append(100);
std.debug.print("Items: {any}\n", .{list.items});
```

**Pre-allocated Capacity**
```zig
var list = try std.ArrayList(u8).initCapacity(allocator, 1024);
defer list.deinit();
list.appendAssumeCapacity('a');  // No allocation needed
```

**Building from Slice**
```zig
const owned_slice = try allocator.dupe(u8, "hello");
var list = std.ArrayList(u8).fromOwnedSlice(owned_slice);
defer list.deinit();
```

**Taking Ownership**
```zig
var list = std.ArrayList(u8).init(allocator);
try list.appendSlice("data");
const owned = try list.toOwnedSlice();  // Caller now owns memory
defer allocator.free(owned);
```

### Key Operations
- `append(item)` - Add single item | `appendSlice(items)` - Add multiple
- `insert(i, item)` - Insert at index | `orderedRemove(i)` - Remove at index
- `pop()` - Remove last | `clearRetainingCapacity()` - Clear but keep memory
- `ensureUnusedCapacity(n)` - Pre-allocate space

### ⚠️ Critical: Memory Management
```zig
var list = std.ArrayList(T).init(allocator);
defer list.deinit();  // ← REQUIRED! Always deinit or use toOwnedSlice
```

---

## Overview

`std.array_list.Aligned` is a contiguous, growable list of arbitrarily aligned items in memory. This is the foundation for Zig's dynamic array implementation, providing efficient resizable storage with control over memory alignment.

**Key Characteristics:**
- **Generic Type**: Parameterized over element type `T` and alignment
- **Dynamic Growth**: Automatically grows with amortized O(1) append operations
- **Direct Access**: `items` field provides direct slice access to elements
- **Manual Memory Management**: Requires explicit `deinit()` or `toOwnedSlice()`
- **Alignment Control**: Optional custom alignment (defaults to `@alignOf(T)`)

**When to use Aligned ArrayList:**
- Building dynamic collections with specific alignment requirements
- Working with SIMD types or hardware-specific aligned data
- Implementing custom data structures requiring alignment guarantees

**Common Types:**
- `std.ArrayList(T)` - Default alignment, most common use case
- `std.ArrayListAligned(T, 16)` - 16-byte aligned (SIMD operations)
- `std.ArrayListUnmanaged(T)` - Requires passing allocator to each operation

## Parameters

### `T: type`

The element type stored in the list. Can be any Zig type.

------

### `alignment: ?mem.Alignment`

The alignment requirement for the internal buffer. If `null`, defaults to `@alignOf(T)`. Use specific alignments for SIMD types or hardware requirements.

**Example:**
```zig
// Default alignment
const List1 = std.ArrayList(u32);  // Uses @alignOf(u32) = 4

// Custom alignment
const List2 = std.array_list.Aligned(u32, 16);  // 16-byte aligned
```

## Fields

### `items: Slice = &[_]T{}`

Contents of the list as a slice. **This field is intended to be accessed directly** for reading and iteration.

**Important Notes:**
- Pointers to elements may be invalidated by growth operations
- "Invalidated" means memory has been passed to allocator's resize or free function
- Direct modification of `items` is allowed but avoid changing length directly

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
try list.append(10);
try list.append(20);
for (list.items) |item| {
    std.debug.print("{}\n", .{item});
}
```

------

### `capacity: usize = 0`

How many `T` values this list can hold without allocating additional memory. Always greater than or equal to `items.len`.

**Example:**
```zig
var list = try std.ArrayList(i32).initCapacity(allocator, 100);
defer list.deinit();
std.debug.print("Capacity: {}, Length: {}\n", .{list.capacity, list.items.len});
// Output: Capacity: 100, Length: 0
```

## Nested Types

- **SentinelSlice**: Slice type with sentinel terminator
- **Slice**: Standard slice type for the elements

## Values

### `empty: Self`

An ArrayList containing no elements. Equivalent to zero-initialization but explicit.

**Example:**
```zig
var list: std.ArrayList(u8) = .empty;
// No deinit needed - no allocation yet
```

## Core Operations

These are the fundamental operations you'll use most often.

### `pub fn init(allocator: Allocator) Self`

**Not shown in original but implied** - Initialize an empty ArrayList with zero capacity.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
```

------

### `pub fn initCapacity(gpa: Allocator, num: usize) Allocator.Error!Self`

Initialize with capacity to hold exactly `num` elements. Useful when you know the approximate size to avoid multiple allocations. Deinitialize with `deinit` or `toOwnedSlice`.

**Example:**
```zig
var list = try std.ArrayList(i32).initCapacity(allocator, 1000);
defer list.deinit();
// Can append 1000 items without reallocation
```

------

### `pub fn deinit(self: *Self, gpa: Allocator) void`

Release all allocated memory. After calling this, the ArrayList is in an undefined state and should not be used.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
try list.append('a');
list.deinit();  // Must be called to free memory
```

------

### `pub fn append(self: *Self, gpa: Allocator, item: T) Allocator.Error!void`

Extend the list by 1 element. Allocates more memory as necessary using amortized growth strategy. Invalidates element pointers if additional memory is needed.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.append(42);
try list.append(100);
```

------

### `pub fn appendAssumeCapacity(self: *Self, item: T) void`

Extend the list by 1 element without checking capacity. **Asserts that capacity is sufficient**. Use after `ensureUnusedCapacity` or `ensureTotalCapacity`.

**Example:**
```zig
var list = try std.ArrayList(i32).initCapacity(allocator, 10);
defer list.deinit();
list.appendAssumeCapacity(42);  // No error check needed
```

------

### `pub fn appendSlice(self: *Self, gpa: Allocator, items: []const T) Allocator.Error!void`

Append the slice of items to the list. Allocates more memory as necessary. Invalidates element pointers if additional memory is needed.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try list.appendSlice("Hello, ");
try list.appendSlice("World!");
```

------

### `pub fn appendSliceAssumeCapacity(self: *Self, items: []const T) void`

Append the slice of items to the list without capacity checks. **Asserts that capacity is sufficient**.

------

### `pub fn pop(self: *Self) ?T`

Remove and return the last element from the list. If the list is empty, returns `null`. Invalidates pointers to last element.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.append(42);
const value = list.pop();  // Some(42)
const empty = list.pop();  // null
```

------

### `pub fn getLast(self: Self) T`

Return the last element from the list. **Asserts that the list is not empty**.

**Example:**
```zig
const last = list.getLast();
```

------

### `pub fn getLastOrNull(self: Self) ?T`

Return the last element from the list, or return `null` if list is empty.

## Capacity Management Functions

### `pub fn ensureUnusedCapacity(self: *Self, gpa: Allocator, additional_count: usize) Allocator.Error!void`

Modify the array so that it can hold at least `additional_count` **more** items beyond current length. Invalidates element pointers if additional memory is needed.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try list.ensureUnusedCapacity(100);
// Can now append 100 items without reallocation
for (0..100) |_| {
    list.appendAssumeCapacity('x');
}
```

------

### `pub fn ensureTotalCapacity(self: *Self, gpa: Allocator, new_capacity: usize) Allocator.Error!void`

Modify the array so that it can hold at least `new_capacity` items total. Implements super-linear growth to achieve amortized O(1) append operations. Invalidates element pointers if additional memory is needed.

------

### `pub fn ensureTotalCapacityPrecise(self: *Self, gpa: Allocator, new_capacity: usize) Allocator.Error!void`

If the current capacity is less than `new_capacity`, this function will modify the array so that it can hold **exactly** `new_capacity` items (no over-allocation). Invalidates element pointers if additional memory is needed.

------

### `pub fn clearRetainingCapacity(self: *Self) void`

Reduce length to 0 while keeping allocated capacity. Invalidates all element pointers. Useful for reusing the allocation.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try list.appendSlice("temporary");
list.clearRetainingCapacity();  // Length is 0, capacity unchanged
try list.appendSlice("reused");
```

------

### `pub fn clearAndFree(self: *Self, gpa: Allocator) void`

Reset length to 0 and free all allocated memory. Invalidates all element pointers. Equivalent to `deinit` followed by `init`.

------

### `pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void`

Reduce length to `new_len`. Invalidates pointers to elements `items[new_len..]`. Keeps capacity the same. **Asserts that the new length is less than or equal to the previous length**.

------

### `pub fn shrinkAndFree(self: *Self, gpa: Allocator, new_len: usize) void`

Reduce allocated capacity to `new_len`. May invalidate element pointers. **Asserts that the new length is less than or equal to the previous length**.

------

### `pub fn expandToCapacity(self: *Self) void`

Increases the array's length to match the full capacity that is already allocated. The new elements have `undefined` values. Never invalidates element pointers.

------

### `pub fn unusedCapacitySlice(self: Self) []T`

Returns a slice of only the extra capacity after items. This can be useful for writing directly into an ArrayList. **Note that such an operation must be followed up with a direct modification of `self.items.len`**.

**Example:**
```zig
var list = try std.ArrayList(u8).initCapacity(allocator, 100);
const unused = list.unusedCapacitySlice();
const bytes_written = try file.read(unused);
list.items.len += bytes_written;
```

------

### `pub fn allocatedSlice(self: Self) Slice`

Returns a slice of all the items plus the extra capacity, whose memory contents are `undefined`.

## Insertion Functions

### `pub fn insert(self: *Self, gpa: Allocator, i: usize, item: T) Allocator.Error!void`

Insert `item` at index `i`. Moves `list[i .. list.len]` to higher indices to make room. If `i` is equal to the length of the list this operation is equivalent to append. **This operation is O(N)**. Invalidates element pointers if additional memory is needed. **Asserts that the index is in bounds or equal to the length**.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.append(10);
try list.append(30);
try list.insert(1, 20);  // [10, 20, 30]
```

------

### `pub fn insertAssumeCapacity(self: *Self, i: usize, item: T) void`

Insert `item` at index `i`. Moves `list[i .. list.len]` to higher indices to make room. **Asserts that capacity is sufficient**.

------

### `pub fn insertSlice(self: *Self, gpa: Allocator, index: usize, items: []const T) Allocator.Error!void`

Insert slice `items` at index `i` by moving `list[i .. list.len]` to make room. **This operation is O(N)**. Invalidates pre-existing pointers to elements at and after `index`. Invalidates all pre-existing element pointers if capacity must be increased to accommodate the new elements. **Asserts that the index is in bounds or equal to the length**.

------

### `pub fn insertSliceAssumeCapacity(self: *Self, index: usize, items: []const T) void`

Insert slice `items` at index `i` by moving `list[i .. list.len]` to make room. **This operation is O(N)**. Invalidates pre-existing pointers to elements at and after `index`. **Asserts that the list has capacity for the additional items**. **Asserts that the index is in bounds or equal to the length**.

------

### `pub fn addManyAt(self: *Self, gpa: Allocator, index: usize, count: usize) Allocator.Error![]T`

Add `count` new elements at position `index`, which have `undefined` values. Returns a slice pointing to the newly allocated elements, which becomes invalid after various `ArrayList` operations. Invalidates pre-existing pointers to elements at and after `index`. Invalidates all pre-existing element pointers if capacity must be increased to accommodate the new elements. **Asserts that the index is in bounds or equal to the length**.

------

### `pub fn addManyAtAssumeCapacity(self: *Self, index: usize, count: usize) []T`

Add `count` new elements at position `index`, which have `undefined` values. Returns a slice pointing to the newly allocated elements, which becomes invalid after various `ArrayList` operations. Invalidates pre-existing pointers to elements at and after `index`, but does not invalidate any before that. **Asserts that the list has capacity for the additional items**. **Asserts that the index is in bounds or equal to the length**.

## Removal Functions

### `pub fn orderedRemove(self: *Self, i: usize) T`

Remove the element at index `i` from the list and return its value. Shifts all elements after `i` down by one index to maintain order. Invalidates pointers to the last element. **This operation is O(N)**. **Asserts that the index is in bounds**.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.appendSlice(&[_]i32{10, 20, 30, 40});
const removed = list.orderedRemove(1);  // 20
// list.items is now [10, 30, 40]
```

------

### `pub fn swapRemove(self: *Self, i: usize) T`

Removes the element at the specified index and returns it. The empty slot is filled from the end of the list, **changing element order**. Invalidates pointers to last element. **This operation is O(1)**. **Asserts that the index is in bounds**.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.appendSlice(&[_]i32{10, 20, 30, 40});
const removed = list.swapRemove(1);  // 20
// list.items is now [10, 40, 30] (40 moved to index 1)
```

------

### `pub fn orderedRemoveMany(self: *Self, sorted_indexes: []const usize) void`

Remove the elements indexed by `sorted_indexes`. The indexes to be removed correspond to the array list **before deletion**. The `sorted_indexes` slice must be sorted in ascending order.

## Adding Multiple Elements

### `pub fn addOne(self: *Self, gpa: Allocator) Allocator.Error!*T`

Increase length by 1, returning pointer to the new item with `undefined` value. The returned element pointer becomes invalid when the list is resized.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
const ptr = try list.addOne();
ptr.* = 42;
```

------

### `pub fn addOneAssumeCapacity(self: *Self) *T`

Increase length by 1, returning pointer to the new item. **Asserts that capacity is sufficient**.

------

### `pub fn addManyAsSlice(self: *Self, gpa: Allocator, n: usize) Allocator.Error![]T`

Resize the array, adding `n` new elements, which have `undefined` values. The return value is a slice pointing to the newly allocated elements. The returned pointer becomes invalid when the list is resized. Resizes list if `self.capacity` is not large enough.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
const slice = try list.addManyAsSlice(10);
@memset(slice, 'x');
```

------

### `pub fn addManyAsSliceAssumeCapacity(self: *Self, n: usize) []T`

Resizes the array, adding `n` new elements, which have `undefined` values, returning a slice pointing to the newly allocated elements. **Asserts that capacity is sufficient**.

------

### `pub fn addManyAsArray(self: *Self, gpa: Allocator, comptime n: usize) Allocator.Error!*[n]T`

Resize the array, adding `n` new elements, which have `undefined` values. The return value is an array pointer to the newly allocated elements. The returned pointer becomes invalid when the list is resized.

------

### `pub fn addManyAsArrayAssumeCapacity(self: *Self, comptime n: usize) *[n]T`

Resize the array, adding `n` new elements, which have `undefined` values. **Asserts that capacity is sufficient**.

------

### `pub inline fn appendNTimes(self: *Self, gpa: Allocator, value: T, n: usize) Allocator.Error!void`

Append a value to the list `n` times. Allocates more memory as necessary. Invalidates element pointers if additional memory is needed. The function is inline so that a comptime-known `value` parameter will have a more optimal memset codegen in case it has a repeated byte pattern.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try list.appendNTimes('-', 80);  // Add 80 dashes
```

------

### `pub inline fn appendNTimesAssumeCapacity(self: *Self, value: T, n: usize) void`

Append a value to the list `n` times. **Asserts that capacity is sufficient**.

## Unaligned Slice Operations

### `pub fn appendUnalignedSlice(self: *Self, gpa: Allocator, items: []align(1) const T) Allocator.Error!void`

Append the slice of items to the list. Allocates more memory as necessary. **Only call this function if a call to `appendSlice` instead would be a compile error** due to alignment mismatch. Invalidates element pointers if additional memory is needed.

------

### `pub fn appendUnalignedSliceAssumeCapacity(self: *Self, items: []align(1) const T) void`

Append an unaligned slice of items to the list. **Asserts that capacity is sufficient**.

## Range Modification Functions

### `pub fn replaceRange(self: *Self, gpa: Allocator, start: usize, len: usize, new_items: []const T) Allocator.Error!void`

Replace `len` elements starting at `start` with `new_items`. Grows or shrinks the list as necessary. Invalidates element pointers if additional capacity is allocated. **Asserts that the range is in bounds**.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try list.appendSlice("Hello, World!");
try list.replaceRange(7, 6, "Zig!");
// list.items is now "Hello, Zig!"
```

------

### `pub fn replaceRangeAssumeCapacity(self: *Self, start: usize, len: usize, new_items: []const T) void`

Grows or shrinks the list as necessary. **Asserts that capacity is sufficient if growing**.

------

### `pub fn resize(self: *Self, gpa: Allocator, new_len: usize) Allocator.Error!void`

Adjust the list length to `new_len`. Additional elements contain the value `undefined`. Invalidates element pointers if additional memory is needed.

**Example:**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.resize(100);  // list.items.len is now 100
```

## Memory Transfer Functions

### `pub fn toOwnedSlice(self: *Self, gpa: Allocator) Allocator.Error!Slice`

The caller owns the returned memory and must free it with `allocator.free()`. Empties this ArrayList. Its capacity is cleared, making `deinit()` safe but unnecessary to call.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
try list.appendSlice("transfer ownership");
const owned = try list.toOwnedSlice();
defer allocator.free(owned);
// list is now empty and can be reused or ignored
```

------

### `pub fn toOwnedSliceSentinel(self: *Self, gpa: Allocator, comptime sentinel: T) Allocator.Error!SentinelSlice(sentinel)`

The caller owns the returned memory. ArrayList becomes empty. The returned slice includes a sentinel terminator.

------

### `pub fn fromOwnedSlice(slice: Slice) Self`

ArrayList takes ownership of the passed in slice. The slice's memory becomes the ArrayList's internal buffer. Deinitialize with `deinit` or use `toOwnedSlice`.

**Example:**
```zig
const owned_memory = try allocator.alloc(u8, 100);
@memcpy(owned_memory[0..5], "hello");
var list = std.ArrayList(u8).fromOwnedSlice(owned_memory[0..5]);
defer list.deinit();
```

------

### `pub fn fromOwnedSliceSentinel(comptime sentinel: T, slice: [:sentinel]T) Self`

ArrayList takes ownership of the passed in sentinel-terminated slice. Deinitialize with `deinit` or use `toOwnedSlice`.

------

### `pub fn clone(self: Self, gpa: Allocator) Allocator.Error!Self`

Creates a complete copy of this ArrayList with independent memory allocation.

**Example:**
```zig
var original = std.ArrayList(i32).init(allocator);
defer original.deinit();
try original.append(42);

var copy = try original.clone();
defer copy.deinit();
// Modifications to copy don't affect original
```

## Initialization Functions

### `pub fn initBuffer(buffer: Slice) Self`

Initialize with externally-managed memory. The buffer determines the capacity, and the length is set to zero. **Do not call `deinit()` on this ArrayList** - the buffer is not owned by the ArrayList.

**Example:**
```zig
var buffer: [100]u8 = undefined;
var list = std.ArrayList(u8).initBuffer(&buffer);
list.appendAssumeCapacity('a');
// No deinit needed - buffer is stack-allocated
```

## Conversion Functions

### `pub fn toManaged(self: *Self, gpa: Allocator) AlignedManaged(T, alignment)`

Convert this list into an analogous memory-managed one. The returned list has ownership of the underlying memory.

## Bounded Variants

Several functions have "Bounded" variants that return `error.OutOfMemory` if the operation would require more capacity than currently available, without attempting to allocate:

- `appendBounded`
- `appendSliceBounded`
- `appendNTimesBounded`
- `appendUnalignedSliceBounded`
- `insertBounded`
- `insertSliceBounded`
- `addOneBounded`
- `addManyAsSliceBounded`
- `addManyAsArrayBounded`
- `addManyAtBounded`
- `replaceRangeBounded`

These are useful when you want to work within a fixed memory budget without growing.

## Print Functions

### `pub fn print(self: *Self, gpa: Allocator, comptime fmt: []const u8, args: anytype) error{OutOfMemory}!void`

Format and append text to the ArrayList using `std.fmt` format strings. Similar to `std.fmt.format` but appends to the list.

**Example:**
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
try list.print("Value: {d}, Hex: 0x{x}\n", .{42, 255});
```

------

### `pub fn printAssumeCapacity(self: *Self, comptime fmt: []const u8, args: anytype) void`

Format and append text without capacity checks. **Asserts that capacity is sufficient**.

------

### `pub fn printBounded(self: *Self, comptime fmt: []const u8, args: anytype) error{OutOfMemory}!void`

Format and append text, returning error if insufficient capacity without growing.

## Static Utility Functions

### `pub fn growCapacity(minimum: usize) usize`

Called when memory growth is necessary. Returns a capacity larger than `minimum` that grows super-linearly. This is the growth strategy that ensures amortized O(1) append operations.

## Debug Checklist

If your code doesn't compile, check:

1. ✅ Did you call `deinit()` or `toOwnedSlice()` to clean up memory?
2. ✅ Are you using the right allocator type? (`std.mem.Allocator`)
3. ✅ Did you handle `Allocator.Error` in functions that may allocate?
4. ✅ Are you using `AssumeCapacity` variants after ensuring capacity?
5. ✅ Did you initialize with `.init(allocator)` or `.empty`?
6. ✅ Are indices in bounds for operations like `insert` and `remove`?
7. ✅ Are you avoiding use-after-free by not holding pointers across resize operations?

## Performance Tips

1. **Pre-allocate when size is known**: Use `initCapacity` or `ensureTotalCapacity` to avoid multiple allocations
2. **Use `AssumeCapacity` variants in hot loops**: After ensuring capacity once, use faster non-checking variants
3. **Prefer `swapRemove` over `orderedRemove`**: O(1) vs O(N) when order doesn't matter
4. **Reuse allocations with `clearRetainingCapacity`**: Avoid repeated alloc/free cycles
5. **Use `appendSlice` instead of multiple `append`**: Single capacity check instead of multiple
6. **Batch operations**: Call `ensureUnusedCapacity` once, then use multiple `AssumeCapacity` operations
7. **Consider `ArrayListUnmanaged`**: Slightly more efficient if you're passing allocator around anyway

## Common Patterns

### Building a String
```zig
var string = std.ArrayList(u8).init(allocator);
defer string.deinit();
try string.appendSlice("Hello, ");
try string.print("{s}!", .{"World"});
std.debug.print("{s}\n", .{string.items});
```

### Fixed-Size Buffer
```zig
var buffer: [1024]u8 = undefined;
var list = std.ArrayList(u8).initBuffer(&buffer);
// Use without deinit - buffer is stack-allocated
```

### Efficient Batch Append
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.ensureUnusedCapacity(1000);
for (0..1000) |i| {
    list.appendAssumeCapacity(@intCast(i));
}
```

### Reading into ArrayList
```zig
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
while (true) {
    const byte_ptr = try list.addOne();
    byte_ptr.* = try reader.readByte();
    if (byte_ptr.* == '\n') break;
}
```

## Example Files

The following runnable examples demonstrate all major ArrayList features:

### Basic Operations

**[test_arraylist_aligned_basic.zig](../../Examples/test_arraylist_aligned_basic.zig)**
- Basic ArrayList initialization and usage
- Appending items
- Accessing items directly via `.items`
- Checking length and capacity

### Capacity Management

**[test_arraylist_aligned_capacity.zig](../../Examples/test_arraylist_aligned_capacity.zig)**
- Pre-allocating capacity with `initCapacity`
- Using `ensureUnusedCapacity` for batch operations
- `AssumeCapacity` variants for guaranteed capacity
- Avoiding reallocations for performance

### Insertion Operations

**[test_arraylist_aligned_insertion.zig](../../Examples/test_arraylist_aligned_insertion.zig)**
- Inserting single items at specific indices
- Inserting slices with `insertSlice`
- Using `addManyAt` to insert multiple undefined elements
- Understanding insertion complexity (O(N))

### Removal Operations

**[test_arraylist_aligned_removal.zig](../../Examples/test_arraylist_aligned_removal.zig)**
- Popping last element with `pop()`
- Maintaining order with `orderedRemove` (O(N))
- Fast removal with `swapRemove` (O(1))
- Getting last element without removing

### Memory Management

**[test_arraylist_aligned_memory.zig](../../Examples/test_arraylist_aligned_memory.zig)**
- Transferring ownership with `toOwnedSlice`
- Creating independent copies with `clone`
- Transfer ownership back and forth between slice and ArrayList
- Understanding when to use `deinit()` vs `toOwnedSlice()`

### String Building

**[test_arraylist_aligned_string_builder.zig](../../Examples/test_arraylist_aligned_string_builder.zig)**
- Using ArrayList as a string builder
- Formatted output with `print()`
- Building complex strings dynamically
- Converting to owned slice for return values

### SIMD and Alignment

**[test_arraylist_aligned_simd.zig](../../Examples/test_arraylist_aligned_simd.zig)**
- Working with SIMD vector types
- Understanding alignment guarantees
- Processing aligned data efficiently
- Checking alignment at runtime

### Stack-Allocated Buffers

**[test_arraylist_aligned_buffer.zig](../../Examples/test_arraylist_aligned_buffer.zig)**
- Using `initBuffer` with stack-allocated memory
- Avoiding heap allocations for temporary data
- Understanding when NOT to call `deinit()`
- Reusing buffers efficiently

### Performance Patterns

**[test_arraylist_aligned_performance.zig](../../Examples/test_arraylist_aligned_performance.zig)**
- Pre-allocating capacity to avoid reallocations
- Using `AssumeCapacity` variants in hot loops
- Comparing `swapRemove` vs `orderedRemove`
- Reusing allocations with `clearRetainingCapacity`

### Range Modifications

**[test_arraylist_aligned_replaceRange.zig](../../Examples/test_arraylist_aligned_replaceRange.zig)**
- Replacing ranges of elements
- Growing and shrinking with `replaceRange`
- Using `resize` to change length
- Expanding and filling with new data

## See Also

- `std.ArrayList(T)` - Default-aligned ArrayList (most common)
- `std.ArrayListUnmanaged(T)` - Unmanaged variant requiring allocator per call
- `std.ArrayListAligned(T, alignment)` - Convenient type alias
- `std.MultiArrayList(T)` - Structure-of-arrays layout for better cache performance
- `std.BoundedArray(T, capacity)` - Fixed-capacity array without allocator
- `std.mem.Allocator` - Memory allocator interface
