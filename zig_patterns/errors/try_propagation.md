# Pattern: Error Propagation with try

**Problem**: How to handle errors that should be propagated to the caller?

**When to use**:
- Functions that perform operations which may fail
- Building error chains through call stacks
- When the current function cannot meaningfully recover from an error

**Alternatives**:
- `catch` for local recovery (when you can handle the error)
- `catch unreachable` for impossible errors (use sparingly)
- Error unions without try (manual unwrapping, verbose)

---

## Basic Example

```zig
// TODO: Add try propagation example
```

---

## Error Union Functions

```zig
// TODO: Add example of function returning error union
```

---

## Real-World Example

```zig
// TODO: Add file processing pipeline with error propagation
```

---

## Common Mistakes

- ❌ **Using `catch unreachable` prematurely**: Assuming errors can't happen
- ❌ **Silent error swallowing**: `catch {}`  without logging
- ❌ **Not documenting error conditions**: Callers need to know what can fail

---

## See Also

- [Custom Error Sets Pattern](custom_error_sets.md)
- [Error Recovery Pattern](error_recovery.md)
