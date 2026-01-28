# std.Io.Duration

A span of time, used for sleep durations, timeouts, and timestamp arithmetic. See also [std.Io.Clock](std.Io.Clock.md) for the full time system overview.

## Quick Start

### Create from Common Units
```zig
const half_second = std.Io.Duration.fromMilliseconds(500);
const two_minutes = std.Io.Duration.fromSeconds(120);
const precise     = std.Io.Duration.fromNanoseconds(1_500_000); // 1.5ms
```

### Convert Back
```zig
const d = std.Io.Duration.fromSeconds(5);
const ms = d.toMilliseconds(); // 5000
const s  = d.toSeconds();      // 5
```

### Use as a Sleep Duration
```zig
io.sleep(.fromMilliseconds(200), .awake) catch {};
```

---

## Overview

`std.Io.Duration` represents a signed span of time stored internally as nanoseconds in an `i96`. It is the primary way to express time intervals in Zig's I/O system — used for `io.sleep`, network timeouts, and arithmetic on `Timestamp` values.

**Key Characteristics:**
- **Signed**: Durations can be negative (e.g. the result of `durationTo` when the target is in the past).
- **Nanosecond precision**: Internally stored as `i96` nanoseconds, covering a range far beyond any practical use.
- **Value type**: `Duration` is a small struct — pass by value, no cleanup needed.
- **No `Io` required**: Construction and conversion are pure arithmetic. Only `io.sleep` actually performs I/O.

**When to use:**
- Specifying how long to sleep or wait.
- Computing the time difference between two `Timestamp` values.
- Setting network operation timeouts.

## Fields

`nanoseconds: i96`

The raw duration in nanoseconds. Positive values represent forward time; negative values represent backward time.

## Values

| Name | Type | Description |
| :--- | :--- | :--- |
| `zero` | `Duration` | A duration of exactly zero nanoseconds. |
| `max` | `Duration` | The maximum representable duration. |

## Construction Functions

### `pub fn fromSeconds(x: i64) Duration`

Creates a `Duration` from a number of seconds.

**Example:**
```zig
const d = std.Io.Duration.fromSeconds(10);
```

------

### `pub fn fromMilliseconds(x: i64) Duration`

Creates a `Duration` from a number of milliseconds.

**Example:**
```zig
const d = std.Io.Duration.fromMilliseconds(500);
```

------

### `pub fn fromNanoseconds(x: i96) Duration`

Creates a `Duration` from a number of nanoseconds. Use when sub-millisecond precision is needed.

**Example:**
```zig
const d = std.Io.Duration.fromNanoseconds(1_500_000); // 1.5ms
```

## Conversion Functions

### `pub fn toSeconds(d: Duration) i64`

Converts to whole seconds (truncates toward zero).

------

### `pub fn toMilliseconds(d: Duration) i64`

Converts to whole milliseconds (truncates toward zero).

------

### `pub fn toNanoseconds(d: Duration) i96`

Returns the raw nanosecond value.

## See Also

- `std.Io.Clock` — Time source selection and the `now` function.
- `std.Io.Timestamp` — A point in time; use `durationTo` and `addDuration` for arithmetic.
- `std.Io` — The I/O interface hosting `sleep`.
