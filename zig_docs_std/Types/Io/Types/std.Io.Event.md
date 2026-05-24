# std.Io.Event

📚 **[See Comprehensive Examples & Tests](../../Examples/test_io_event.zig)** - Complete runnable code demonstrating Event synchronization

## Quick Start

### Basic Usage
```zig
var event = std.Io.Event.unset;

// In a worker thread/task:
event.set(io);

// In the main thread/task:
try event.wait(io);
```

### With Timeout
```zig
var event = std.Io.Event.unset;

// Wait up to 1 second
event.waitTimeout(io, .{
    .duration = .{
  .raw = std.Io.Duration.fromSeconds(1),
  .clock = .awake
    }
}) catch |err| switch (err) {
    error.Timeout => std.debug.print("Timed out waiting for event\n", .{}),
    else => return err,
};
```

⚠️ **Critical**: `Event` is an `enum(u32)` using atomic operations. Always initialize with `.unset` and use the provided methods for thread-safe access.

---

## Overview

`std.Io.Event` is a lightweight synchronization primitive introduced in Zig 0.16. It represents a logical boolean flag that can be set, reset, and waited upon. It is specifically designed to work with the `std.Io` interface, leveraging its `futexWait` and `futexWake` capabilities for efficient cross-thread and cross-backend signaling.

**Key Characteristics:**
- **Atomic State**: Uses atomic memory operations (`Xchg`, `Load`, `Store`) to ensure thread safety.
- **Io Integration**: Requires an `Io` instance for `wait` and `set` operations to perform efficient kernel-level or user-level waiting/waking.
- **Edge-Triggered Semantic**: Once set, it stays set until explicitly reset. Multiple calls to `set()` are safe and have no additional effect.
- **Zero Allocation**: The `Event` type itself is a simple enum and requires no heap allocation.

**When to use:**
- Signaling completion of a background task to a main loop.
- Implementing simple producer-consumer patterns where a "ready" signal is needed.
- Coordinating startup or shutdown sequences across multiple concurrent tasks.

## States (Enum Fields)

`unset`

The initial state. Logical value is `false`.

------

`waiting`

Internal state indicating that one or more threads are currently blocked on a `wait` operation.

------

`is_set`

The logical `true` state. Any pending or future `wait` calls will return immediately.

## Core Functions

### `pub fn isSet(event: *const Event) bool`

Returns whether the logical boolean is `true` (`is_set`). This uses an atomic `.acquire` load to ensure memory visibility of previous operations.

**Example:**
```zig
if (event.isSet()) {
    // Flag is true
}
```

------

### `pub fn set(e: *Event, io: Io) void`

Sets the logical boolean to `true`. This unblocks any pending calls to `wait`. The flag remains `true` until `reset` is called.

**Memory Visibility**: Any memory accesses prior to `set` are guaranteed to be visible to any task that subsequently observes `isSet() == true` or finishes a `wait()`.

**Example:**
```zig
// Prepare data
shared_data.ready = true;
// Signal completion
event.set(io);
```

------

### `pub fn reset(e: *Event) void`

Resets the logical boolean to `false` (`unset`).

⚠️ **Note**: This function assumes there are no pending calls to `wait` or `waitUncancelable`. Concurrent calls to `isSet`, `set`, and `reset` are allowed.

**Example:**
```zig
event.reset();
```

------

### `pub fn wait(event: *Event, io: Io) Io.Cancelable!void`

Blocks the current execution until the event is `set`.

**Example:**
```zig
try event.wait(io);
// Guaranteed that event.isSet() is now true
```

------

### `pub fn waitUncancelable(event: *Event, io: Io) void`

Same as `wait`, but does not introduce a cancellation point. It will ignore any attempts to cancel the current task while waiting.

------

### `pub fn waitTimeout(event: *Event, io: Io, timeout: Timeout) WaitTimeoutError!void`

Blocks until the event is set or the specified timeout expires.

**Returns:**
- `void`: If the event was set before the timeout.
- `error.Timeout`: If the timeout period elapsed.
- `error.Canceled`: If the wait was cancelled (and the backend supports it).

**Example:**
```zig
try event.waitTimeout(io, .fromMillis(500));
```

## Usage Patterns

### Background Task Completion Signal

```zig
const std = @import("std");

var completion_event = std.Io.Event.unset;

fn backgroundWorker(io: std.Io) !void {
    // Perform expensive computation
    performHeavyWork();

    // Signal completion
    completion_event.set(io);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Spawn background task
    var group = std.Io.Group.init(io);
    group.async(backgroundWorker, .{io});

    // Wait for completion
    try completion_event.wait(io);
    std.debug.print("Background task completed!\n", .{});
}
```

