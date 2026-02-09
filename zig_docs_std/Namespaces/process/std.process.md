# std.process

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all process management features

## Quick Start

### Most Common Patterns

**Getting Command-Line Arguments**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();

    while (args.next()) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
```

**Running a Child Process (Capture Output)**
```zig
const result = try std.process.Child.run(.{
    .allocator = allocator,
    .argv = &[_][]const u8{ "ls", "-l" },
});
defer allocator.free(result.stdout);
defer allocator.free(result.stderr);

std.debug.print("stdout: {s}\n", .{result.stdout});
```

**Spawning a Child Process (Live Interaction)**
```zig
var child = std.process.Child.init(&[_][]const u8{ "cat" }, allocator);
child.stdin_behavior = .Pipe;
child.stdout_behavior = .Pipe;

try child.spawn();
defer _ = child.wait() catch {};

try child.stdin.?.writeAll("Hello from parent!\n");
child.stdin.?.close();
child.stdin = null;

const output = try child.stdout.?.readToEndAlloc(allocator, 1024);
defer allocator.free(output);
```

**Environment Variables**
```zig
// Get environment variable
if (try std.process.getEnvVarOwned(allocator, "HOME")) |home| {
    defer allocator.free(home);
    std.debug.print("HOME: {s}\n", .{home});
}

// Check if environment variable exists
const has_path = try std.process.hasEnvVarConstant("PATH");
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
| Get arguments | `argsWithAllocator()` | `try std.process.argsWithAllocator(allocator)` |
| Run command | `Child.run()` | `try Child.run(.{ .allocator = allocator, .argv = &cmd })` |
| Spawn process | `Child.init()` + `spawn()` | `var child = Child.init(&cmd, allocator); try child.spawn()` |
| Get env var | `getEnvVarOwned()` | `try std.process.getEnvVarOwned(allocator, "PATH")` |
| Exit | `exit()` | `std.process.exit(0)` |
| Get current dir | `getCwd()` | `try std.process.getCwd(&buffer)` |
| Get executable path | `getSelfExePath()` | `try std.process.getSelfExePath(&buffer)` |

### ⚠️ Critical: Always Clean Up Child Processes

```zig
// WRONG - Child process becomes zombie if not waited!
var child = std.process.Child.init(&[_][]const u8{"sleep", "10"}, allocator);
try child.spawn();
// ❌ Forgot to wait! Process will become a zombie.

// CORRECT - Always wait or kill
var child = std.process.Child.init(&[_][]const u8{"sleep", "10"}, allocator);
try child.spawn();
defer _ = child.wait() catch {}; // ✅ Cleanup guaranteed

// CORRECT - Alternative with kill
var child = std.process.Child.init(&[_][]const u8{"sleep", "10"}, allocator);
try child.spawn();
defer child.kill(); // ✅ Forcibly terminate and cleanup
```

---

## Overview

`std.process` provides comprehensive process management functionality including command-line argument parsing, environment variable access, child process creation and control, and process lifecycle management.

**Key Characteristics:**
- **Cross-platform**: Works on Windows, Linux, macOS, BSD, and WASI
- **Type-safe**: Compile-time checks for process options and behaviors
- **Resource-safe**: RAII patterns ensure proper cleanup of child processes
- **Flexible I/O**: Full control over stdin/stdout/stderr redirection
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
- `std.os` - Lower-level OS syscalls (fork, exec, waitpid)
- `std.fs` - File system operations often used with process management
- `std.io` - I/O primitives used for process stdin/stdout/stderr

---

## Core Types

### `Child`

Represents a child process that has been spawned or is ready to be spawned. This is the central type for process management in Zig.

