# std.process.can_spawn

Tells whether spawning child processes is supported.

## Source Code

```
pub const can_spawn = switch (native_os) {
    .wasi, .ios, .tvos, .visionos, .watchos => false,
    else => true,
}
```
