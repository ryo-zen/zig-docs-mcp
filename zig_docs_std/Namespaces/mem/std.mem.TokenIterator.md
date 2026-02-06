# std.mem.TokenIterator

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.TokenIterator.tests.zig)**

## Overview

`TokenIterator` provides forward iteration over tokens in a buffer, skipping empty sequences between delimiters. This is the tokenization counterpart to `SplitIterator`.

Where `SplitIterator` preserves empty fields between consecutive delimiters, `TokenIterator` treats consecutive delimiters as a single separator and skips them. This makes it ideal for:
- **Whitespace-separated parsing**: Handling variable amounts of whitespace between words
- **Shell-like argument splitting**: Where multiple spaces between arguments are irrelevant
- **Natural language processing**: Extracting words from text with irregular spacing
- **Log parsing**: Extracting fields from space-padded log formats

**Key difference from `SplitIterator`**: TokenIterator skips empty sequences — consecutive delimiters are treated as one. SplitIterator preserves them.

**Created by**: Use `std.mem.tokenizeScalar()`, `std.mem.tokenizeAny()`, or `std.mem.tokenizeSequence()`.

## Parameters

`T: type`

The element type of the buffer being tokenized (commonly `u8` for strings).

------

`delimiter_type: DelimiterType`

Compile-time parameter controlling delimiter interpretation:
- `.scalar`: Single character delimiter
- `.any`: Any character from a set
- `.sequence`: Exact substring match

See [std.mem.DelimiterType](std.mem.DelimiterType.md) for details.

## Fields

`buffer: []const T`

The complete input buffer being tokenized. The iterator provides read-only views into this buffer.

------

`index: usize`

Current position in the buffer. Unlike `SplitIterator`, this is never `null` — it uses `buffer.len` to indicate completion rather than an optional.

------

`delimiter: switch (delimiter_type) { ... }`

The delimiter value used for tokenization. Type varies based on `delimiter_type`:
- `.scalar`: Single value of type `T`
- `.any` / `.sequence`: Slice `[]const T`

## Functions

### `pub fn next(self: *Self) ?[]const T`

Returns the next non-empty token, or `null` when tokenization is complete.

**Behavior**:
- Skips over any leading delimiters before finding the next token
- Returns the content between the current position and the next delimiter
- Consecutive delimiters are treated as a single separator

**Returns**: `[]const T` slice of the next token, or `null` when done.

**Example**:
```zig
var iter = std.mem.tokenizeScalar(u8, "  hello  world  ", ' ');
// Returns: "hello", "world", then null
```

------

### `pub fn peek(self: *Self) ?[]const T`

Returns the next token without advancing the iterator position, or `null` if tokenization is complete.

**Does not modify iterator state**: Calling `peek()` multiple times returns the same value. Call `next()` to advance.

**Use when**: You need to inspect the next token before deciding whether to consume it.

**Example**:
```zig
var iter = std.mem.tokenizeScalar(u8, "a b c", ' ');
_ = iter.next(); // "a"
const peeked = iter.peek().?; // "b" (does not advance)
const next = iter.next().?;   // "b" (same value, now advances)
```

------

### `pub fn rest(self: Self) []const T`

Returns all remaining unprocessed content as a single slice (everything from the current position to the end).

**Does not modify iterator state**: You can call this multiple times or continue calling `next()` afterward.

**Note**: The returned slice may start with delimiter characters if the iterator has not yet skipped past them.

**Use when**: You want to capture the remainder without further tokenization.

**Example**:
```zig
var iter = std.mem.tokenizeScalar(u8, "one two three", ' ');
_ = iter.next(); // "one"
const remaining = iter.rest(); // "two three"
```

------

### `pub fn reset(self: *Self) void`

Resets the iterator to its initial state, allowing re-iteration from the beginning.

**Effect**: Sets position back to the start of the buffer.

**Use when**: You need to iterate over the same buffer multiple times.

## Usage Examples

### Basic Tokenization

```zig
const std = @import("std");

var iter = std.mem.tokenizeScalar(u8, "  hello   world  ", ' ');

while (iter.next()) |token| {
    std.debug.print("{s}\n", .{token});
}
// Prints: "hello", "world"
```

### Whitespace-Separated Word Extraction

```zig
const text = "  The   quick   brown   fox  ";
var iter = std.mem.tokenizeScalar(u8, text, ' ');

// Yields: "The", "quick", "brown", "fox"
// Leading, trailing, and multiple spaces are all skipped
```

### Multi-Delimiter Tokenization

```zig
// Tokenize by any whitespace-like character
const input = "word1\tword2  word3\nword4";
var iter = std.mem.tokenizeAny(u8, input, " \t\n");

// Yields: "word1", "word2", "word3", "word4"
```

### Sequence Delimiter

```zig
const input = "first---second---third";
var iter = std.mem.tokenizeSequence(u8, input, "---");

// Yields: "first", "second", "third"
```

### Comparison with SplitIterator

```zig
const input = "a,,b,,c";

// TokenIterator: skips empty fields
var token = std.mem.tokenizeScalar(u8, input, ',');
// Yields: "a", "b", "c"

// SplitIterator: preserves empty fields
var split = std.mem.splitScalar(u8, input, ',');
// Yields: "a", "", "b", "", "c"
```

### Shell-Like Argument Parsing

```zig
const command = "ls   -la    /usr/local/bin";
var iter = std.mem.tokenizeScalar(u8, command, ' ');

const program = iter.next().?; // "ls"
const flag = iter.next().?;    // "-la"
const path = iter.next().?;    // "/usr/local/bin"
```

## Behavior Notes

**Consecutive delimiters are skipped**: Unlike `SplitIterator`, no empty fields are produced.

```zig
var iter = std.mem.tokenizeScalar(u8, "a,,,b", ',');
// Returns: "a", "b" (no empty fields)
```

**Leading delimiters are skipped**: Delimiters at the start of input are ignored.

```zig
var iter = std.mem.tokenizeScalar(u8, ",,a,b", ',');
// Returns: "a", "b"
```

**Trailing delimiters are skipped**: Delimiters at the end of input are ignored.

```zig
var iter = std.mem.tokenizeScalar(u8, "a,b,,", ',');
// Returns: "a", "b"
```

**Empty input**: Returns `null` immediately — no tokens.

```zig
var iter = std.mem.tokenizeScalar(u8, "", ',');
// Returns: null immediately
```

**Delimiter-only input**: Returns `null` immediately — no tokens.

```zig
var iter = std.mem.tokenizeScalar(u8, ",,,", ',');
// Returns: null immediately
```

## Performance Considerations

- **Zero-allocation**: Creates views into the existing buffer
- **Single-pass**: O(n) complexity, processes each character once
- **Lazy evaluation**: Only computes the next token when `next()` is called
- **Slightly more work than SplitIterator**: Must skip over delimiter runs, but still O(1) amortized per token

## See Also

- [std.mem.SplitIterator](std.mem.SplitIterator.md) - Similar but preserves empty fields
- [std.mem.SplitBackwardsIterator](std.mem.SplitBackwardsIterator.md) - Backward splitting iterator
- [std.mem.DelimiterType](std.mem.DelimiterType.md) - Delimiter type documentation
