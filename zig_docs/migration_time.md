# Time/Timestamp Migration Guide (0.16)

## Runnable Examples

```bash
zig test zig_docs_std/Examples/test_unix_time.zig
zig test zig_docs_std/Examples/test_clock_comprehensive.zig
zig test zig_docs_std/Examples/test_timeout_comprehensive.zig
```

## Core Change: Through Io.Clock

Time operations now go through `std.Io.Clock`, requiring an `io: Io` parameter.

## Unix Timestamp

### Getting Current Timestamp

Prefer passing an existing `io: std.Io` when the caller already has one:

```zig
pub fn getTime(io: std.Io) i64 {
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}
```

For small command-line tools or legacy utility functions that do not already have an `io` value, `std.Io.Threaded.global_single_threaded` is a pragmatic drop-in bridge:

**Before (0.13-0.14):**
```zig
const timestamp = std.time.timestamp();
std.debug.print("Unix time: {}\n", .{timestamp});
```

**After (0.16) - Simple:**
```zig
pub fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}

// Use it
const timestamp = getTime();
std.debug.print("Unix time: {}\n", .{timestamp});
```

**After (0.16) - Full Pattern:**
```zig
var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();
const allocator = da.allocator();

var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
defer threaded.deinit();
const io = threaded.io();

const ts = std.Io.Clock.real.now(io);
const seconds = ts.toSeconds();
std.debug.print("Unix time: {}\n", .{seconds});
```

**Changes:**
- `std.time.timestamp()` → `std.Io.Clock.real.now(io).toSeconds()`
- Pass `io: std.Io` through application/server code that already participates in `std.Io`
- Use `std.Io.Threaded.global_single_threaded.io()` only for simple single-threaded utilities or migration bridges
- `Clock.now` returns a `Timestamp` directly; call `.toSeconds()` for Unix time
- Sleep operations are fallible and still require `try`

### `global_single_threaded` Guidance

`std.Io.Threaded.global_single_threaded` is a pre-initialized global Io instance for single-threaded environments.

Use it for:
- Small CLI tools
- Leaf utility functions that need a temporary bridge from `std.time.timestamp()`
- Examples where setting up `Io.Threaded.init` would obscure the point

Avoid it for:
- Libraries and reusable APIs
- Servers and async/concurrent code
- Code that already has an `io: std.Io` parameter
- Hot paths with many I/O operations

## Clock Types

### Real-time Clock (Wall Clock)

```zig
const ts = std.Io.Clock.real.now(io);
const seconds = ts.toSeconds();
```

Use for:
- Current date/time
- Unix timestamps
- Logging timestamps

### Monotonic Clock

```zig
const start = std.Io.Clock.awake.now(io);
// ... do work ...
const end = std.Io.Clock.awake.now(io);
const elapsed = start.durationTo(end);
```

Use for:
- Measuring elapsed time
- Performance timing
- Timeouts (not affected by system clock changes)

## Duration and Sleep

### Sleep Operation

**Before:**
```zig
std.time.sleep(std.time.ns_per_s); // 1 second
```

**After:**
```zig
const duration = std.Io.Duration.fromSeconds(1);
try io.sleep(duration, std.Io.Clock.awake);
```

### Duration Construction

```zig
const one_sec = std.Io.Duration.fromSeconds(1);
const one_ms = std.Io.Duration.fromMilliseconds(1000);
const one_us = std.Io.Duration.fromMicroseconds(1_000_000);
const one_ns = std.Io.Duration.fromNanoseconds(1_000_000_000);
```

## Timestamp Conversion

### From Seconds

```zig
const ts = std.Io.Timestamp.fromSeconds(1704067200);
```

### To Seconds

```zig
const ts = std.Io.Clock.real.now(io);
const seconds = ts.toSeconds();
```

### Arithmetic

```zig
const ts1 = std.Io.Clock.real.now(io);
const ts2 = std.Io.Clock.real.now(io);

// Difference
const duration = ts1.durationTo(ts2);

// Add duration
const future = ts1.addDuration(std.Io.Duration.fromSeconds(60));
```

## Complete Examples

