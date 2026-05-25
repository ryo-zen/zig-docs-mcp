# std.HashMapUnmanaged

`std.HashMapUnmanaged` is the root namespace alias for `std.hash_map.HashMapUnmanaged`.

## Source Declaration

```zig
pub const HashMapUnmanaged = hash_map.HashMapUnmanaged;
```

## Signature

```zig
pub fn HashMapUnmanaged(
    comptime K: type,
    comptime V: type,
    comptime Context: type,
    comptime max_load_percentage: u64,
) type
```

## Overview

`std.HashMapUnmanaged` returns an unmanaged, open-addressed hash table type. It does not store an allocator; allocation-aware operations receive an allocator argument.

The context type must provide hashing and equality for keys:

```zig
pub fn hash(self: Context, key: K) u64
pub fn eql(self: Context, a: K, b: K) bool
```

Use this type when embedding a map inside another structure or when allocator ownership should stay outside the map value.

## Parameters

- `K`: key type.
- `V`: value type.
- `Context`: hash/equality context type.
- `max_load_percentage`: load threshold before growth; must be between 0 and 100.

## Fields

- `metadata`: pointer to the backing metadata allocation, or null for an empty map.
- `size`: current number of elements.
- `available`: slots available before a grow is required.
- `pointer_stability`: safety lock used to detect pointer invalidation mistakes.

## Notes

- Prefer `.empty` for initialization.
- Pass the allocator to allocating methods and to `deinit()`.
- No iteration order is guaranteed.
- Deletions use tombstones; `rehash()` removes tombstones and invalidates key/value pointers.

## See Also

- `std.hash_map.HashMapUnmanaged`
- `std.HashMap`
- `std.AutoHashMapUnmanaged`
- `std.StringHashMapUnmanaged`
