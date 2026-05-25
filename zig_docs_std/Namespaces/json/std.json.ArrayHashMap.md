# std.json.ArrayHashMap

A thin wrapper around `std.StringArrayHashMapUnmanaged` that implements `jsonParse`, `jsonParseFromValue`, and `jsonStringify`. This is useful when your JSON schema has an object with arbitrary data keys instead of comptime-known struct field names.

## Parameters

    T: type

### Fields

    map: std.StringArrayHashMapUnmanaged(T) = .empty

## Functions

`pub fn deinit(self: *@This(), allocator: Allocator) void`

`pub fn jsonParse(allocator: Allocator, source: anytype, options: ParseOptions) !@This()`

`pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This()`

`pub fn jsonStringify(self: @This(), jws: anytype) !void`
