# Pattern: Compile-Time Validation

**Problem**: How to catch errors at compile time rather than runtime?

**When to use**:
- Validating type constraints
- Enforcing API contracts at compile time
- Checking configuration parameters
- Building type-safe APIs

**Alternatives**:
- Runtime validation (slower, errors discovered late)
- Documentation-only constraints (not enforced)
- Assertions (runtime overhead, can be disabled)

---

## Basic Example

```zig
// TODO: Add @compileError example for invalid types
```

---

## Pattern: Type Constraints

```zig
// TODO: Add example validating type properties
```

---

## Real-World Example

```zig
// TODO: Add library function with compile-time safety checks
```

---

## Common Mistakes

- ❌ **Overly restrictive constraints**: Prevents valid use cases
- ❌ **Poor error messages**: @compileError needs clear explanation
- ❌ **Compile-time validation for runtime data**: Use runtime checks instead

---

## See Also

- [Generic Functions Pattern](generic_functions.md)
