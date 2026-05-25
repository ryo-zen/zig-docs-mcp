# std.AutoHashMap

`std.AutoHashMap` is the root namespace alias for `std.hash_map.AutoHashMap`.

## Source Declaration

```zig
pub const AutoHashMap = hash_map.AutoHashMap;
```

## Signature

```zig
pub fn AutoHashMap(comptime K: type, comptime V: type) type
```

## Overview

`std.AutoHashMap(K, V)` returns a managed hash map type that stores its allocator and automatically chooses hash and equality functions for `K`.

It expands to `std.HashMap(K, V, std.hash_map.AutoContext(K), std.hash_map.default_max_load_percentage)`.

Use this for general-purpose key-value storage when the key type works with Zig's automatic hashing. For string slice keys, use `std.StringHashMap` because automatic hashing rejects `[]const u8` keys to avoid ambiguous pointer-versus-content hashing.

## Parameters

- `K`: key type.
- `V`: value type.

## Notes

- The map does not guarantee iteration order.
- Insertions and removals can invalidate live iterators and stored key/value pointers.
- Call `deinit()` when finished; keys and values that own memory still need to be released by the caller.

## See Also

- `std.hash_map.AutoHashMap`
- `std.AutoHashMapUnmanaged`
- `std.HashMap`
- `std.StringHashMap`
