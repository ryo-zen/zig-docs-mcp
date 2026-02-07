# std.testing.environ

## Source Code

```
pub var environ: Environ = if (builtin.is_test) undefined else @compileError("not testing")
```
