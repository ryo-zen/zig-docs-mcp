# std.PriorityDequeue

`std.PriorityDequeue` is the root namespace alias for the priority-dequeue implementation in `priority_dequeue.zig`.

## Source Declaration

```zig
pub const PriorityDequeue = @import("priority_dequeue.zig").PriorityDequeue;
```

## Signature

```zig
pub fn PriorityDequeue(
    comptime T: type,
    comptime Context: type,
    comptime compareFn: fn (context: Context, a: T, b: T) std.math.Order,
) type
```

## Overview

`std.PriorityDequeue` stores generic items in a min-max priority queue so callers can inspect or remove both minimum and maximum priority items.

The comparison function should return `.lt` when `a` should be min-popped before `b`, `.eq` when they have equal priority, and `.gt` when `b` should be min-popped before `a`.

## Parameters

- `T`: item type.
- `Context`: comparison context type.
- `compareFn`: priority comparison function.

## Fields

- `items`: backing storage.
- `len`: number of queued elements.
- `context`: comparison context.

## Common Operations

- `empty`: dequeue containing no elements.
- `initContext(context)`: initialize with a comparison context.
- `deinit(allocator)`: release memory.
- `push(allocator, elem)`: insert one element.
- `pushSlice(allocator, items)`: insert several elements.
- `peekMin()`, `peekMax()`: view the minimum or maximum item.
- `popMin()`, `popMax()`: remove and return the minimum or maximum item.
- `count()`: number of queued elements.

## See Also

- `std.PriorityQueue`
