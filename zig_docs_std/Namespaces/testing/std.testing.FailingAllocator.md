# std.testing.FailingAllocator

**Type:** `struct`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

An allocator wrapper that **fails after N allocations**, designed for exhaustive testing of out-of-memory error paths. Unlike `std.testing.failing_allocator` (which always fails), this allocator succeeds for a configured number of allocations before inducing failure.

**Use Cases:**
- ✅ Testing partial allocation failure scenarios
- ✅ Verifying cleanup code runs when allocation fails mid-operation
- ✅ Ensuring no memory leaks when OOM occurs partway through
- ✅ Capturing stack traces of allocation failure points

---

## Fields

### `alloc_index: usize`

Current count of successful allocations performed. Incremented on each successful alloc.

------

### `resize_index: usize`

Current count of successful resize operations performed. Incremented on each successful resize.

------

### `internal_allocator: mem.Allocator`

The underlying allocator that performs actual allocations until the failure threshold is reached.

------

### `allocated_bytes: usize`

Total number of bytes allocated (for tracking and debugging).

------

### `freed_bytes: usize`

Total number of bytes freed (for leak detection).

------

### `allocations: usize`

Total count of allocation calls made (both successful and failed).

------

### `deallocations: usize`

Total count of deallocation calls made.

------

### `stack_addresses: [num_stack_frames]usize`

Captured stack trace addresses when the induced failure occurs. Use with `getStackTrace()`.

------

### `has_induced_failure: bool`

Set to `true` once the allocator has triggered its configured failure. After this, the stack trace is valid.

------

### `fail_index: usize`

The allocation index at which to fail. Allocations at this index and beyond return `error.OutOfMemory`.

------

### `resize_fail_index: usize`

The resize index at which to fail. Resize operations at this index and beyond return `error.OutOfMemory`.

---

## Types

### `Config`

Configuration for controlling when failures occur. See **[std.testing.FailingAllocator.Config](./std.testing.FailingAllocator.Config.md)** for details.

---

## Functions

### `pub fn init(internal_allocator: mem.Allocator, config: Config) FailingAllocator`

Creates a new `FailingAllocator` wrapping the provided allocator with the specified failure configuration.

**Parameters:**
- `internal_allocator` - The real allocator to use for actual allocations
- `config` - Configuration specifying when to fail

**Example:**
```zig
const std = @import("std");

test "fail after 3 allocations" {
    var failing = std.testing.FailingAllocator.init(
  std.testing.allocator,
  .{ .fail_index = 3 },
    );
    const allocator = failing.allocator();

    // These succeed (index 0, 1, 2)
    const a = try allocator.alloc(u8, 10);
    const b = try allocator.alloc(u8, 20);
    const c = try allocator.alloc(u8, 30);

    // This fails (index 3)
    const result = allocator.alloc(u8, 40);
    try std.testing.expectError(error.OutOfMemory, result);

    // Cleanup successful allocations
    allocator.free(a);
    allocator.free(b);
    allocator.free(c);
}
```

------

### `pub fn allocator(self: *FailingAllocator) mem.Allocator`

Returns the `mem.Allocator` interface for this failing allocator instance.

**Example:**
```zig
var failing = std.testing.FailingAllocator.init(gpa, .{ .fail_index = 5 });
const allocator = failing.allocator();
// Use allocator as normal mem.Allocator
```

------

### `pub fn getStackTrace(self: *FailingAllocator) std.builtin.StackTrace`

Returns a stack trace captured at the point where the allocator induced its first failure.

⚠️ **Only valid once `has_induced_failure == true`**

**Example:**
```zig
test "capture allocation failure stack trace" {
    var failing = std.testing.FailingAllocator.init(
  std.testing.allocator,
  .{ .fail_index = 0 },
    );
    const allocator = failing.allocator();

    _ = allocator.alloc(u8, 100) catch |err| {
  try std.testing.expect(failing.has_induced_failure);
  const trace = failing.getStackTrace();
  std.debug.print("Failure stack trace:\n{}\n", .{trace});
  return err;
    };
}
```

---

## Usage Patterns

### Testing Multi-Step Allocation Failure

```zig
test "partial operation failure handling" {
    // Fail on the 2nd allocation
    var failing = std.testing.FailingAllocator.init(
  std.testing.allocator,
  .{ .fail_index = 1 },
    );
    const allocator = failing.allocator();

    const first = try allocator.alloc(u8, 100); // Succeeds (index 0)

    // This allocation fails (index 1)
    const second = allocator.alloc(u8, 200);
    try std.testing.expectError(error.OutOfMemory, second);

    // Ensure cleanup of partial success
    allocator.free(first);

    // Verify no leaks in the internal allocator
    try std.testing.expect(failing.allocated_bytes == failing.freed_bytes);
}
```

### Testing Resize Failures

```zig
test "resize failure handling" {
    var failing = std.testing.FailingAllocator.init(
  std.testing.allocator,
  .{ .resize_fail_index = 0 },
    );
    const allocator = failing.allocator();

    var buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    // Attempt to resize - should fail
    const result = allocator.realloc(buffer, 200);
    try std.testing.expectError(error.OutOfMemory, result);
}
```

---

## Related

- **[std.testing.failing_allocator](./std.testing.failing_allocator.md)** - Always fails (simpler, for basic OOM tests)
- **[std.testing.checkAllAllocationFailures](./std.testing.md#checkAllAllocationFailures)** - Exhaustive OOM testing framework
- **[std.testing.FailingAllocator.Config](./std.testing.FailingAllocator.Config.md)** - Configuration options
- **[std.mem.Allocator](../mem/std.mem.md)** - Standard allocator interface
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Test all OOM paths** - Try different failure points to ensure all error paths are covered
✅ **Verify no leaks** - Check `allocated_bytes == freed_bytes` after test
✅ **Use with defer** - Ensure cleanup happens even when testing error paths
✅ **Capture stack traces** - Use `getStackTrace()` for debugging complex failures
⚠️ **Wrap a real allocator** - Use `testing.allocator` or GPA as internal allocator
❌ **Not for production** - Testing tool only, not meant for production use
