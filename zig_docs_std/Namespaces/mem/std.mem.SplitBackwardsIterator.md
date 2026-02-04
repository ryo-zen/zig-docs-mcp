# std.mem.SplitBackwardsIterator

Iterator type for splitting operations from the end backwards, including empty sequences.

## Parameters

    T: type

    delimiter_type: DelimiterType

### Fields

    buffer: []const T

    index: ?usize

    delimiter: switch (delimiter_type) {
        .sequence, .any => []const T,
        .scalar => T,
    }

## Functions

`pub fn first(self: *Self) []const T`  
Returns a slice of the first field. Call this only to get the first field and then use `next` to get all subsequent fields. Asserts that iteration has not begun.

`pub fn next(self: *Self) ?[]const T`  
Returns a slice of the next field, or null if splitting is complete.

`pub fn reset(self: *Self) void`  
Resets the iterator to the initial slice.

`pub fn rest(self: Self) []const T`  
Returns a slice of the remaining bytes. Does not affect iterator state.
