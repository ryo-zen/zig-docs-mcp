# std.Uri

`std.Uri` is the root import of `Uri.zig`, a URI parser and formatter that roughly follows RFC 3986 while accepting common real-world URI forms.

## Source Declaration

```zig
pub const Uri = @import("Uri.zig");
```

## Data Fields

- `scheme: []const u8`
- `user: ?Component = null`
- `password: ?Component = null`
- `host: ?Component = null`
- `port: ?u16 = null`
- `path: Component = Component.empty`
- `query: ?Component = null`
- `fragment: ?Component = null`

Parsed components point into the original input text unless the caller constructs a `Uri` manually.

## Nested Types

### `Component`

```zig
pub const Component = union(enum) {
    raw: []const u8,
    percent_encoded: []const u8,
};
```

`raw` components are percent-escaped when formatted. `percent_encoded` components are written as already escaped text. `Component.empty` is a percent-encoded empty component.

### `Format`

`Format` stores a URI pointer and `Format.Flags` that choose which parts to write. `Format.Flags.all` enables scheme, authentication, authority, path, query, fragment, and port output.

## Error Sets

### `GetHostError`

```zig
pub const GetHostError = error{UriMissingHost};
```

### `ParseError`

```zig
pub const ParseError = error{
    UnexpectedCharacter,
    InvalidFormat,
    InvalidPort,
    InvalidHostName,
};
```

### `ResolveInPlaceError`

```zig
pub const ResolveInPlaceError = ParseError || error{NoSpaceLeft};
```

## Core Functions

### `pub fn parse(text: []const u8) ParseError!Uri`

Parses a full URI with a required scheme. The returned component slices point into `text`.

### `pub fn parseAfterScheme(scheme: []const u8, text: []const u8) ParseError!Uri`

Parses the portion after a known scheme. This is used for URI forms found in the wild, such as HTTP Location headers.

### `pub fn resolveInPlace(base: Uri, new_len: usize, aux_buf: *[]u8) ResolveInPlaceError!Uri`

Resolves a URI reference against `base` using RFC 3986 section 5 rules. The new location must already be copied to the start of `aux_buf.*`.

### `pub fn percentDecodeInPlace(buffer: []u8) []u8`

Percent-decodes valid `%XX` sequences in place and returns the decoded subslice.

### `pub fn percentDecodeBackwards(output: []u8, input: []const u8) []u8`

Percent-decodes valid `%XX` sequences into `output` from the end toward the front. `output` may alias `input` when `output.ptr <= input.ptr`.

### `pub fn writeToStream(uri: *const Uri, writer: *Writer, flags: Format.Flags) Writer.Error!void`

Writes selected URI parts to a writer.

### `pub fn fmt(uri: *const Uri, flags: Format.Flags) std.fmt.Alt(Format, Format.default)`

Returns a formatting adapter for use with formatted output.

### `pub fn getHost(uri: Uri, buffer: *[HostName.max_len]u8) GetHostError!HostName`

Returns a validated host name, using `buffer` only when decoding is required.

### `pub fn getHostAlloc(uri: Uri, arena: Allocator) GetHostAllocError!HostName`

Returns a validated host name, allocating from `arena` only when decoding is required.

## Notes

- `parse` requires a valid scheme followed by `:`.
- Host parsing accepts IPv6 bracket notation and optional ports.
- Formatting escapes raw components with rules specific to each URI part.
- `resolveInPlace` mutates its auxiliary buffer while removing dot segments and merging paths.

## See Also

- `std.fmt`
- `std.Io.Writer`
