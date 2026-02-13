# Unsafe Boundaries and Invariants

Practical guard rails for casts, pointer conversions, and unchecked assumptions.

## Runnable Examples

- `zig_docs_std/Examples/unsafe_boundaries.tests.zig`
- `zig_docs_std/Examples/pointers.tests.zig`
- `zig_docs_std/Examples/slices.tests.zig`

## Overview

Unsafe boundaries are places where type information or runtime guarantees are weakened.
Common examples:

1. Narrowing casts (`@intCast`, `@floatFromInt`, `@intFromFloat`).
2. Pointer reinterpretation (`@ptrCast`, `@ptrFromInt`, `@alignCast`).
3. Sentinel assumptions (`[:0]const u8`, C-string boundaries).
4. Enum/tag reconstruction (`@enumFromInt`).

Before crossing any unsafe boundary, define and check preconditions explicitly.

## Quick Start

Use this pattern at every unsafe boundary:

1. Validate preconditions (range, alignment, lifetime, sentinel, aliasing).
2. Convert only after validation.
3. Return explicit errors for invalid inputs.

```zig
const std = @import("std");

const BoundaryError = error{ UnalignedPointer, ValueOutOfRange };

fn checkedNarrow(value: i64) BoundaryError!u16 {
    if (value < 0 or value > std.math.maxInt(u16)) {
        return error.ValueOutOfRange;
    }
    return @intCast(value);
}

fn checkedAlign(ptr: [*]const u8) BoundaryError!*const u32 {
    if (@intFromPtr(ptr) % @alignOf(u32) != 0) {
        return error.UnalignedPointer;
    }
    return @ptrCast(@alignCast(ptr));
}
```

## Preconditions Checklist

Validate these before using low-level casts or pointer arithmetic:

1. **Range:** destination type can represent every possible value.
2. **Alignment:** pointer address satisfies target alignment.
3. **Lifetime:** pointed memory outlives all uses.
4. **Mutability:** `const` guarantees are not weakened accidentally.
5. **Bounds:** any index/range access stays inside allocated region.
6. **Sentinel:** sentinel exists where type says it exists.
7. **Aliasing:** mutable aliases do not violate invariants.
8. **Concurrency:** cross-thread mutable access has synchronization.

## Failure/Safe Pairs

`unsafe_boundaries.tests.zig` includes eight runnable pairs:

1. Integer narrowing: rejected out-of-range vs safe cast.
2. Float-to-int conversion: rejected NaN/range vs safe conversion.
3. Alignment checks: rejected unaligned pointer vs safe `@alignCast` path.
4. Pointer-from-int: rejected null/misaligned address vs safe path.
5. Sentinel enforcement: rejected missing terminator vs safe C-string boundary.
6. Enum validation: rejected invalid tag vs safe `@enumFromInt`.
7. Slice bounds guard: rejected invalid range vs safe sub-slice.
8. Non-overlap copy contract: rejected overlap vs safe copy.

## Gotchas

1. `@ptrCast` changes the view, not the underlying bytes or validity.
2. `@alignCast` is not a proof; it must be backed by a real alignment check.
3. `@enumFromInt` is only safe when value domain is validated first.
4. Sentinel types (`[:0]const u8`) require runtime truth, not just annotation.
5. Passing raw pointers at API boundaries hides length and often hides ownership.

## Decision Guide

Choose the narrowest interface that still fits your use case:

1. Use `[]T` instead of `[*]T` when you need bounds.
2. Use explicit checked conversion helper functions instead of inline raw casts.
3. Keep unsafe operations inside one module and expose safe wrappers.
4. If invariant checks are repetitive, centralize them in one guard function.

## Related Docs

- [Casting](casting.md)
- [Pointers](pointers.md)
- [Illegal Behavior](illegal_behavior.md)
- [Common Errors](common_errors.md)
