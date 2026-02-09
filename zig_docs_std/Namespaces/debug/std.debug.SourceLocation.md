# std.debug.SourceLocation

Unresolved source locations can be represented with a single `usize` that corresponds to a virtual memory address of the program counter. Combined with debug information, those values can be converted into a resolved source location, including file, line, and column.

### Fields

    line: u64

    column: u64

    file_name: []const u8

## Values

|         |                  |     |
|---------|------------------|-----|
| invalid | `SourceLocation` |     |
