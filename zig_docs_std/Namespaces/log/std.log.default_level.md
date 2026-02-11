# std.log.default_level

The default log level is based on build mode.

## Overview

`std.log.default_level` is the compile-time fallback threshold used when no custom `std_options.log_level` is provided.

It defaults to verbose logging in debug builds and less verbose logging in release builds.

## Source Code

```
pub const default_level: Level = switch (builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,
}
```

## Practical Meaning

- `Debug` mode: keep `.debug`, `.info`, `.warn`, `.err`.
- Release modes: keep `.info`, `.warn`, `.err`; drop `.debug`.
- You can override this via `std_options.log_level`.
