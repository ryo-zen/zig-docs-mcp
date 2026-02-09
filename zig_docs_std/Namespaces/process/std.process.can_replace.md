# std.process.can_replace

Tells whether the target operating system supports replacing the current process image. If this is `false` then calling `replace` or `replaceFile` functions will return `error.OperationUnsupported`.

## Source Code

```
pub const can_replace = switch (native_os) {
    .windows, .haiku, .wasi => false,
    else => true,
}
```