**Fields:**
- `id: ?Id` - Process ID (PID on POSIX, hProcess on Windows). Becomes `null` after `wait()` or `kill()`
- `stdin: ?std.fs.File` - Write end of child's stdin pipe (requires `.Pipe` stdin_behavior)
- `stdout: ?std.fs.File` - Read end of child's stdout pipe (requires `.Pipe` stdout_behavior)
- `stderr: ?std.fs.File` - Read end of child's stderr pipe (requires `.Pipe` stderr_behavior)
- `stdin_behavior: StdIo` - How to handle stdin (`.Inherit`, `.Pipe`, `.Ignore`, `.Close`)
- `stdout_behavior: StdIo` - How to handle stdout
- `stderr_behavior: StdIo` - How to handle stderr
- `cwd: ?[]const u8` - Working directory for child process
- `env_map: ?*EnvMap` - Custom environment variables for child

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var child = std.process.Child.init(
        &[_][]const u8{ "echo", "Hello, World!" },
        allocator,
    );
    child.stdout_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(stdout);

    const term = try child.wait();
    std.debug.print("Output: {s}\n", .{stdout});
    std.debug.print("Exit code: {}\n", .{term});
}
```

------

### `Environ`

Represents environment variables in a platform-agnostic way. Provides access to the process's environment block.

**Key Methods:**
- `get()` - Get value of an environment variable
- `contains()` - Check if variable exists
- `createMap()` - Create a mutable map of environment variables

See [std.process.Environ](std.process.Environ.md) for details.

------

### `EnvMap`

A hash map for managing environment variables when spawning child processes.

**Example:**
```zig
var env_map = std.process.EnvMap.init(allocator);
defer env_map.deinit();

try env_map.put("MY_VAR", "my_value");
try env_map.put("PATH", "/custom/path");

var child = std.process.Child.init(&[_][]const u8{"program"}, allocator);
child.env_map = &env_map;
try child.spawn();
```

------

## Argument Parsing Functions

### `pub fn argsWithAllocator(allocator: Allocator) !ArgIterator`

Returns an iterator over command-line arguments. First argument is typically the program name.

**Parameters:**
- `allocator` - Allocator for argument strings

**Returns:** Iterator that yields argument strings

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(gpa.allocator());
    defer args.deinit();

    // Skip program name
    _ = args.skip();

    while (args.next()) |arg| {
        std.debug.print("Argument: {s}\n", .{arg});
    }
}
```

------

### `pub fn argsAlloc(allocator: Allocator) ![][:0]u8`

Allocates and returns all command-line arguments as a slice. Caller must free each argument and the slice.

**Example:**
```zig
const args = try std.process.argsAlloc(allocator);
defer std.process.argsFree(allocator, args);

for (args, 0..) |arg, i| {
    std.debug.print("arg[{}]: {s}\n", .{i, arg});
}
```

------

### `pub fn argsFree(allocator: Allocator, args: [][:0]u8) void`

Frees memory allocated by `argsAlloc()`.

------

## Child Process Functions

### `pub fn Child.run(args: RunArgs) !RunResult`

High-level convenience function to run a child process and capture its output. Blocks until the process completes.

**Parameters (in `RunArgs`):**
- `allocator` - Allocator for captured output
- `argv` - Command and arguments as string array
- `cwd` - Optional working directory
- `env_map` - Optional environment variables
- `max_output_bytes` - Limit for stdout/stderr capture (default: 50MB)
- `expand_arg0` - Whether to search PATH for argv[0]

**Returns:** `RunResult` with fields:
- `term: Term` - Termination status
- `stdout: []u8` - Captured stdout (caller owns)
- `stderr: []u8` - Captured stderr (caller owns)

