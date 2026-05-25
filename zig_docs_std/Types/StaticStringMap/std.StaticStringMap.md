# std.StaticStringMap

`std.StaticStringMap` is the root namespace alias for `std.static_string_map.StaticStringMap`.

## Source Declaration

```zig
pub const StaticStringMap = static_string_map.StaticStringMap;
```

## Signature

```zig
pub fn StaticStringMap(comptime V: type) type
```

## Overview

`std.StaticStringMap(V)` returns a string-keyed lookup table optimized for small, fixed key sets.

The map separates keys by length during initialization, so runtime lookup only compares strings with the same length. The default equality function is case-sensitive and equivalent to byte equality for equal-length strings.

Use `initComptime()` for maps backed by comptime-allocated memory, or `init()` for maps backed by an allocator.

## Parameters

- `V`: value type.

## Fields

- `kvs`: pointer to sorted key/value storage.
- `len_indexes`: index table by string length.
- `len_indexes_len`: number of length-index entries.
- `min_len`: shortest key length.
- `max_len`: longest key length.

## Functions

- `initComptime(kvs_list)`: returns a map backed by static, comptime allocated memory.
- `init(kvs_list, allocator)`: returns a map backed by allocator-owned memory.
- `deinit(allocator)`: releases storage created by `init()`.
- `has(str)`: checks whether a key exists.
- `get(str)`: returns the value for a key, or null.
- `getIndex(str)`: returns the index for a key, or null.
- `getLongestPrefix(str)`: returns the key/value pair with the longest key prefix of `str`.
- `getLongestPrefixIndex(str)`: returns the index of the longest matching prefix.
- `keys()`: returns the stored keys.
- `values()`: returns the stored values.

## See Also

- `std.static_string_map.StaticStringMap`
- `std.StaticStringMapWithEql`
