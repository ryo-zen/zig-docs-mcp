# std.unicode

## Overview

`std.unicode` provides UTF-8, UTF-16 little-endian, WTF-8, and WTF-16 little-endian encoding, decoding, validation, iteration, conversion, and formatting helpers.

Source: `/path/to/zig-0.16.0/lib/std/unicode.zig`

## Public API

### Replacement Characters

- `std.unicode.replacement_character`
- `std.unicode.replacement_character_utf8`

### UTF-8

- `std.unicode.utf8CodepointSequenceLength`
- `std.unicode.utf8ByteSequenceLength`
- `std.unicode.utf8Encode`
- `std.unicode.utf8Decode`
- `std.unicode.utf8Decode2`
- `std.unicode.utf8Decode3`
- `std.unicode.utf8Decode3AllowSurrogateHalf`
- `std.unicode.utf8Decode4`
- `std.unicode.utf8ValidCodepoint`
- `std.unicode.utf8CountCodepoints`
- `std.unicode.utf8ValidateSlice`
- `std.unicode.Utf8View`
- `std.unicode.Utf8Iterator`
- `std.unicode.fmtUtf8`

### UTF-16 Little-Endian

- `std.unicode.utf16IsHighSurrogate`
- `std.unicode.utf16IsLowSurrogate`
- `std.unicode.utf16CodepointSequenceLength`
- `std.unicode.utf16CodeUnitSequenceLength`
- `std.unicode.utf16DecodeSurrogatePair`
- `std.unicode.Utf16LeIterator`
- `std.unicode.utf16CountCodepoints`
- `std.unicode.utf16LeToUtf8ArrayList`
- `std.unicode.utf16LeToUtf8Alloc`
- `std.unicode.utf16LeToUtf8AllocZ`
- `std.unicode.utf16LeToUtf8`
- `std.unicode.utf8ToUtf16LeArrayList`
- `std.unicode.utf8ToUtf16LeAlloc`
- `std.unicode.utf8ToUtf16LeAllocZ`
- `std.unicode.utf8ToUtf16Le`
- `std.unicode.utf8ToUtf16LeStringLiteral`
- `std.unicode.calcUtf16LeLen`
- `std.unicode.fmtUtf16Le`

### WTF-8 and WTF-16 Little-Endian

- `std.unicode.isSurrogateCodepoint`
- `std.unicode.wtf8Encode`
- `std.unicode.wtf8Decode`
- `std.unicode.wtf8ValidateSlice`
- `std.unicode.Wtf8View`
- `std.unicode.Wtf8Iterator`
- `std.unicode.wtf16LeToWtf8ArrayList`
- `std.unicode.wtf16LeToWtf8Alloc`
- `std.unicode.wtf16LeToWtf8AllocZ`
- `std.unicode.wtf16LeToWtf8`
- `std.unicode.wtf8ToWtf16LeArrayList`
- `std.unicode.wtf8ToWtf16LeAlloc`
- `std.unicode.wtf8ToWtf16LeAllocZ`
- `std.unicode.wtf8ToWtf16Le`
- `std.unicode.wtf8ToUtf8Lossy`
- `std.unicode.wtf8ToUtf8LossyAlloc`
- `std.unicode.wtf8ToUtf8LossyAllocZ`
- `std.unicode.Wtf16LeIterator`
- `std.unicode.calcWtf16LeLen`
- `std.unicode.calcWtf8Len`

## Notes

Use `std.ascii` for byte-oriented 7-bit ASCII classification and case conversion. Use this namespace when code must validate, iterate, format, or convert Unicode encodings.
