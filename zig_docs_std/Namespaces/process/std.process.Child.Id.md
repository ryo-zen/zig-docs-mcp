# std.process.Child.Id

## Source Code

```
pub const Id = switch (native_os) {
    .windows => std.os.windows.HANDLE,
    .wasi => void,
    else => std.posix.pid_t,
}
```
