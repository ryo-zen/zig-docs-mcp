# std.process

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all process management features

## Quick Start

### Most Common Patterns (Zig 0.16)

**Getting Command-Line Arguments**
```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // iterateAllocator is the cross-platform way to get arguments
    var args = try init.minimal.args.iterateAllocator(init.gpa);
    defer args.deinit();

    while (args.next()) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
```

**Running a Child Process (Capture Output)**
```zig
// High-level 'run' captures both stdout and stderr into owned slices
const result = try std.process.run(init.gpa, init.io, .{
    .argv = &[_][]const u8{ "ls", "-l" },
});
defer init.gpa.free(result.stdout);
defer init.gpa.free(result.stderr);

std.debug.print("stdout: {s}\n", .{result.stdout});
```

**Spawning a Child Process (Live Interaction)**
```zig
var child = try std.process.spawn(init.io, .{
    .argv = &[_][]const u8{ "cat" },
    .stdin = .pipe,
    .stdout = .pipe,
    .stderr = .pipe,
});
defer _ = child.wait(init.io) catch {};

// Use writeStreamingAll to send data to stdin
try child.stdin.?.writeStreamingAll(init.io, "Hello from parent!\n");
child.stdin.?.close(init.io);
child.stdin = null;

// Use collectOutput to capture stdout/stderr from the child
var stdout_list: std.ArrayList(u8) = .empty;
defer stdout_list.deinit(init.gpa);
var stderr_list: std.ArrayList(u8) = .empty;
defer stderr_list.deinit(init.gpa);

try child.collectOutput(init.gpa, &stdout_list, &stderr_list, 1024 * 1024);
std.debug.print("Output: {s}\n", .{stdout_list.items});
```

**Environment Variables**
```zig
// Access the pre-parsed environment map provided by Init
if (init.environ_map.get("HOME")) |home| {
    std.debug.print("HOME: {s}\n", .{home});
}

// Check if environment variable exists
const has_path = init.environ_map.contains("PATH");
```

**Exit with Status Code**
```zig
// Normal exit
std.process.exit(0);

// Error exit
std.process.exit(1);

// Fatal error (logs message and exits with code 1)
std.process.fatal("Critical error occurred!", .{});
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Get arguments | `Args.iterateAllocator()` | `try init.minimal.args.iterateAllocator(init.gpa)` |
| Run command | `std.process.run()` | `try std.process.run(gpa, io, .{ .argv = &cmd })` |
| Spawn process | `std.process.spawn()` | `var child = try std.process.spawn(io, .{ .argv = &cmd })` |
| Get env var | `Environ.Map.get()` | `init.environ_map.get("PATH")` |
| Exit | `exit()` | `std.process.exit(0)` |
| Get current dir | `getCwd()` | `try std.process.getCwd(&buffer)` |
| Get executable path | `executablePath()` | `try std.process.executablePath(io, &buffer)` |

### ⚠️ Critical: Always Wait for Child Processes

```zig
// WRONG - Child process becomes zombie if not waited!
var child = try std.process.spawn(init.io, .{ .argv = &[_][]const u8{"sleep", "10"} });
// ❌ Forgot to wait! Process will become a zombie.

// CORRECT - Always wait or kill
var child = try std.process.spawn(init.io, .{ .argv = &[_][]const u8{"sleep", "10"} });
defer _ = child.wait(init.io) catch {}; // ✅ Cleanup guaranteed

