# Simple Unix Timestamp (0.16)

## The Simplest Pattern

For getting Unix timestamps without passing `io` everywhere, use the global single-threaded Io:

```zig
const std = @import("std");

/// Get current Unix timestamp (simplest approach)
pub fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}
```

## Comparison

### Before (0.14.1)
```zig
pub fn getTime() i64 {
    return std.time.timestamp();
}
```

### After (0.16) - Simple Global Pattern
```zig
pub fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}
```

## What is `global_single_threaded`?

`std.Io.Threaded.global_single_threaded` is a pre-initialized global Io instance for single-threaded programs.

**Benefits:**
- No need to pass `io` parameter everywhere
- No manual initialization/cleanup
- Perfect for utility functions
- Zero overhead for simple programs

**When to use:**
- Getting timestamps in utility functions
- Simple CLI tools
- Functions that don't have access to `io` parameter
- Legacy code migration (drop-in replacement)

**When NOT to use:**
- Multi-threaded programs (use proper Io.Threaded.init)
- Async/concurrent operations (need proper Io instance)
- Performance-critical code with many Io operations

## Complete Example

```zig
const std = @import("std");

/// Get current Unix timestamp
pub fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}

/// Log with timestamp
pub fn log(level: []const u8, msg: []const u8) void {
    const timestamp = getTime();
    std.debug.print("[{}][{s}] {s}\n", .{timestamp, level, msg});
}

pub fn main() !void {
    log("INFO", "Application started");
    log("DEBUG", "Processing data...");
    log("ERROR", "Something went wrong");

    const now = getTime();
    std.debug.print("Current timestamp: {}\n", .{now});
}
```

## Real-World Usage Pattern

```zig
const std = @import("std");

const Transaction = struct {
    hash: [32]u8,
    timestamp: i64,
    amount: u64,

    pub fn create(hash: [32]u8, amount: u64) Transaction {
  return .{
      .hash = hash,
      .timestamp = getTime(),  // Simple!
      .amount = amount,
  };
    }
};

fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}
```

## Passing Io Explicitly

`Clock.now` is not fallible. In code that already has an `io` value, pass it
directly instead of using the global helper:

```zig
pub fn getTime(io: std.Io) i64 {
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}
```

## Alternatives

### 1. Global Pattern (Simplest)
```zig
pub fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.io();
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}
```
**Best for:** Utility functions, simple programs

### 2. Thread Io Pattern (Recommended for servers)
```zig
pub fn getTime(io: std.Io) i64 {
    const ts = std.Io.Clock.real.now(io);
    return ts.toSeconds();
}
```
**Best for:** Servers, async code, multi-threaded programs

### 3. Direct posix (Lowest level)
```zig
pub fn getTime() i64 {
    var ts: std.posix.timespec = undefined;
    _ = std.posix.clock_gettime(std.posix.CLOCK.REALTIME, &ts) catch return 0;
    return ts.sec;
}
```
**Best for:** Embedded systems, minimal overhead

## Migration Checklist

Replace all instances of `std.time.timestamp()`:

- [ ] Find all `std.time.timestamp()` calls
- [ ] Create `getTime()` helper using global pattern
- [ ] Replace calls with `getTime()`
- [ ] Test that timestamps are reasonable (> 1_500_000_000)

**Example migration:**

```zig
// Before
const timestamp = std.time.timestamp();

// After
const timestamp = getTime();  // Uses global_single_threaded internally
```

## Why No `std.time.timestamp()` in 0.16?

The old `std.time.timestamp()` used hidden global state and wasn't async-aware. The new Io-based approach:

1. **Explicit dependencies**: You know when you're doing I/O
2. **Async-ready**: Works with async/await when needed
3. **Testable**: Can mock Io for testing
4. **Cross-platform**: Unified interface across OSes

The `global_single_threaded` pattern is a pragmatic compromise - simple like the old API, but using the new infrastructure.

## See Also

- [Migration: Time](migration_time.md) - Full time migration guide
- [std.Io.Clock](../zig_docs_std/Types/Io/Types/std.Io.Clock.md) - Clock API reference
- [std.Io.Threaded](../zig_docs_std/Types/Io/Types/std.Io.Threaded.md) - Threaded Io documentation
