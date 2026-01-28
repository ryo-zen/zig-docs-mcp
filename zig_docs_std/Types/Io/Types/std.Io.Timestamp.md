# std.Io.Timestamp

A point in time returned by `Clock.now`. Used for elapsed-time measurement, deadline computation, and time arithmetic. See also [std.Io.Clock](std.Io.Clock.md) for the full time system overview.

## Quick Start

### Read the Current Time
```zig
const now = try std.Io.Clock.real.now(io);
std.debug.print("Unix seconds: {}\n", .{now.toSeconds()});
```

### Compute a Deadline
```zig
const now = try std.Io.Clock.awake.now(io);
const deadline = now.addDuration(.fromSeconds(30));
```

### Measure Elapsed Time
```zig
const start = try std.Io.Clock.awake.now(io);
// ... work ...
const end = try std.Io.Clock.awake.now(io);
const elapsed = start.durationTo(end);
std.debug.print("Elapsed: {}ms\n", .{elapsed.toMilliseconds()});
```

---

## Overview

`std.Io.Timestamp` represents a single point in time, stored internally as nanoseconds in an `i96`. Timestamps are produced by `Clock.now` and can be converted to seconds or milliseconds, or used in arithmetic with `Duration` values.

**Key Characteristics:**
- **Signed nanoseconds**: Internally an `i96`, giving enormous range with nanosecond precision.
- **Clock-agnostic after creation**: Once you have a `Timestamp`, it is just a number. Meaningful comparison requires that both timestamps come from the same clock.
- **Value type**: Small struct, pass by value, no cleanup.
- **No `Io` required for arithmetic**: Only `Clock.now` needs `Io`. All other operations are pure.

**When to use:**
- Storing the result of `Clock.now` for later comparison.
- Computing deadlines by adding a `Duration`.
- Measuring how much time passed between two events.

## Fields

`nanoseconds: i96`

The raw timestamp in nanoseconds. The meaning of this value depends on which clock produced it (e.g. Unix epoch for `.real`, arbitrary origin for `.awake`).

## Values

| Name | Type | Description |
| :--- | :--- | :--- |
| `zero` | `Timestamp` | The zero timestamp (nanoseconds == 0). |

## Arithmetic Functions

### `pub fn addDuration(from: Timestamp, duration: Duration) Timestamp`

Returns a new `Timestamp` that is `duration` after `from`. Use for computing deadlines and expiry times.

**Example:**
```zig
const now = try std.Io.Clock.awake.now(io);
const deadline = now.addDuration(.fromSeconds(10));
```

------

### `pub fn subDuration(from: Timestamp, duration: Duration) Timestamp`

Returns a new `Timestamp` that is `duration` before `from`.

**Example:**
```zig
const now = try std.Io.Clock.real.now(io);
const ten_seconds_ago = now.subDuration(.fromSeconds(10));
```

------

### `pub fn durationTo(from: Timestamp, to: Timestamp) Duration`

Returns the `Duration` between two timestamps. Positive if `to` is after `from`; negative if `to` is before `from`.

**Example:**
```zig
const start = try std.Io.Clock.awake.now(io);
// ... work ...
const end = try std.Io.Clock.awake.now(io);
const elapsed = start.durationTo(end);
```

## Conversion Functions

### `pub fn toSeconds(t: Timestamp) i64`

Converts to whole seconds (truncates toward zero). For `.real` timestamps, this is the Unix epoch timestamp.

------

### `pub fn toMilliseconds(t: Timestamp) i64`

Converts to whole milliseconds (truncates toward zero).

------

### `pub fn toNanoseconds(t: Timestamp) i96`

Returns the raw nanosecond value.

------

### `pub fn fromNanoseconds(x: i96) Timestamp`

Constructs a `Timestamp` from a raw nanosecond value.

------

### `pub fn withClock(t: Timestamp, clock: Clock) Clock.Timestamp`

Associates a `Timestamp` with a specific clock, producing a `Clock.Timestamp` that carries clock context.

------

### `pub fn formatNumber(t: Timestamp, w: *std.Io.Writer, n: std.fmt.Number) std.Io.Writer.Error!void`

Formats the timestamp as a number using the given `Writer` and format specifier.

## See Also

- `std.Io.Clock` — Time source selection and the `now` function.
- `std.Io.Duration` — Time span type for arithmetic and timeouts.
- `std.Io` — The I/O interface hosting `sleep`.