// CORRECT - Alternative with kill
var child = try std.process.spawn(init.io, .{ .argv = &[_][]const u8{"sleep", "10"} });
defer child.kill(init.io); // ✅ Forcibly terminate and cleanup
```

---

## Overview

`std.process` provides comprehensive process management functionality including command-line argument parsing, environment variable access, child process creation and control, and process lifecycle management.

**Key Characteristics:**
- **Cross-platform**: Works on Windows, Linux, macOS, BSD, and WASI
- **Type-safe**: Compile-time checks for process options and behaviors
- **Resource-safe**: Patterns ensure proper cleanup of child processes and memory
- **Flexible I/O**: Full control over stdin/stdout/stderr redirection via `std.Io`
- **Environment management**: Read, set, and manipulate environment variables
- **Path resolution**: Find executables, get current directory, executable path

**When to use std.process:**
- Building CLI applications that parse command-line arguments
- Running external programs and capturing their output
- Creating process pipelines and complex process graphs
- Managing environment variables for child processes
- Getting system information (current directory, executable path, memory)
- Implementing build tools, test runners, or automation scripts

**Related namespaces:**
- `std.posix` - Lower-level OS syscalls (fork, exec, waitpid)
- `std.fs` - File system operations often used with process management
- `std.Io` - I/O primitives used for process stdin/stdout/stderr

---

## Core Types

### `Init`

The primary initialization structure passed to `main`. It provides access to common resources like allocators, arguments, and environment variables.

See [std.process.Init](std.process.Init.md) for details.

------

### `Child`

Represents a running child process returned by `std.process.spawn`.

**Fields:**
- `id: ?Id` - Process ID (PID on POSIX, hProcess on Windows). Becomes `null` after `wait()` or `kill()`
- `stdin: ?std.Io.File` - Write end of child's stdin pipe (requires `.pipe` in SpawnOptions)
- `stdout: ?std.Io.File` - Read end of child's stdout pipe (requires `.pipe` in SpawnOptions)
- `stderr: ?std.Io.File` - Read end of child's stderr pipe (requires `.pipe` in SpawnOptions)
- `resource_usage_statistics: ResourceUsageStatistics` - Statistics available after `wait()`

**Example:**
```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var child = try std.process.spawn(init.io, .{
        .argv = &[_][]const u8{ "echo", "Hello, World!" },
        .stdout = .pipe,
        .stderr = .pipe,
    });

    var stdout_list: std.ArrayList(u8) = .empty;
    defer stdout_list.deinit(init.gpa);
    var stderr_list: std.ArrayList(u8) = .empty;
    defer stderr_list.deinit(init.gpa);

    try child.collectOutput(init.gpa, &stdout_list, &stderr_list, 1024 * 1024);

    const term = try child.wait(init.io);
    std.debug.print("Output: {s}\n", .{stdout_list.items});
    std.debug.print("Exit status: {}\n", .{term});
}
```

------

### `Environ`

Represents environment variables in a platform-agnostic way. Provides access to the process's environment block.

See [std.process.Environ](std.process.Environ.md) for details.

------

### `Environ.Map`

A hash map for managing environment variables. An instance is provided in `std.process.Init`.

**Example:**
```zig
var env_map = std.process.Environ.Map.init(allocator);
defer env_map.deinit();

try env_map.put("MY_VAR", "my_value");
try env_map.put("PATH", "/custom/path");

var child = try std.process.spawn(io, .{
    .argv = &[_][]const u8{"program"},
    .environ_map = &env_map,
});
```

---

## Argument Parsing Functions

In Zig 0.16, arguments are accessed through the `Args` instance provided in `std.process.Init.Minimal`.

### `pub fn Args.iterateAllocator(a: Args, gpa: Allocator) !Iterator`

Returns an iterator over command-line arguments. First argument is typically the program name.

**Parameters:**
- `gpa` - Allocator for argument strings (e.g. `init.gpa`)

**Returns:** Iterator that yields argument strings. Caller must call `deinit()` on the iterator.

**Example:**
```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args.iterateAllocator(init.gpa);
    defer args.deinit();

    // Skip program name
    _ = args.skip();

    while (args.next()) |arg| {
        std.debug.print("Argument: {s}\n", .{arg});
    }
}
```

------

### `pub fn Args.toSlice(a: Args, arena: Allocator) ![]const [:0]const u8`

Allocates and returns all command-line arguments as a slice. An `ArenaAllocator` is recommended for simple cleanup.

**Example:**
```zig
const args = try init.minimal.args.toSlice(init.arena.allocator());

for (args, 0..) |arg, i| {
    std.debug.print("arg[{}]: {s}\n", .{i, arg});
}
```

---

## Child Process Functions

### `pub fn run(gpa: Allocator, io: Io, options: RunOptions) !RunResult`

High-level convenience function to run a child process and capture its output. Blocks until the process completes.

**Parameters:**
- `gpa` - Allocator for captured output
- `io` - Io interface for process management
- `options` - Spawn options including `argv`

**Returns:** `RunResult` with fields:
- `term: Term` - Termination status
- `stdout: []u8` - Captured stdout (caller owns)
- `stderr: []u8` - Captured stderr (caller owns)

**Example:**
```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const result = try std.process.run(init.gpa, init.io, .{
        .argv = &[_][]const u8{ "git", "status", "--short" },
    });
    defer init.gpa.free(result.stdout);
    defer init.gpa.free(result.stderr);

    switch (result.term) {
        .exited => |code| {
            if (code == 0) {
                std.debug.print("Git status:\n{s}\n", .{result.stdout});
            } else {
                std.debug.print("Git failed with code {}\n", .{code});
                std.debug.print("Error: {s}\n", .{result.stderr});
            }
        },
        .signal => |sig| {
            std.debug.print("Process killed by signal {}\n", .{sig});
        },
        else => {},
    }
}
```

------

### `pub fn spawn(io: Io, options: SpawnOptions) !Child`

Spawns a new Child process according to the provided options. The process is started immediately.

**Parameters:**
- `io` - Io interface for process management
- `options` - Configuration for the new process

**Returns:** A `Child` handle to the running process.

**Example:**
```zig
var child = try std.process.spawn(init.io, .{
    .argv = &[_][]const u8{ "ls", "-la" },
    .stdout = .pipe,
    .stderr = .inherit,
    .cwd = "/tmp",
});

