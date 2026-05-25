# std.StringHashMapUnmanaged

`std.StringHashMapUnmanaged` is the root namespace alias for `std.hash_map.StringHashMapUnmanaged`.

## Source Declaration

```zig
pub const StringHashMapUnmanaged = hash_map.StringHashMapUnmanaged;
```

## Signature

```zig
pub fn StringHashMapUnmanaged(comptime V: type) type
```

## Overview

`std.StringHashMapUnmanaged(V)` returns an unmanaged hash map type specialized for `[]const u8` string keys.

It expands to `std.HashMapUnmanaged([]const u8, V, std.hash_map.StringContext, std.hash_map.default_max_load_percentage)`.

The map hashes and compares string contents. It does not store an allocator, and key/value memory ownership remains with the caller.

## Parameters

- `V`: value type.

## Notes

- Use `.empty` for initialization.
- Pass an allocator to allocating methods and `deinit()`.
- Use this instead of `std.AutoHashMapUnmanaged([]const u8, V)`.
- No iteration order is guaranteed.

## See Also

- `std.hash_map.StringHashMapUnmanaged`
- `std.StringHashMap`
- `std.HashMapUnmanaged`
- `std.AutoHashMapUnmanaged`
