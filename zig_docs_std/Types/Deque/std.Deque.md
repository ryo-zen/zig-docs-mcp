# std.Deque

`std.Deque` is the root namespace alias for the deque implementation in `deque.zig`.

## Source Declaration

```zig
pub const Deque = @import("deque.zig").Deque;
```

## Signature

```zig
pub fn Deque(comptime T: type) type
```

## Overview

`std.Deque(T)` returns a contiguous, growable, double-ended queue backed by a ring buffer.

Pushing and popping items from either end of the queue is O(1) amortized. The deque can allocate its own storage with `initCapacity`, or it can use externally managed storage with `initBuffer`.

## Parameters

- `T`: element type stored in the deque.

## Fields

- `buffer`: ring-buffer storage.
- `head`: index of the first logical item in `buffer`.
- `len`: number of logical items currently stored.

## Common Operations

- `empty`: a deque containing no elements.
- `initCapacity(gpa, capacity)`: initializes with exact capacity.
- `initBuffer(buffer)`: initializes with externally managed memory.
- `deinit(gpa)`: releases allocated memory.
- `pushFront`, `pushBack`: add one item to either end, growing if needed.
- `pushFrontBounded`, `pushBackBounded`: add without allocation, returning `error.OutOfMemory` when full.
- `popFront`, `popBack`: remove one item from either end.
- `ensureTotalCapacity`, `ensureUnusedCapacity`: grow capacity.

## Notes

- Growth can invalidate element pointers.
- Functions that take an allocator must not be used after `initBuffer`.
- Use bounded or assume-capacity operations when allocation is not allowed.

## See Also

- `std.ArrayList`
