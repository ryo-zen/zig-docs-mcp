# Pattern: Generic Functions with comptime

**Problem**: How to write functions that work with multiple types without runtime overhead?

**When to use**:
- Building data structures (ArrayList, HashMap, etc.)
- Creating type-safe utilities that work with any type
- Implementing polymorphic behavior at compile time
- When you need zero-cost abstraction

**Alternatives**:
- Runtime polymorphism (interfaces, vtables - slower, less type-safe)
- Code duplication (hard to maintain)
- void pointers and type erasure (not type-safe, not idiomatic)

---

## Basic Example

```zig
// TODO: Add generic function example
```

---

## Pattern: Type-Parameterized Structs

```zig
// TODO: Add generic struct example (like ArrayList)
```

---

## Real-World Example

```zig
// TODO: Add complete generic data structure
```

---

## Common Mistakes

- ❌ **Using comptime when not needed**: Adds complexity
- ❌ **Not using comptime when needed**: Loses type information
- ❌ **Confusing comptime parameters with runtime parameters**: Different purposes

---

## See Also

- [Compile-Time Validation Pattern](compile_time_validation.md)
