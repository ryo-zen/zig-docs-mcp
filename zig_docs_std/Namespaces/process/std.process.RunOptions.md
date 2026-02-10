# std.process.RunOptions

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.RunOptions` is the configuration structure used by the high-level `std.process.run()` function. It simplifies the process of spawning a child, capturing its output, and waiting for termination in a single call.

---

## Fields

`argv: []const []const u8`
------
**Mandatory.** The command and its arguments. `argv[0]` is the program to execute.

`max_output_bytes: usize = 51200` (50 KB)
------
The maximum number of bytes to capture from `stdout` and `stderr` combined. If the child process produces more output, `run()` will return `error.StdoutStreamTooLong` or `error.StderrStreamTooLong`.

`cwd: ?[]const u8 = null`
------
The current working directory for the child process.

`cwd_dir: ?std.Io.Dir = null`
------
An alternative to `cwd` that uses an open directory handle.

`environ_map: ?*const std.process.Environ.Map = null`
------
Custom environment variables for the child process.

`expand_arg0: std.process.ArgExpansion = .no_expand`
------
Controls whether `argv[0]` should be searched for in the `PATH`.

`create_no_window: bool = true`
------
**Windows-only.** If true, the child process is created without a console window.

---

## Usage Example

```zig
const result = try std.process.run(init.gpa, init.io, .{
    .argv = &[_][]const u8{ "ls", "-l" },
    .max_output_bytes = 10 * 1024 * 1024, // 10 MB
});
defer init.gpa.free(result.stdout);
defer init.gpa.free(result.stderr);
```

---

## See Also

- **std.process.run** - The function that consumes this struct.
- **std.process.RunResult** - The result produced by `run()`.
- **std.process.SpawnOptions** - Lower-level options for process creation.
