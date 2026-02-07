# std.json.Scanner

The lowest level parsing API in this package; supports streaming input with a low memory footprint. The memory requirement is `O(d)` where d is the nesting depth of `[]` or `{}` containers in the input. Specifically `d/8` bytes are required for this purpose, with some extra buffer according to the implementation of `std.ArrayList`.

This scanner can emit partial tokens; see `std.json.Token`. The input to this class is a sequence of input buffers that you must supply one at a time. Call `feedInput()` with the first buffer, then call `next()` repeatedly until `error.BufferUnderrun` is returned. Then call `feedInput()` again and so forth. Call `endInput()` when the last input buffer has been given to `feedInput()`, either immediately after calling `feedInput()`, or when `error.BufferUnderrun` requests more data and there is no more. Be sure to call `next()` after calling `endInput()` until `Token.end_of_document` has been returned.

Notes on standards compliance: https://datatracker.ietf.org/doc/html/rfc8259

- RFC 8259 requires JSON documents be valid UTF-8, but makes an allowance for systems that are "part of a closed ecosystem". I have no idea what that's supposed to mean in the context of a standard specification. This implementation requires inputs to be valid UTF-8.
- RFC 8259 contradicts itself regarding whether lowercase is allowed in \u hex digits, but this is probably a bug in the spec, and it's clear that lowercase is meant to be allowed. (RFC 5234 defines HEXDIG to only allow uppercase.)
- When RFC 8259 refers to a "character", I assume they really mean a "Unicode scalar value". See http://www.unicode.org/glossary/#unicode_scalar_value .
- RFC 8259 doesn't explicitly disallow unpaired surrogate halves in \u escape sequences, but vaguely implies that \u escapes are for encoding Unicode "characters" (i.e. Unicode scalar values?), which would mean that unpaired surrogate halves are forbidden. By contrast ECMA-404 (a competing(/compatible?) JSON standard, which JavaScript's JSON.parse() conforms to) explicitly allows unpaired surrogate halves. This implementation forbids unpaired surrogate halves in \u sequences. If a high surrogate half appears in a \u sequence, then a low surrogate half must immediately follow in \u notation.
- RFC 8259 allows implementations to "accept non-JSON forms or extensions". This implementation does not accept any of that.
- RFC 8259 allows implementations to put limits on "the size of texts", "the maximum depth of nesting", "the range and precision of numbers", and "the length and character contents of strings". This low-level implementation does not limit these, except where noted above, and except that nesting depth requires memory allocation. Note that this low-level API does not interpret numbers numerically, but simply emits their source form for some higher level code to make sense of.
- This low-level implementation allows duplicate object keys, and key/value pairs are emitted in the order they appear in the input.

### Fields

    state: State = .value

    string_is_object_key: bool = false

    stack: BitStack

    value_start: usize = undefined

    utf16_code_units: [2]u16 = undefined

    input: []const u8 = ""

    cursor: usize = 0

    is_end_of_input: bool = false

    diagnostics: ?*Diagnostics = null

## Types

- AllocWhen
- Diagnostics
- Reader
- Token
- TokenType

## Values

|  |  |  |
|----|----|----|
| default_buffer_size |  | Used by `json.reader`. |
| default_max_value_len |  | For security, the maximum size allocated to store a single string or number value is limited to 4MiB by default. This limit can be specified by calling `nextAllocMax()` instead of `nextAlloc()`. |

## Functions

`pub fn allocNextIntoArrayList(self: *@This(), value_list: *std.array_list.Managed(u8), when: AllocWhen) AllocIntoArrayListError!?[]const u8`  
Equivalent to `allocNextIntoArrayListMax(value_list, when, default_max_value_len);`

`pub fn allocNextIntoArrayListMax(self: *@This(), value_list: *std.array_list.Managed(u8), when: AllocWhen, max_value_len: usize) AllocIntoArrayListError!?[]const u8`  
The next token type must be either `.number` or `.string`. See `peekNextTokenType()`. When allocation is not necessary with `.alloc_if_needed`, this method returns the content slice from the input buffer, and `value_list` is not touched. When allocation is necessary or with `.alloc_always`, this method concatenates partial tokens into the given `value_list`, and returns `null` once the final `.number` or `.string` token has been written into it. In case of an `error.BufferUnderrun`, partial values will be left in the given value_list. The given `value_list` is never reset by this method, so an `error.BufferUnderrun` situation can be resumed by passing the same array list in again. This method does not indicate whether the token content being returned is for a `.number` or `.string` token type; the caller of this method is expected to know which type of token is being processed.

