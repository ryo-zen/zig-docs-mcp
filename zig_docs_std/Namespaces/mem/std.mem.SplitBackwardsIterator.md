# std.mem.SplitBackwardsIterator

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.SplitBackwardsIterator.tests.zig)**

## Overview

`SplitBackwardsIterator` provides reverse iteration over delimited sequences, starting from the end of a buffer and moving toward the beginning. This is the backward-iterating counterpart to `SplitIterator`.

Unlike forward splitting which returns fields left-to-right, backward splitting returns fields right-to-left. This is particularly useful for:
- **Path parsing**: Extracting filename from a path (`/path/to/file.txt` → `file.txt` first)
- **Log processing**: Reading most recent entries first
- **URL parsing**: Getting query parameters or path segments from the end
- **Reverse tokenization**: Processing data in reverse order without building intermediate arrays

**Key difference from `SplitIterator`**: Same interface and behavior, but iterates from end to beginning.

**Created by**: Use functions like `std.mem.splitBackwardsScalar()`, `std.mem.splitBackwardsAny()`, or `std.mem.splitBackwardsSequence()`.

## Parameters

`T: type`

The element type of the buffer being split (commonly `u8` for strings).

------

`delimiter_type: DelimiterType`

Compile-time parameter controlling delimiter interpretation:
- `.scalar`: Single character delimiter
- `.any`: Any character from a set
- `.sequence`: Exact substring match

See [std.mem.DelimiterType](std.mem.DelimiterType.md) for details.

## Fields

`buffer: []const T`

The complete input buffer being split. The iterator provides read-only views into this buffer.

------

`index: ?usize`

Current position in the buffer, moving from end toward beginning. `null` indicates iteration is complete.

------

`delimiter: switch (delimiter_type) { ... }`

The delimiter value used for splitting. Type varies based on `delimiter_type`:
- `.scalar`: Single value of type `T`
- `.any` / `.sequence`: Slice `[]const T`

## Functions

### `pub fn next(self: *Self) ?[]const T`

Returns the next field moving backward through the buffer, or `null` when iteration is complete.

**Behavior**:
- First call returns the rightmost field
- Subsequent calls return fields moving leftward
- Empty fields between consecutive delimiters are included

**Returns**: `[]const T` slice of the next field, or `null` when done.

**Example**:
```zig
var iter = std.mem.splitBackwardsScalar(u8, "a,b,c", ',');
// Returns: "c", "b", "a", then null
```

------

### `pub fn first(self: *Self) []const T`

Returns the first field without consuming it. After calling this, use `next()` to get all subsequent fields.

**Asserts**: Iteration has not yet begun (no prior calls to `next()` or `first()`).

**Use when**: You need to peek at or specially handle the first (rightmost) field.

**Example**:
```zig
var iter = std.mem.splitBackwardsScalar(u8, "a,b,c", ',');
const rightmost = iter.first(); // "c"
// Now use next() to continue: "c", "b", "a"
```

------

### `pub fn rest(self: Self) []const T`

Returns all remaining unprocessed fields as a single slice (everything from the current position to the beginning).

**Does not modify iterator state**: You can call this multiple times or continue calling `next()` afterward.

**Use when**: You want to capture the remainder without further splitting.

------

### `pub fn reset(self: *Self) void`

Resets the iterator to its initial state, allowing re-iteration from the end.

**Effect**: Sets position back to the end of the buffer.

**Use when**: You need to iterate over the same buffer multiple times.

## Usage Examples

### Basic Backward Splitting

```zig
const std = @import("std");

var iter = std.mem.splitBackwardsScalar(u8, "one,two,three", ',');

// Iterate from right to left
while (iter.next()) |field| {
    std.debug.print("{s}\n", .{field});
}
// Prints: "three", "two", "one"
```

### Path Processing (Extract Filename)

```zig
const path = "/usr/local/bin/myapp";
var iter = std.mem.splitBackwardsScalar(u8, path, '/');

const filename = iter.next().?; // "myapp" (rightmost component)
const directory = iter.next().?; // "bin"
```

### Comparison with Forward Splitting

```zig
const input = "a::b::c";

// Forward iteration
var forward = std.mem.splitSequence(u8, input, "::");
// Yields: "a", "b", "c"

// Backward iteration
var backward = std.mem.splitBackwardsSequence(u8, input, "::");
// Yields: "c", "b", "a"
```

## Behavior Notes

**Empty fields are preserved**: Consecutive delimiters produce empty slices, just like `SplitIterator`.

```zig
var iter = std.mem.splitBackwardsScalar(u8, "a,,b", ',');
// Returns: "b", "", "a"
```

**Trailing delimiter**: A delimiter at the start of the buffer produces an empty field.

```zig
var iter = std.mem.splitBackwardsScalar(u8, ",a,b", ',');
// Returns: "b", "a", ""
```

## Performance Considerations

- **Zero-allocation**: Creates views into the existing buffer
- **Single-pass**: O(n) complexity, processes each character once
- **Same cost as forward splitting**: Backward iteration is no slower than forward

## See Also

- [std.mem.SplitIterator](std.mem.SplitIterator.md) - Forward splitting iterator
- [std.mem.TokenIterator](std.mem.TokenIterator.md) - Similar but skips empty sequences
- [std.mem.DelimiterType](std.mem.DelimiterType.md) - Delimiter type documentation
