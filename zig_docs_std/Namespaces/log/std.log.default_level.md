# std.log.default_level

The default log level is based on build mode.

## Source Code

```
pub const default_level: Level = switch (builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,
}
```
