# Pattern: Defer for Resource Cleanup

**Problem**: How to ensure resources are properly freed even when errors occur?

**When to use**:
- Managing allocators, file handles, locks, or any resource requiring cleanup
- Ensuring cleanup happens regardless of error paths
- Implementing RAII-style resource management in Zig

**Alternatives**:
- Manual cleanup (error-prone, must track all exit paths)
- Scope-based wrappers (more verbose, less idiomatic)

---

## Basic Example

```zig
const std = @import("std");

pub fn processData(allocator: std.mem.Allocator) !void {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer); // Guaranteed cleanup

    // Use buffer...
    // Even if error occurs, defer ensures free() is called
}
```

---

## Pattern with errdefer

```zig
// TODO: Add errdefer example for multi-step initialization
```

---

## Real-World Example

```zig
// TODO: Add complete example with file I/O and multiple resources
```

---

## Common Mistakes

- ❌ **Deferring before error check**: `defer foo.deinit(); try foo.init();`
- ❌ **Forgetting errdefer for partial cleanup**: Multi-step init without rollback
- ❌ **Deferring in wrong scope**: Defer outside the owning scope

---

## See Also

- [errdefer for Error Rollback](errdefer_rollback.md)
- [Arena Allocator Pattern](arena_allocator.md)
- [std.mem.Allocator documentation](../../zig_docs_std/Namespaces/mem/std.mem.Allocator.md)
