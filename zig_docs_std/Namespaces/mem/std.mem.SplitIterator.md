# std.mem.SplitIterator

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.SplitIterator.tests.zig)**

## Overview

`SplitIterator` provides forward iteration over delimited sequences, returning each field between delimiters including empty fields. This is the standard splitting iterator and the forward counterpart to `SplitBackwardsIterator`.

Unlike `TokenIterator` which skips empty fields, `SplitIterator` preserves them — consecutive delimiters produce empty slices. This makes it suitable for:
- **CSV/TSV parsing**: Where empty columns are meaningful (`"a,,c"` → `"a"`, `""`, `"c"`)
- **Path splitting**: Breaking paths into components (`"/usr/local/bin"`)
- **Protocol parsing**: Splitting fixed-format messages where field position matters
- **Configuration parsing**: Processing key-value pairs separated by delimiters

**Key difference from `TokenIterator`**: SplitIterator preserves empty fields between consecutive delimiters. TokenIterator skips them.

**Created by**: Use `std.mem.splitScalar()`, `std.mem.splitAny()`, or `std.mem.splitSequence()`.

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

Current position in the buffer, advancing from beginning to end. `null` indicates iteration is complete.

------

`delimiter: switch (delimiter_type) { ... }`

The delimiter value used for splitting. Type varies based on `delimiter_type`:
- `.scalar`: Single value of type `T`
- `.any` / `.sequence`: Slice `[]const T`

## Functions

### `pub fn next(self: *Self) ?[]const T`

Returns the next field moving forward through the buffer, or `null` when iteration is complete.

**Behavior**:
- First call returns the leftmost field
- Subsequent calls return fields moving rightward
- Empty fields between consecutive delimiters are included

**Returns**: `[]const T` slice of the next field, or `null` when done.

**Example**:
```zig
var iter = std.mem.splitScalar(u8, "a,b,c", ',');
// Returns: "a", "b", "c", then null
```

------

### `pub fn first(self: *Self) []const T`

Returns the first field without consuming it. After calling this, use `next()` to get all subsequent fields.

**Asserts**: Iteration has not yet begun (no prior calls to `next()` or `first()`).

**Use when**: You need to peek at or specially handle the first (leftmost) field.

**Example**:
```zig
var iter = std.mem.splitScalar(u8, "a,b,c", ',');
const leftmost = iter.first(); // "a"
// Now use next() to continue: "a", "b", "c"
```

------

### `pub fn peek(self: *Self) ?[]const T`

Returns the next field without advancing the iterator position, or `null` if splitting is complete.

**Does not modify iterator state**: Calling `peek()` multiple times returns the same value. Call `next()` to advance.

**Use when**: You need to inspect the next field before deciding whether to consume it.

**Example**:
```zig
var iter = std.mem.splitScalar(u8, "a,b,c", ',');
_ = iter.next(); // "a"
const peeked = iter.peek().?; // "b" (does not advance)
const next = iter.next().?;   // "b" (same value, now advances)
```

------

### `pub fn rest(self: Self) []const T`

Returns all remaining unprocessed content as a single slice (everything from the current position to the end).

**Does not modify iterator state**: You can call this multiple times or continue calling `next()` afterward.

**Use when**: You want to capture the remainder without further splitting.

**Example**:
```zig
var iter = std.mem.splitScalar(u8, "a,b,c,d", ',');
_ = iter.next(); // "a"
const remaining = iter.rest(); // "b,c,d"
```

------

### `pub fn reset(self: *Self) void`

Resets the iterator to its initial state, allowing re-iteration from the beginning.

**Effect**: Sets position back to the start of the buffer.

**Use when**: You need to iterate over the same buffer multiple times.

## Usage Examples

### Basic Forward Splitting

```zig
const std = @import("std");

var iter = std.mem.splitScalar(u8, "one,two,three", ',');

while (iter.next()) |field| {
    std.debug.print("{s}\n", .{field});
}
// Prints: "one", "two", "three"
```

### CSV Row Parsing (Empty Fields Matter)

```zig
const row = "Alice,,30,Engineer";
var iter = std.mem.splitScalar(u8, row, ',');

const name = iter.next().?;    // "Alice"
const middle = iter.next().?;  // "" (empty — no middle name)
const age = iter.next().?;     // "30"
const role = iter.next().?;    // "Engineer"
```

### Multi-Character Sequence Delimiter

```zig
const input = "key=value;;host=localhost;;port=8080";
var iter = std.mem.splitSequence(u8, input, ";;");

// Yields: "key=value", "host=localhost", "port=8080"
```

### Any-Of Delimiter

```zig
const input = "one,two;three,four";
var iter = std.mem.splitAny(u8, input, ",;");

// Yields: "one", "two", "three", "four"
```

### Comparison with TokenIterator

```zig
const input = "a,,b,,c";

// SplitIterator: preserves empty fields
var split = std.mem.splitScalar(u8, input, ',');
// Yields: "a", "", "b", "", "c"

// TokenIterator: skips empty fields
var token = std.mem.tokenizeScalar(u8, input, ',');
// Yields: "a", "b", "c"
```

## Behavior Notes

**Empty fields are preserved**: Consecutive delimiters produce empty slices.

```zig
var iter = std.mem.splitScalar(u8, "a,,b", ',');
// Returns: "a", "", "b"
```

**Trailing delimiter**: A delimiter at the end of the buffer produces a trailing empty field.

```zig
var iter = std.mem.splitScalar(u8, "a,b,", ',');
// Returns: "a", "b", ""
```

**Leading delimiter**: A delimiter at the start of the buffer produces a leading empty field.

```zig
var iter = std.mem.splitScalar(u8, ",a,b", ',');
// Returns: "", "a", "b"
```

**Empty input**: Returns a single empty field.

```zig
var iter = std.mem.splitScalar(u8, "", ',');
// Returns: "", then null
```

## Performance Considerations

- **Zero-allocation**: Creates views into the existing buffer
- **Single-pass**: O(n) complexity, processes each character once
- **Lazy evaluation**: Only computes the next field when `next()` is called

## See Also

- [std.mem.SplitBackwardsIterator](std.mem.SplitBackwardsIterator.md) - Backward splitting iterator
- [std.mem.TokenIterator](std.mem.TokenIterator.md) - Similar but skips empty sequences
- [std.mem.DelimiterType](std.mem.DelimiterType.md) - Delimiter type documentation
