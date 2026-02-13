# std.json.dynamic.Value

Represents any JSON value, potentially containing other JSON values. A .float value may be an approximation of the original value. Arbitrary precision numbers can be represented by .number_string values. See also `std.json.ParseOptions.parse_numbers`.

### Fields

    null

    bool: bool

    integer: i64

    float: f64

    number_string: []const u8

    string: []const u8

    array: Array

    object: ObjectMap

## Functions

`pub fn dump(v: Value) void`

`pub fn jsonParse(allocator: Allocator, source: anytype, options: ParseOptions) ParseError(@TypeOf(source.*))!@This()`

`pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This()`

`pub fn jsonStringify(value: @This(), jws: anytype) !void`

`pub fn parseFromNumberSlice(s: []const u8) Value`
