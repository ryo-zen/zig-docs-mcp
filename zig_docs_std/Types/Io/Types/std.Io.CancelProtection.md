# std.Io.CancelProtection

## Quick Start

### Protecting Critical Sections

```zig
const std = @import("std");

pub fn criticalOperation(io: std.Io) !void {
    // Save current protection state
    const old_protection = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old_protection); // Restore on exit

    // This section cannot be interrupted by cancellation
    try performDatabaseCommit(io);
    try updateInMemoryState(io);
    // Even if task is cancelled, these operations complete atomically
}
```

### Temporary Protection During Cleanup

```zig
const std = @import("std");

pub fn resourceCleanup(io: std.Io, resource: *Resource) !void {
    // Block cancellation during cleanup to prevent resource leaks
    const old = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old);

    try resource.flush(io);     // Won't be interrupted
    try resource.close(io);     // Guaranteed to complete
    resource.deallocate();      // Safe cleanup
}
```

⚠️ **Critical**: Always restore the previous protection state using `defer`. Leaving protection blocked permanently prevents graceful task cancellation.

---

## Overview

`std.Io.CancelProtection` is an enum controlling whether a task can observe `error.Canceled` during I/O operations. Every task in the `std.Io` system has an associated cancel protection state that determines if I/O functions introduce *cancellation points* (locations where `error.Canceled` can be returned).

**Key Characteristics:**
- **Per-Task State**: Each task has its own independent protection level
- **Default Unblocked**: Tasks start with cancellation enabled (`.unblocked`)
- **Atomic Swap**: Change protection with `io.swapCancelProtection()`, which returns the old value
- **Safety Mechanism**: Prevents partial updates and resource leaks in critical sections

**When to use `.blocked`:**
- **Critical Sections**: Transactions or multi-step updates that must complete atomically
- **Resource Cleanup**: Preventing interruption during deallocation or file closing
- **Shutdown Sequences**: Ensuring orderly teardown despite cancellation requests

**When to keep `.unblocked` (default):**
- **Normal Operations**: Most code should allow cancellation for responsiveness
- **Long-Running Tasks**: Allow users to cancel slow operations
- **Network I/O**: Permit timeout/cancellation of hung connections

## Enum Values

`unblocked`

**Cancellation points enabled (default).**

Any call to an `Io` function with `error.Canceled` in its error set is a *cancellation point*. If the task has been cancelled (via `Future.cancel()`), the function will return `error.Canceled` instead of blocking or performing I/O.

**Behavior:**
- I/O functions check for pending cancellation before blocking
- If cancelled, return `error.Canceled` immediately
- Allows responsive task termination

**This is the default state, which all tasks are created in.**

**Example:**
```zig
// Task is cancellable
const data = try reader.readAll(io, &buffer); // Can return error.Canceled
```

------

`blocked`

**Cancellation points disabled.**

No `Io` function introduces a cancellation point (`error.Canceled` will never be returned). I/O operations proceed normally even if the task has been marked for cancellation.

**Behavior:**
- I/O functions ignore pending cancellation
- Operations complete as if the task were not cancelled
- Cancellation is *deferred* until protection is restored to `.unblocked`

**Use case:** Critical sections that must complete atomically.

**Example:**
```zig
const old = io.swapCancelProtection(.blocked);
defer _ = io.swapCancelProtection(old);

// These operations cannot be interrupted by cancellation
try writer.writeAll(io, header);
try writer.writeAll(io, body);
try writer.flush(io);
```

## Related Functions

### `pub fn swapCancelProtection(io: Io, new_protection: CancelProtection) CancelProtection`

Atomically swaps the current task's cancel protection state and returns the previous value.

**Parameters:**
- `new_protection`: The new protection level (`.blocked` or `.unblocked`)

**Returns:** The previous protection level

**Example:**
```zig
const old_protection = io.swapCancelProtection(.blocked);
// ... protected code ...
_ = io.swapCancelProtection(old_protection); // Restore
```

