# Pattern: Custom Error Sets

**Problem**: How to define domain-specific errors that clearly communicate failure modes?

**When to use**:
- Building libraries or modules with specific error conditions
- When standard errors (OutOfMemory, etc.) don't describe your failure modes
- Creating hierarchical error taxonomies

**Alternatives**:
- Using anyerror (loses type information, not recommended)
- Reusing standard library error sets (may not fit your domain)
- Error codes/integers (not type-safe, not idiomatic)

---

## Basic Example

```zig
// TODO: Add custom error set definition
```

---

## Error Set Composition

```zig
// TODO: Add example of combining error sets
```

---

## Real-World Example

```zig
// TODO: Add parser or protocol handler with custom errors
```

---

## Common Mistakes

- ❌ **Too many error types**: Creates verbose error handling
- ❌ **Too few error types**: Loses diagnostic information
- ❌ **Inconsistent naming**: Use standard Error suffix convention

---

## See Also

- [Error Propagation Pattern](try_propagation.md)
- [Error Recovery Pattern](error_recovery.md)
