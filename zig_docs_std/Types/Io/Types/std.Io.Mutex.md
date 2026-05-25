# std.Io.Mutex

## Quick Start

### Protecting Shared Data

```zig
const std = @import("std");

var counter: u32 = 0;
var counter_mutex = std.Io.Mutex.init;

pub fn incrementCounter(io: std.Io) !void {
    try counter_mutex.lock(io);
    defer counter_mutex.unlock(io);

    counter += 1; // Protected access
}
```

### Try-Lock Pattern

```zig
const std = @import("std");

pub fn tryUpdate(mutex: *std.Io.Mutex, io: std.Io) !void {
    if (mutex.tryLock()) {
  defer mutex.unlock(io);

  // Got the lock - do work
  try performCriticalOperation();
    } else {
  // Lock is held by someone else - skip or retry later
  std.debug.print("Lock busy, skipping update\n", .{});
    }
}
```

### Uncancelable Lock

```zig
const std = @import("std");

pub fn criticalCleanup(mutex: *std.Io.Mutex, io: std.Io) void {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);

    // This cleanup cannot be interrupted by cancellation
    performCleanup();
}
```

⚠️ **Critical**: Always unlock with `defer` immediately after locking to prevent deadlocks. Forgetting to unlock will permanently block other tasks.

---

## Overview

`std.Io.Mutex` is a synchronization primitive enforcing mutually exclusive access to shared resources. It integrates with the `std.Io` framework, allowing tasks to block efficiently when waiting for lock acquisition using futex-based OS primitives or user-space scheduling.

**Key Characteristics:**
- **Mutual Exclusion**: Only one task can hold the lock at a time
- **Blocking**: Tasks waiting for the lock suspend via `std.Io`, yielding CPU efficiently
- **Cancellable**: `lock()` can return `error.Canceled` if the task is cancelled while waiting
- **Extern Layout**: Uses `extern struct` for stable memory layout, enabling IPC via shared memory (mmap)
- **Futex-Based**: Leverages OS futex (Linux) or equivalent for efficient kernel-assisted blocking

**When to use:**
- Protecting shared mutable state accessed by multiple tasks
- Coordinating access to non-thread-safe resources (file handles, caches)
- Implementing higher-level synchronization primitives (semaphores, condition variables)

**When NOT to use:**
- Single-threaded code with no concurrency
- Read-heavy workloads (consider read-write locks)
- Lock-free algorithms (consider atomics directly)

## Fields

`state: std.atomic.Value(State)`

Atomic value tracking the mutex state (unlocked, locked, or locked with waiters). Uses atomic operations for lock-free fast-path acquire/release.

**Internal representation** (opaque to users):
- unlocked: no task holds the lock
- locked_once: one task holds the lock with no known waiters
- contended: one task holds the lock and others may be blocked

------

## Types

### `State`

Internal enum representing the mutex state machine. Not directly usable by application code.

**Values:**
- `unlocked`
- `locked_once`
- `contended`

## Initialization

### `init: Mutex`

Constant initializer for creating an unlocked mutex.

**Example:**
```zig
var mutex = std.Io.Mutex.init;
```

**For global/static mutexes:**
```zig
var global_mutex = std.Io.Mutex.init;
```

## Core Functions

### `pub fn lock(m: *Mutex, io: Io) Cancelable!void`

Acquires the mutex, blocking if it's currently held by another task. Returns when the lock is acquired or if the task is cancelled.

**Errors:**
- `error.Canceled`: The task was cancelled while waiting for the lock

**Behavior:**
- If unlocked: Acquires immediately (fast path)
- If locked: Blocks the current task until the holder calls `unlock()`
- Cancellable: Returns `error.Canceled` if task is cancelled while waiting

**Example:**
```zig
try mutex.lock(io);
defer mutex.unlock(io);

// Critical section - only one task executes here at a time
shared_data.value += 1;
```

------

### `pub fn lockUncancelable(m: *Mutex, io: Io) void`

Same as `lock()`, but does not introduce a cancellation point. Guarantees the lock will be acquired, even if the task is cancelled.

**Use case:** Critical cleanup or shutdown sequences that must complete regardless of cancellation.

**Example:**
```zig
mutex.lockUncancelable(io);
defer mutex.unlock(io);

// This cleanup will complete even if task is cancelled
releaseResources();
```

------

### `pub fn tryLock(m: *Mutex) bool`

Attempts to acquire the lock without blocking.

**Returns:**
- `true`: Lock was acquired (caller now owns the lock)
- `false`: Lock is currently held by another task (no state change)

**Use case:**
- Polling patterns
- Optional critical sections
- Avoiding deadlock in lock hierarchies

**Example:**
```zig
if (mutex.tryLock()) {
    defer mutex.unlock(io);

    // Acquired lock - do work
    updateCachedData();
} else {
    // Lock busy - use stale data or retry later
}
```

------

### `pub fn unlock(m: *Mutex, io: Io) void`

Releases the mutex, allowing one waiting task (if any) to acquire it.

**Behavior:**
- If no waiters: Sets state to `unlocked`
- If waiters: Wakes one waiting task and transfers ownership

**⚠️ Precondition:** The calling task must currently hold the lock (undefined behavior otherwise).

