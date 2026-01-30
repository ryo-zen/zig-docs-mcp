# std.Io.Evented

📚 **[See Comprehensive Examples & Tests](../../Examples/test_evented_io_uring.zig)** - Complete runnable code demonstrating Evented backend selection and usage

## Overview

`std.Io.Evented` is a compile-time type alias that selects the most efficient event-based I/O backend for the target operating system. It provides a unified entry point for asynchronous I/O, mapping to native kernel APIs like `io_uring` or `kqueue` where available.

**Type Definition:**
```zig
pub const Evented = switch (builtin.os.tag) {
    .linux => switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => std.Io.IoUring,
        else => void,
    },
    .dragonfly, .freebsd, .netbsd, .openbsd, .macos, .ios, .watchos, .tvos, .visionos => switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => std.Io.Kqueue,
        else => void,
    },
    else => void,
};
```

**Key Characteristics:**
- **Platform-Optimized**: Automatically selects `IoUring` on Linux and `Kqueue` on BSD/macOS.
- **Async-First**: Designed for high-concurrency, non-blocking I/O using native OS capabilities.
- **Io Interface**: Implements the standard `std.Io` interface, making it interchangeable with `Threaded` for most operations.

**When to use:**
- Cross-platform network servers requiring high C10k+ scalability.
- Applications needing maximum I/O throughput with minimal thread overhead.
- When you want the "best available" event loop for the target OS.

## Backend Selection

| Operating System | Architecture | Backend | Note |
| :--- | :--- | :--- | :--- |
| **Linux** | x86_64, aarch64 | [`std.Io.IoUring`](./std.Io.IoUring.md) | Requires kernel 5.1+ |
| **macOS / iOS** | x86_64, aarch64 | [`std.Io.Kqueue`](./std.Io.Kqueue.md) | |
| **BSD Family** | x86_64, aarch64 | [`std.Io.Kqueue`](./std.Io.Kqueue.md) | FreeBSD, OpenBSD, NetBSD, Dragonfly |
| **Windows** | Any | *Not yet implemented* | Use `std.Io.Threaded` |
| **Other** | - | `void` | Compile error if used |

## Usage

Because `Evented` is a type alias, you initialize it using the method signature of the underlying type. Note that initialization arguments may vary between backends.

### Initialization Example

```zig
const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    if (std.Io.Evented == void) {
        std.debug.print("Evented I/O not supported on this platform. Use Threaded.\n", .{});
        return;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var loop: std.Io.Evented = undefined;
    
    // Initialization signatures differ by backend:
    if (builtin.os.tag == .linux) {
        // IoUring initialization
        try loop.init(allocator);
    } else {
        // Kqueue initialization (requires options)
        try loop.init(allocator, .{});
    }
    defer loop.deinit();

    // Get the generic Io interface
    const io = loop.io();
    
    // Now use 'io' for standard operations
    const file = try std.Io.Dir.cwd().openFile(io, "data.txt", .{});
    defer file.close(io);
}
```

## See Also

- `std.Io.IoUring` - Documentation for the Linux backend.
- `std.Io.Kqueue` - Documentation for the BSD/macOS backend.
- `std.Io.Threaded` - The portable thread-pool backend (safe fallback for all platforms).