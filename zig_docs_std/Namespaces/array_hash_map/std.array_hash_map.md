# std.array_hash_map

## Overview

`std.array_hash_map` provides ordered hash maps whose keys and values are stored sequentially. Insertion order is preserved, and the backing storage supports many operations similar to an array list.

Source: `/path/to/zig-0.16.0/lib/std/array_hash_map.zig`

## Public API

### Map Constructors

- `std.array_hash_map.Auto(K, V)` - ordered hash map using the default context for key type `K`.
- `std.array_hash_map.String(V)` - ordered hash map with `[]const u8` string keys.
- `std.array_hash_map.Custom(K, V, Context, store_hash)` - ordered hash map with caller-provided hashing and equality behavior.
- `std.array_hash_map.ArrayHashMap` - deprecated alias for `Custom`.

### String Helpers

- `std.array_hash_map.StringContext` - context used by `String(V)`.
- `std.array_hash_map.eqlString(a, b)` - string equality helper.
- `std.array_hash_map.hashString(s)` - string hash helper using Wyhash.

### Context Helpers

- `std.array_hash_map.getHashPtrAddrFn(K, Context)`
- `std.array_hash_map.getTrivialEqlFn(K, Context)`
- `std.array_hash_map.AutoContext(K)`
- `std.array_hash_map.getAutoHashFn(K, Context)`
- `std.array_hash_map.getAutoEqlFn(K, Context)`
- `std.array_hash_map.autoEqlIsCheap(K)`
- `std.array_hash_map.getAutoHashStratFn(K, Context, strategy)`

## Custom Context Contract

`Custom` expects a context namespace with:

```zig
pub fn hash(self, key: K) u32
pub fn eql(self, a: K, b: K, b_index: usize) bool
```

The `b_index` argument is the index of the key already stored in the map.

## Notes

Use this namespace when iteration order matters. For unordered hash maps, see `std.hash_map` or the root hash map aliases such as `std.AutoHashMap`.
