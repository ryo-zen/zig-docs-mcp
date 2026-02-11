# std.log.debug

Log a debug message using the default scope. This log level is intended to be used for messages which are only useful for debugging.

## Overview

`std.log.debug` is a convenience alias for default-scope debug logging.

Use it for development diagnostics that are safe to compile out at higher log thresholds.

## Source Code

```
pub const debug = default.debug
```

## Usage Notes

- Equivalent to `std.log.default.debug(...)`.
- Guard expensive debug argument construction with `std.log.logEnabled(.debug, .default)`.
