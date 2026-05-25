# std.PriorityQueue

`std.PriorityQueue` is the root namespace alias for the priority-queue implementation in `priority_queue.zig`.

## Source Declaration

```zig
pub const PriorityQueue = @import("priority_queue.zig").PriorityQueue;
```

## Signature

```zig
pub fn PriorityQueue(
    comptime T: type,
    comptime Context: type,
    comptime compareFn: fn (context: Context, a: T, b: T) std.math.Order,
) type
```

## Overview

`std.PriorityQueue` stores generic items and pops the highest-priority item according to `compareFn`.

The comparison function should return `.lt` when `a` should be popped before `b`, `.eq` when they have equal priority, and `.gt` when `b` should be popped first.

## Parameters

- `T`: item type.
- `Context`: comparison context type.
- `compareFn`: priority comparison function.

## Fields

- `items`: active item storage.
- `cap`: allocated capacity.
- `context`: comparison context.

## Common Operations

- `empty`: queue containing no elements.
- `initContext(context)`: initialize with a comparison context.
- `deinit(allocator)`: release memory.
- `push(allocator, elem)`: insert one element.
- `pushSlice(allocator, items)`: insert several elements.
- `peek()`: view the next item without removing it.
- `pop()`: remove and return the next item.
- `removeIndex(index)`: remove an item at an iterator-order index.
- `count()`: number of queued elements.
- `capacity()`: number of elements that fit before growing.

## See Also

- `std.PriorityDequeue`
