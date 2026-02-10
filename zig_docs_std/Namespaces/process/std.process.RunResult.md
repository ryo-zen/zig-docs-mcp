# std.process.RunResult

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.RunResult` is the structure returned by the high-level `std.process.run()` function. it contains the termination status of the child process along with the captured data from its standard output and standard error streams.

---

## Fields

`term: std.process.Child.Term`
------
Describes how the process terminated (e.g., normal exit with a code, or terminated by a signal).

`stdout: []u8`
------
The captured standard output of the child process. This memory is allocated with the allocator passed to `run()` and must be freed by the caller.

`stderr: []u8`
------
The captured standard error output of the child process. This memory is allocated with the allocator passed to `run()` and must be freed by the caller.

---

## Usage Example

```zig
const result = try std.process.run(init.gpa, init.io, .{
    .argv = &[_][]const u8{ "uptime" },
});
defer init.gpa.free(result.stdout);
defer init.gpa.free(result.stderr);

if (result.term == .exited and result.term.exited == 0) {
    std.debug.print("Uptime: {s}\n", .{result.stdout});
}
```

---

## See Also

- **std.process.run** - The function that returns this result.
- **std.process.Child.Term** - Details on the termination union.
- **std.process.RunOptions** - Options used to configure the run call.