### Multi-Phase Startup Coordination

```zig
const std = @import("std");

const StartupPhases = struct {
    database_ready: std.Io.Event = .unset,
    cache_ready: std.Io.Event = .unset,
    network_ready: std.Io.Event = .unset,
};

fn initDatabase(phases: *StartupPhases, io: std.Io) !void {
    try connectToDatabase();
    phases.database_ready.set(io);
}

fn initCache(phases: *StartupPhases, io: std.Io) !void {
    // Wait for database first
    try phases.database_ready.wait(io);

    try setupCache();
    phases.cache_ready.set(io);
}

fn initNetwork(phases: *StartupPhases, io: std.Io) !void {
    // Wait for both database and cache
    try phases.database_ready.wait(io);
    try phases.cache_ready.wait(io);

    try startNetworkServer();
    phases.network_ready.set(io);
}

pub fn main() !void {
    var phases = StartupPhases{};

    // Launch initialization tasks
    var group = std.Io.Group.init(io);
    group.async(initDatabase, .{&phases, io});
    group.async(initCache, .{&phases, io});
    group.async(initNetwork, .{&phases, io});

    // Wait for full startup
    try phases.network_ready.wait(io);
    std.debug.print("All services ready!\n", .{});
}
```

### Graceful Shutdown Signal

```zig
const std = @import("std");

var shutdown_event = std.Io.Event.unset;

fn workerLoop(io: std.Io) !void {
    while (!shutdown_event.isSet()) {
  // Process work items
  processNextItem() catch |err| {
      if (err == error.NoMoreWork) {
          try io.sleep(.fromMilliseconds(10), .awake);
          continue;
      }
      return err;
  };
    }

    // Cleanup before exit
    cleanupResources();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Spawn workers
    var group = std.Io.Group.init(io);
    for (0..4) |_| {
  group.async(workerLoop, .{io});
    }

    // Wait for shutdown signal (e.g., SIGTERM handler)
    waitForShutdownSignal();

    // Signal all workers to stop
    shutdown_event.set(io);

    // Wait for workers to finish cleanup
    try group.wait();
}
```

### Event with Timeout (Operation Timeout Pattern)

```zig
const std = @import("std");

fn operationWithTimeout(
    operation_event: *std.Io.Event,
    io: std.Io,
    timeout_ms: u64
) !void {
    const timeout = std.Io.Timeout{
  .duration = .{
      .raw = std.Io.Duration.fromMillis(timeout_ms),
      .clock = .awake,
  },
    };

    operation_event.waitTimeout(io, timeout) catch |err| {
  if (err == error.Timeout) {
      std.debug.print("Operation timed out after {} ms\n", .{timeout_ms});
      return error.OperationTimeout;
  }
  return err;
    };

    std.debug.print("Operation completed within timeout\n", .{});
}
```

### Reusable Event (Reset Pattern)

```zig
const std = @import("std");

fn processMultipleBatches(io: std.Io) !void {
    var batch_ready = std.Io.Event.unset;

    for (0..5) |batch_num| {
  // Spawn batch processor
  spawnBatchProcessor(io, batch_num, &batch_ready);

  // Wait for this batch
  try batch_ready.wait(io);
  std.debug.print("Batch {} completed\n", .{batch_num});

  // Reset for next batch
  batch_ready.reset();
    }
}
```

## Error Sets

### `WaitTimeoutError`
Combines `error{Timeout}` with the potential cancellation error from the `Io` interface.

## Debug Checklist

- ✅ **Initialization**: Did you initialize with `std.Io.Event.unset`?
- ✅ **Io Instance**: Are you passing the same `Io` interface to both `set` and `wait`? (Ideally, though they can be different instances of the same backend).
- ✅ **Reset Safety**: Are you sure no one is waiting when you call `reset()`?
- ✅ **Redundant Sets**: Remember that calling `set()` multiple times is harmless; it only triggers a wake-up if the state was `waiting`.

## Performance Tips

1. **Avoid Frequent Resets**: `Event` is most efficient for "one-shot" or infrequent signaling. For high-frequency signaling, consider a dedicated queue.
2. **Atomic Load vs. Wait**: Use `isSet()` if you just want to check the status without blocking.
3. **Release/Acquire Semantics**: Zig handles the memory barriers for you. You don't need to manually sync shared memory if you use `Event` to signal readiness.

## See Also

- `std.Io.Future` - For values that are produced asynchronously.
- `std.Io.Mutex` - For mutual exclusion.
- `std.Io.Queue` - For passing data between tasks.
