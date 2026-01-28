# std.Io.Threaded

📚 **[See Comprehensive Examples & Tests](../../Examples/test_io_threaded_comprehensive.zig)** - Complete runnable code demonstrating Threaded I/O features

## Quick Start

### Basic Initialization
```zig
var threaded = std.Io.Threaded.init(allocator, .{
    .environ = .empty, // Required: specify environment variables
});
defer threaded.deinit();

const io = threaded.io(); // Get the Io interface
```

### Concurrent Execution
```zig
var task1 = io.async(doWork, .{ gpa, io, "A" });
defer if (task1.cancel(io)) |result| gpa.free(result) else |_| {};

var task2 = io.async(doWork, .{ gpa, io, "B" });
defer if (task2.cancel(io)) |result| gpa.free(result) else |_| {};

const result1 = try task1.await(io);
const result2 = try task2.await(io);
```

### File Reading
```zig
const file = try std.Io.Dir.cwd().openFile(io, "data.txt", .{});
defer file.close(io);

var buf: [1024]u8 = undefined;
// readStreaming takes a slice of buffers (scatter/gather I/O);
// for a single buffer, wrap it in a one-element array literal
const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
const data = buf[0..bytes_read];
```

### File Writing
```zig
const file = try std.Io.Dir.cwd().createFile(io, "output.txt", .{});
defer file.close(io);

var buf: [4096]u8 = undefined;
var writer = file.writer(io, &buf); // Requires 'io' and a buffer

// Use .interface for standard Writer methods
try writer.interface.writeAll("Hello Threaded World\n");
try writer.interface.flush();
```

⚠️ **Critical**: `Threaded.init` requires `.environ` in its options. Use `.empty` if you don't need environment variables. Omitting it is a compile error.

---

## Overview

`std.Io.Threaded` is the standard thread-pool based implementation of Zig's `Io` interface. It provides a way to perform concurrent and asynchronous I/O operations by offloading tasks to a pool of worker threads.

**Key Characteristics:**
- **Thread-Pool Backend**: Uses a pool of threads to execute I/O tasks.
- **Synchronous API compatibility**: Implements the `Io` interface, making it interchangeable with other backends like `Evented`.
- **Cross-Platform**: Works on all systems supported by Zig's standard library.
- **Resource Management**: Automatically manages worker threads and task queues.

**When to use:**
- In standard CLI or server applications that require concurrency but don't need the extreme scalability of evented I/O.
- When working with libraries that expect a standard `Io` interface.
- As a reliable, "works-everywhere" I/O backend.

## Fields

`allocator: Allocator`

The allocator used for internal structures, including worker thread state and task queues.

------

`async_limit: Io.Limit`

The maximum number of concurrent asynchronous tasks that can be queued.

------

`concurrent_limit: Io.Limit = .unlimited`

The maximum number of threads that can be spawned for concurrent operations.

------

`cpu_count_error: ?std.Thread.CpuCountError`

Stores any error encountered when trying to detect the CPU count during initialization.

------

`busy_count: usize = 0`

The number of worker threads currently executing tasks.

------

`stderr_writer: File.Writer`

A writer for the standard error stream, pre-configured for use with this backend.

------

`environ: Environ`

Stored environment variables for this I/O instance.

------

`stack_size: usize`

The stack size allocated for each worker thread.

------

`use_sendfile: UseSendfile`

Specifies whether to use the `sendfile` optimization if available.

## Types

- **Argv0**: Argument vector zero management.
- **Csprng**: Cryptographically Secure Pseudo-Random Number Generator state.
- **InitOptions**: Options passed to `init`.
- **Pid**: Process ID representation.
- **PosixAddress**: Low-level POSIX socket address.
- **UseSendfile**: Enum for `sendfile` optimization behavior (`.default`, `.always`, `.never`).

## Values

| Name | Type | Description |
| :--- | :--- | :--- |
| `global_single_threaded` | `*Threaded` | Global instance for single-threaded environments. Avoid direct use in libraries. |
| `init_single_threaded` | `Threaded` | Static initializer for a single-threaded I/O instance. |
| `socket_flags_unsupported` | `bool` | Indicates if the current platform lacks support for certain socket flags. |

