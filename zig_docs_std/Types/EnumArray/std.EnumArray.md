# std.EnumArray

`std.EnumArray` is the root namespace alias for `std.enums.EnumArray`.

## Source Declaration

```zig
pub const EnumArray = enums.EnumArray;
```

## Signature

```zig
pub fn EnumArray(comptime E: type, comptime V: type) type
```

## Overview

`std.EnumArray(E, V)` returns an array keyed by enum values and backed by dense storage.

If the enum is not dense, an index mapping is constructed from enum values to dense indices. The type performs no dynamic allocation and can be copied by value.

## Parameters

- `E`: enum key type.
- `V`: value type.

## Types And Values

- `Indexer`: mapping between enum keys and dense indices.
- `Key`: enum key type used for indexing.
- `Value`: stored value type.
- `len`: number of possible enum keys.

## Common Operations

- `init(init_values)`: initialize from a struct of values.
- `initDefault(default, init_values)`: initialize with a default.
- `initUndefined()`: create with undefined storage.
- `initFill(v)`: fill all entries with one value.
- `get(key)`: read the value for a key.
- `getPtr(key)`: get a pointer to the value slot for a key.

## See Also

- `std.EnumMap`
- `std.EnumSet`
