# std.json.Scanner.Token

The tokens emitted by `std.json.Scanner` and `std.json.Reader` `.next*()` functions follow this grammar:

     <document> = <value> .end_of_document
     <value> =
 | <object>
 | <array>
 | <number>
 | <string>
 | .true
 | .false
 | .null
     <object> = .object_begin ( <string> <value> )* .object_end
     <array> = .array_begin ( <value> )* .array_end
     <number> = <It depends. See below.>
     <string> = <It depends. See below.>

What you get for `<number>` and `<string>` values depends on which `next*()` method you call:

    next():
     <number> = ( .partial_number )* .number
     <string> = ( <partial_string> )* .string
     <partial_string> =
 | .partial_string
 | .partial_string_escaped_1
 | .partial_string_escaped_2
 | .partial_string_escaped_3
 | .partial_string_escaped_4

    nextAlloc*(..., .alloc_always):
     <number> = .allocated_number
     <string> = .allocated_string

    nextAlloc*(..., .alloc_if_needed):
     <number> =
 | .number
 | .allocated_number
     <string> =
 | .string
 | .allocated_string

For all tokens with a `[]const u8`, `[]u8`, or `[n]u8` payload, the payload represents the content of the value. For number values, this is the representation of the number exactly as it appears in the input. For strings, this is the content of the string after resolving escape sequences.

For `.allocated_number` and `.allocated_string`, the `[]u8` payloads are allocations made with the given allocator. You are responsible for managing that memory. `json.Reader.deinit()` does *not* free those allocations.

The `.partial_*` tokens indicate that a value spans multiple input buffers or that a string contains escape sequences. To get a complete value in memory, you need to concatenate the values yourself. Calling `nextAlloc*()` does this for you, and returns an `.allocated_*` token with the result.

For tokens with a `[]const u8` payload, the payload is a slice into the current input buffer. The memory may become undefined during the next call to `json.Scanner.feedInput()` or any `json.Reader` method whose return error set includes `json.Error`. To keep the value persistently, it recommended to make a copy or to use `.alloc_always`, which makes a copy for you.

Note that `.number` and `.string` tokens that follow `.partial_*` tokens may have `0` length to indicate that the previously partial value is completed with no additional bytes. (This can happen when the break between input buffers happens to land on the exact end of a value. E.g. `"[1234"`, `"]"`.) `.partial_*` tokens never have `0` length.

The recommended strategy for using the different `next*()` methods is something like this:

When you're expecting an object key, use `.alloc_if_needed`. You often don't need a copy of the key string to persist; you might just check which field it is. In the case that the key happens to require an allocation, free it immediately after checking it.

When you're expecting a meaningful string value (such as on the right of a `:`), use `.alloc_always` in order to keep the value valid throughout parsing the rest of the document.

When you're expecting a number value, use `.alloc_if_needed`. You're probably going to be parsing the string representation of the number into a numeric representation, so you need the complete string representation only temporarily.

When you're skipping an unrecognized value, use `skipValue()`.

### Fields

    object_begin

    object_end

    array_begin

    array_end

    true

    false

    null

    number: []const u8

    partial_number: []const u8

    allocated_number: []u8

    string: []const u8

    partial_string: []const u8

    partial_string_escaped_1: [1]u8

    partial_string_escaped_2: [2]u8

    partial_string_escaped_3: [3]u8

    partial_string_escaped_4: [4]u8

    allocated_string: []u8

    end_of_document
