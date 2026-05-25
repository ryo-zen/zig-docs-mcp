# std.DynamicBitSet

`std.DynamicBitSet` is the root namespace alias for `std.bit_set.DynamicBitSet`.

## Source Declaration

```zig
pub const DynamicBitSet = bit_set.DynamicBitSet;
```

## Overview

`std.DynamicBitSet` is a runtime-sized bit set backed by allocated `usize` masks.

It is a thin managed wrapper around `std.DynamicBitSetUnmanaged` that stores the allocator used for resizing and deinitialization.

## Fields

- `allocator`: allocator used by the bit set.
- `unmanaged`: underlying unmanaged dynamic bit set.

## Common Operations

- `initEmpty(allocator, bit_length)`: create a set with no bits present.
- `initFull(allocator, bit_length)`: create a set with all bits present.
- `resize(new_len, fill)`: change the bit length.
- `deinit()`: release allocated storage.
- `clone(new_allocator)`: duplicate into another allocator.
- `capacity()`: return the number of valid bit positions.
- `isSet(index)`: test whether a bit is present.
- `count()`: count set bits.
- `set(index)`, `unset(index)`, `setValue(index, value)`: update individual bits.

## Notes

- Use `std.StaticBitSet` when the maximum size is known at comptime.
- Use `std.DynamicBitSetUnmanaged` when allocator ownership should stay outside the value.

## See Also

- `std.DynamicBitSetUnmanaged`
- `std.StaticBitSet`
