# std.debug.Trace

This API helps you track where a value originated and where it was mutated, or any other points of interest. In debug mode, it adds a small size penalty (104 bytes on 64-bit architectures) to the aggregate that you add it to. In release mode, it is size 0 and all methods are no-ops. This is a pre-made type with default settings. For more advanced usage, see `ConfigurableTrace`.

## Source Code

```
pub const Trace = ConfigurableTrace(2, 4, builtin.mode == .Debug)
```
