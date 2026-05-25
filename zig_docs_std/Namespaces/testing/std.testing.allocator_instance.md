# std.testing.allocator_instance

**Type:** `std.heap.DebugAllocator` (configured for testing)

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

The underlying `DebugAllocator` instance that powers `std.testing.allocator`. Configured with leak detection, stack traces, and a unique canary value to prevent misuse.

**Key Configuration:**
- ✅ Stack trace frames: 10 (when platform supports stack traces)
- ✅ Resize stack traces: enabled
- ✅ Unique canary: prevents mixing with regular GPA instances

⚠️ **Internal:** Most tests should use `std.testing.allocator` directly instead of accessing this instance.

---

## Source

```zig
pub var allocator_instance: std.heap.DebugAllocator(.{
    .stack_trace_frames = if (std.debug.sys_can_stack_trace) 10 else 0,
    .resize_stack_traces = true,
    // A unique value so that when a default-constructed
    // DebugAllocator is incorrectly passed to testing allocator, or
    // vice versa, panic occurs.
    .canary = @truncate(0x2731e675c3a701ba),
}) = b: {
    if (!builtin.is_test) @compileError("testing allocator used when not testing");
    break :b .init;
};
```

---

## Related

- **[std.testing.allocator](./std.testing.allocator.md)** - The public allocator interface (use this in tests)
- **[std.heap.DebugAllocator](../heap/std.heap.md)** - The underlying allocator type
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Use std.testing.allocator** - Don't access this instance directly
⚠️ **Test-only** - Compile error if used outside of test builds
❌ **Don't create your own** - The unique canary prevents mixing instances