`pub fn deinit(self: *@This()) void`  

`pub fn enableDiagnostics(self: *@This(), diagnostics: *Diagnostics) void`  

`pub fn endInput(self: *@This()) void`  
Call this when you will no longer call `feedInput()` anymore. This can be called either immediately after the last `feedInput()`, or at any time afterward, such as when getting `error.BufferUnderrun` from `next()`. Don't forget to call `next*()` after `endInput()` until you get `.end_of_document`.

`pub fn ensureTotalStackCapacity(self: *@This(), height: usize) Allocator.Error!void`  
Pre allocate memory to hold the given number of nesting levels. `stackHeight()` up to the given number will not cause allocations.

`pub fn feedInput(self: *@This(), input: []const u8) void`  
Call this whenever you get `error.BufferUnderrun` from `next()`. When there is no more input to provide, call `endInput()`.

`pub fn initCompleteInput(allocator: Allocator, complete_input: []const u8) @This()`  
Use this if your input is a single slice. This is effectively equivalent to:

    initStreaming(allocator);
    feedInput(complete_input);
    endInput();

`pub fn initStreaming(allocator: Allocator) @This()`  
The allocator is only used to track `[]` and `{}` nesting levels.

`pub fn isNumberFormattedLikeAnInteger(value: []const u8) bool`  
For the slice you get from a `Token.number` or `Token.allocated_number`, this function returns true if the number doesn't contain any fraction or exponent components, and is not `-0`. Note, the numeric value encoded by the value may still be an integer, such as `1.0`. This function is meant to give a hint about whether integer parsing or float parsing should be used on the value. This function will not give meaningful results on non-numeric input.

`pub fn next(self: *@This()) NextError!Token`  
See `std.json.Token` for documentation of this function.

`pub fn nextAlloc(self: *@This(), allocator: Allocator, when: AllocWhen) AllocError!Token`  
Equivalent to `nextAllocMax(allocator, when, default_max_value_len);` This function is only available after `endInput()` (or `initCompleteInput()`) has been called. See also `std.json.Token` for documentation of `nextAlloc*()` function behavior.

`pub fn nextAllocMax(self: *@This(), allocator: Allocator, when: AllocWhen, max_value_len: usize) AllocError!Token`  
This function is only available after `endInput()` (or `initCompleteInput()`) has been called. See also `std.json.Token` for documentation of `nextAlloc*()` function behavior.

`pub fn peekNextTokenType(self: *@This()) PeekError!TokenType`  
Seeks ahead in the input until the first byte of the next token (or the end of the input) determines which type of token will be returned from the next `next*()` call. This function is idempotent, only advancing past commas, colons, and inter-token whitespace.

`pub fn skipUntilStackHeight(self: *@This(), terminal_stack_height: usize) NextError!void`  
Skip tokens until an `.object_end` or `.array_end` token results in a `stackHeight()` equal the given stack height. Unlike `skipValue()`, this function is available in streaming mode.

`pub fn skipValue(self: *@This()) SkipError!void`  
This function is only available after `endInput()` (or `initCompleteInput()`) has been called. If the next token type is `.object_begin` or `.array_begin`, this function calls `next()` repeatedly until the corresponding `.object_end` or `.array_end` is found. If the next token type is `.number` or `.string`, this function calls `next()` repeatedly until the (non `.partial_*`) `.number` or `.string` token is found. If the next token type is `.true`, `.false`, or `.null`, this function calls `next()` once. The next token type must not be `.object_end`, `.array_end`, or `.end_of_document`; see `peekNextTokenType()`.

`pub fn stackHeight(self: *const @This()) usize`  
The depth of `{}` or `[]` nesting levels at the current position.

`pub fn validate(allocator: Allocator, s: []const u8) Allocator.Error!bool`  
Scan the input and check for malformed JSON. On `SyntaxError` or `UnexpectedEndOfInput`, returns `false`. Returns any errors from the allocator as-is, which is unlikely, but can be caused by extreme nesting depth in the input.

## Error Sets

- AllocError
- AllocIntoArrayListError
- Error
- NextError
- PeekError
- SkipError
