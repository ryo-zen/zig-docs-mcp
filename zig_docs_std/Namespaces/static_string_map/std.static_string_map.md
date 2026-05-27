# std.static_string_map

## Overview

`std.static_string_map` provides maps optimized for small sets of string keys. It separates keys by length during initialization and only compares strings of equal length at lookup time.

Source: `/path/to/zig-0.16.0/lib/std/static_string_map.zig`

## Public API

- `std.static_string_map.StaticStringMap(V)` - string map using default byte equality.
- `std.static_string_map.StaticStringMapWithEql(V, eql)` - string map with a caller-provided equality function.
- `std.static_string_map.defaultEql(a, b)` - equality function for equal-length byte strings.
- `std.static_string_map.eqlAsciiIgnoreCase(a, b)` - ASCII case-insensitive equality for equal-length strings.

## Initialization

The generated map type supports:

- `initComptime(kvs_list)` - returns a map backed by comptime-allocated memory.
- `init(kvs_list, allocator)` - returns a map backed by allocator-owned memory.
- `deinit(allocator)` - releases memory for allocator-backed maps.

`kvs_list` is a list of key-value tuples. If the value type is `void`, entries may contain only keys.

## Use Cases

Use this namespace for compact keyword tables, protocol token lookup, file-extension tables, or other mostly-static string lookup sets.
