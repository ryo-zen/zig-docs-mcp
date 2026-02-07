# std.testing.failing_allocator

**Type:** `std.mem.Allocator`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

An allocator that **always returns `error.OutOfMemory`**. Used for testing error paths without actually exhausting system memory.

**Use Case:** Verify that your code handles allocation failures gracefully.

⚠️ **Warning:** Never use this allocator for actual allocations - it always fails!

---

## Usage

```zig
const std = @import("std");

fn processData(allocator: std.mem.Allocator) ![]u8 {
    const buffer = try allocator.alloc(u8, 100);
    // ... process ...
    return buffer;
}

test "OOM handling" {
    const result = processData(std.testing.failing_allocator);

    // Verify the function returns OutOfMemory error
    try std.testing.expectError(error.OutOfMemory, result);
}
```

---

## Source

```zig
pub const failing_allocator = failing_allocator_instance.allocator();
```

---

## Related

- **[std.testing.allocator](./std.testing.allocator.md)** - Normal test allocator with leak detection
- **[std.testing.checkAllAllocationFailures](./std.testing.md#checkAllAllocationFailures)** - Exhaustive OOM testing
- **[std.testing.FailingAllocator](./std.testing.FailingAllocator.md)** - The underlying type

---

## Best Practices

✅ **Only for testing errors** - Use to verify error handling, not for real allocations
✅ **Test both paths** - Test both success (with testing.allocator) and failure (with failing_allocator)
❌ **Never allocate with it** - It will always fail!
