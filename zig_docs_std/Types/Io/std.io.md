# std.Io

📚 **[See Comprehensive Examples & Tests](../../Examples/test_io_threaded.zig)** - Runnable code showing initialization and basic usage.
📘 **Reliability playbook:** [I/O Reliability and Backpressure](../../../zig_docs/io_reliability_backpressure.md)

## Quick Start

### 1. Initialize an Backend
To do any I/O in Zig 0.16, you first need to initialize a backend. `std.Io.Threaded` is the standard, cross-platform choice.

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Initialize the Threaded backend
    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();

    // Get the generic 'Io' interface
    const io = threaded.io();

    // Pass 'io' to functions that need it
    try doWork(io);
}
```

### 2. Async Execution
```zig
fn doWork(io: std.Io) !void {
    // Launch a task concurrently
    var task = io.async(heavyComputation, .{123});
    defer _ = task.cancel(io); // Always clean up futures

    // Do other work...
    io.sleep(.fromMilliseconds(100), .awake) catch {};

    // Await the result
    const result = try task.await(io);
}

fn heavyComputation(arg: u32) u32 {
    return arg * 2;
}
```

---

## Overview

`std.Io` is the central abstraction for all I/O and concurrency operations in Zig. It replaces the old ad-hoc `std.fs`, `std.net`, and `std.time` functions with a unified, vtable-based interface.

**Key Design Principles:**
- **Backend Agnostic**: Code written against `std.Io` runs on threads, io_uring, kqueue, or even custom backends without changes.
- **Explicit Context**: No global state. All I/O operations (reading files, sleeping, spawning tasks) require an `io` instance.
- **Integrated Concurrency**: Async/await is a library feature, not just a language keyword. `io.async` spawns tasks that are managed by the backend.

## Fields

`userdata: ?*anyopaque`

A pointer to the backend-specific state (e.g., the `Threaded` struct or `IoUring` instance).

------

`vtable: *const VTable`

The table of function pointers implementing the standard I/O operations.

## Core Types

### Primary Interfaces
- **[Threaded](Types/std.Io.Threaded.md)**: The standard cross-platform backend.
- **[Evented](Types/std.Io.Evented.md)**: High-performance async backend (IoUring/Kqueue).
- **[File](Types/std.Io.File.md)**: Buffered file operations.
- **[Reader](Types/std.Io.Reader.md)**: Generic stream reading interface.
- **[Writer](Types/std.Io.Writer.md)**: Generic stream writing interface.

### Namespaces
- **[net](Namespaces/std.Io.net.md)**: Networking primitives (Sockets, IPs).

### Support Types
- **[Clock](Types/std.Io.Clock.md)**: Time sources (`.awake`, `.boot`, `.real`, CPU clocks).
- **[Duration](Types/std.Io.Duration.md)**: Time duration handling.
- **[Future](Types/std.Io.Future.md)**: Handle for async task completion.

## Function Reference

### Concurrency & Tasks

#### `pub fn async(io: Io, function: anytype, args: anytype) Future`
Spawns a new task to run `function` with `args`. The task may run on another thread or be multiplexed on the same thread, depending on the backend. Returns a `Future` that must be awaited or canceled.

#### `pub fn concurrent(io: Io, function: anytype, args: anytype) ConcurrentError!Future`
Similar to `async`, but explicitly requests concurrent execution (e.g., on a separate thread). Can fail if the backend hits its concurrency limit.

#### `pub fn select(io: Io, s: anytype) Cancelable!SelectUnion`
Waits for one of multiple futures to complete. `s` is a struct of futures. Returns a union indicating which future finished first.

#### `pub fn checkCancel(io: Io) Cancelable!void`
Explicit cancellation point. Returns `error.Canceled` if the current task has been requested to stop.

#### `pub fn recancel(io: Io) void`
Re-arms a cancellation request after it has been caught.

#### `pub fn swapCancelProtection(io: Io, new: CancelProtection) CancelProtection`
Enables or disables cancellation for a critical section of code.

### Synchronization

#### `pub fn futexWait(io: Io, ptr: *const T, expected: T) Cancelable!void`
Atomically checks if `*ptr == expected` and blocks if true. Efficient low-level waiting primitive.

#### `pub fn futexWaitTimeout(io: Io, ptr: *const T, expected: T, timeout: Timeout) Cancelable!void`
Same as `futexWait` but with a timeout.

#### `pub fn futexWake(io: Io, ptr: *const T, max_waiters: u32) void`
Wakes up to `max_waiters` threads blocked on `ptr`.

#### `pub fn lockStderr(io: Io, buffer: []u8, terminal_mode: ?Terminal.Mode) Cancelable!LockedStderr`
Acquires a lock on standard error for coordinated printing.

### Time & Randomness

#### `pub fn sleep(io: Io, duration: Duration, clock: Clock) Cancelable!void`
Suspends execution for at least `duration`. Use `std.Io.Duration` constructors (e.g., `.fromMilliseconds(100)`).

#### `pub fn random(io: Io, buffer: []u8) void`
Fills `buffer` with random bytes. Use `randomSecure` when OS entropy is required.

#### `pub fn randomSecure(io: Io, buffer: []u8) (error{EntropyUnavailable} || Cancelable)!void`
Fills `buffer` using OS entropy and fails if secure entropy is unavailable.

## Error Sets

- **Cancelable**: `error{Canceled}`
- **ConcurrentError**: `error{TooManyConcurrentTasks, OutOfMemory}` + `Cancelable`
- **RandomSecureError**: `error{EntropyUnavailable}` + `Cancelable`
