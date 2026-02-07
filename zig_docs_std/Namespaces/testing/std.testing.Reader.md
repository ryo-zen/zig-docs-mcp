# std.testing.Reader

A `Io.Reader` that writes a predetermined list of buffers during `stream`.

### Fields

    calls: []const Call

    interface: Io.Reader

    next_call_index: usize

    next_offset: usize

    artificial_limit: Io.Limit = .unlimited

Further reduces how many bytes are written in each `stream` call.

## Types

- Call

## Functions

`pub fn init(buffer: []u8, calls: []const Call) Reader`  
