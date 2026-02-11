# std.log.default

The default scoped logging namespace.

## Overview

`std.log.default` is the scoped logger returned by `std.log.scoped(std.log.default_log_scope)`.

Top-level helpers like `std.log.info` and `std.log.err` are aliases to functions on this namespace.

## Source Code

```
pub const default = scoped(default_log_scope)
```

## Usage Notes

- Use this directly when you want explicitness without creating a custom scope.
- Prefer `std.log.scoped(.your_scope)` in reusable libraries.
