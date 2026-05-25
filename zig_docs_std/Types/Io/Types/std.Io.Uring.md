# std.Io.Uring

📚 **[See Comprehensive Examples & Tests](../../Examples/test_evented_io_uring.zig)** - Complete runnable code demonstrating IoUring initialization and usage

## Quick Start

### Basic Initialization (Linux Only)
```zig
var ring: std.Io.Uring = undefined;
try ring.init(allocator);
defer ring.deinit();

const io = ring.io(); // Get the Io interface
```

### File Operations
```zig
const file = try std.Io.Dir.cwd().openFile(io, "data.txt", .{});
defer file.close(io);

var buf: [1024]u8 = undefined;
const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
```

⚠️ **Critical**: This backend is **Linux-only**. It requires a Linux kernel version that supports `io_uring` (5.1+ recommended). On non-Linux platforms, use `std.Io.Threaded`.

---

## Overview

`std.Io.Uring` is a high-performance, asynchronous I/O backend for Linux based on the `io_uring` kernel interface. Unlike thread-pool based approaches, `io_uring` allows applications to submit I/O requests to the kernel and retrieve completions asynchronously without the overhead of context switches or blocking syscalls.

**Key Characteristics:**
- **True Asynchrony**: Leverages the kernel's submission and completion queue rings.
- **Zero-Copy**: supports efficient data transfer paths.
- **Batching**: Can submit and reap multiple I/O operations in a single syscall.
- **Fiber-based**: Uses internal fibers (coroutines) to manage async control flow, integrating smoothly with Zig's `async`/`await` patterns (if applicable) or the `Io` interface.

**When to use:**
- High-performance network servers (HTTP, database) on Linux.
- I/O heavy applications requiring high throughput and low latency.
- As the underlying engine for `std.Io.Evented` on supported Linux architectures.

## Fields

`gpa: Allocator`

The allocator used for internal ring buffers, fiber stacks, and other dynamic resources. Must be thread-safe if the ring is shared.

------

`mutex: std.Thread.Mutex`

Internal mutex for synchronizing access to the ring submission queue, ensuring thread safety when multiple threads submit tasks to the same ring.

------

`main_fiber_buffer: [@sizeOf(Fiber) + Fiber.max_result_size]u8 align(@alignOf(Fiber))`

Statically allocated buffer storage for the main execution fiber's context.

------

`threads: Thread.List`

Internal list to track any auxiliary threads managed by this backend.

## Core Functions

### `pub fn init(self: *IoUring, gpa: Allocator) !void`

Initializes the `io_uring` backend. This sets up the submission and completion rings (SQ/CQ) with the kernel via the `io_uring_setup` syscall.

**Parameters:**
- `self`: Pointer to the `IoUring` struct to initialize.
- `gpa`: Allocator for internal resources.

**Example:**
```zig
var ring: std.Io.Uring = undefined;
try ring.init(allocator);
```

------

### `pub fn deinit(self: *IoUring) void`

Tears down the `io_uring` instance, unmaps the rings, closes the ring file descriptor, and frees any allocated resources.

------

### `pub fn io(self: *IoUring) Io`

Returns the generic `Io` interface for this instance. This vtable-based interface allows the `IoUring` backend to be used polymorphically with any standard `std.Io` functions.

## Debug Checklist

- ✅ **Kernel Support**: Is the running Linux kernel version 5.1 or newer? (Check with `uname -r`)
- ✅ **Privileges**: Does the process have sufficient locked memory limits (`ulimit -l`)? `io_uring` requires locking memory for the rings.
- ✅ **Initialization**: Did you call `init` on the struct pointer?
- ✅ **Platform**: Are you compiling for Linux? Use `@import("builtin").os.tag == .linux` checks.

## See Also

- `std.Io.Evented` - The generic event loop wrapper that defaults to `IoUring` on Linux.
- `std.Io.Threaded` - The portable thread-pool fallback for other platforms.
- `std.os.linux.IoUring` - Low-level wrapper for the io_uring subsystem.
