# std.testing.FailingAllocator.Config

**Type:** `struct`

**Module:** `std.testing`

**Parent Type:** `FailingAllocator`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

Configuration struct for `FailingAllocator` that controls when allocation and resize operations should fail. Allows precise control over which operation triggers `error.OutOfMemory`.

**Default Behavior:** Both fields default to `maxInt(usize)`, meaning no failures occur unless explicitly configured.

---

## Fields

### `fail_index: usize = std.math.maxInt(usize)`

The allocation index at which to induce failure. Allocations before this index succeed; this allocation and all subsequent ones fail.

**Default:** `std.math.maxInt(usize)` (never fail)

**Example:**
```zig
// Fail on the 3rd allocation (index 2)
.{ .fail_index = 2 }

// Fail immediately on first allocation
.{ .fail_index = 0 }
```

------

### `resize_fail_index: usize = std.math.maxInt(usize)`

The resize operation index at which to induce failure. Resize operations before this index succeed; this resize and all subsequent ones fail.

**Default:** `std.math.maxInt(usize)` (never fail)

**Example:**
```zig
// Fail on the first resize operation
.{ .resize_fail_index = 0 }

// Allow 2 successful resizes, fail on the 3rd
.{ .resize_fail_index = 2 }
```

---

## Usage

### Fail on Specific Allocation

```zig
const std = @import("std");

test "fail on second allocation" {
    var failing = std.testing.FailingAllocator.init(
  std.testing.allocator,
  .{ .fail_index = 1 }, // Fail on index 1 (second allocation)
    );
    const allocator = failing.allocator();

    const first = try allocator.alloc(u8, 100);  // Index 0: succeeds
    defer allocator.free(first);

    const second = allocator.alloc(u8, 200);     // Index 1: fails
    try std.testing.expectError(error.OutOfMemory, second);
}
```

### Fail on Resize

```zig
test "fail on resize" {
    var failing = std.testing.FailingAllocator.init(
  std.testing.allocator,
  .{ .resize_fail_index = 0 }, // Fail on first resize
    );
    const allocator = failing.allocator();

    var buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    // Resize attempt fails
    const result = allocator.realloc(buffer, 200);
    try std.testing.expectError(error.OutOfMemory, result);
}
```

### Combine Allocation and Resize Failures

```zig
test "multiple failure points" {
    var failing = std.testing.FailingAllocator.init(
  std.testing.allocator,
  .{
      .fail_index = 5,         // Fail allocations starting at index 5
      .resize_fail_index = 2,  // Fail resizes starting at index 2
  },
    );
    const allocator = failing.allocator();

    // Test both paths...
}
```

---

## Related

- **[std.testing.FailingAllocator](./std.testing.FailingAllocator.md)** - The allocator type this configures
- **[std.testing.failing_allocator](./std.testing.failing_allocator.md)** - Simple always-failing allocator
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Start with 0** - Test immediate failure first (`.fail_index = 0`)
✅ **Test different indices** - Try various failure points to cover all paths
✅ **Combine with checkAllAllocationFailures** - For exhaustive testing
⚠️ **Index is 0-based** - First operation is index 0, not 1
