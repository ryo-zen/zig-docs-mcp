# std.sort

## Overview

`std.sort` provides in-place sorting algorithms, comparator helpers, binary-search helpers, and min/max helpers.

Source: `/path/to/zig-0.16.0/lib/std/sort.zig`

## Public API

### Algorithms

- `std.sort.insertion` - stable in-place insertion sort. Best case `O(n)`, worst case `O(n^2)`, no allocator required.
- `std.sort.insertionContext` - context-based insertion sort where the context supplies `swap` and `lessThan` methods over indexes.
- `std.sort.heap` - unstable in-place heap sort. Best, average, and worst case `O(n * log(n))`, no allocator required.
- `std.sort.heapContext` - context-based heap sort where the context supplies `swap` and `lessThan`.
- `std.sort.block` - stable block sort imported from `sort/block.zig`.
- `std.sort.pdq` - pattern-defeating quicksort imported from `sort/pdq.zig`.
- `std.sort.pdqContext` - context-based pattern-defeating quicksort.

### Comparator Helpers

- `std.sort.asc(T)` - returns a comparator for ascending order.
- `std.sort.desc(T)` - returns a comparator for descending order.
- `std.sort.Mode` - enum with `.stable` and `.unstable`.

### Search Helpers

- `std.sort.binarySearch` - searches a sorted slice for a key.
- `std.sort.lowerBound` - returns the insertion position before equal values.
- `std.sort.upperBound` - returns the insertion position after equal values.
- `std.sort.partitionPoint` - finds the boundary where a predicate switches.
- `std.sort.equalRange` - returns the range of elements equal to a key.

### Selection Helpers

- `std.sort.argMin` - returns the index of the minimum element.
- `std.sort.min` - returns the minimum element.
- `std.sort.argMax` - returns the index of the maximum element.
- `std.sort.max` - returns the maximum element.
- `std.sort.isSorted` - checks whether a slice is already sorted for a comparator.

## Common Pattern

```zig
const std = @import("std");

var values = [_]u32{ 4, 1, 3, 2 };
std.sort.heap(u32, &values, {}, std.sort.asc(u32));
```

Use the context variants when sorting external storage or when swapping by index is cheaper than passing element values through a normal comparator.
