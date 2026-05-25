# std.AutoHashMapUnmanaged

`std.AutoHashMapUnmanaged` is the root namespace alias for `std.hash_map.AutoHashMapUnmanaged`.

## Source Declaration

```zig
pub const AutoHashMapUnmanaged = hash_map.AutoHashMapUnmanaged;
```

## Signature

```zig
pub fn AutoHashMapUnmanaged(comptime K: type, comptime V: type) type
```

## Overview

`std.AutoHashMapUnmanaged(K, V)` returns an unmanaged hash map type with automatic hash and equality functions for `K`.

It expands to `std.HashMapUnmanaged(K, V, std.hash_map.AutoContext(K), std.hash_map.default_max_load_percentage)`.

Use this when the map should not store an allocator. Allocating operations take an allocator argument, and the same allocator should be passed to `deinit()`.

## Parameters

- `K`: key type.
- `V`: value type.

## Notes

- The map starts empty with `.empty`.
- The map does not guarantee iteration order.
- Insertions and removals can invalidate live iterators and stored key/value pointers.
- For string slice keys, use `std.StringHashMapUnmanaged` rather than automatic hashing.

## See Also

- `std.hash_map.AutoHashMapUnmanaged`
- `std.AutoHashMap`
- `std.HashMapUnmanaged`
- `std.StringHashMapUnmanaged`