## Core Functions

### `pub fn init(gpa: Allocator, options: InitOptions) Threaded`

Initializes a new `Threaded` I/O instance using the provided allocator and options. This sets up the task queue and detects system capabilities (like CPU count).

**Example:**
```zig
var threaded = std.Io.Threaded.init(gpa, .{ .environ = .empty });
```

------

### `pub fn deinit(t: *Threaded) void`

Cleans up all resources, joins worker threads, and releases memory. Must be called when the instance is no longer needed.

------

### `pub fn io(t: *Threaded) Io`

Returns the generic `Io` interface for this instance. This interface is what most functions (like file reading or networking) expect.

------

### `pub fn ioBasic(t: *Threaded) Io`

Same as `io()`, but excludes networking functionality. Useful on Windows to avoid dependencies on `ws2_32.lib`.

------

### `pub fn setAsyncLimit(t: *Threaded, new_limit: Io.Limit) void`

Updates the limit on how many asynchronous tasks can be queued.

## Path and Environment Functions

### `pub fn chdir(dir_path: []const u8) ChdirError!void`

Changes the current working directory.

------

### `pub fn environString(t: *Threaded, comptime name: []const u8) ?[:0]const u8`

Retrieves an environment variable by name.

## Platform and OS-specific Functions

### `pub fn dup2(old_fd: posix.fd_t, new_fd: posix.fd_t) DupError!void`

Wraps the `dup2` system call for file descriptor duplication.

------

### `pub fn pipe2(flags: posix.O) PipeError![2]posix.fd_t`

Creates a pipe with specified flags.

------

### `pub fn fchdir(fd: posix.fd_t) FchdirError!void`

Changes the current working directory using a file descriptor.

------

### `pub fn posixExecvPath(path: [*:0]const u8, child_argv: [*:null]const ?[*:0]const u8, envp: [*:null]const ?[*:0]const u8) process.ReplaceError`

Low-level POSIX execution function. Note: This function ignores the `PATH` environment variable.

------

### `pub fn posixSocketMode(mode: net.Socket.Mode) u32`

Converts a Zig socket mode to the corresponding POSIX constant.

------

### `pub fn addressFromPosix(posix_address: *const PosixAddress) IpAddress`

Converts a POSIX socket address to a Zig `IpAddress`.

------

### `pub fn addressToPosix(a: *const IpAddress, storage: *PosixAddress) posix.socklen_t`

Converts a Zig `IpAddress` to a POSIX socket address storage.

## Error Sets

- **ChdirError**: Errors from changing directory (AccessDenied, FileTooBig, etc.)
- **DupError**: Errors from duplicating file descriptors.
- **FchdirError**: Errors from changing directory via file descriptor.
- **PipeError**: Errors from pipe creation.

## Debug Checklist

- ✅ **Initialization**: Did you provide `.environ` in `InitOptions`?
- ✅ **Cleanup**: Did you call `deinit()`?
- ✅ **Interface**: Are you passing `threaded.io()` to functions expecting `Io`?
- ✅ **Windows Networking**: If you don't need networking, use `ioBasic()` to reduce binary size.

## Performance Tips

1. **Limit Concurrency**: Use `concurrent_limit` in `InitOptions` if you want to avoid spawning too many threads on high-core systems.
2. **Reuse Instance**: Create one `Threaded` instance and share its `Io` interface throughout your application.
3. **Async vs Sync**: Use `io.async()` for long-running operations to avoid blocking the main thread. Always pair with a `defer cancel` to avoid leaking results if the caller returns early.

## See Also

- `std.Io` - The generic I/O interface.
- `std.Io.Evented` - The asynchronous evented I/O backend.
- `std.Io.File` - High-level file operations.
- `std.Io.net` - Networking operations.
- `std.Io.net.Socket` - Socket type used with address conversion functions above.
