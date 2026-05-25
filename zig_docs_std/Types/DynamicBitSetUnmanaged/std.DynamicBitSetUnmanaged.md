# std.DynamicBitSetUnmanaged

`std.DynamicBitSetUnmanaged` is the root namespace alias for `std.bit_set.DynamicBitSetUnmanaged`.

## Source Declaration

```zig
pub const DynamicBitSetUnmanaged = bit_set.DynamicBitSetUnmanaged;
```

## Overview

`std.DynamicBitSetUnmanaged` is a runtime-sized bit set backed by allocated `usize` masks.

Unlike `std.DynamicBitSet`, it does not store an allocator. Allocation-aware methods take an allocator argument.

## Fields

- `bit_length`: number of valid bit positions.
- `masks`: bit-mask storage ordered with lower indices first.

## Common Operations

- `initEmpty(allocator, bit_length)`: create a set with no bits present.
- `initFull(allocator, bit_length)`: create a set with all bits present.
- `resize(allocator, new_len, fill)`: change the bit length.
- `deinit(allocator)`: release allocated storage.
- `clone(allocator)`: duplicate into an allocator.
- `capacity()`: return the number of valid bit positions.
- `isSet(index)`: test whether a bit is present.
- `count()`: count set bits.
- `set(index)`, `unset(index)`, `setValue(index, value)`: update individual bits.

## Notes

- If initialized or resized to a nonzero length, call `deinit` with a compatible allocator.
- Use this type when embedding the set in a larger owner that already tracks allocation.

## See Also

- `std.DynamicBitSet`
- `std.StaticBitSet`
