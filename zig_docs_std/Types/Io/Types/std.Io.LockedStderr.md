# std.Io.LockedStderr

📚 **[See Comprehensive Examples & Tests](../../Examples/test_locked_stderr_comprehensive.zig)** - Complete runnable code demonstrating LockedStderr features

## Quick Start

### Most Common Patterns

**Basic Thread-Safe Writing**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

try stderr.file_writer.interface.writeAll("Error: Operation failed\n");
```

**Colored Output with Terminal**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

const term = stderr.terminal();
try term.setColor(.red);
try stderr.file_writer.interface.writeAll("CRITICAL: System failure\n");
try term.setColor(.reset);
```

**Multiple Coordinated Writes**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

// All these writes are guaranteed not to be interrupted by other threads
try stderr.file_writer.interface.writeAll("[ERROR] ");
try stderr.file_writer.interface.print("Failed to open file: {s}\n", .{filename});
try stderr.file_writer.interface.writeAll("  Suggestion: Check file permissions\n");
```

**Clear Screen**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

try stderr.clear(&buffer);
try stderr.file_writer.interface.writeAll("Screen cleared!\n");
```

### Key Operations
- `io.lockStderr(&buffer, mode)` - Acquire exclusive stderr lock
- `io.unlockStderr()` - Release the lock (always use with `defer`)
- `.file_writer.interface.writeAll()` - Write to stderr
- `.file_writer.interface.print()` - Formatted write to stderr
- `.terminal()` - Get Terminal instance for colors
- `.clear(buffer)` - Clear terminal screen

### ⚠️ Critical: Always Unlock
```zig
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();  // ALWAYS unlock! Use defer immediately after lock
```

---

## Overview

`std.Io.LockedStderr` is a thread-safe wrapper for the standard error stream, obtained via `io.lockStderr()`. While the lock is held, it prevents other threads (and the debug logger) from interleaving output on stderr, ensuring atomic multi-line writes.

**Key Characteristics:**
- **Thread-safe**: Holds `std.process.stderr_thread_mutex` while active
- **Atomic writes**: Multiple writes appear as a single uninterrupted block
- **Terminal integration**: Provides access to Terminal for colors and screen control
- **Buffer management**: Automatically clears the buffer on lock acquisition
- **Non-blocking variant**: `tryLockStderr()` available for non-blocking acquisition

**When to use LockedStderr:**
- Writing multi-line error messages that should not be interrupted
- Coordinating colored output from multiple threads
- Ensuring atomic diagnostic output in concurrent applications
- Any scenario requiring exclusive access to stderr

## Fields

`file_writer: *File.Writer`

The underlying writer for the stderr file handle. Use this for all write operations while the lock is held.

------

`terminal_mode: Terminal.Mode`

The detected mode of the terminal, indicating whether colors and escape codes are supported.

## Functions

### `pub fn terminal(ls: LockedStderr) Terminal`

Returns a `std.Io.Terminal` instance associated with this locked stderr stream. This allows you to set colors or query terminal properties safely while holding the lock.

**Returns:**
A `Terminal` instance configured with the stderr writer and detected terminal mode.

**Example:**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

const term = stderr.terminal();
try term.setColor(.red);
try stderr.file_writer.interface.writeAll("ERROR: ");
try term.setColor(.reset);
try stderr.file_writer.interface.writeAll("Operation failed\n");
```

------

### `pub fn clear(ls: LockedStderr, buffer: []u8) Cancelable!void`

Clears the terminal screen if supported, and resets the internal buffer. This function:
1. Attempts to clear the terminal using escape codes
2. Flushes the writer
3. Sets the writer's buffer to the provided buffer

**Parameters:**
- `buffer` - The buffer to use for subsequent write operations

**Behavior:**
Writes ANSI escape codes to clear the screen if the terminal supports them. Ignores errors from terminals that don't support clearing, except for `Canceled` errors which are propagated.

**Example:**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

try stderr.clear(&buffer);
try stderr.file_writer.interface.writeAll("Fresh screen!\n");
```

