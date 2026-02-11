# std.debug.default_enable_segfault_handler

## Overview

`std.debug.default_enable_segfault_handler` is the stdlib default for enabling segfault handling and diagnostic output.

It is enabled only when runtime safety is on and the target has segfault-handling support.

## Source Code

```
pub const default_enable_segfault_handler = runtime_safety and have_segfault_handling_support
```

## Practical Meaning

- `true` in safety-oriented builds on supported targets.
- `false` in fast/small release builds or unsupported environments.
- Can be overridden by application-level debug/panic strategy.

## Related APIs

- `std.debug.runtime_safety`
- `std.debug.have_segfault_handling_support`
