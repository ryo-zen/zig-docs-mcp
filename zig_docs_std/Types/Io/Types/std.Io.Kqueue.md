# std.Io.Kqueue

## Quick Start

### Basic Kqueue Backend

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var kq: std.Io.Kqueue = undefined;
    try kq.init(gpa.allocator(), .{});
    defer kq.deinit();

    const io = kq.io();

    // Use io for all I/O operations
    const file = try std.Io.File.open(io, "test.txt", .{});
    defer file.close(io);
}
```

### Using Kqueue with File Operations

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var kq: std.Io.Kqueue = undefined;
    try kq.init(gpa.allocator(), .{});
    defer kq.deinit();

    const io = kq.io();

    // Create and write to a file
    const file = try std.Io.File.create(io, "output.txt", .{});
    defer file.close(io);

    var buffer: [256]u8 = undefined;
    var writer = file.writer(io, &buffer);
    try writer.interface.writeAll("Hello from Kqueue!\n");
    try writer.interface.flush();
}
```

⚠️ **Critical**: Call `deinit()` to clean up threads and resources. The allocator must be thread-safe (e.g., `GeneralPurposeAllocator`).

---

## Overview

`std.Io.Kqueue` is a macOS and BSD-specific I/O backend leveraging the `kqueue` kernel event notification system. It provides efficient, scalable event-driven I/O by monitoring file descriptors, sockets, and other kernel events through the kqueue API. This backend is the native choice for macOS, FreeBSD, OpenBSD, NetBSD, and DragonFly BSD.

**Key Characteristics:**
- **Platform-Specific**: Only available on macOS and BSD systems
- **Kernel Event System**: Uses `kqueue(2)` and `kevent(2)` syscalls for event notification
- **Thread Pool**: Manages a pool of worker threads for concurrent I/O operations
- **Allocator-Based**: Requires a thread-safe allocator for dynamic memory management
- **Event Loop**: Efficiently waits for multiple events using `kevent(2)`

**When to use:**
- **macOS/BSD Targets**: Default choice on these platforms
- **High Concurrency**: Efficiently handles thousands of concurrent connections
- **Event-Driven I/O**: Network servers, file watchers, multi-client systems

**Platform Equivalents:**
- **Linux**: `std.Io.IoUring` (preferred) or `std.Io.Evented`
- **Windows**: `std.Io.Evented` (IOCP-based)
- **Cross-Platform**: `std.Io.Threaded` (works everywhere but less efficient)

## Fields

`gpa: Allocator`

The general-purpose allocator used for internal memory allocation (threads, buffers, task structures). **Must be thread-safe**, as multiple worker threads will use it concurrently.

**Recommended allocators:**
- `std.heap.GeneralPurposeAllocator` (thread-safe)
- `std.heap.c_allocator` (thread-safe)

**Not recommended:**
- `std.heap.ArenaAllocator` (not thread-safe)
- `std.heap.FixedBufferAllocator` (not thread-safe)

------

`mutex: std.Thread.Mutex`

Internal mutex protecting shared state across worker threads. Used to synchronize access to the kqueue file descriptor and event lists.

------

`main_fiber_buffer: [@sizeOf(Fiber) + Fiber.max_result_size]u8 align(@alignOf(Fiber))`

Buffer for the main execution fiber. Kqueue uses fibers (user-space cooperative threads) to manage task execution and context switching.

------

`threads: Thread.List`

List of worker threads managed by the kqueue backend. These threads wait for kernel events and execute I/O tasks.

## Types

### `InitOptions`

Configuration options for initializing a Kqueue backend.

**Note:** As of Zig 0.16, InitOptions is an empty struct. The Kqueue backend automatically manages thread pool sizing internally.

**Example:**
```zig
const options = std.Io.Kqueue.InitOptions{};
```

## Initialization

### `pub fn init(k: *Kqueue, gpa: Allocator, options: InitOptions) !void`

Initializes the Kqueue backend with the specified allocator and options.

**Parameters:**
- `gpa`: Thread-safe allocator for backend memory allocation
- `options`: Configuration (thread count, etc.)

**Errors:**
- `error.SystemResources`: Failed to create kqueue file descriptor or threads
- `error.OutOfMemory`: Allocator exhausted

**Behavior:**
- Creates the kqueue file descriptor via `createFileDescriptor()`
- Spawns `num_threads` worker threads (or CPU count if not specified)
- Initializes synchronization primitives (mutex, fibers)

**Example:**
```zig
var kq: std.Io.Kqueue = undefined;
try kq.init(gpa.allocator(), .{ .num_threads = null }); // Default thread count
defer kq.deinit();
```

------

### `pub fn deinit(k: *Kqueue) void`

Cleans up the Kqueue backend, stopping all worker threads and freeing resources.

**Behavior:**
- Signals all worker threads to terminate
- Joins (waits for) all threads to complete
- Closes the kqueue file descriptor
- Frees allocated memory

**Example:**
```zig
kq.deinit();
```

## Core Functions

### `pub fn io(k: *Kqueue) Io`

Returns an `Io` interface wrapping this Kqueue backend. This is the primary way to use the backend for I/O operations.

**Returns:** `std.Io` handle for the kqueue backend

**Example:**
```zig
const io = kq.io();

// Use io for all I/O operations
const file = try std.Io.File.create(io, "output.txt", .{});
defer file.close(io);
```

------

### `pub fn createFileDescriptor() CreateFileDescriptorError!posix.fd_t`

Creates a new kqueue file descriptor using the `kqueue(2)` syscall.

**Returns:** File descriptor for the kqueue instance

