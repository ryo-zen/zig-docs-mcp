# std.ArrayListAligned

`std.ArrayListAligned` is a deprecated root alias for the canonical type function `std.array_list.Aligned`.

## Source Declaration

```zig
/// Deprecated; use `array_list.Aligned`.
pub const ArrayListAligned = array_list.Aligned;
```

## Signature

```zig
pub fn Aligned(comptime T: type, comptime alignment: ?std.mem.Alignment) type
```

## Overview

`std.ArrayListAligned(T, alignment)` calls the same implementation documented as `std.array_list.Aligned(T, alignment)`. It returns a contiguous, growable list whose backing buffer uses `alignment`, or `@alignOf(T)` when `alignment` is null.

In Zig 0.16, new code should prefer `std.array_list.Aligned(T, alignment)` directly. Use `std.ArrayList(T)` for the common default-alignment spelling, which returns `std.array_list.Aligned(T, null)`.

## Parameters

- `T`: element type.
- `alignment`: optional element alignment.

## Notes

- The alias is deprecated at the root `std` level.
- The full field, value, and method surface is documented on `std.array_list.Aligned`.
- Initialize and deinitialize according to the returned array-list API.

## See Also

- `std.array_list.Aligned`
- `std.ArrayList`
