# std.StringHashMap

`std.StringHashMap` is the root namespace alias for `std.hash_map.StringHashMap`.

## Source Declaration

```zig
pub const StringHashMap = hash_map.StringHashMap;
```

## Signature

```zig
pub fn StringHashMap(comptime V: type) type
```

## Overview

`std.StringHashMap(V)` returns a managed hash map type specialized for `[]const u8` string keys.

It expands to `std.HashMap([]const u8, V, std.hash_map.StringContext, std.hash_map.default_max_load_percentage)`.

The map hashes and compares string contents. Key memory is managed by the caller; keys and values are not automatically freed by `deinit()`.

## Parameters

- `V`: value type.

## Notes

- Use this instead of `std.AutoHashMap([]const u8, V)`.
- The map stores an allocator internally.
- No iteration order is guaranteed.
- Any owned key or value memory must be released by the caller before or after map deinitialization as appropriate.

## See Also

- `std.hash_map.StringHashMap`
- `std.StringHashMapUnmanaged`
- `std.HashMap`
- `std.AutoHashMap`