**Errors:**
- `error.StdoutStreamTooLong` - Output exceeded max_output_bytes
- `error.StderrStreamTooLong` - Error output exceeded max_output_bytes
- Plus spawn/wait errors

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "status", "--short" },
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    switch (result.term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("Git status:\n{s}\n", .{result.stdout});
            } else {
                std.debug.print("Git failed with code {}\n", .{code});
                std.debug.print("Error: {s}\n", .{result.stderr});
            }
        },
        .Signal => |sig| {
            std.debug.print("Process killed by signal {}\n", .{sig});
        },
        else => {},
    }
}
```

------

### `pub fn Child.init(argv: []const []const u8, allocator: Allocator) Child`

Creates a new Child process object without spawning it. Allows full configuration before spawning.

**Parameters:**
- `argv` - Command and arguments
- `allocator` - Allocator for process management

**Returns:** Initialized `Child` struct (not yet running)

**Example:**
```zig
var child = std.process.Child.init(
    &[_][]const u8{ "ls", "-la" },
    allocator,
);

// Configure before spawning
child.stdout_behavior = .Pipe;
child.stderr_behavior = .Pipe;
child.cwd = "/tmp";

try child.spawn();
defer _ = child.wait() catch {};
```

------

### `pub fn Child.spawn(child: *Child) !void`

Spawns the child process. Must be called after `init()` and configuration.

**Errors:**
- `error.InvalidUserId` - Invalid UID/GID specified
- `error.PermissionDenied` - No permission to execute
- `error.FileNotFound` - Executable not found
- `error.OutOfMemory` - System out of memory
- Plus OS-specific errors

------

### `pub fn Child.wait(child: *Child) !Term`

Blocks until the child process terminates, then cleans up resources.

**Returns:** `Term` enum indicating how the process terminated:
- `.Exited(u8)` - Normal exit with status code
- `.Signal(u32)` - Killed by signal (POSIX)
- `.Stopped(u32)` - Stopped by signal (POSIX)
- `.Unknown(u32)` - Unknown termination

**Example:**
```zig
try child.spawn();

const term = try child.wait();
switch (term) {
    .Exited => |code| std.debug.print("Exit code: {}\n", .{code}),
    .Signal => |sig| std.debug.print("Killed by signal {}\n", .{sig}),
    else => {},
}
```

------

### `pub fn Child.kill(child: *Child) !Term`

Forcibly terminates the child process (SIGKILL on POSIX, TerminateProcess on Windows), then waits for it and cleans up.

**Example:**
```zig
var child = std.process.Child.init(&[_][]const u8{"sleep", "999"}, allocator);
try child.spawn();

// Changed our mind - kill it
const term = try child.kill();
std.debug.print("Process terminated: {}\n", .{term});
```

------

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    if (try std.process.getEnvVarOwned(gpa.allocator(), "HOME")) |home| {
        defer gpa.allocator().free(home);
        std.debug.print("Home directory: {s}\n", .{home});
    } else {
        std.debug.print("HOME not set\n", .{});
    }
}
```

------

### `pub fn getEnvMap(allocator: Allocator) !*EnvMap`

Creates a map of all environment variables. Caller owns the map and must call `deinit()`.

**Example:**
```zig
var env_map = try std.process.getEnvMap(allocator);
defer env_map.deinit();

var it = env_map.iterator();
while (it.next()) |entry| {
    std.debug.print("{s}={s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
}
```

------

### `pub fn hasEnvVarConstant(comptime key: []const u8) bool`

Compile-time check if an environment variable exists. Useful for conditional compilation.

**Example:**
```zig
const has_ci = comptime std.process.hasEnvVarConstant("CI");
if (has_ci) {
    // Running in CI environment
}
```

------

## Path and Directory Functions

### `pub fn getCwd(buf: []u8) ![]u8`

Gets the current working directory.

**Parameters:**
- `buf` - Buffer for path (must be large enough)

**Returns:** Slice of `buf` containing path

**Errors:** `error.NameTooLong` if buffer too small

**Example:**
```zig
var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
const cwd = try std.process.getCwd(&buf);
std.debug.print("Current directory: {s}\n", .{cwd});
```

------

### `pub fn getCwdAlloc(allocator: Allocator) ![]u8`

Gets current working directory with dynamic allocation.

**Example:**
```zig
const cwd = try std.process.getCwdAlloc(allocator);
defer allocator.free(cwd);
std.debug.print("CWD: {s}\n", .{cwd});
```

