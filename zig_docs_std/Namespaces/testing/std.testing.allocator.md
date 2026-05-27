# std.testing.allocator

**Type:** `std.mem.Allocator`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A `DebugAllocator` instance configured for testing with automatic leak detection and safety checks. This is the **recommended allocator for all unit tests**.

**Key Features:**
- ✅ Automatic leak detection - test fails if memory isn't freed
- ✅ Double-free detection
- ✅ Use-after-free detection (when runtime safety enabled)
- ✅ Stack traces on leaks (when available)

---

## Usage

```zig
const std = @import("std");

test "using testing.allocator" {
    const allocator = std.testing.allocator;

    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data); // Test fails if this is missing!

    data[0] = 42;
    try std.testing.expectEqual(@as(u8, 42), data[0]);
}
```

---

## Source

```zig
pub const allocator = allocator_instance.allocator();
```

The underlying instance is a `DebugAllocator` with stack trace frames enabled.

---

## Related

- **[std.testing.failing_allocator](./std.testing.failing_allocator.md)** - Always fails, for testing OOM paths
- **[std.heap.DebugAllocator](../heap/std.heap.md)** - The underlying allocator type
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Always use in tests** - Catches memory leaks automatically
✅ **Use `defer` immediately** - Ensures cleanup even if test fails
✅ **Don't use in production** - This is for tests only
