# std.debug.simple_panic

This namespace is the default one used by the Zig compiler to emit various kinds of safety panics, due to the logic in `std.builtin.panic`.

Since Zig does not have interfaces, this file serves as an example template for users to provide their own alternative panic handling.

As an alternative, see `std.debug.FullPanic`.

## Functions

`pub fn call(msg: []const u8, ra: ?usize) noreturn`  
Prints the message to stderr without a newline and then traps.

`pub fn castToNull() noreturn`  

`pub fn copyLenMismatch() noreturn`  

`pub fn corruptSwitch() noreturn`  

`pub fn divideByZero() noreturn`  

`pub fn exactDivisionRemainder() noreturn`  

`pub fn forLenMismatch() noreturn`  

`pub fn inactiveUnionField(active: anytype, accessed: @TypeOf(active)) noreturn`  

`pub fn incorrectAlignment() noreturn`  

`pub fn integerOutOfBounds() noreturn`  

`pub fn integerOverflow() noreturn`  

`pub fn integerPartOutOfBounds() noreturn`  

`pub fn invalidEnumValue() noreturn`  

`pub fn invalidErrorCode() noreturn`  

`pub fn memcpyAlias() noreturn`  

`pub fn noreturnReturned() noreturn`  

`pub fn outOfBounds(index: usize, len: usize) noreturn`  

`pub fn reachedUnreachable() noreturn`  

`pub fn sentinelMismatch(expected: anytype, found: @TypeOf(expected)) noreturn`  

`pub fn shiftRhsTooBig() noreturn`  

`pub fn shlOverflow() noreturn`  

`pub fn shrOverflow() noreturn`  

`pub fn sliceCastLenRemainder(src_len: usize) noreturn`  

`pub fn startGreaterThanEnd(start: usize, end: usize) noreturn`  

`pub fn unwrapError(err: anyerror) noreturn`  

`pub fn unwrapNull() noreturn`  
