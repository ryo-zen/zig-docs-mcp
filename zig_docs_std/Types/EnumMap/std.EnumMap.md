# std.EnumMap

`std.EnumMap` is the root namespace alias for `std.enums.EnumMap`.

## Source Declaration

```zig
pub const EnumMap = enums.EnumMap;
```

## Signature

```zig
pub fn EnumMap(comptime E: type, comptime V: type) type
```

## Overview

`std.EnumMap(E, V)` returns a sparse map keyed by enum values. It is backed by a bit set indicating present keys and a dense value array.

If the enum is exhaustive but not dense, an index mapping is constructed from enum values to dense indices. The type performs no dynamic allocation and can be copied by value.

## Parameters

- `E`: enum key type.
- `V`: value type.

## Fields

- `bits`: bit set marking which keys are present.
- `values`: dense value storage.

## Types And Values

- `Indexer`: mapping between enum keys and dense indices.
- `Key`: enum key type used for indexing.
- `Value`: stored value type.
- `len`: number of possible enum keys.

## Common Operations

- `init(init_values)`: initialize from a sparse struct of optionals.
- `initFull(value)`: initialize all keys to the same value.
- `get(key)`: return the value for a key, or null.
- `getPtr(key)`: return a pointer to a value, or null.
- `put(key, value)`: insert or replace a value.
- `remove(key)`: remove a key.
- `iterator()`: iterate present entries.

## See Also

- `std.EnumArray`
- `std.EnumSet`