## Usage Patterns

### Pattern 1: Atomic Multi-Line Error Messages

```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();

// All these lines appear together, not interleaved with other output
try stderr.file_writer.interface.writeAll("========================================\n");
try stderr.file_writer.interface.writeAll("FATAL ERROR\n");
try stderr.file_writer.interface.writeAll("========================================\n");
try stderr.file_writer.interface.print("Thread ID: {}\n", .{std.Thread.getCurrentId()});
try stderr.file_writer.interface.writeAll("Stack trace:\n");
// ... more output
```

### Pattern 2: Colored Status Messages

```zig
const std = @import("std");

fn reportStatus(io: std.Io, status: enum { success, warning, error_ }, message: []const u8) !void {
    var buffer: [2048]u8 = undefined;
    const stderr = try io.lockStderr(&buffer, null);
    defer io.unlockStderr();

    const term = stderr.terminal();

    switch (status) {
        .success => {
            try term.setColor(.green);
            try stderr.file_writer.interface.writeAll("[SUCCESS] ");
        },
        .warning => {
            try term.setColor(.yellow);
            try stderr.file_writer.interface.writeAll("[WARNING] ");
        },
        .error_ => {
            try term.setColor(.red);
            try stderr.file_writer.interface.writeAll("[ERROR] ");
        },
    }
    try term.setColor(.reset);
    try stderr.file_writer.interface.print("{s}\n", .{message});
}
```

### Pattern 3: Non-Blocking Lock Attempt

```zig
var buffer: [1024]u8 = undefined;
if (try io.tryLockStderr(&buffer, null)) |stderr| {
    defer io.unlockStderr();
    try stderr.file_writer.interface.writeAll("Got the lock!\n");
} else {
    // Lock is held by another thread - skip or queue message
    std.debug.print("Could not acquire stderr lock\n", .{});
}
```

## Related Functions

### `pub fn lockStderr(io: Io, buffer: []u8, terminal_mode: ?Terminal.Mode) Cancelable!LockedStderr`

Acquires exclusive access to stderr. Blocks until the lock is available.

**Parameters:**
- `buffer` - Buffer to use for write operations (typically 1024-4096 bytes)
- `terminal_mode` - Optional terminal mode override (pass `null` to auto-detect)

**Returns:**
A `LockedStderr` instance that must be released with `io.unlockStderr()`.

**Example:**
```zig
var buffer: [1024]u8 = undefined;
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();
```

------

### `pub fn tryLockStderr(io: Io, buffer: []u8, terminal_mode: ?Terminal.Mode) Cancelable!?LockedStderr`

Non-blocking version of `lockStderr()`. Returns `null` if the lock is already held by another thread.

**Parameters:**
- `buffer` - Buffer to use for write operations
- `terminal_mode` - Optional terminal mode override (pass `null` to auto-detect)

**Returns:**
A `LockedStderr` instance if the lock was acquired, or `null` if it's already held.

**⚠️ Known Issue:** In Zig version 0.16.0-dev.2193, there is a bug in `tryLockStderr()` where the vtable function signature doesn't match the wrapper function. This may be fixed in newer versions of Zig.

**Example:**
```zig
var buffer: [1024]u8 = undefined;
if (try io.tryLockStderr(&buffer, null)) |stderr| {
    defer io.unlockStderr();
    try stderr.file_writer.interface.writeAll("Message\n");
}
```

------

### `pub fn unlockStderr(io: Io) void`

Releases the stderr lock. Must be called after every successful `lockStderr()` or `tryLockStderr()` call.

**Best Practice:** Always use `defer` immediately after acquiring the lock:
```zig
const stderr = try io.lockStderr(&buffer, null);
defer io.unlockStderr();  // Guaranteed to run even on error
```

