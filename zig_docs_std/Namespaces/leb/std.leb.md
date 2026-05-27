# std.leb

## Overview

`std.leb` provides fixed-width LEB128 writing helpers. In this stdlib, the root name `std.leb` imports source file `leb128.zig`.

Source: `/path/to/zig-0.16.0/lib/std/leb128.zig`

## Public API

- `std.leb.writeUnsignedFixed(l, ptr, int)` - writes an unsigned LEB128 value into exactly `l` bytes.
- `std.leb.writeUnsignedExtended(slice, arg)` - runtime-length variant of unsigned fixed-width writing; asserts the slice is non-empty.
- `std.leb.writeSignedFixed(l, ptr, int)` - writes a signed LEB128 value into exactly `l` bytes.

## Notes

These are advanced fixed-width helpers. Fixed-width LEB128 gives predictable field sizes, which is useful for patchable or relocatable encodings, but it removes the usual space-saving property of variable-width LEB128.

For reading LEB128 values, use the relevant `std.Io.Reader` helpers available in the locked stdlib source.
