# std.StaticBitSet

`std.StaticBitSet` is the root namespace alias for `std.bit_set.StaticBitSet`.

## Source Declaration

```zig
pub const StaticBitSet = bit_set.StaticBitSet;
```

## Signature

```zig
pub fn StaticBitSet(comptime size: usize) type
```

## Overview

`std.StaticBitSet(size)` returns the optimal fixed-size bit set type for `size` possible items.

For small sizes it uses an integer-backed bit set. For larger sizes it uses an array-backed bit set. Both variants expose the same main API, perform no allocations, can be copied by value, and do not require deinitialization.

## Parameters

- `size`: number of valid bit positions.

## Common Operations

- `empty`: set with no bits present.
- `full`: set with all bits present.
- `capacity()`: return the number of valid bit positions.
- `isSet(index)`: test whether a bit is present.
- `count()`: count set bits.
- `set(index)`, `unset(index)`, `setValue(index, value)`: update individual bits.
- `toggle(index)`: flip a bit.
- `setRangeValue(range, value)`: update a range.
- `iterator(options)`: iterate set or unset bits.

## Notes

- Use `std.DynamicBitSet` when the size is known only at runtime.
- This type is useful for dense integer sets with a known maximum.

## See Also

- `std.DynamicBitSet`
- `std.DynamicBitSetUnmanaged`
