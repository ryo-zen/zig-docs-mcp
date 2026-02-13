# std.process.Environ.Block

On WASI without libc, this is `void` because the environment has to be queried and heap-allocated at runtime.

## Source Code

```
pub const Block = switch (native_os) {
    .windows => GlobalBlock,
    .wasi => switch (builtin.link_libc) {
  false => GlobalBlock,
  true => PosixBlock,
    },
    .freestanding, .other => GlobalBlock,
    else => PosixBlock,
}
```
