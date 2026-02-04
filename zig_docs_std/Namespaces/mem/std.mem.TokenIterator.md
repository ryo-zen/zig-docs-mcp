# std.mem.TokenIterator

Iterator type for tokenization operations, skipping empty sequences and delimiter sequences.

## Parameters

    T: type

    delimiter_type: DelimiterType

### Fields

    buffer: []const T

    delimiter: switch (delimiter_type) {
        .sequence, .any => []const T,
        .scalar => T,
    }

    index: usize

## Functions

`pub fn next(self: *Self) ?[]const T`  
Returns a slice of the current token, or null if tokenization is complete, and advances to the next token.

`pub fn peek(self: *Self) ?[]const T`  
Returns a slice of the current token, or null if tokenization is complete. Does not advance to the next token.

`pub fn reset(self: *Self) void`  
Resets the iterator to the initial token.

`pub fn rest(self: Self) []const T`  
Returns a slice of the remaining bytes. Does not affect iterator state.
