# std.ArrayListUnmanaged

`std.ArrayListUnmanaged` is a deprecated root alias for `std.ArrayList`, which returns `std.array_list.Aligned(T, null)`.

## Source Declaration

```zig
/// Deprecated; use `ArrayList`.
pub const ArrayListUnmanaged = ArrayList;
```

## Signature

```zig
pub fn ArrayList(comptime T: type) type
```

## Overview

`std.ArrayListUnmanaged(T)` is kept as a compatibility alias. In Zig 0.16 it points at `std.ArrayList(T)`, and `std.ArrayList(T)` returns `std.array_list.Aligned(T, null)`.

New code should use `std.ArrayList(T)` directly.

## Parameters

- `T`: element type.

## Notes

- The alias is deprecated at the root `std` level.
- The full field, value, and method surface is documented on `std.array_list.Aligned`.
- The same allocator must be used throughout the list lifetime.

## See Also

- `std.ArrayList`
- `std.array_list.Aligned`
