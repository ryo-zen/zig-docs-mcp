# std.json.Scanner.Diagnostics

To enable diagnostics, declare `var diagnostics = Diagnostics{};` then call `source.enableDiagnostics(&diagnostics);` where `source` is either a `std.json.Reader` or a `std.json.Scanner` that has just been initialized. At any time, notably just after an error, call `getLine()`, `getColumn()`, and/or `getByteOffset()` to get meaningful information from this.

### Fields

    line_number: u64 = 1

    line_start_cursor: usize = @as(usize, @bitCast(@as(isize, -1)))

    total_bytes_before_current_input: u64 = 0

    cursor_pointer: *const usize = undefined

## Functions

`pub fn getByteOffset(self: *const @This()) u64`  
Starts at 0. Measures the byte offset since the start of the input.

`pub fn getColumn(self: *const @This()) u64`  
Starts at 1.

`pub fn getLine(self: *const @This()) u64`  
Starts at 1.