### Basic Timestamp

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const ts = std.Io.Clock.real.now(io);
    const seconds = ts.toSeconds();

    std.debug.print("Current unix timestamp: {}\n", .{seconds});
}
```

### Measuring Elapsed Time

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const start = std.Io.Clock.awake.now(io);

    // Simulate work
    const duration = std.Io.Duration.fromMilliseconds(100);
    try io.sleep(duration, std.Io.Clock.awake);

    const end = std.Io.Clock.awake.now(io);
    const elapsed = start.durationTo(end);

    std.debug.print("Elapsed: {} ns\n", .{elapsed.toNanoseconds()});
}
```

### Timeout Pattern

```zig
const std = @import("std");

pub fn doWorkWithTimeout(io: std.Io) !void {
    const timeout_duration = std.Io.Duration.fromSeconds(5);
    const deadline = std.Io.Clock.awake.now(io);
    const timeout_ts = deadline.addDuration(timeout_duration);

    while (true) {
  // Do work

  // Check timeout
  const now = std.Io.Clock.awake.now(io);
  if (now.nanoseconds >= timeout_ts.nanoseconds) {
      return error.Timeout;
  }

  // Sleep a bit
  try io.sleep(std.Io.Duration.fromMilliseconds(10), std.Io.Clock.awake);
    }
}
```

## Migration Patterns

### Pattern 1: Simple Timestamp

**Before:**
```zig
fn logMessage(msg: []const u8) void {
    const ts = std.time.timestamp();
    std.debug.print("[{}] {s}\n", .{ts, msg});
}
```

**After:**
```zig
fn logMessage(io: std.Io, msg: []const u8) !void {
    const ts = std.Io.Clock.real.now(io);
    const seconds = ts.toSeconds();
    std.debug.print("[{}] {s}\n", .{seconds, msg});
}
```

### Pattern 2: Performance Timer

**Before:**
```zig
fn measurePerformance() !void {
    var timer = try std.time.Timer.start();

    // Do work

    const elapsed_ns = timer.read();
    std.debug.print("Took {} ns\n", .{elapsed_ns});
}
```

**After:**
```zig
fn measurePerformance(io: std.Io) !void {
    const start = std.Io.Clock.awake.now(io);

    // Do work

    const end = std.Io.Clock.awake.now(io);
    const elapsed = start.durationTo(end);
    std.debug.print("Took {} ns\n", .{elapsed.toNanoseconds()});
}
```

## Testing Pattern

```zig
test "unix timestamp" {
    const allocator = std.testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const ts = std.Io.Clock.real.now(io);
    const seconds = ts.toSeconds();

    // Should be after year 2020
    try std.testing.expect(seconds > 1_500_000_000);
}
```

## Common Errors

### Error: "std.time.timestamp not found"

```zig
// Wrong
const ts = std.time.timestamp();

// Fixed
const ts = std.Io.Clock.real.now(io);
const seconds = ts.toSeconds();
```

### Error: "expected i64, found Timestamp"

```zig
// Wrong
const ts = std.Io.Clock.real.now(io);
std.debug.print("{}\n", .{ts}); // ts is Timestamp type

// Fixed
const ts = std.Io.Clock.real.now(io);
std.debug.print("{}\n", .{ts.toSeconds()}); // Convert to i64
```

### Error: "std.time.sleep not found"

```zig
// Wrong
std.time.sleep(1_000_000_000);

// Fixed
try io.sleep(std.Io.Duration.fromSeconds(1), std.Io.Clock.awake);
```

## API Changes Summary

| Before (0.13-0.14) | After (0.16) |
|-------------------|--------------|
| `std.time.timestamp()` | `std.Io.Clock.real.now(io).toSeconds()` |
| `std.time.sleep(ns)` | `io.sleep(Duration.fromNanoseconds(ns), Clock.awake)` |
| `Timer.start()` | `Clock.awake.now(io)` |
| `timer.read()` | `start.durationTo(end).toNanoseconds()` |

## Migration Checklist

- [ ] Add Io.Threaded setup if not present
- [ ] Replace `std.time.timestamp()` → `Clock.real.now(io).toSeconds()`
- [ ] Replace `std.time.sleep()` → `io.sleep(Duration, Clock)`
- [ ] Replace `Timer.start()` → `Clock.awake.now(io)`
- [ ] Update function signatures to accept `io: Io`
- [ ] Handle errors with `try` for sleep and other fallible Io operations
- [ ] Use `Clock.real` for wall time
- [ ] Use `Clock.awake` for durations
- [ ] Convert Timestamp to seconds when needed
- [ ] Test all timing code
