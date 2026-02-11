# std.debug.Symbol

## Overview

`std.debug.Symbol` represents the best-known symbolic information for a program counter (address).

It is returned by symbol-lookup APIs and may be partially populated when debug info is incomplete.

### Fields

    name: ?[]const u8

Function or symbol name, if available.

    compile_unit_name: ?[]const u8

Compilation unit (often source file or object) associated with the symbol.

    source_location: ?SourceLocation

Resolved file/line/column location, if available.

## Values

|         |          |     |
|---------|----------|-----|
| unknown | `Symbol` |     |

`unknown` is the sentinel used when no symbol information could be resolved.

## Usage Notes

- Always handle nullable fields; stripped binaries and partial debug info are common.
- `name` may be available even when `source_location` is `null`.
- Use `std.debug.SourceLocation.invalid` to represent unresolved locations in fixed-size outputs.
