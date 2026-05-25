# std.MultiArrayList

`std.MultiArrayList` is the root namespace alias for the multi-array-list implementation in `multi_array_list.zig`.

## Source Declaration

```zig
pub const MultiArrayList = @import("multi_array_list.zig").MultiArrayList;
```

## Signature

```zig
pub fn MultiArrayList(comptime T: type) type
```

## Overview

`std.MultiArrayList(T)` stores a list of struct or tagged-union values as separate arrays for each field.

This layout can reduce memory wasted by padding and improve cache behavior when code reads only some fields. The main field-access API is `slice()`, which computes field pointers; from the slice, use `.items(.field_name)` to get a field slice.

## Parameters

- `T`: struct or tagged union element type.

## Fields

- `bytes`: backing allocation pointer.
- `len`: number of initialized elements.
- `capacity`: allocated capacity.

## Types

- `Field`: enum of element fields.
- `Slice`: cached field pointers for efficient repeated field access.

## Common Operations

- `empty`: empty list value.
- `initCapacity(gpa, num)`: initialize with exact capacity.
- `deinit(gpa)`: release storage.
- `slice()`: compute field pointers.
- `append(gpa, elem)`: append one element.
- `appendAssumeCapacity(elem)`: append without allocation.
- `ensureTotalCapacity(gpa, new_capacity)`: grow capacity.
- `toOwnedSlice()`: transfer storage to a slice representation.

## Notes

- Only structs and tagged unions are supported.
- Field slices may be invalidated by reallocation.

## See Also

- `std.ArrayList`