------

### `pub fn changeCurDir(dir_path: []const u8) !void`

Changes the current working directory.

**Example:**
```zig
try std.process.changeCurDir("/tmp");
```

------

### `pub fn getSelfExePath(buf: []u8) ![]u8`

Gets the absolute path to the currently running executable.

**Example:**
```zig
var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
const exe_path = try std.process.getSelfExePath(&buf);
std.debug.print("Executable: {s}\n", .{exe_path});
```

------

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

------

## Usage Patterns

### Pattern 1: CLI Tool with Argument Parsing

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.skip();

    const input_file = args.next() orelse {
        std.debug.print("Usage: program <input-file>\n", .{});
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

fn runGitCommand(allocator: std.mem.Allocator) !void {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "git", "rev-parse", "HEAD" },
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    if (result.term != .Exited or result.term.Exited != 0) {
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

pub fn compressData(allocator: std.mem.Allocator, data: []const u8) ![]u8 {
    var child = std.process.Child.init(
        &[_][]const u8{ "gzip", "-c" },
        allocator,
    );
    child.stdin_behavior = .Pipe;
    child.stdout_behavior = .Pipe;

    try child.spawn();
    errdefer _ = child.kill() catch {};

    // Write data to stdin
    try child.stdin.?.writeAll(data);
    child.stdin.?.close();
    child.stdin = null;

    // Read compressed output
    const compressed = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    errdefer allocator.free(compressed);

    const term = try child.wait();
    if (term != .Exited or term.Exited != 0) {
        allocator.free(compressed);
        return error.CompressionFailed;
    }

    return compressed;
}
```

------

### Pattern 4: Custom Environment for Child Process

```zig
const std = @import("std");

pub fn runWithCustomEnv(allocator: std.mem.Allocator) !void {
    var env_map = std.process.EnvMap.init(allocator);
    defer env_map.deinit();

    // Start with parent environment
    try env_map.put("PATH", "/usr/local/bin:/usr/bin:/bin");
    try env_map.put("MY_CUSTOM_VAR", "custom_value");
    try env_map.put("LOG_LEVEL", "debug");

    var child = std.process.Child.init(
        &[_][]const u8{"./my_program"},
        allocator,
    );
    child.env_map = &env_map;

    try child.spawn();
    const term = try child.wait();

    std.debug.print("Child exited with: {}\n", .{term});
}
```

------

### Pattern 5: Process Pipeline (Chaining Commands)

```zig
const std = @import("std");

pub fn runPipeline(allocator: std.mem.Allocator) ![]u8 {
    // First command: cat file.txt
    var cat = std.process.Child.init(&[_][]const u8{ "cat", "file.txt" }, allocator);
    cat.stdout_behavior = .Pipe;
    try cat.spawn();
    defer _ = cat.wait() catch {};

    // Second command: grep pattern
    var grep = std.process.Child.init(&[_][]const u8{ "grep", "pattern" }, allocator);
    grep.stdin_behavior = .Pipe;
    grep.stdout_behavior = .Pipe;
    try grep.spawn();
    defer _ = grep.wait() catch {};

    // Pipe cat's stdout to grep's stdin
    const cat_output = try cat.stdout.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(cat_output);

    try grep.stdin.?.writeAll(cat_output);
    grep.stdin.?.close();
    grep.stdin = null;

    // Get final output
    const result = try grep.stdout.?.readToEndAlloc(allocator, 10 * 1024 * 1024);
    return result;
}
```

------

## Types and Constants

### `StdIo` (enum)

Controls how child process stdin/stdout/stderr are handled.

**Values:**
- `.Inherit` - Inherit from parent process (default)
- `.Pipe` - Create a pipe for communication
- `.Ignore` - Discard input/output
- `.Close` - Close the file descriptor

**Example:**
```zig
child.stdin_behavior = .Pipe;    // Parent can write to child
child.stdout_behavior = .Pipe;   // Parent can read from child
child.stderr_behavior = .Inherit; // Child errors go to parent's stderr
```

------

### `Term` (union)

Describes how a process terminated.

**Variants:**
- `.Exited(u8)` - Normal exit with status code
- `.Signal(u32)` - Terminated by signal (POSIX)
- `.Stopped(u32)` - Stopped by signal (POSIX)
- `.Unknown(u32)` - Unknown/unsupported termination

**Example:**
```zig
const term = try child.wait();
switch (term) {
    .Exited => |code| {
        if (code == 0) {
            std.debug.print("Success!\n", .{});
        } else {
            std.debug.print("Failed with code {}\n", .{code});
        }
    },
    .Signal => |sig| {
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

------

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

------

## Debug Checklist

✅ **Always wait for or kill child processes** - Failing to wait creates zombie processes

✅ **Close pipe ends you don't use** - Keep stdin/stdout/stderr = null if not using `.Pipe`

✅ **Check exit codes** - Don't assume `.Exited(0)` means success in all cases

✅ **Free captured output** - `Child.run()` allocates stdout/stderr - must free

✅ **Use defer for cleanup** - `defer _ = child.wait() catch {};` prevents leaks

✅ **Handle spawn errors** - Executable might not exist or have wrong permissions

✅ **Limit output capture** - Set reasonable `max_output_bytes` to prevent OOM

✅ **Close stdin after writing** - Child won't see EOF until you close stdin pipe

✅ **Don't use `exit()` in libraries** - Only use in `main()` - prevents cleanup

✅ **Validate argument arrays** - Empty `argv` or `null` elements cause errors

------

## Performance Tips

1. **Use `Child.run()` for simple cases** - Higher level, less boilerplate, automatic cleanup:
   ```zig
   const result = try std.process.Child.run(.{
       .allocator = allocator,
       .argv = &cmd,
   });
   defer allocator.free(result.stdout);
   defer allocator.free(result.stderr);
   ```

2. **Pre-size buffers for output capture** - Reduce allocations when you know output size:
   ```zig
   const result = try std.process.Child.run(.{
       .allocator = allocator,
       .argv = &cmd,
       .max_output_bytes = 1024 * 1024, // 1MB limit
   });
   ```

3. **Reuse EnvMap when spawning many processes** - Create once, use multiple times:
   ```zig
   var env_map = try std.process.getEnvMap(allocator);
   defer env_map.deinit();
   try env_map.put("CUSTOM", "value");

   for (commands) |cmd| {
       var child = std.process.Child.init(cmd, allocator);
       child.env_map = &env_map; // Reuse
       try child.spawn();
   }
   ```

4. **Use `.Inherit` when you don't need I/O control** - Avoids pipe overhead:
   ```zig
   child.stdout_behavior = .Inherit; // Faster than .Pipe
   ```

5. **Avoid polling wait()** - Blocks efficiently at OS level, don't busy-wait

6. **Set appropriate max_output_bytes** - Prevents runaway memory usage:
   ```zig
   const result = try std.process.Child.run(.{
       .allocator = allocator,
       .argv = &cmd,
       .max_output_bytes = 10 * 1024, // 10KB max
   });
   ```

7. **Use ArenaAllocator for temporary process operations** - Bulk cleanup:
   ```zig
   var arena = std.heap.ArenaAllocator.init(base_allocator);
   defer arena.deinit();

   const result = try std.process.Child.run(.{
       .allocator = arena.allocator(),
       .argv = &cmd,
   });
   // No need to free stdout/stderr - arena handles it
   ```

------

## See Also

- **std.os** - Low-level OS syscalls (fork, exec, waitpid, pipe)
- **std.fs** - File system operations for working directories and paths
- **std.io** - I/O primitives for process stdin/stdout/stderr
- **std.ChildProcess** - Legacy name for `std.process.Child`
- **std.Progress** - Progress reporting for long-running child processes