## Error Sets

### Cancelable

Errors that may occur when locking stderr.

**Errors:**
- `Canceled` - The operation was canceled (e.g., by user interrupt)

**Note:** Most terminal operations ignore non-critical errors to maintain robustness.

## Debug Checklist

If your stderr output isn't working correctly, check:

1. ✅ Did you unlock stderr with `defer`?
   ```zig
   // ❌ DON'T: Forget to unlock
   const stderr = try io.lockStderr(&buffer, null);
   try stderr.file_writer.interface.writeAll("Message\n");

   // ✅ DO: Always unlock with defer
   const stderr = try io.lockStderr(&buffer, null);
   defer io.unlockStderr();
   ```

2. ✅ Is your buffer large enough?
   ```zig
   // ❌ DON'T: Too small
   var buffer: [16]u8 = undefined;

   // ✅ DO: Adequate size (1-4 KB typical)
   var buffer: [1024]u8 = undefined;
   ```

3. ✅ Are you using the correct writer?
   ```zig
   // ❌ DON'T: Use wrong writer
   try term.writer.writeAll("Text\n");

   // ✅ DO: Use file_writer
   try stderr.file_writer.interface.writeAll("Text\n");
   ```

4. ✅ Did you call `unlockStderr()` on the same `io` instance?
   ```zig
   // ✅ Correct: Same io for lock and unlock
   const stderr = try io.lockStderr(&buffer, null);
   defer io.unlockStderr();  // Unlocks using the same io
   ```

5. ✅ Are you holding the lock for too long?
   - Lock only for the duration of the atomic write operation
   - Release quickly to avoid blocking other threads
   - Consider buffering output and locking once for the entire message

6. ✅ Did you handle the `tryLockStderr()` null case?
   ```zig
   if (try io.tryLockStderr(&buffer, null)) |stderr| {
       defer io.unlockStderr();
       // ... use stderr
   } else {
       // Handle "lock already held" case
   }
   ```

## Performance Tips

1. **Buffer size**: Use 1-4 KB buffers for typical stderr output
   ```zig
   var buffer: [2048]u8 = undefined;  // Good size for most messages
   ```

2. **Lock duration**: Minimize time holding the lock
   ```zig
   // ✅ DO: Prepare message first, then lock briefly
   var message_buffer: [1024]u8 = undefined;
   const msg = try std.fmt.bufPrint(&message_buffer, "Error {}: {s}\n", .{ code, text });

   var buffer: [1024]u8 = undefined;
   const stderr = try io.lockStderr(&buffer, null);
   defer io.unlockStderr();
   try stderr.file_writer.interface.writeAll(msg);
   ```

3. **Batch writes**: Group multiple lines into a single lock
   ```zig
   // ❌ DON'T: Lock/unlock repeatedly
   for (errors) |err| {
       const stderr = try io.lockStderr(&buffer, null);
       defer io.unlockStderr();
       try stderr.file_writer.interface.print("{s}\n", .{err});
   }

   // ✅ DO: Lock once for all writes
   const stderr = try io.lockStderr(&buffer, null);
   defer io.unlockStderr();
   for (errors) |err| {
       try stderr.file_writer.interface.print("{s}\n", .{err});
   }
   ```

4. **Non-blocking when appropriate**: Use `tryLockStderr()` for non-critical output
   ```zig
   // For debug/trace output that can be dropped if lock is busy
   if (try io.tryLockStderr(&buffer, null)) |stderr| {
       defer io.unlockStderr();
       try stderr.file_writer.interface.writeAll("Debug: ...\n");
   }
   // If null, just skip the debug output
   ```

## See Also

- [std.Io.Terminal](std.Io.Terminal.md) - For controlling terminal colors and modes
- [std.Io.Writer](std.Io.Writer.md) - Underlying writer interface
- [std.Io.File](std.Io.File.md) - File operations and File.Writer details
