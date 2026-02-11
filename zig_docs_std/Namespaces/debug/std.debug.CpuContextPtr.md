# std.debug.CpuContextPtr

The pointer through which a `cpu_context.Native` is received from callers of stack tracing logic.

## Overview

`std.debug.CpuContextPtr` is a target-dependent alias used when unwinding from an externally supplied CPU context (for example, a signal or exception handler).

It abstracts over platforms where native CPU context is unavailable by collapsing to `noreturn`.

## Source Code

```
pub const CpuContextPtr = if (cpu_context.Native == noreturn) noreturn else *const cpu_context.Native
```

## Usage Notes

- Use this type through APIs like `std.debug.StackUnwindOptions.context`.
- On targets where `cpu_context.Native == noreturn`, context-based unwinding is not supported.
- If you are writing portable stack-trace code, treat this as optional capability and fall back to current-thread unwinding when unavailable.

## Related APIs

- `std.debug.StackUnwindOptions`
- `std.debug.cpu_context`
- `std.debug.dumpCurrentStackTrace`
