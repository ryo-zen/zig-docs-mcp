# std.hash_map

## Types

- AutoContext
- AutoHashMap
- AutoHashMapUnmanaged
- HashMap
- HashMapUnmanaged
- StringHashMap
- StringHashMapUnmanaged
- StringIndexAdapter
- StringIndexContext

## Namespaces

- StringContext

## Values

|                             |     |     |
|-----------------------------|-----|-----|
| default_max_load_percentage |     |     |

## Functions

`pub fn eqlString(a: []const u8, b: []const u8) bool`  

`pub fn getAutoEqlFn(comptime K: type, comptime Context: type) (fn (Context, K, K) bool)`  

`pub fn getAutoHashFn(comptime K: type, comptime Context: type) (fn (Context, K) u64)`  

`pub fn hashString(s: []const u8) u64`  
