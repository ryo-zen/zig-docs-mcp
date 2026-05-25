# std.json.ParseError

The error set that will be returned when parsing from `*Source`. Note that this may contain `error.BufferUnderrun`, but that error will never actually be returned.

## Parameters

    Source: type

## Source Code

```
pub fn ParseError(comptime Source: type) type {
    // A few of these will either always be present or present enough of the time that
    // omitting them is more confusing than always including them.
    return ParseFromValueError || Source.NextError || Source.PeekError || Source.AllocError;
}
```