**Common pattern with `defer`:**
```zig
const old = io.swapCancelProtection(.blocked);
defer _ = io.swapCancelProtection(old); // Automatic restoration
```

## Usage Patterns

### Transaction-Style Updates

```zig
const std = @import("std");

pub fn atomicUpdate(io: std.Io, db: *Database) !void {
    const old = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old);

    // These operations complete as a unit, even if task is cancelled
    try db.beginTransaction(io);
    errdefer db.rollback(io) catch {};

    try db.updateRecord(io, record1);
    try db.updateRecord(io, record2);
    try db.commit(io);
}
```

### Nested Protection (Idempotent)

```zig
const std = @import("std");

pub fn outerCritical(io: std.Io) !void {
    const old1 = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old1);

    try innerCritical(io); // Also blocks, but will restore correctly
}

pub fn innerCritical(io: std.Io) !void {
    const old2 = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old2);

    // Protected operations
}
// After innerCritical returns, protection remains .blocked
// After outerCritical returns, protection restored to original state
```

### Conditional Protection

```zig
const std = @import("std");

pub fn maybeProtect(io: std.Io, critical: bool) !void {
    const old = if (critical) io.swapCancelProtection(.blocked) else io.swapCancelProtection(.unblocked);
    defer _ = io.swapCancelProtection(old);

    try performOperation(io);
}
```

### Protecting Cleanup Without Masking Errors

```zig
const std = @import("std");

pub fn operationWithCleanup(io: std.Io, resource: *Resource) !void {
    resource.acquire(io) catch |err| return err;

    // Normal operation - cancellable
    const result = performWork(io, resource) catch |err| {
  // Cleanup is protected, even if we're returning an error
  const old = io.swapCancelProtection(.blocked);
  defer _ = io.swapCancelProtection(old);

  resource.release(io) catch {}; // Won't be cancelled
  return err;
    };

    // Success path cleanup - also protected
    const old = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old);
    try resource.release(io);

    return result;
}
```

## Conceptual Model

### Cancellation Flow

1. **Cancellation Request**: `Future.cancel()` is called on a task
2. **State Updated**: Task is marked as "cancelled" internally
3. **Cancellation Point Check**: Next I/O function checks:
   - If protection is `.unblocked`: Return `error.Canceled`
   - If protection is `.blocked`: Proceed normally (cancellation deferred)
4. **Protection Restored**: When `.unblocked` is restored, next I/O operation returns `error.Canceled`

### Why Blocking is Temporary

Cancellation is not "cleared" when blocked—it's merely *deferred*. Once protection is restored to `.unblocked`, the next cancellable I/O operation will immediately return `error.Canceled`.

**Example:**
```zig
// Task is cancelled here
const old = io.swapCancelProtection(.blocked);

// These don't return Canceled, despite task being cancelled
try operation1(io);
try operation2(io);

_ = io.swapCancelProtection(.unblocked); // Restore

// Next I/O operation will return error.Canceled
try operation3(io); // ← Returns error.Canceled immediately
```

## Debug Checklist

- ✅ **Defer Restoration**: Did you use `defer` to restore the old protection state?
- ✅ **Minimize Protected Scope**: Is the `.blocked` region as small as possible?
- ✅ **Avoid Infinite Blocks**: Does the protected code eventually complete?
- ✅ **Handle Deferred Cancellation**: After restoring `.unblocked`, do you handle potential `error.Canceled`?

## Performance Tips

1. **Keep Protected Regions Small**: Minimize the scope of `.blocked` to maintain responsiveness
2. **Use `defer` Always**: Prevents accidentally leaving protection blocked on early returns
3. **Don't Block Preemptively**: Only block when actually needed for correctness, not "just in case"
4. **Document Why**: Comment why protection is needed in each case for maintainability

## See Also

- `Future.cancel()` - Initiates task cancellation
- `io.swapCancelProtection()` - Changes protection state
- `std.Io.Cancelable` - Error set containing `error.Canceled`
- `std.Io.Future` - Task primitive that can be cancelled