**Example:**
```zig
mutex.lock(io);
defer mutex.unlock(io); // Always use defer

// Critical section
```

## Usage Patterns

### Defer Unlock Idiom

```zig
const std = @import("std");

pub fn safeUpdate(mutex: *std.Io.Mutex, io: std.Io) !void {
    try mutex.lock(io);
    defer mutex.unlock(io); // Unlocks even on error paths

    try mightFail();
    updateState();
    // Lock automatically released on return or error
}
```

### Producer-Consumer with Mutex

```zig
const std = @import("std");

const SharedQueue = struct {
    mutex: std.Io.Mutex = .init,
    data: std.ArrayList(u32),

    pub fn push(self: *SharedQueue, io: std.Io, value: u32) !void {
  try self.mutex.lock(io);
  defer self.mutex.unlock(io);

  try self.data.append(value);
    }

    pub fn pop(self: *SharedQueue, io: std.Io) !?u32 {
  try self.mutex.lock(io);
  defer self.mutex.unlock(io);

  if (self.data.items.len == 0) return null;
  return self.data.pop();
    }
};
```

### Try-Lock for Timeout Simulation

```zig
const std = @import("std");

pub fn lockWithTimeout(mutex: *std.Io.Mutex, io: std.Io, max_attempts: u32) !void {
    var attempts: u32 = 0;
    while (attempts < max_attempts) : (attempts += 1) {
  if (mutex.tryLock()) {
      defer mutex.unlock(io);
      performWork();
      return;
  }

  // Brief sleep before retry
  try io.sleep(.fromMilliseconds(10), .awake);
    }

    return error.LockTimeout;
}
```

### Lock Hierarchy (Preventing Deadlock)

```zig
const std = @import("std");

// Always lock in the same order: mutex1 → mutex2
pub fn updateBoth(m1: *std.Io.Mutex, m2: *std.Io.Mutex, io: std.Io) !void {
    try m1.lock(io);
    defer m1.unlock(io);

    try m2.lock(io);
    defer m2.unlock(io);

    // Both locks held - safe to update
    updateResource1();
    updateResource2();
}
```

## Extern Struct for IPC

The mutex is defined as `extern struct`, providing a stable memory layout for inter-process communication:

```zig
const std = @import("std");

// Shared memory structure
const SharedData = extern struct {
    mutex: std.Io.Mutex,
    counter: u32,
};

pub fn ipcExample() !void {
    // Map shared memory region
    const shm = try std.os.mmap(...);
    const shared: *SharedData = @alignCast(@ptrCast(shm.ptr));

    // Processes can synchronize using the shared mutex
    try shared.mutex.lock(io);
    defer shared.mutex.unlock(io);

    shared.counter += 1;
}
```

## Error Handling

### Handling Cancellation

```zig
const std = @import("std");

pub fn cancellableUpdate(mutex: *std.Io.Mutex, io: std.Io) !void {
    mutex.lock(io) catch |err| {
  if (err == error.Canceled) {
      std.debug.print("Task cancelled while waiting for lock\n", .{});
      return error.Canceled;
  }
  return err;
    };
    defer mutex.unlock(io);

    // Acquired lock - proceed with update
}
```

## Debug Checklist

- ✅ **Defer Unlock**: Did you use `defer mutex.unlock(io)` immediately after locking?
- ✅ **Lock Order**: Are you always acquiring multiple locks in the same order?
- ✅ **Unlock Owner**: Are you only calling `unlock()` from the task that acquired the lock?
- ✅ **No Double Lock**: Are you avoiding locking the same mutex twice in one task (not reentrant)?
- ✅ **Handle Cancellation**: If using `lock()`, do you handle `error.Canceled`?

## Performance Tips

1. **Keep Critical Sections Small**: Minimize time spent holding the lock
2. **Use `tryLock()` for Contention Detection**: Measure lock contention by tracking `tryLock()` failure rates
3. **Prefer `lockUncancelable()` for Cleanup**: Avoid cancellation overhead in shutdown paths
4. **Avoid Nested Locks**: Reduces deadlock risk and improves performance
5. **Consider Read-Write Locks**: If reads vastly outnumber writes, use RwLock instead

## Common Pitfalls

### Double Lock (Deadlock)

```zig
// ❌ BAD: Deadlock
mutex.lock(io);
mutex.lock(io); // Blocks forever (not reentrant)
```

### Forgetting Unlock

```zig
// ❌ BAD: Lock never released
mutex.lock(io);
if (error_condition) {
    return error.Failed; // Forgot to unlock!
}
mutex.unlock(io);
```

**Fix with defer:**
```zig
// ✅ GOOD
try mutex.lock(io);
defer mutex.unlock(io); // Always unlocks
if (error_condition) return error.Failed;
```

### Lock Order Inversion

```zig
// Task A
m1.lock(); m2.lock(); // A → B

// Task B
m2.lock(); m1.lock(); // B → A (deadlock!)
```

**Fix:** Always lock in same order (e.g., always A → B).

## See Also

- `std.Io.Event` - For signaling without data protection
- `std.Io.Queue` - Thread-safe queue using mutex internally
- Thread mutexes - Use lower-level threading primitives when an `std.Io` backend is not involved
- `std.Io.Future` - For task-based concurrency primitives
