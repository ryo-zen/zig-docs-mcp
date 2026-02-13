# std.debug.FullPanic

A fully-featured panic handler namespace which lowers all panics to calls to `panicFn`. Safety panics will use formatted printing to provide a meaningful error message. The signature of `panicFn` should match that of `defaultPanic`.

## Overview

`std.debug.FullPanic` is the rich panic-handler adapter for applications that want detailed panic diagnostics while still centralizing termination behavior through a custom `panicFn`.

It exposes per-safety-check entry points used by generated runtime checks.

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

## Usage Notes

- Intended for use as `pub const panic = std.debug.FullPanic(myPanicFn).call;` (or equivalent root integration pattern).
- Compared with `simple_panic`, this variant emphasizes diagnostic quality.
- Compared with `no_panic`, this variant is for functional crash reporting rather than minimum code size.

## Related APIs

- `std.debug.simple_panic`
- `std.debug.no_panic`
