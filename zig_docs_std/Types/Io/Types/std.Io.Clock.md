# std.Io.Clock

📚 **[See Comprehensive Examples & Tests](../../Examples/test_clock_comprehensive.zig)** - Runnable code demonstrating Clock, Duration, and Timestamp usage

## Quick Start

### Get the Current Unix Time
```zig
const ts = std.Io.Clock.real.now(io);
const unix_seconds = ts.toSeconds();
```

### Measure Elapsed Time
```zig
const before = std.Io.Clock.awake.now(io);
// ... do work ...
const after = std.Io.Clock.awake.now(io);
const elapsed = before.durationTo(after);
std.debug.print("Took {}ms\n", .{elapsed.toMilliseconds()});
```

### Sleep for a Duration
```zig
io.sleep(.fromMilliseconds(500), .awake) catch {};
```

### Compute a Future Timestamp
```zig
const now = std.Io.Clock.real.now(io);
const deadline = now.addDuration(.fromSeconds(30));
```

⚠️ **Critical**: Use `.awake` for elapsed-time measurement and timeouts — it is monotonic and unaffected by system clock changes. Use `.real` only when you need wall-clock time (e.g. Unix timestamps, log entries).

---

## Overview

`std.Io.Clock` is an enum representing the different time sources available in the system. Each variant has distinct guarantees about monotonicity, settability, and what time it tracks. The primary operation is `now`, which returns a `Timestamp` for the chosen clock.

Clocks, Durations, and Timestamps form a trio:
- **`Clock`** — selects *which* time source to read.
- **`Timestamp`** — a point in time returned by `Clock.now`.
- **`Duration`** — a span of time, used for arithmetic on timestamps and for timeouts.

**Key Characteristics:**
- **Enum-based**: Clock variants are accessed as `Clock.real`, `Clock.awake`, etc. — not instantiated.
- **Not cancelable**: `now` does not block, so it cannot be canceled. This is intentional — cancellation logic itself may need to check the time.
- **Requires `Io`**: `now` takes an `Io` parameter to route through the active backend.
- **Platform-mapped**: Each variant maps to a specific OS clock (see variant docs below).

**When to use:**
- `.real` — when you need wall-clock time (Unix timestamps, log entries, expiry dates).
- `.awake` — when you need monotonic elapsed time (benchmarks, timeouts, animation loops).
- `.boot` — like `.awake` but includes suspend time. Rarely needed.
- `.cpu_process` / `.cpu_thread` — for profiling CPU usage.

## Clock Variants (Fields)

`real`

A settable system-wide clock measuring real (wall-clock) time. Affected by NTP adjustments and manual system clock changes. Timestamps represent seconds since the Unix epoch (1970-01-01T00:00:00Z), ignoring leap seconds. On Windows, the native epoch (1601-01-01) is translated automatically.

------

`awake`

A nonsettable monotonic clock representing time since some unspecified point in the past. Consecutive calls are guaranteed to never go backwards (though successive calls may return identical values). Not affected by system clock jumps. Expresses intent to **exclude suspended time**, though implementations may include it.

- On Linux: `CLOCK_MONOTONIC`
- On macOS: `CLOCK_UPTIME_RAW`

------

`boot`

Identical to `awake` except it expresses intent to **include suspended time**. Due to platform limitations, it may behave identically to `awake` on some systems.

- On Linux: `CLOCK_BOOTTIME`
- On macOS: `CLOCK_MONOTONIC_RAW`

------

`cpu_process`

Tracks the amount of CPU time (user + kernel mode) used by the calling process.

------

`cpu_thread`

Tracks the amount of CPU time (user + kernel mode) used by the calling thread.

## Types

- **Duration** — A span of time. See [std.Io.Duration](std.Io.Duration.md) for the full reference.
- **Timestamp** — A point in time. See [std.Io.Timestamp](std.Io.Timestamp.md) for the full reference.

## Core Functions

### `pub fn now(clock: Clock, io: Io) Timestamp`

Returns the current time for this clock as a `Timestamp`. Not cancelable — it does not block, and cancellation logic itself may need to read the time.

**Example:**
```zig
const ts = std.Io.Clock.real.now(io);
std.debug.print("Unix time: {}s\n", .{ts.toSeconds()});
```

------

### `io.sleep(duration: Duration, clock: Clock) !void`

Suspends the current execution context for at least `duration` on the specified clock. This is the primary consumer of `Duration` values.

**Example:**
```zig
// Sleep 200ms using the monotonic clock
io.sleep(.fromMilliseconds(200), .awake) catch {};
```

Note: `sleep` lives on the `Io` interface, not on `Clock` itself, but it is the most common use of Clock variants alongside `now`.

## Usage Patterns

### Benchmarking a Block of Work
```zig
const before = std.Io.Clock.awake.now(io);

// ... work to measure ...
var sum: u64 = 0;
for (0..1_000_000) |i| sum += i;

const after = std.Io.Clock.awake.now(io);
const elapsed = before.durationTo(after);
std.debug.print("Sum {} took {}ms\n", .{ sum, elapsed.toMilliseconds() });
```

### Deadline-Based Loop
```zig
const deadline = std.Io.Clock.awake.now(io).addDuration(.fromSeconds(5));

while (true) {
    const now = std.Io.Clock.awake.now(io);
    if (now.durationTo(deadline).nanoseconds <= 0) break;
    // ... poll or do work ...
    io.sleep(.fromMilliseconds(10), .awake) catch {};
}
```

### Timeout for Network Operations
```zig
const result = socket.receiveTimeout(io, &buf, .{
    .duration = .{
  .raw = std.Io.Duration.fromMilliseconds(100),
  .clock = .awake,
    },
});
```

## Error Sets

- **Error** — Errors from `Clock.now` (e.g. unsupported clock on the current platform).

## Debug Checklist

1. ✅ **Using the right clock?** `.awake` for monotonic/elapsed time. `.real` for wall-clock Unix timestamps. Mixing them up gives meaningless durations.
2. ✅ **Did you handle the error from `now`?** Some clock variants may not be supported on all platforms.
3. ✅ **Sleep clock matches measurement clock?** If you sleep on `.awake` and measure on `.real`, a system clock adjustment can make the duration appear wrong.
4. ✅ **Negative duration check?** `durationTo` can return negative values if the "to" timestamp is in the past. Check `.nanoseconds <= 0` before acting on it.

## Performance Tips

1. **Cache `now` calls** — Each `now` is a syscall. If you need the time multiple times in a tight loop, read it once per iteration.
2. **Use `.awake` over `.real` for timeouts** — Monotonic clocks are immune to NTP jumps, so your timeout won't accidentally fire early or run forever.
3. **Prefer `fromMilliseconds` for human-scale durations** — It reads clearly and avoids error-prone nanosecond math.

## See Also

- `std.Io.Duration` — Time span type used for arithmetic and timeouts.
- `std.Io.Timestamp` — Point-in-time type returned by `Clock.now`.
- `std.Io` — The generic I/O interface (hosts `sleep`).
- `std.Io.Threaded` — The standard I/O backend.
