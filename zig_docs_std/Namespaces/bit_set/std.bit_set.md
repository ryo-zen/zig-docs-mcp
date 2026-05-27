# std.bit_set

## Overview

`std.bit_set` provides densely stored sets of integer indexes. Bit sets are fast for membership tests, updates, union, and intersection when the maximum possible item count is known.

Source: `/path/to/zig-0.16.0/lib/std/bit_set.zig`

## Public API

### Static Bit Sets

- `std.bit_set.StaticBitSet(size)` - chooses `IntegerBitSet` for small sizes or `ArrayBitSet` for larger sizes.
- `std.bit_set.IntegerBitSet(size)` - static-size bit set backed by one integer.
- `std.bit_set.ArrayBitSet(MaskIntType, size)` - static-size bit set backed by an array of integer masks.

Static bit sets do not allocate, can be copied by value, and do not require deinitialization.

### Dynamic Bit Sets

- `std.bit_set.DynamicBitSetUnmanaged` - runtime-size bit set that does not store an allocator.
- `std.bit_set.DynamicBitSet` - runtime-size bit set backed by allocated storage and storing allocator state.

### Supporting Types

- `std.bit_set.IteratorOptions` - controls bit-set iteration behavior.
- `std.bit_set.Range` - range type used by range operations.

## Common Operations

The bit set implementations share a common style of operations:

- create empty or full sets
- check capacity and count set bits
- `isSet`, `set`, `unset`, `toggle`, and `setValue`
- set or toggle ranges
- union, intersection, difference, and complement-style operations
- iterate over set or unset indexes

## Choosing a Type

Use `StaticBitSet(size)` when the maximum size is known at compile time. Use `DynamicBitSet` or `DynamicBitSetUnmanaged` when the bit count is only known at runtime.
