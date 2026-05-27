# std.mem.Allocator

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.Allocator.tests.zig)**

## Overview

`Allocator` is the standard memory allocation interface in Zig. It provides a unified, type-erased interface for requesting and releasing memory, enabling code to be generic over different allocation strategies.

Zig's allocator design is intentional — instead of a hidden global allocator (like `malloc` in C), allocators are passed explicitly. This makes memory allocation:
- **Visible**: Every allocation site is obvious in the code
- **Testable**: Swap in a testing allocator to detect leaks and invalid frees
- **Configurable**: Choose the right allocator for each use case (arena, page, general purpose)
- **Composable**: Wrap allocators with validation, logging, or other behaviors

**Common allocators**:
- `std.heap.page_allocator` — Allocates directly from the OS (slow, page-granular)
- `std.heap.DebugAllocator` — General-purpose debugging allocator with safety checks
- `std.testing.allocator` — Test allocator that detects memory leaks
- `std.heap.ArenaAllocator` — Bulk-free allocator (free everything at once)
- `std.heap.FixedBufferAllocator` — Allocates from a fixed buffer (no OS calls)

## Fields

`ptr: *anyopaque`

The type-erased pointer to the allocator implementation. This holds the allocator's internal state.

**Warning**: Any comparison of this field may result in illegal behavior, since it may be set to `undefined` in cases where the allocator implementation does not have any associated state.

------

`vtable: *const VTable`

Pointer to the virtual function table containing the actual allocation/deallocation function pointers. This enables the type-erased interface.

## Types

- **Log2Align** — Type representing alignment as a log2 value
- **VTable** — The virtual function table struct containing `alloc`, `resize`, `remap`, and `free` function pointers

## Values

|         |             |                                             |
|---------|-------------|---------------------------------------------|
| failing | `Allocator` | An allocator that always fails to allocate. Useful for testing error paths. |

## Functions

### Core Allocation

#### `pub fn alloc(self: Allocator, comptime T: type, n: usize) Error![]T`

Allocates an array of `n` items of type `T`. All items are set to `undefined`.

**Returns**: A slice of `n` elements, or `Error` on failure.

**Caller must**: Call `free()` when the memory is no longer needed.

**Example**:
```zig
const allocator = std.testing.allocator;
const buf = try allocator.alloc(u8, 100);
defer allocator.free(buf);
```

------

#### `pub fn alignedAlloc(self: Allocator, comptime T: type, comptime alignment: ?Alignment, n: usize) Error![]align(...) T`

Allocates an array of `n` items with a specific alignment. If `alignment` is `null`, uses the natural alignment of `T`.

**Use when**: You need memory aligned to a specific boundary (e.g., SIMD operations, hardware interfaces).

------

#### `pub fn allocSentinel(self: Allocator, comptime Elem: type, n: usize, comptime sentinel: Elem) Error![:sentinel]Elem`

Allocates `n + 1` elements, setting the first `n` to `undefined` and the last to `sentinel`.

**Use when**: You need null-terminated or sentinel-terminated buffers (e.g., passing strings to C APIs).

**Example**:
```zig
const allocator = std.testing.allocator;
const str = try allocator.allocSentinel(u8, 5, 0);
defer allocator.free(str);
// str has length 5 with a null terminator at str[5]
```

------

#### `pub fn allocWithOptions(self: Allocator, comptime Elem: type, n: usize, comptime optional_alignment: ?Alignment, comptime optional_sentinel: ?Elem) Error!...`

Combines alignment and sentinel options in a single call.

------

### Single Item Allocation

#### `pub fn create(a: Allocator, comptime T: type) Error!*T`

Allocates and returns a pointer to a single item of type `T`, set to `undefined`.

**Returns**: `*T` pointer to the allocated item.

**Caller must**: Call `destroy()` to free.

**Example**:
```zig
const allocator = std.testing.allocator;
const node = try allocator.create(Node);
defer allocator.destroy(node);
node.* = .{ .data = 42, .next = null };
```

------

#### `pub fn destroy(self: Allocator, ptr: anytype) void`

Frees a single item allocated with `create()`.

**`ptr`** should be the return value of `create()`, or otherwise have the same address and alignment.

------

### Reallocation

#### `pub fn realloc(self: Allocator, old_mem: anytype, new_n: usize) Error![]T`

Requests a new size for an existing allocation. Can grow or shrink. May relocate the memory.

**Returns**: A new slice of `new_n` elements. The old slice is invalidated.

**Example**:
```zig
var buf = try allocator.alloc(u8, 10);
buf = try allocator.realloc(buf, 20); // grow
defer allocator.free(buf);
```

------

