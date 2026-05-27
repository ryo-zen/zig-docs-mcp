# std.ascii

## Overview

`std.ascii` contains utilities for the 7-bit ASCII character encoding. The functions accept `u8` for convenience, and bytes outside the ASCII range are handled without treating them as ASCII characters.

Source: `/path/to/zig-0.16.0/lib/std/ascii.zig`

## Public API

### Character Sets and Constants

- `std.ascii.lowercase` - lowercase ASCII letters.
- `std.ascii.uppercase` - uppercase ASCII letters.
- `std.ascii.letters` - lowercase followed by uppercase letters.
- `std.ascii.control_code` - C0 control-code constants plus `del`, `xon`, and `xoff`.
- `std.ascii.whitespace` - ASCII whitespace bytes: space, tab, newline, carriage return, vertical tab, and form feed.

### Classification

- `std.ascii.isAlphanumeric(c)`
- `std.ascii.isAlphabetic(c)`
- `std.ascii.isControl(c)`
- `std.ascii.isDigit(c)`
- `std.ascii.isLower(c)`
- `std.ascii.isPrint(c)`
- `std.ascii.isGraphical(c)`
- `std.ascii.isPunctuation(c)`
- `std.ascii.isWhitespace(c)`
- `std.ascii.isUpper(c)`
- `std.ascii.isHex(c)`
- `std.ascii.isAscii(c)`

### Case Conversion

- `std.ascii.toUpper(c)` - uppercases one ASCII letter and leaves other bytes unchanged.
- `std.ascii.toLower(c)` - lowercases one ASCII letter and leaves other bytes unchanged.
- `std.ascii.lowerString(output, ascii_string)` - writes a lowercase copy into `output`.
- `std.ascii.allocLowerString(allocator, ascii_string)` - allocates a lowercase copy.
- `std.ascii.upperString(output, ascii_string)` - writes an uppercase copy into `output`.
- `std.ascii.allocUpperString(allocator, ascii_string)` - allocates an uppercase copy.

### Case-Insensitive Search and Ordering

- `std.ascii.eqlIgnoreCase(a, b)`
- `std.ascii.startsWithIgnoreCase(haystack, needle)`
- `std.ascii.endsWithIgnoreCase(haystack, needle)`
- `std.ascii.findIgnoreCase(haystack, needle)`
- `std.ascii.findIgnoreCasePos(haystack, start_index, needle)`
- `std.ascii.findIgnoreCasePosLinear(haystack, start_index, needle)`
- `std.ascii.indexOfIgnoreCase` - alias of `findIgnoreCase`.
- `std.ascii.indexOfIgnoreCasePos` - alias of `findIgnoreCasePos`.
- `std.ascii.indexOfIgnoreCasePosLinear` - alias of `findIgnoreCasePosLinear`.
- `std.ascii.orderIgnoreCase(lhs, rhs)`
- `std.ascii.orderIgnoreCaseZ(lhs, rhs)`
- `std.ascii.boundedOrderIgnoreCaseZ(lhs, rhs, bound)`
- `std.ascii.lessThanIgnoreCase(lhs, rhs)`

### Escaping

- `std.ascii.HexEscape` - formatter helper for hex escaping bytes.
- `std.ascii.hexEscape(bytes, case)` - returns a formatter for escaped byte output.

## Notes

Use `std.unicode` for UTF-8, UTF-16, WTF-8, or codepoint-aware work. `std.ascii` is intentionally byte-oriented.
