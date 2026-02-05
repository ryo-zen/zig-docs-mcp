# Pattern: Testing with Allocators

**Problem**: How to detect memory leaks and allocation errors in tests?

**When to use**:
- Testing functions that allocate memory
- Validating proper cleanup in error paths
- Ensuring no memory leaks in your code
- Catching allocator misuse (double-free, invalid free, etc.)

**Alternatives**:
- Manual inspection (unreliable, doesn't catch all leaks)
- External tools like valgrind (slow, OS-specific)
- Trust and hope (❌ not recommended)

---

## Basic Example: Testing Allocator

```zig
const std = @import("std");

test "function doesn't leak" {
    // std.testing.allocator detects leaks automatically
    const allocator = std.testing.allocator;

    const buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    // If we forget the defer, test fails with "memory leak detected"
}
```

---

## Pattern: ValidationAllocator for Debug Builds

```zig
// TODO: Add ValidationAllocator example
// See: ../../zig_docs_std/Namespaces/mem/std.mem.ValidationAllocator.md
```

---

## Pattern: Testing OutOfMemory Handling

```zig
test "handles allocation failure gracefully" {
    // FailingAllocator simulates allocation failures
    var result = myFunction(std.testing.failing_allocator);
    try std.testing.expectError(error.OutOfMemory, result);
}
```

---

## Real-World Example

```zig
// TODO: Add test suite for data structure with proper allocator testing
```

---

## Common Mistakes

- ❌ **Using GPA in tests**: Use `std.testing.allocator` for automatic leak detection
- ❌ **Not testing error paths**: Allocation failures often leak resources
- ❌ **Ignoring allocator parameter in tests**: Always pass test allocator

---

## Testing Checklist

✅ All allocations paired with frees (or defer)
✅ Error paths tested (use `failing_allocator`)
✅ No leaks detected by `std.testing.allocator`
✅ Proper use of errdefer for multi-step init

---

## See Also

- [ValidationAllocator Documentation](../../zig_docs_std/Namespaces/mem/std.mem.ValidationAllocator.md)
- [ValidationAllocator Tests](../../zig_docs_std/Examples/std.mem.ValidationAllocator.tests.zig)
- [defer Cleanup Pattern](../memory/defer_cleanup.md)
- [errdefer Rollback Pattern](../memory/errdefer_rollback.md)
