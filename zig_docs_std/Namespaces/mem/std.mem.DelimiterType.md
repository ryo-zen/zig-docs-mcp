# std.mem.DelimiterType

📚 **[See Comprehensive Examples & Tests](../../Examples/std.mem.DelimiterType.tests.zig)**

## Overview

`DelimiterType` is an enum that controls how split and tokenize functions interpret the delimiter parameter. This determines whether the delimiter is treated as a single character, a set of characters, or an exact sequence to match.

The choice of delimiter type affects both matching behavior and performance. Use this enum when calling functions like `std.mem.splitAny`, `std.mem.tokenizeAny`, and their variants.

## Variants

### `.sequence`
Matches the entire delimiter string as a single sequence (substring matching).

**Use when**: You want to split on multi-character patterns like `", "` (comma-space), `"\r\n"` (CRLF), or `"||"` (double pipe).

**Example**: Splitting `"foo||bar||baz"` with delimiter `"||"` and type `.sequence` yields: `"foo"`, `"bar"`, `"baz"`

**Behavior**: The complete delimiter string must appear in order for a match to occur.

------

### `.any`
Matches any single character from the delimiter set (OR logic).

**Use when**: You want to split on multiple possible single-character delimiters, like splitting on any whitespace character or any punctuation mark.

**Example**: Splitting `"foo,bar;baz"` with delimiter `",;"` and type `.any` yields: `"foo"`, `"bar"`, `"baz"`

**Behavior**: Each character in the delimiter string is treated as an independent delimiter. A match occurs when any one of those characters is found.

------

### `.scalar`
Matches a single delimiter value exactly (the delimiter must be a single character).

**Use when**: You're splitting on a single known character like `'\n'`, `','`, or `' '`.

**Example**: Splitting `"foo,bar,baz"` with delimiter `','` and type `.scalar` yields: `"foo"`, `"bar"`, `"baz"`

**Behavior**: Only the exact character provided is treated as a delimiter. This is the most efficient option for single-character delimiters.

## Usage Example

```zig
const std = @import("std");

// .sequence - matches entire substring
var iter_seq = std.mem.splitSequence(u8, "a::b::c", "::");
// yields: "a", "b", "c"

// .any - matches any character in set
var iter_any = std.mem.splitAny(u8, "a,b;c", ",;");
// yields: "a", "b", "c"

// .scalar - matches single character
var iter_scalar = std.mem.splitScalar(u8, "a,b,c", ',');
// yields: "a", "b", "c"
```

## Performance Considerations

- **`.scalar`** is the fastest option (direct character comparison)
- **`.any`** requires checking each character against the delimiter set
- **`.sequence`** requires substring matching, which is slower for long delimiters

When splitting on a single character, prefer `.scalar` for best performance.
