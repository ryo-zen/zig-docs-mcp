# std.mem.ValidationAllocator

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.ValidationAllocator.tests.zig)**

## Overview

`ValidationAllocator` is a wrapper allocator that adds runtime safety checks to detect violations of the `std.mem.Allocator` interface contract. It wraps any underlying allocator and validates all allocation operations, asserting on incorrect usage patterns.

This allocator is primarily useful during development and testing to catch:
- **Double frees**: Attempting to free the same memory twice
- **Invalid frees**: Freeing memory that was never allocated
- **Alignment violations**: Requesting allocations with invalid alignment
- **Buffer mismatches**: Freeing memory with incorrect size or alignment parameters

**When to use**:
- Debug builds to catch allocator misuse early
- Testing code that does complex memory management
- Validating custom allocator implementations

**Performance impact**: Adds overhead to every allocation operation. Typically disabled in release builds.

## Parameters

`T: type`

The type of the underlying allocator to wrap. Must implement the `std.mem.Allocator` interface.

## Fields

`underlying_allocator: T`

The wrapped allocator that performs the actual memory operations. All validated requests are forwarded to this allocator.

## Functions

### Initialization

`pub fn init(underlying_allocator: T) @This()`

Creates a new `ValidationAllocator` wrapping the provided allocator.

**Example**:
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var validating = std.mem.ValidationAllocator.init(gpa.allocator());
const allocator = validating.allocator();
```

**Returns**: A configured `ValidationAllocator` instance ready for use.

------

`pub fn allocator(self: *Self) Allocator`

Returns the `std.mem.Allocator` interface for this validation allocator.

**Use when**: You need to pass the allocator to functions expecting `std.mem.Allocator`.

**Returns**: An `Allocator` instance that performs validation on all operations.

------

`pub fn reset(self: *Self) void`

Resets the validation state, clearing any tracked allocations. Call this between test cases when reusing the same allocator instance.

**Warning**: Only call this when you're certain all allocated memory has been properly freed. This doesn't free memory, it only clears validation tracking.

### Low-Level Allocator Interface

These functions implement the `std.mem.Allocator` interface and are not typically called directly. Use the high-level `allocator()` methods instead.

------

`pub fn alloc(ctx: *anyopaque, n: usize, alignment: mem.Alignment, ret_addr: usize) ?[*]u8`

Validates and performs an allocation request.

**Validation checks**:
- Alignment is a valid power of 2
- Size is non-zero (when appropriate)
- Underlying allocator returns properly aligned memory

**Asserts on**: Invalid alignment, allocator contract violations

------

`pub fn free(ctx: *anyopaque, buf: []u8, alignment: Alignment, ret_addr: usize) void`

Validates and performs a free operation.

**Validation checks**:
- Buffer was previously allocated by this allocator
- Buffer hasn't already been freed (double-free detection)
- Alignment matches the original allocation

**Asserts on**: Double-free, freeing unallocated memory, alignment mismatch

------

`pub fn resize(ctx: *anyopaque, buf: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool`

Validates and attempts to resize an existing allocation in-place.

**Validation checks**:
- Buffer is a valid allocation
- Alignment is correct
- New size is reasonable

**Returns**: `true` if resize succeeded, `false` otherwise

------

`pub fn remap(ctx: *anyopaque, buf: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8`

Validates and attempts to resize/move an allocation (combines resize + potential reallocation).

**Validation checks**: Same as resize, plus validates returned pointer if reallocation occurs

**Returns**: Pointer to resized memory (may be same or different address), or `null` on failure

## Usage Example

```zig
const std = @import("std");

// Wrap any allocator with validation
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

var validating = std.mem.ValidationAllocator.init(gpa.allocator());
const allocator = validating.allocator();

// Use normally - violations will trigger assertions
const slice = try allocator.alloc(u8, 100);
defer allocator.free(slice);

// This would assert: double free
// allocator.free(slice);
```

## Debug vs Release Builds

`ValidationAllocator` performs runtime checks that add overhead. Consider:

**Debug builds**: Always use validation to catch bugs early
```zig
const allocator = if (builtin.mode == .Debug)
    validating.allocator()
else
    gpa.allocator();
```

**Release builds**: Skip validation for performance
- Tests still benefit from validation regardless of build mode
- Production code typically uses the underlying allocator directly
