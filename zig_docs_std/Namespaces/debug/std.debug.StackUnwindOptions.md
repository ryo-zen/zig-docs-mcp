# std.debug.StackUnwindOptions

## Overview

`std.debug.StackUnwindOptions` controls how stack-unwinding and stack-trace capture functions walk frames.

Use it with APIs such as `captureCurrentStackTrace`, `writeCurrentStackTrace`, and `dumpCurrentStackTrace`.

### Fields

    first_address: ?usize = null

If not `null`, we will ignore all frames up until this return address. This is typically used to omit intermediate handling code (for instance, a panic handler and its machinery) from stack traces.

    context: ?CpuContextPtr = null

If not `null`, we will unwind from this `cpu_context.Native` instead of the current top of the stack. The main use case here is printing stack traces from signal handlers, where the kernel provides a `*const cpu_context.Native` of the state before the signal.

    allow_unsafe_unwind: bool = false

If `true`, stack unwinding strategies which may cause crashes are used as a last resort. If `false`, only known-safe mechanisms will be attempted.

## Typical Usage

```zig
const std = @import("std");

pub fn main() void {
    std.debug.dumpCurrentStackTrace(.{
  .first_address = @returnAddress(),
  .allow_unsafe_unwind = false,
    });
}
```

## Gotchas

- `context` is platform-dependent; not all targets provide native context support.
- `allow_unsafe_unwind = true` can improve trace completeness but may be risky in compromised process states.
- If `std.debug.sys_can_stack_trace` is `false`, traces may be empty even with valid options.
