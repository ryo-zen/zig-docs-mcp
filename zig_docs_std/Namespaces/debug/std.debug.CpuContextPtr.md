# std.debug.CpuContextPtr

The pointer through which a `cpu_context.Native` is received from callers of stack tracing logic.

## Source Code

```
pub const CpuContextPtr = if (cpu_context.Native == noreturn) noreturn else *const cpu_context.Native
```