#### `pub fn resize(self: Allocator, allocation: anytype, new_len: usize) bool`

Attempts to resize an allocation in-place without relocation. Returns `true` if successful.

**Use when**: You want to try resizing without the cost of copying, and can handle failure.

**Example**:
```zig
var buf = try allocator.alloc(u8, 10);
if (allocator.resize(buf, 20)) {
    buf = buf.ptr[0..20];
} else {
    buf = try allocator.realloc(buf, 20);
}
defer allocator.free(buf);
```

------

#### `pub fn remap(self: Allocator, allocation: anytype, new_len: usize) ?[]T`

Requests to modify the size of an allocation, allowing relocation. Returns `null` if the operation is not supported or fails.

**Difference from `realloc`**: `remap` returns an optional instead of an error, and may be cheaper than `realloc` when supported.

------

### Deallocation

#### `pub fn free(self: Allocator, memory: anytype) void`

Frees an array allocated with `alloc()`, `realloc()`, or similar. If memory has length 0, free is a no-op.

**To free a single item**, use `destroy()` instead.

------

### Duplication

#### `pub fn dupe(allocator: Allocator, comptime T: type, m: []const T) Error![]T`

Copies a slice to newly allocated memory. Caller owns the returned memory.

**Example**:
```zig
const original = "hello";
const copy = try allocator.dupe(u8, original);
defer allocator.free(copy);
```

------

#### `pub fn dupeZ(allocator: Allocator, comptime T: type, m: []const T) Error![:0]T`

Copies a slice to newly allocated memory with a null terminator appended. Caller owns the returned memory.

**Use when**: You need to pass a Zig string slice to a C API expecting a null-terminated string.

**Example**:
```zig
const name = "hello";
const c_name = try allocator.dupeZ(u8, name);
defer allocator.free(c_name);
// c_name can be passed to C functions expecting [*:0]const u8
```

------

### Low-Level Interface

These functions are intended for allocator implementors, not typical users:

#### `pub fn rawAlloc(a: Allocator, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8`

Raw allocation function. Not intended for direct use — use `alloc()` instead.

#### `pub fn rawFree(a: Allocator, memory: []u8, alignment: Alignment, ret_addr: usize) void`

Raw deallocation function. Not intended for direct use — use `free()` instead.

#### `pub fn rawRemap(a: Allocator, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8`

Raw remap function. Not intended for direct use.

#### `pub fn rawResize(a: Allocator, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool`

Raw resize function. Not intended for direct use.

------

### No-Op Implementations

Used internally when building allocator vtables:

- `noAlloc` — Always returns `null`
- `noFree` — No-op free
- `noRemap` — Always returns `null`
- `noResize` — Always returns `false`

## Error Sets

- **Error** — `OutOfMemory` — The single error returned when allocation fails.

## Usage Examples

### Basic Allocation Pattern

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

    // Allocate a buffer
    const buf = try allocator.alloc(u8, 256);
    defer allocator.free(buf);

    // Use the buffer...
    @memset(buf, 0);
}
```

### Arena Allocator (Bulk Free)

```zig
const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // Frees everything at once

    const allocator = arena.allocator();

    // No need to free individual allocations
    const a = try allocator.alloc(u8, 100);
    const b = try allocator.alloc(u32, 50);
    _ = a;
    _ = b;
    // All freed when arena.deinit() is called
}
```

### Testing with Leak Detection

```zig
const std = @import("std");

test "no memory leaks" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(u8, 42);
    defer allocator.free(data);

    // If we forget `defer allocator.free(data)`, the test will fail
    // with a memory leak report
}
```

### Passing Allocators to Functions

```zig
fn buildString(allocator: std.mem.Allocator, parts: []const []const u8) ![]u8 {
    return std.mem.join(allocator, " ", parts);
}

test "allocator passing" {
    const allocator = std.testing.allocator;
    const result = try buildString(allocator, &.{ "hello", "world" });
    defer allocator.free(result);

    try std.testing.expectEqualStrings("hello world", result);
}
```

## Design Notes

- **No global allocator**: Zig does not have a default global allocator. You must always choose and pass one explicitly.
- **Error handling**: All allocation functions return errors that must be handled, making out-of-memory a recoverable condition.
- **Type safety**: The generic `alloc`/`free` functions work with typed slices, preventing byte-level mistakes common in C.
- **Composability**: Allocators can wrap other allocators (e.g., `ArenaAllocator` wraps any backing allocator, `ValidationAllocator` adds safety checks).

## See Also

- [std.mem.ValidationAllocator](std.mem.ValidationAllocator.md) - Allocator wrapper with validation checks
- [std.mem.Alignment](std.mem.Alignment.md) - Alignment type used by allocator functions
