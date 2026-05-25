# std.ArrayListAlignedUnmanaged

`std.ArrayListAlignedUnmanaged` is a deprecated root alias for the canonical type function `std.array_list.Aligned`.

## Source Declaration

```zig
/// Deprecated; use `array_list.Aligned`.
pub const ArrayListAlignedUnmanaged = array_list.Aligned;
```

## Signature

```zig
pub fn Aligned(comptime T: type, comptime alignment: ?std.mem.Alignment) type
```

## Overview

`std.ArrayListAlignedUnmanaged(T, alignment)` is kept as a compatibility alias. In Zig 0.16 it points at the same `std.array_list.Aligned(T, alignment)` implementation as `std.ArrayListAligned`.

New code should use `std.array_list.Aligned(T, alignment)` directly.

## Parameters

- `T`: element type.
- `alignment`: optional element alignment.

## Notes

- The alias is deprecated at the root `std` level.
- Despite the historical name, the alias target is `std.array_list.Aligned`.
- The full field, value, and method surface is documented on `std.array_list.Aligned`.

## See Also

- `std.array_list.Aligned`
- `std.ArrayListAligned`
- `std.ArrayList`
