# std.debug.no_panic

This namespace can be used with `pub const panic = std.debug.no_panic;` in the root file. It emits as little code as possible, for testing purposes.

For a functional alternative, see `std.debug.FullPanic`.

## Functions

`pub fn call(_: []const u8, _: ?usize) noreturn`  

`pub fn castToNull() noreturn`  

`pub fn copyLenMismatch() noreturn`  

`pub fn corruptSwitch() noreturn`  

`pub fn divideByZero() noreturn`  

`pub fn exactDivisionRemainder() noreturn`  

`pub fn forLenMismatch() noreturn`  

`pub fn inactiveUnionField(_: anytype, _: anytype) noreturn`  

`pub fn incorrectAlignment() noreturn`  

`pub fn integerOutOfBounds() noreturn`  

`pub fn integerOverflow() noreturn`  

`pub fn integerPartOutOfBounds() noreturn`  

`pub fn invalidEnumValue() noreturn`  

`pub fn invalidErrorCode() noreturn`  

`pub fn memcpyAlias() noreturn`  

`pub fn noreturnReturned() noreturn`  

`pub fn outOfBounds(_: usize, _: usize) noreturn`  

`pub fn reachedUnreachable() noreturn`  

`pub fn sentinelMismatch(_: anytype, _: anytype) noreturn`  

`pub fn shiftRhsTooBig() noreturn`  

`pub fn shlOverflow() noreturn`  

`pub fn shrOverflow() noreturn`  

`pub fn sliceCastLenRemainder(_: usize) noreturn`  

`pub fn startGreaterThanEnd(_: usize, _: usize) noreturn`  

`pub fn unwrapError(_: anyerror) noreturn`  

`pub fn unwrapNull() noreturn`  
