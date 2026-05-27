# std.enums

## Overview

`std.enums` contains utilities and data structures for working with enum types at compile time and runtime.

Source: `/path/to/zig-0.16.0/lib/std/enums.zig`

## Public API

### Conversion and Introspection

- `std.enums.fromInt(E, integer)` - returns an enum value when the integer matches the enum.
- `std.enums.EnumFieldStruct(E, Data, field_default)` - creates a struct with one field for each unique named enum element.
- `std.enums.valuesFromFields(E, fields)` - returns enum values for a list of enum fields.
- `std.enums.values(E)` - returns all named enum values in declaration order.
- `std.enums.tagName(E, e)` - safe tag-name lookup that returns `null` for unnamed non-exhaustive values.

### Direct Enum Arrays

- `std.enums.directEnumArrayLen(E, max_unused_slots)` - computes the array length for direct enum indexing.
- `std.enums.directEnumArray(E, Data, max_unused_slots, init_values)` - creates a direct-indexed array from field init values.
- `std.enums.directEnumArrayDefault(E, Data, default, max_unused_slots, init_values)` - direct-indexed array with a default for missing slots.

### Enum Collections

- `std.enums.EnumSet(E)` - set of enum values.
- `std.enums.EnumMap(E, V)` - map from enum values to values.
- `std.enums.EnumMultiset(E)` - multiset keyed by enum values.
- `std.enums.BoundedEnumMultiset(E, CountSize)` - multiset with configurable count type.
- `std.enums.EnumArray(E, V)` - array-like storage keyed by enum values.
- `std.enums.EnumIndexer(E)` - helper for mapping enum values to indexes.

## Notes

Many helpers rely on `comptime` enum information and may emit compile errors for unsupported enum shapes, negative direct-array indexes, or direct arrays with too many unused slots.
