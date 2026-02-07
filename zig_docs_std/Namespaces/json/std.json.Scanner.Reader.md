# std.json.Scanner.Reader

All `next*()` methods here handle `error.BufferUnderrun` from `std.json.Scanner`, and then read from the reader.

### Fields

    scanner: Scanner

    reader: *std.Io.Reader

## Functions

`pub fn allocNextIntoArrayList(self: *@This(), value_list: *std.array_list.Managed(u8), when: AllocWhen) Reader.AllocError!?[]const u8`  
Equivalent to `allocNextIntoArrayListMax(value_list, when, default_max_value_len);`

`pub fn allocNextIntoArrayListMax(self: *@This(), value_list: *std.array_list.Managed(u8), when: AllocWhen, max_value_len: usize) Reader.AllocError!?[]const u8`  
Calls `std.json.Scanner.allocNextIntoArrayListMax` and handles `error.BufferUnderrun`.

`pub fn deinit(self: *@This()) void`  

`pub fn enableDiagnostics(self: *@This(), diagnostics: *Diagnostics) void`  
Calls `std.json.Scanner.enableDiagnostics`.

`pub fn ensureTotalStackCapacity(self: *@This(), height: usize) Allocator.Error!void`  
Calls `std.json.Scanner.ensureTotalStackCapacity`.

`pub fn init(allocator: Allocator, io_reader: *std.Io.Reader) @This()`  
The allocator is only used to track `[]` and `{}` nesting levels.

`pub fn next(self: *@This()) Reader.NextError!Token`  
See `std.json.Token` for documentation of this function.

`pub fn nextAlloc(self: *@This(), allocator: Allocator, when: AllocWhen) Reader.AllocError!Token`  
Equivalent to `nextAllocMax(allocator, when, default_max_value_len);` See also `std.json.Token` for documentation of `nextAlloc*()` function behavior.

`pub fn nextAllocMax(self: *@This(), allocator: Allocator, when: AllocWhen, max_value_len: usize) Reader.AllocError!Token`  
See also `std.json.Token` for documentation of `nextAlloc*()` function behavior.

`pub fn peekNextTokenType(self: *@This()) Reader.PeekError!TokenType`  
See `std.json.Scanner.peekNextTokenType()`.

`pub fn skipUntilStackHeight(self: *@This(), terminal_stack_height: usize) Reader.NextError!void`  
Like `std.json.Scanner.skipUntilStackHeight()` but handles `error.BufferUnderrun`.

`pub fn skipValue(self: *@This()) Reader.SkipError!void`  
Like `std.json.Scanner.skipValue`, but handles `error.BufferUnderrun`.

`pub fn stackHeight(self: *const @This()) usize`  
Calls `std.json.Scanner.stackHeight`.

## Error Sets

- AllocError
- NextError
- PeekError
- SkipError
