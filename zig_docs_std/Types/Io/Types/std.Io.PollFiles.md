# std.Io.PollFiles

Given an enum, returns a struct with fields of that enum, each field representing an I/O stream for polling.

## Parameters

    StreamEnum: type

## Source Code

```
pub fn PollFiles(comptime StreamEnum: type) type {
    return @Struct(.auto, null, std.meta.fieldNames(StreamEnum), &@splat(Io.File), &@splat(.{}));
}
```
