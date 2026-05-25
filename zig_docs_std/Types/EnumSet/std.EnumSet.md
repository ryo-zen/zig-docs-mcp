# std.EnumSet

`std.EnumSet` is the root namespace alias for `std.enums.EnumSet`.

## Source Declaration

```zig
pub const EnumSet = enums.EnumSet;
```

## Signature

```zig
pub fn EnumSet(comptime E: type) type
```

## Overview

`std.EnumSet(E)` returns a set of enum elements backed by a bitfield.

If the enum is exhaustive but not dense, an index mapping is constructed from enum values to dense indices. The type performs no dynamic allocation and can be copied by value.

## Parameters

- `E`: enum element type.

## Fields

- `bits`: bit set storing present enum values.

## Types And Values

- `Indexer`: mapping between enum keys and dense indices.
- `Key`: enum element type.
- `len`: number of possible enum values.
- `empty`: set containing no keys.
- `full`: set containing all possible keys.

## Common Operations

- `init(init_values)`: initialize from a struct of bools.
- `contains(key)`: test membership.
- `insert(key)`: add a key.
- `remove(key)`: remove a key.
- `toggle(key)`: flip membership.
- `setUnion`, `setIntersection`, `setDifference`: combine sets.
- `iterator()`: iterate present keys.

## See Also

- `std.EnumArray`
- `std.EnumMap`
