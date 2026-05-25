# std.HashMap

`std.HashMap` is the root namespace alias for `std.hash_map.HashMap`.

## Source Declaration

```zig
pub const HashMap = hash_map.HashMap;
```

## Signature

```zig
pub fn HashMap(
    comptime K: type,
    comptime V: type,
    comptime Context: type,
    comptime max_load_percentage: u64,
) type
```

## Overview

`std.HashMap` returns a managed, general-purpose hash table type. It stores an allocator, a context value, and an unmanaged backing map.

The context type must provide hashing and equality for keys:

```zig
pub fn hash(self: Context, key: K) u64
pub fn eql(self: Context, a: K, b: K) bool
```

Use `std.HashMap` when custom hashing or equality is required. Use `std.AutoHashMap` when the default automatic context is sufficient, or `std.StringHashMap` for string slice keys.

## Parameters

- `K`: key type.
- `V`: value type.
- `Context`: hash/equality context type.
- `max_load_percentage`: load threshold before growth; must be between 0 and 100.

## Notes

- No iteration order is guaranteed.
- Modifying the map invalidates live iterators.
- The managed map stores the allocator and passes it to the underlying unmanaged map.
- If ordered iteration matters, consider `std.array_hash_map.ArrayHashMap`.

## See Also

- `std.hash_map.HashMap`
- `std.HashMapUnmanaged`
- `std.AutoHashMap`
- `std.StringHashMap`
