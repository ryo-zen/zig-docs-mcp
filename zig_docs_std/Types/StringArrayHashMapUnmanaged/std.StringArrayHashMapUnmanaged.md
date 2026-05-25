# std.StringArrayHashMapUnmanaged

`std.StringArrayHashMapUnmanaged` is a deprecated root alias for the canonical type function `std.array_hash_map.String`.

## Source Declaration

```zig
/// Deprecated; use `array_hash_map.String`.
pub const StringArrayHashMapUnmanaged = array_hash_map.String;
```

## Signature

```zig
pub fn String(comptime V: type) type
```

## Overview

`std.StringArrayHashMapUnmanaged(V)` returns an unmanaged, insertion-order-preserving array hash map specialized for `[]const u8` keys.

New code should use `std.array_hash_map.String(V)` directly. This page exists for older code and searchability; the alias calls the same implementation.

## Parameters

- `V`: value type.

## Notes

- This is an unmanaged map; allocation-aware operations take an allocator argument.
- Iteration follows insertion order.
- String keys are compared by contents.
- Key and value memory ownership remains with the caller.
- The full field, value, and method surface is documented by the `std.array_hash_map.String` implementation.

## See Also

- `std.array_hash_map.String`
- `std.ArrayHashMapUnmanaged`
- `std.AutoArrayHashMapUnmanaged`
