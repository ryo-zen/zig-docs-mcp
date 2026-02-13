# std.process.Child.Term

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.Child.Term` is a tagged union that describes how a child process terminated. It is returned by `child.wait()` and `std.process.run()`.

---

## Variants

`exited: u8`
------
The process terminated normally by calling `exit()` or returning from `main`. The associated value is the exit status code (typically `0` for success).

`signal: std.posix.SIG`
------
**POSIX-only.** The process was terminated by an asynchronous signal (e.g., `SIGKILL`, `SIGTERM`, `SIGSEGV`).

`stopped: u32`
------
**POSIX-only.** The process was stopped by a signal (e.g., `SIGSTOP`). This usually only occurs if the parent is tracing the child or specifically requested stop notifications.

`unknown: u32`
------
The process terminated for an unknown or platform-specific reason that does not map to the other variants.

---

## Usage Example

```zig
const term = try child.wait(io);
switch (term) {
    .exited => |code| {
  if (code == 0) {
      std.debug.print("Success\n", .{});
  } else {
      std.debug.print("Failed with code {d}\n", .{code});
  }
    },
    .signal => |sig| {
  std.debug.print("Terminated by signal: {s} ({d})\n", .{ @tagName(sig), @intFromEnum(sig) });
    },
    .stopped => |s| std.debug.print("Stopped by signal {d}\n", .{s}),
    .unknown => |u| std.debug.print("Unknown termination: {d}\n", .{u}),
}
```

---

## See Also

- **std.process.Child** - The handle representing the child process.
- **std.process.run** - High-level function that returns `RunResult` containing a `Term`.
- **std.posix.SIG** - Enum of POSIX signal values.
