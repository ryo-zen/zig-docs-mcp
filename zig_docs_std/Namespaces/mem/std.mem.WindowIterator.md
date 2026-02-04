# std.mem.WindowIterator

Iterator type returned by the `window` function for sliding window operations.

## Parameters

    T: type

### Fields

    buffer: []const T

    index: ?usize

    size: usize

    advance: usize

## Functions

`pub fn next(self: *Self) ?[]const T`  
Returns a slice of the next window, or null if window is at end.

`pub fn reset(self: *Self) void`  
Resets the iterator to the initial window.
