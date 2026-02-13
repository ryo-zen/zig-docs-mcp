# std.process.Child

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating child process management.

## Quick Start

### Running a simple command

In Zig 0.16, you use `std.process.spawn` to create a `Child` process handle.

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var child = try std.process.spawn(init.io, .{
  .argv = &[_][]const u8{ "ls", "-l" },
    });

    // Wait for the process to complete
    const term = try child.wait(init.io);
    std.debug.print("Process exited with {}\n", .{term});
}
```

### Capturing Output (Piping)

```zig
pub fn main(init: std.process.Init) !void {
    var child = try std.process.spawn(init.io, .{
  .argv = &[_][]const u8{ "echo", "Hello from Zig!" },
  .stdout = .pipe,
  .stderr = .pipe,
    });

    var stdout_list: std.ArrayList(u8) = .empty;
    defer stdout_list.deinit(init.gpa);
    var stderr_list: std.ArrayList(u8) = .empty;
    defer stderr_list.deinit(init.gpa);

    // Use collectOutput to capture all output from stdout and stderr pipes
    try child.collectOutput(init.gpa, &stdout_list, &stderr_list, 1024);

    _ = try child.wait(init.io);
    std.debug.print("Got: {s}", .{stdout_list.items});
}
```

---

## Overview

`std.process.Child` is a handle to a running child process. It is created by calling `std.process.spawn()` or `std.process.spawnPath()`.

**Key Characteristics:**
- **Asynchronous Creation**: The process is started immediately upon a successful `spawn()`.
- **I/O Control**: Supports inheriting, ignoring, piping, or redirecting streams to files.
- **Resource Management**: Provides mechanisms to wait for termination or forcibly kill the process.
- **Platform Agnostic**: Hides OS-specific details like PIDs vs Handles.

---

## Fields

`id: ?Id`
------
The operating system's process identifier. On POSIX systems, this is a `pid_t`. On Windows, it is an `HANDLE`. It becomes `null` after `wait()` or `kill()` is called.

`stdin: ?std.Io.File`
------
The writing end of the child's stdin pipe. Only populated if `SpawnOptions.stdin` was set to `.pipe`.

`stdout: ?std.Io.File`
------
The reading end of the child's stdout pipe. Only populated if `SpawnOptions.stdout` was set to `.pipe`.

`stderr: ?std.Io.File`
------
The reading end of the child's stderr pipe. Only populated if `SpawnOptions.stderr` was set to `.pipe`.

`resource_usage_statistics: ResourceUsageStatistics`
------
Populated after `wait()` if `request_resource_usage_statistics` was set to `true` during spawn.

---

## Types

### `Term` (union)

Indicates how the process terminated.

- `exited: u8` - Process exited normally with the given status code.
- `signal: std.posix.SIG` - Process was terminated by a signal (POSIX).
- `stopped: u32` - Process was stopped.
- `unknown: u32` - Termination reason is unknown.

---

## Functions

### `pub fn wait(child: *Child, io: std.Io) WaitError!Term`

Blocks until the child process terminates and cleans up all associated OS resources.

**Parameters:**
- `child`: Pointer to the Child handle.
- `io`: The `std.Io` interface to use for waiting.

**Returns:** A `Term` union describing the exit status.

------

### `pub fn kill(child: *Child, io: std.Io) void`

Forcibly terminates the child process and waits for it to exit. This ensures resources are cleaned up.

------

### `pub fn collectOutput(child: *const Child, allocator: Allocator, stdout: *ArrayList(u8), stderr: *ArrayList(u8), max_output_bytes: usize) !void`

Convenience function to read all remaining data from `stdout` and `stderr` pipes until EOF. The child must have been spawned with `.pipe` for these streams.

---

## Debug Checklist

✅ **Always call `wait()` or `kill()`** - Failure to do so results in "zombie" processes that consume system resources.

✅ **Check for `null` pipes** - `stdin`, `stdout`, and `stderr` are only available if configured as `.pipe`.

✅ **Close pipe ends in the parent** - If you're not using a pipe, or after you're done writing to `stdin`, ensure it's closed using `close(io)` so the child receives EOF.

✅ **Handle `wait()` errors** - Network issues or OS errors can cause waiting to fail.

---

## See Also

- **std.process.spawn** - The function used to create a `Child` instance.
- **std.process.RunResult** - Returned by the high-level `std.process.run` function.
- **std.Io** - The I/O interface used for process communication.
