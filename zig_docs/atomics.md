# Atomics

Use atomics to coordinate shared memory between threads when lock-free access is required.

## Runnable Examples

- `zig_docs_std/Examples/atomic.tests.zig`
- `zig_docs_std/Examples/concurrency_playbook.tests.zig`

## Overview

Atomics are for shared-state synchronization, not for replacing all mutex usage.
Use them for counters, flags, sequence values, and low-level coordination primitives.

## Quick Start

```zig
const std = @import("std");

test "atomic counter" {
    var counter = std.atomic.Value(u64).init(0);
    _ = counter.fetchAdd(1, .monotonic);
    try std.testing.expectEqual(@as(u64, 1), counter.load(.acquire));
}
```

## Memory Ordering Guidance

1. Start with `.seq_cst` for correctness.
2. Use `.release` on publishing writes.
3. Use `.acquire` when consuming published state.
4. Use `.monotonic` for counters where ordering is not used for visibility.
5. Only weaken ordering after measurement and proof.

## RMW Operations

Common read-modify-write methods on `std.atomic.Value(T)`:

- `fetchAdd`, `fetchSub`
- `fetchOr`, `fetchAnd`, `fetchXor`
- `swap`
- `cmpxchgWeak`, `cmpxchgStrong`
- `rmw`

## Gotchas

1. Atomics prevent data races on that value, not on surrounding non-atomic state.
2. `monotonic` does not establish cross-variable happens-before relationships.
3. Lock-free does not mean wait-free or faster under contention.
4. Mixing atomic and non-atomic accesses to the same memory is unsafe.

## See Also

- [Concurrency Playbook](concurrency_playbook.md)
- [Unsafe Boundaries and Invariants](unsafe_boundaries.md)
- [@atomicLoad](builtin_functions.md#atomicLoad)
- [@atomicStore](builtin_functions.md#atomicStore)
- [@atomicRmw](builtin_functions.md#atomicRmw)
- [@cmpxchgWeak](builtin_functions.md#cmpxchgWeak)
- [@cmpxchgStrong](builtin_functions.md#cmpxchgStrong)
