# std.json.Stringify

Writes JSON (RFC8259) formatted data to a stream.

The sequence of method calls to write JSON content must follow this grammar:

     <once> = <value>
     <value> =
       | <object>
       | <array>
       | write
       | print
       | <writeRawStream>
     <object> = beginObject ( <field> <value> )* endObject
     <field> = objectField | objectFieldRaw | <objectFieldRawStream>
     <array> = beginArray ( <value> )* endArray
     <writeRawStream> = beginWriteRaw ( stream.writeAll )* endWriteRaw
     <objectFieldRawStream> = beginObjectFieldRaw ( stream.writeAll )* endObjectFieldRaw

### Fields

    writer: *Writer

    options: Options = .{}

    indent_level: usize = 0

    next_punctuation: enum {
        the_beginning,
        none,
        comma,
        colon,
    } = .the_beginning

    nesting_stack: switch (safety_checks) {
        .checked_to_fixed_depth => |fixed_buffer_size| [(fixed_buffer_size + 7) >> 3]u8,
        .assumed_correct => void,
    } = switch (safety_checks) {
        .checked_to_fixed_depth => @splat(0),
        .assumed_correct => {},
    }

    raw_streaming_mode: if (build_mode_has_safety)
        enum { none, value, objectField }
    else
        void = if (build_mode_has_safety) .none else {}

## Types

- Options

## Functions

`pub fn beginArray(self: *Stringify) Error!void`  

`pub fn beginObject(self: *Stringify) Error!void`  

`pub fn beginObjectFieldRaw(self: *Stringify) !void`  
In the rare case that you need to write very long object field names, this is an alternative to `objectField` and `objectFieldRaw` that allows you to write directly to the `.writer` field similar to `beginWriteRaw`. Call `endObjectFieldRaw()` when you're done.

`pub fn beginWriteRaw(self: *Stringify) !void`  
An alternative to calling `write` that allows you to write directly to the `.writer` field, e.g. with `.writer.writeAll()`. Call `beginWriteRaw()`, then write a complete value (including any quotes if necessary) directly to the `.writer` field, then call `endWriteRaw()`. This can be useful for streaming very long strings into the output without needing it all buffered in memory.

`pub fn encodeJsonString(string: []const u8, options: Options, writer: *Writer) Error!void`  
Write `string` to `writer` as a JSON encoded string.

`pub fn encodeJsonStringChars(chars: []const u8, options: Options, writer: *Writer) Error!void`  
Write `chars` to `writer` as JSON encoded string characters.

`pub fn endArray(self: *Stringify) Error!void`  

`pub fn endObject(self: *Stringify) Error!void`  

`pub fn endObjectFieldRaw(self: *Stringify) void`  
See `beginObjectFieldRaw`.

`pub fn endWriteRaw(self: *Stringify) void`  
See `beginWriteRaw`.

`pub fn jsonStringify(v: @This(), jws: anytype) !void`  

`pub fn objectField(self: *Stringify, key: []const u8) Error!void`  
See `Stringify` for when to call this method. `key` is the string content of the property name. Surrounding quotes will be added and any special characters will be escaped. See also `objectFieldRaw`.

`pub fn objectFieldRaw(self: *Stringify, quoted_key: []const u8) Error!void`  
See `Stringify` for when to call this method. `quoted_key` is the complete bytes of the key including quotes and any necessary escape sequences. A few assertions are performed on the given value to ensure that the caller of this function understands the API contract. See also `objectField`.

`pub fn print(self: *Stringify, comptime fmt: []const u8, args: anytype) Error!void`  
An alternative to calling `write` that formats a value with `std.fmt`. This function does the usual punctuation and indentation formatting assuming the resulting formatted string represents a single complete value; e.g. `"1"`, `"[]"`, `"[1,2]"`, not `"1,2"`. This function may be useful for doing your own number formatting.

`pub fn value(v: anytype, options: Options, writer: *Writer) Error!void`  
Writes the given value to the `Writer` writer. See `Stringify` for how the given value is serialized into JSON. The maximum nesting depth of the output JSON document is 256.

`pub fn valueAlloc(gpa: Allocator, v: anytype, options: Options) error{OutOfMemory}![]u8`  
Calls `value` and stores the result in dynamically allocated memory instead of taking a writer.

`pub fn write(self: *Stringify, v: anytype) Error!void`  
Renders the given Zig value as JSON.

## Error Sets

- Error
