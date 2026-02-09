# std.debug.runtime_safety

Deprecated because it returns the optimization mode of the standard library, when the caller probably wants to use the optimization mode of their own module.

## Source Code

```
pub const runtime_safety = switch (builtin.mode) {
    .Debug, .ReleaseSafe => true,
    .ReleaseFast, .ReleaseSmall => false,
}
```
