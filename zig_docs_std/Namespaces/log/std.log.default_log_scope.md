# std.log.default_log_scope

## Overview

`std.log.default_log_scope` is the enum-literal scope used by default-scope logging helpers.

It is the scope behind `std.log.default`, `std.log.info`, `std.log.warn`, `std.log.err`, and `std.log.debug`.

## Source Code

```
pub const default_log_scope = .default
```

## Usage Notes

- Use `.default` for application-wide logs without finer scoping.
- Prefer custom scopes for library/module logs that should be filtered independently.