**Errors:**
- `error.SystemResources`: Kernel failed to create kqueue (resource limits)
- `error.ProcessFdQuotaExceeded`: Process has too many file descriptors open
- `error.SystemFdQuotaExceeded`: System-wide file descriptor limit reached

**Use case:** Typically called internally by `init()`. Advanced users may call directly for custom setups.

**Example:**
```zig
const kq_fd = try std.Io.Kqueue.createFileDescriptor();
defer std.posix.close(kq_fd);
```

------

### `pub fn kevent(kq: i32, changelist: []const posix.Kevent, eventlist: []posix.Kevent, timeout: ?*const posix.timespec) KEventError!usize`

Wrapper around the `kevent(2)` syscall for registering events and waiting for notifications.

**Parameters:**
- `kq`: kqueue file descriptor
- `changelist`: Events to register/modify (e.g., monitor a file descriptor)
- `eventlist`: Buffer to receive triggered events
- `timeout`: Optional timeout (null = block indefinitely)

**Returns:** Number of events returned in `eventlist`

**Errors:**
- `error.AccessDenied`: Insufficient permissions for file descriptor
- `error.ProcessNotFound`: PID specified in event doesn't exist
- `error.SystemResources`: Kernel resource exhaustion
- `error.Interrupted`: Syscall interrupted by signal

**Use case:** Advanced users implementing custom event loops. Most users should use `io()` instead.

**Example:**
```zig
var events: [16]posix.Kevent = undefined;
const num_events = try std.Io.Kqueue.kevent(kq_fd, &.{}, &events, null);

for (events[0..num_events]) |event| {
    std.debug.print("Event: {}\n", .{event});
}
```

## Error Sets

### `CreateFileDescriptorError`

Errors that can occur when creating a kqueue file descriptor.

**Possible errors:**
- `error.SystemResources`
- `error.ProcessFdQuotaExceeded`
- `error.SystemFdQuotaExceeded`

------

### `InitError`

Errors that can occur during kqueue initialization.

**Possible errors:**
- `error.OutOfMemory`
- `error.SystemResources`
- Includes all `CreateFileDescriptorError` values

------

### `KEventError`

Errors that can occur during `kevent(2)` syscall.

**Possible errors:**
- `error.AccessDenied`
- `error.ProcessNotFound`
- `error.SystemResources`
- `error.Interrupted`

## Usage Patterns

### Basic Server Pattern

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var kq: std.Io.Kqueue = undefined;
    try kq.init(gpa.allocator(), .{});
    defer kq.deinit();

    const io = kq.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1:8080", .{});
    var server = try addr.listen(io, .{});
    defer server.close(io);

    while (true) {
        const client = try server.accept(io);
        defer client.stream.close(io);

        // Handle client...
    }
}
```

### Network Server Pattern

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var kq: std.Io.Kqueue = undefined;
    try kq.init(gpa.allocator(), .{});
    defer kq.deinit();

    const io = kq.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1:8080", .{});
    var server = try addr.listen(io, .{});
    defer server.close(io);

    std.debug.print("Server listening on {}\n", .{addr});
    // Accept connections...
}
```

## Platform Notes

### Supported Platforms

- **macOS**: All versions with kqueue support (10.3+)
- **FreeBSD**: All modern versions
- **OpenBSD**: All modern versions
- **NetBSD**: All modern versions
- **DragonFly BSD**: All versions

### Performance Characteristics

- **Event Notification**: O(1) for event registration and retrieval
- **Scalability**: Handles thousands of concurrent file descriptors efficiently
- **Overhead**: Lower than select/poll, comparable to epoll (Linux)

### Comparison to Other Backends

| Backend | Platform | Event System | Scalability |
|---------|----------|--------------|-------------|
| `Kqueue` | macOS/BSD | kqueue | Excellent |
| `IoUring` | Linux 5.1+ | io_uring | Excellent |
| `Evented` | Cross-platform | epoll/IOCP/kqueue | Good |
| `Threaded` | Cross-platform | Thread pool + blocking I/O | Fair |

## Debug Checklist

- ✅ **Thread-Safe Allocator**: Is your allocator thread-safe?
- ✅ **Deinit Called**: Did you call `deinit()` before exiting?
- ✅ **Platform Check**: Are you running on macOS/BSD?
- ✅ **File Descriptor Limits**: Check `ulimit -n` if seeing "too many open files" errors

## Performance Tips

1. **Match Thread Count to Workload**: For CPU-bound tasks, use core count; for I/O-bound, use 2x core count
2. **Batch Events**: Process multiple events per `kevent()` call when possible
3. **Monitor Resource Usage**: Check file descriptor count (`lsof -p <pid> | wc -l`)
4. **Use Proper Allocator**: `GeneralPurposeAllocator` is thread-safe and efficient

## Troubleshooting

### "Too Many Open Files"

**Symptom:** `error.SystemFdQuotaExceeded` or `error.ProcessFdQuotaExceeded`

**Solution:**
```bash
# Check current limit
ulimit -n

# Increase limit (macOS)
ulimit -n 4096

# Permanent increase (macOS)
sudo launchctl limit maxfiles 65536 200000
```

### Slow Performance Despite Low CPU

**Cause:** Too few or too many threads

**Solution:** Tune `num_threads` based on workload:
- **I/O-bound**: 2x CPU cores
- **CPU-bound**: 1x CPU cores
- **Mixed**: 1.5x CPU cores

## See Also

- `std.Io` - Core I/O interface
- `std.Io.IoUring` - Linux equivalent (io_uring-based)
- `std.Io.Evented` - Cross-platform event-driven backend
- `std.Io.Threaded` - Simple thread pool backend
