# std.debug.ConfigurableTrace

## Parameters

    size: usize

    stack_frame_count: usize

    is_enabled: bool

### Fields

    addrs: [actual_size][stack_frame_count]usize

    notes: [actual_size][]const u8

    index: Index

## Values

|         |           |     |
|---------|-----------|-----|
| add     |           |     |
| enabled |           |     |
| init    | `@This()` |     |

## Functions

`pub fn addAddr(t: *@This(), addr: usize, note: []const u8) void`  

`pub noinline fn addNoInline(t: *@This(), note: []const u8) void`  

`pub inline fn addNoOp(t: *@This(), note: []const u8) void`  

`pub fn dump(t: @This()) void`  

`pub fn format( t: @This(), comptime fmt: []const u8, options: std.fmt.Options, writer: *Writer, ) !void`  
