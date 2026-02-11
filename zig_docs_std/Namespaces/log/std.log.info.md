# std.log.info

Log an info message using the default scope. This log level is intended to be used for general messages about the state of the program.

## Overview

`std.log.info` is the default-scope informational logging helper.

Use it for lifecycle and state-transition messages that are useful in normal operation.

## Source Code

```
pub const info = default.info
```

## Usage Notes

- Equivalent to `std.log.default.info(...)`.
- In default release settings, info logs remain enabled.
