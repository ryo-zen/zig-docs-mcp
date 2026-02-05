# Pattern: errdefer for Error Rollback

**Problem**: How to clean up partially-initialized resources when an error occurs mid-initialization?

**When to use**:
- Multi-step initialization where later steps can fail
- Acquiring multiple resources that need symmetric cleanup
- Building complex objects with interdependent parts

**Alternatives**:
- Manual error handling with goto/labels (verbose, hard to maintain)
- Helper functions for each init step (scattered cleanup logic)
- Accepting potential leaks (❌ not acceptable)

---

## Basic Example

```zig
// TODO: Add errdefer example with multi-step init
```

---

## Real-World Example

```zig
// TODO: Add database connection pool example
```

---

## Common Mistakes

- ❌ **Using defer instead of errdefer**: Cleanup happens even on success
- ❌ **Wrong errdefer order**: Should mirror initialization order in reverse
- ❌ **Forgetting errdefer on early steps**: Partial resource leaks

---

## See Also

- [Defer Cleanup Pattern](defer_cleanup.md)
- [Error Propagation Pattern](../errors/try_propagation.md)
