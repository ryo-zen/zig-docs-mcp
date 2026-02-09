# std.debug.FullPanic

A fully-featured panic handler namespace which lowers all panics to calls to `panicFn`. Safety panics will use formatted printing to provide a meaningful error message. The signature of `panicFn` should match that of `defaultPanic`.

## Parameters

    panicFn: fn ([]const u8, ?usize) noreturn

## Values

|      |     |     |
|------|-----|-----|
| call |     |     |

## Functions

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
