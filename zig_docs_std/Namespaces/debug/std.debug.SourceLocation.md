# std.debug.SourceLocation

Unresolved source locations can be represented with a single `usize` that corresponds to a virtual memory address of the program counter. Combined with debug information, those values can be converted into a resolved source location, including file, line, and column.

## Overview

`std.debug.SourceLocation` is the resolved location payload used by debug-symbol lookup.

It differs from `@src()` output: this type is used for runtime address-to-source mapping, not compile-time call-site capture.

### Fields

    line: u64

1-based line number in `file_name`.

    column: u64

1-based column number in `file_name`.

    file_name: []const u8

Path or file name associated with the resolved location.

## Values

|         |                  |     |
|---------|------------------|-----|
| invalid | `SourceLocation` |     |

`invalid` is used when resolution fails or no debug information is available.

## Typical Usage

- Returned from symbolization APIs such as `Info.resolveAddresses` and `Pdb.getLineNumberInfo`.
- Carried inside `std.debug.Symbol.source_location`.
- Useful for crash reporting and offline address resolution pipelines.
