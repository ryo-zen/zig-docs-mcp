# Pattern: Arena Allocator

**Problem**: How to simplify memory management when allocating many objects with the same lifetime?

**When to use**:
- Building temporary data structures (parsing, AST construction)
- Request/response handlers (web servers, RPC)
- Short-lived computation phases with many allocations
- When individual free operations would be tedious and error-prone

**Alternatives**:
- Individual allocations with manual tracking (verbose, error-prone)
- Fixed buffer allocator (limited size, no dynamic growth)
- General purpose allocator (slower, more overhead per allocation)

---

## Basic Example

```zig
// TODO: Add simple arena allocator example
```

---

## Real-World Example

```zig
// TODO: Add HTTP request handler example using arena
```

---

## Common Mistakes

- ❌ **Using arena for long-lived data**: Arenas don't free individual items
- ❌ **Not calling deinit**: Memory leak of the entire arena
- ❌ **Mixing arena and non-arena allocations**: Confusing ownership

---

## Performance Characteristics

- **Allocation**: Very fast (bump pointer)
- **Deallocation**: All-at-once only
- **Memory overhead**: Minimal per allocation
- **Fragmentation**: None (contiguous allocation)

---

## See Also

- [Defer Cleanup Pattern](defer_cleanup.md)
- [Allocator Testing Pattern](../testing/allocator_testing.md)
