# std.log.err

Log an error message using the default scope. This log level is intended to be used when something has gone wrong. This might be recoverable or might be followed by the program exiting.

## Overview

`std.log.err` is the default-scope error-level logging helper.

Use it for failures and exceptional states that require operator/developer attention.

## Source Code

```
pub const err = default.err
```

## Usage Notes

- Equivalent to `std.log.default.err(...)`.
- Prefer logging contextual error details with `@errorName(err)` when handling error unions.
