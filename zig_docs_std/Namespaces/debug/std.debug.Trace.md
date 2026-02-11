# std.debug.Trace

This API helps you track where a value originated and where it was mutated, or any other points of interest. In debug mode, it adds a small size penalty (104 bytes on 64-bit architectures) to the aggregate that you add it to. In release mode, it is size 0 and all methods are no-ops. This is a pre-made type with default settings. For more advanced usage, see `ConfigurableTrace`.

## Overview

`std.debug.Trace` is a ready-to-use instantiation of `std.debug.ConfigurableTrace` intended for quick provenance tracking during development.

It is designed to be cheap to add to structs in debug builds, while compiling away in optimized builds.

## Source Code

```
pub const Trace = ConfigurableTrace(2, 4, builtin.mode == .Debug)
```

## Practical Behavior

- In `Debug` mode, trace entries record recent addresses and user notes.
- In optimized release modes, the type has zero runtime overhead and methods become no-ops.
- The default configuration tracks a small rolling history; for custom depth, use `std.debug.ConfigurableTrace`.

## Typical Pattern

```zig
const std = @import("std");

const State = struct {
    trace: std.debug.Trace = .init,
};
```

## Related APIs

- `std.debug.ConfigurableTrace`
- `std.debug.dumpCurrentStackTrace`
