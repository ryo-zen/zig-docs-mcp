# std.debug.have_segfault_handling_support

Whether or not the current target can print useful debug information when a segfault occurs.

## Overview

`std.debug.have_segfault_handling_support` is a compile-time capability flag indicating whether the current target has stdlib support for segfault diagnostics.

This is a platform matrix constant, not a runtime probe.

## Source Code

```
pub const have_segfault_handling_support = switch (native_os) {
    .haiku,
    .linux,
    .serenity,

    .dragonfly,
    .freebsd,
    .netbsd,
    .openbsd,

    .driverkit,
    .ios,
    .maccatalyst,
    .macos,
    .tvos,
    .visionos,
    .watchos,

    .illumos,

    .windows,
    => true,

    else => false,
}
```

## Usage Notes

- Commonly paired with `runtime_safety` to compute defaults (see `default_enable_segfault_handler`).
- `false` means diagnostic segfault handling is unavailable in stdlib for the target, not necessarily that faults cannot occur.
- Treat this as a capability gate for optional debug features.

## Related APIs

- `std.debug.default_enable_segfault_handler`
- `std.debug.sys_can_stack_trace`
