# std.testing.io

## Source Code

```
pub const io = if (builtin.is_test) io_instance.io() else @compileError("not testing")
```