defer _ = child.wait(init.io) catch {};
```

------

### `pub fn Child.wait(child: *Child, io: Io) !Term`

Blocks until the child process terminates, then cleans up resources.

**Returns:** `Term` union indicating how the process terminated:
- `.exited(u8)` - Normal exit with status code
- `.signal(SIG)` - Killed by signal (POSIX)
- `.stopped(u32)` - Stopped by signal (POSIX)
- `.unknown(u32)` - Unknown termination

**Example:**
```zig
const term = try child.wait(init.io);
switch (term) {
    .exited => |code| std.debug.print("Exit code: {}\n", .{code}),
    .signal => |sig| std.debug.print("Killed by signal {}\n", .{sig}),
    else => {},
}
```

------

### `pub fn Child.kill(child: *Child, io: Io) void`

Forcibly terminates the child process and cleans up all associated resources.

**Example:**
```zig
var child = try std.process.spawn(init.io, .{ .argv = &[_][]const u8{"sleep", "999"} });

// Changed our mind - kill it
child.kill(init.io);
```

---

## Environment Variable Functions

### `pub fn getEnvVarOwned(allocator: Allocator, key: []const u8) !?[]u8`

Gets an environment variable value. Returns `null` if not set.

**Parameters:**
- `allocator` - Allocator for returned string
- `key` - Variable name

**Returns:** Owned string value or `null`

**Example:**
```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    if (try std.process.getEnvVarOwned(init.gpa, "HOME")) |home| {
        defer init.gpa.free(home);
        std.debug.print("Home directory: {s}\n", .{home});
    } else {
        std.debug.print("HOME not set\n", .{});
    }
}
```

------

### `pub fn getEnvMap(allocator: Allocator) !*Environ.Map`

Creates a map of all environment variables. Caller owns the map and must call `deinit()`.

**Example:**
```zig
var env_map = try std.process.getEnvMap(init.gpa);
defer env_map.deinit();

