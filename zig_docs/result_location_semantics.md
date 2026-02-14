# Result Location Semantics

Result Location Semantics (RLS) is Zig's model for how expression context flows through code.
For each expression, the compiler may track:

- A **result type** (what type should be produced).
- A **result location** (where the produced value should be written).

Not every expression has this information. For example, assigning to `_` provides neither a concrete destination nor a useful type target.

A simple example:

```zig
const x: u32 = 42;
```

Here, `42` begins as `comptime_int`, and the declaration context provides a result type of `u32`.

This behavior is part of Zig's language semantics, not an internal optimizer trick. RLS is one of the main mechanisms behind Zig's type inference and aggregate initialization behavior.

## Overview

RLS affects both correctness and performance characteristics:

- Correctness: overlapping reads/writes can behave differently than expected.
- Performance: aggregate initialization can avoid unnecessary temporaries.

Understanding this model helps avoid subtle bugs in in-place updates and makes cast behavior more predictable.

## Runnable Examples

- `zig_docs_std/Examples/result_location_semantics.tests.zig` (20 tests covering RLS, swap problem/solution, propagation tables)
- `zig_docs_std/Examples/comptime_api_design.tests.zig`
- `zig_docs_std/Examples/performance_methodology.tests.zig`
- `zig_docs_std/Examples/arrays.tests.zig`

## Quick Start

1. Assume assignment gives a destination to the right-hand expression.
2. Treat aggregate updates that both read and write the same object with care.
3. Use explicit temporaries when overlap might affect evaluation.
4. Use explicit casts when result type context is ambiguous.

## [Result Types](#toc-Result-Types) §

Result types propagate recursively where language rules allow it.

Example: if `&e` has result type `*u32`, then `e` is given result type `u32` before the reference is formed.

This is why builtins such as `@intCast` can omit an explicit destination type argument: the destination type often comes from surrounding expression context. If that context is missing, use `@as`.

result_type_propagation.zig
```zig
const expectEqual = @import("std").testing.expectEqual;

test "result type propagates through struct initializer" {
    const S = struct { x: u32 };
    const val: u64 = 123;
    const s: S = .{ .x = @intCast(val) };
    // .{ .x = @intCast(val) } has result type `S` from declaration context.
    // @intCast(val) has result type `u32` from field `S.x`.
    // val has no extra result type requirement beyond being an integer.
    try expectEqual(@as(u32, 123), s.x);
}
```

Shell$ `zig test result_type_propagation.zig`
Expected: test passes.

### Result Type Propagation Table

For these rows, `x` and `y` are arbitrary sub-expressions.

| Expression | Parent result type | Sub-expression result type |
|---|---|---|
| `const val: T = x` | none | `x` is `T` |
| `var val: T = x` | none | `x` is `T` |
| `val = x` | none | `x` is `@TypeOf(val)` |
| `@as(T, x)` | none | `x` is `T` |
| `&x` | `*T` | `x` is `T` |
| `&x` | `[]T` | `x` is some array of `T` |
| `f(x)` | none | `x` is the first parameter type of `f` |
| `.{x}` | `T` | `x` is `@FieldType(T, "0")` |
| `.{ .a = x }` | `T` | `x` is `@FieldType(T, "a")` |
| `T{x}` | none | `x` is `@FieldType(T, "0")` |
| `T{ .a = x }` | none | `x` is `@FieldType(T, "a")` |
| `@Int(x, y)` | none | `x` is `std.builtin.Signedness`, `y` is `u16` |
| `@typeInfo(x)` | none | `x` is `type` |
| `x << y` | none | `y` is `std.math.Log2IntCeil(@TypeOf(x))` |

## [Result Locations](#toc-Result-Locations) §

Result location tracks where a value should be written.

For assignment `x = e`, Zig conceptually gives `e`:

- Result type: `@TypeOf(x)`
- Result location: `&x`

This can avoid constructing intermediate aggregate temporaries.

Example:

- If `.{ .a = x, .b = y }` has destination `ptr`, then:
  - `x` writes to `&ptr.a`
  - `y` writes to `&ptr.b`

So `foo = .{ .a = x, .b = y }` behaves like field assignments, not necessarily like "build full temporary then copy".

That matters when source and destination overlap.

**The Swap Problem:**

```zig
var arr: [2]u32 = .{ 1, 2 };
arr = .{ arr[1], arr[0] };  // ❌ WRONG - writes interfere!
// Result: arr = [2, 2] (not swapped!)
```

**The Solution:**

```zig
// ✅ CORRECT: Use explicit temporary
const tmp: [2]u32 = .{ arr[1], arr[0] };
arr = tmp;  // Now: arr = [2, 1] (swapped!)

// ✅ IDIOMATIC: Use std.mem.swap
std.mem.swap(u32, &arr[0], &arr[1]);
```

See `result_location_semantics.tests.zig` tests 4-6 for runnable demonstrations.

### Result Location Propagation Table

For these rows, `x` and `y` are arbitrary sub-expressions.

| Expression | Expression result location | Sub-expression result locations |
|---|---|---|
| `const val: T = x` | none | `x` has `&val` |
| `var val: T = x` | none | `x` has `&val` |
| `val = x` | none | `x` has `&val` |
| `@as(T, x)` | `ptr` | `x` has no result location |
| `&x` | `ptr` | `x` has no result location |
| `f(x)` | `ptr` | `x` has no result location |
| `.{x}` | `ptr` | `x` has `&ptr[0]` |
| `.{ .a = x }` | `ptr` | `x` has `&ptr.a` |
| `T{x}` | `ptr` | `x` has no result location (typed initializers do not propagate it) |
| `T{ .a = x }` | `ptr` | `x` has no result location (typed initializers do not propagate it) |
| `@Int(x, y)` | none | `x` and `y` have no result locations |
| `@typeInfo(x)` | `ptr` | `x` has no result location |
| `x << y` | `ptr` | `x` and `y` have no result locations |

## Decision Guidance

- Use inferred initializers (`.{}`) when destination type is already clear.
- Use typed initializers (`T{}`) when explicit type at the expression site improves readability.
- Use explicit temporaries for in-place transformations to avoid overlap surprises.
- Be explicit about copy-vs-in-place behavior in API design.

## Gotchas

1. Swap-like aggregate assignment can fail due to write ordering.
2. Typed and inferred initializers propagate context differently.
3. Missing type context can make cast diagnostics harder to interpret.
4. Assuming copy behavior without measuring can mislead optimization decisions.

## Related Docs

- [Comptime](comptime.md)
- [Arrays](arrays.md)
- [Memory](memory.md)
- [Performance Methodology](performance.md)
