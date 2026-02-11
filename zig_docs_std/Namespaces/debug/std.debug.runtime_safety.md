# std.debug.runtime_safety

Deprecated because it returns the optimization mode of the standard library, when the caller probably wants to use the optimization mode of their own module.

## Overview

`std.debug.runtime_safety` is a legacy constant that mirrors the stdlib build mode (`true` in `Debug`/`ReleaseSafe`, `false` in `ReleaseFast`/`ReleaseSmall`).

Because this may differ from your module's compilation settings, this value is deprecated for general application logic.

## Source Code

```
pub const runtime_safety = switch (builtin.mode) {
    .Debug, .ReleaseSafe => true,
    .ReleaseFast, .ReleaseSmall => false,
}
```

## Prefer Instead

- For behavior in your own module, use your local build options and mode-specific configuration.
- Keep use of `std.debug.runtime_safety` limited to compatibility paths and existing stdlib-style toggles.