var it = env_map.iterator();
while (it.next()) |entry| {
    std.debug.print("{s}={s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

---

## Path and Directory Functions

### `pub fn getCwd(buf: []u8) ![]u8`

Gets the current working directory.

**Parameters:**
- `buf` - Buffer for path (must be large enough)

**Returns:** Slice of `buf` containing path

**Errors:** `error.NameTooLong` if buffer too small

**Example:**
```zig
var buf: [std.fs.max_path_bytes]u8 = undefined;
const cwd = try std.process.getCwd(&buf);
std.debug.print("Current directory: {s}\n", .{cwd});
```

------

### `pub fn getCwdAlloc(allocator: Allocator) ![]u8`

Gets current working directory with dynamic allocation.

**Example:**
```zig
const cwd = try std.process.getCwdAlloc(init.gpa);
defer init.gpa.free(cwd);
std.debug.print("CWD: {s}\n", .{cwd});
```

------

### `pub fn executablePath(io: Io, buf: []u8) !usize`

Gets the absolute path to the currently running executable.

**Example:**
```zig
var buf: [std.fs.max_path_bytes]u8 = undefined;
const len = try std.process.executablePath(init.io, &buf);
std.debug.print("Executable: {s}\n", .{buf[0..len]});
```

---

## Process Lifecycle Functions

### `pub fn exit(status: u8) noreturn`

Immediately terminates the process with the given exit code. Does NOT run deferred cleanup.

**Parameters:**
- `status` - Exit code (0 = success, non-zero = error)

**Example:**
```zig
// Success
std.process.exit(0);

// Failure
std.process.exit(1);
```

------

### `pub fn abort() noreturn`

Causes abnormal process termination. Typically generates a core dump on POSIX systems.

**When to use:** Fatal errors, assertion failures, unrecoverable bugs

------

### `pub fn fatal(comptime format: []const u8, args: anytype) noreturn`

Logs an error message to stderr and exits with code 1.

**Example:**
```zig
const file = std.fs.cwd().openFile("config.json", .{}) catch {
    std.process.fatal("Failed to open config.json", .{});
};
```

---

## Usage Patterns

### Pattern 1: CLI Tool with Argument Parsing

```zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args.iterateAllocator(init.gpa);
    defer args.deinit();

    // Skip program name
    _ = args.skip();

    const input_file = args.next() orelse {
        std.debug.print("Usage: program <input-file> <output-file>\n", .{});
        std.process.exit(1);
    };

    const output_file = args.next() orelse {
        std.debug.print("Usage: program <input-file> <output-file>\n", .{});
        std.process.exit(1);
    };

    std.debug.print("Processing {s} -> {s}\n", .{input_file, output_file});

    // Process files...
}
```

------

### Pattern 2: Running Commands and Capturing Output

```zig
const std = @import("std");

fn runGitCommand(init: std.process.Init) !void {
    const result = try std.process.run(init.gpa, init.io, .{
        .argv = &[_][]const u8{ "git", "rev-parse", "HEAD" },
    });
    defer init.gpa.free(result.stdout);
    defer init.gpa.free(result.stderr);

    if (result.term != .exited or result.term.exited != 0) {
        std.debug.print("Git command failed: {s}\n", .{result.stderr});
        return error.GitFailed;
    }

    const commit_hash = std.mem.trim(u8, result.stdout, &std.ascii.whitespace);
    std.debug.print("Current commit: {s}\n", .{commit_hash});
}
```

------

### Pattern 3: Interactive Child Process (Piping Data)

```zig
const std = @import("std");

pub fn compressData(init: std.process.Init, data: []const u8) ![]u8 {
    var child = try std.process.spawn(init.io, .{
        .argv = &[_][]const u8{ "gzip", "-c" },
        .stdin = .pipe,
        .stdout = .pipe,
        .stderr = .pipe,
    });
    errdefer child.kill(init.io);

    // Write data to stdin
    try child.stdin.?.writeStreamingAll(init.io, data);
    child.stdin.?.close(init.io);
    child.stdin = null;

    // Read compressed output using collectOutput
    var stdout_list: std.ArrayList(u8) = .empty;
    defer stdout_list.deinit(init.gpa);
    var stderr_list: std.ArrayList(u8) = .empty;
    defer stderr_list.deinit(init.gpa);

    try child.collectOutput(init.gpa, &stdout_list, &stderr_list, 10 * 1024 * 1024);

    const term = try child.wait(init.io);
    if (term != .exited or term.exited != 0) {
        return error.CompressionFailed;
    }

    return try stdout_list.toOwnedSlice(init.gpa);
}
```

------

### Pattern 4: Custom Environment for Child Process

```zig
const std = @import("std");

pub fn runWithCustomEnv(init: std.process.Init) !void {
    var env_map = std.process.Environ.Map.init(init.gpa);
    defer env_map.deinit();

    // Start with custom environment
    try env_map.put("PATH", "/usr/local/bin:/usr/bin:/bin");
    try env_map.put("MY_CUSTOM_VAR", "custom_value");
    try env_map.put("LOG_LEVEL", "debug");

    var child = try std.process.spawn(init.io, .{
        .argv = &[_][]const u8{"./my_program"},
        .environ_map = &env_map,
    });

    const term = try child.wait(init.io);
    std.debug.print("Child exited with: {}\n", .{term});
}
```

------

### Pattern 5: Process Pipeline (Chaining Commands)

```zig
const std = @import("std");

pub fn runPipeline(init: std.process.Init) ![]u8 {
    // First command: cat file.txt
    var cat = try std.process.spawn(init.io, .{
        .argv = &[_][]const u8{ "cat", "file.txt" },
        .stdout = .pipe,
        .stderr = .pipe,
    });
    defer _ = cat.wait(init.io) catch {};

    // Second command: grep pattern
    var grep = try std.process.spawn(init.io, .{
        .argv = &[_][]const u8{ "grep", "pattern" },
        .stdin = .pipe,
        .stdout = .pipe,
        .stderr = .pipe,
    });
    defer _ = grep.wait(init.io) catch {};

    // Pipe cat's stdout to grep's stdin
    var cat_stdout: std.ArrayList(u8) = .empty;
    defer cat_stdout.deinit(init.gpa);
    var cat_stderr: std.ArrayList(u8) = .empty;
    defer cat_stderr.deinit(init.gpa);

    try cat.collectOutput(init.gpa, &cat_stdout, &cat_stderr, 10 * 1024 * 1024);

    try grep.stdin.?.writeStreamingAll(init.io, cat_stdout.items);
    grep.stdin.?.close(init.io);
    grep.stdin = null;

    // Get final output
    var grep_stdout: std.ArrayList(u8) = .empty;
    defer grep_stdout.deinit(init.gpa);
    var grep_stderr: std.ArrayList(u8) = .empty;
    defer grep_stderr.deinit(init.gpa);

    try grep.collectOutput(init.gpa, &grep_stdout, &grep_stderr, 10 * 1024 * 1024);
    
    _ = try grep.wait(init.io);

    return try grep_stdout.toOwnedSlice(init.gpa);
}
```

---

## Types and Constants

### `StdIo` (union)

Controls how child process stdin/stdout/stderr are handled.

**Variants:**
- `.inherit` - Inherit from parent process (default)
- `.pipe` - Create a pipe for communication
- `.ignore` - Discard input/output (opens /dev/null or NUL)
- `.file: File` - Use an already open file

**Example:**
```zig
var child = try std.process.spawn(io, .{
    .argv = &cmd,
    .stdin = .pipe,    // Parent can write to child
    .stdout = .pipe,   // Parent can read from child
    .stderr = .inherit, // Child errors go to parent's stderr
});
```

------

### `Term` (union)

Describes how a process terminated.

**Variants:**
- `exited: u8` - Normal exit with status code
- `signal: SIG` - Terminated by signal (POSIX)
- `stopped: u32` - Stopped by signal (POSIX)
- `unknown: u32` - Unknown/unsupported termination

**Example:**
```zig
const term = try child.wait(io);
switch (term) {
    .exited => |code| {
        if (code == 0) {
            std.debug.print("Success!\n", .{});
        } else {
            std.debug.print("Failed with code {}\n", .{code});
        }
    },
    .signal => |sig| {
        std.debug.print("Killed by signal {}\n", .{sig});
    },
    else => {},
}
```

------

### Constants

**`can_spawn: bool`**

Compile-time constant indicating whether the platform supports spawning child processes.

**`can_execve: bool`**

Compile-time constant indicating whether the platform supports `execve()` (process replacement).

---

## Error Sets

### `SpawnError`
- `error.OutOfMemory` - System out of memory
- `error.InvalidUserId` - Invalid user/group ID specified
- `error.PermissionDenied` - No permission to execute
- `error.FileNotFound` - Executable not found
- `error.AccessDenied` - File exists but not executable
- `error.InvalidExe` - File is not a valid executable
- `error.NameTooLong` - Path or argument too long
- `error.ResourceLimitReached` - Process limit reached

------

### `WaitError`
- `error.ChildExecFailed` - Child process failed to exec
- `error.Unexpected` - Unexpected OS error

------

### `RunError`
- `error.StdoutStreamTooLong` - Stdout exceeded max_output_bytes
- `error.StderrStreamTooLong` - Stderr exceeded max_output_bytes
- Plus `SpawnError` and `WaitError`

---

## Debug Checklist

✅ **Always wait for child processes** - Failing to call `wait()` or `kill()` creates zombie processes.

✅ **Check for null pipes** - `stdin`, `stdout`, and `stderr` on the `Child` struct are only available if configured as `.pipe`.

✅ **Use `std.process.Init`** - It's the most reliable way to get initialized allocators and I/O in Zig 0.16.

✅ **Check exit codes** - Don't assume `.exited(0)` means success in all cases; check the logic of the external program.

✅ **Free captured output** - `std.process.run()` allocates stdout/stderr - must free using the provided allocator.

✅ **Close stdin after writing** - Child won't see EOF until you close the stdin pipe using `close(io)` or set it to `null`.

✅ **Don't use `exit()` in libraries** - Only use in `main()` - it prevents cleanup.

---

## Performance Tips

1. **Use `std.process.run()` for simple cases** - Higher level, less boilerplate, automatic cleanup.

2. **Reuse `Environ.Map` when spawning many processes** - Create once, pass many times.

3. **Use `.inherit` when you don't need I/O control** - Avoids pipe overhead and intermediate buffering.

4. **Avoid polling wait()** - `child.wait(io)` blocks efficiently at the OS level.

5. **Set appropriate max_output_bytes in RunOptions** - Prevents runaway memory usage from rogue processes.

6. **Use `init.arena.allocator()` for bulk cleanup** - Perfect for temporary process operations that don't need manual tracking.

7. **Pass `init.io` directly** - Avoid creating multiple `Io` instances unless specifically needed for isolation.

---

## See Also

- **std.posix** - Low-level OS syscalls (fork, exec, waitpid, pipe)
- **std.fs** - File system operations for working directories and paths
- **std.Io** - I/O primitives used for process communication
- **std.process.Init** - The modern entry point for Zig 0.16 programs
- **std.Progress** - Progress reporting for long-running child processes
