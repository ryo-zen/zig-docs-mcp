# std.StaticStringMapWithEql

`std.StaticStringMapWithEql` is the root namespace alias for `std.static_string_map.StaticStringMapWithEql`.

## Source Declaration

```zig
pub const StaticStringMapWithEql = static_string_map.StaticStringMapWithEql;
```

## Signature

```zig
pub fn StaticStringMapWithEql(
    comptime V: type,
    comptime eql: fn (a: []const u8, b: []const u8) bool,
) type
```

## Overview

`std.StaticStringMapWithEql(V, eql)` returns the same fixed-key string map shape as `std.StaticStringMap`, but uses a caller-provided equality function.

The equality function is called only for strings with equal lengths. Strings with different lengths are rejected before equality is evaluated.

Use this for case-insensitive or otherwise customized string comparisons over a fixed key set.

## Parameters

- `V`: value type.
- `eql`: equality function for equal-length strings.

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

- `std.static_string_map.StaticStringMapWithEql`
- `std.StaticStringMap`
