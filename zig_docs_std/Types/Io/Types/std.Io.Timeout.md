# std.Io.Timeout

Represents a time-based condition for interrupting or limiting the duration of an I/O operation.

## Overview

`std.Io.Timeout` is a union type used to specify when an operation should stop waiting and return `error.Timeout`. It is used extensively in networking (`receiveTimeout`, `connectTimeout`) and synchronization primitives.

- **Union variants:** Can be a relative duration, an absolute deadline, or no timeout.
- **Clock dependent:** Durations and deadlines are tied to a specific `std.Io.Clock` (usually `.awake` for monotonic behavior).

## Fields (Union Variants)

`none`
No timeout. The operation will block indefinitely until it succeeds or fails with a non-timeout error.

`duration: struct { raw: Duration, clock: Clock }`
A relative time span from the start of the operation.

`deadline: struct { raw: Timestamp, clock: Clock }`
An absolute point in time.

## Functions

### `pub fn sleep(timeout: Timeout, io: Io) SleepError!void`
Sleeps until the condition specified by the timeout is met.

- If `.none`: Blocks indefinitely (though typically not used this way).
- If `.duration`: Sleeps for the specified duration.
- If `.deadline`: Sleeps until the specified point in time.

------

### `pub fn toDeadline(t: Timeout, io: Io) Clock.Error!?Clock.Timestamp`
Converts a relative `.duration` to an absolute `.deadline` based on the current time of the associated clock. If the timeout is already a `.deadline`, returns it as-is. Returns `null` if the timeout is `.none`.

------

### `pub fn toDurationFromNow(t: Timeout, io: Io) Clock.Error!?Clock.Duration`
Converts an absolute `.deadline` to a relative `.duration` based on how much time is left. If the timeout is already a `.duration`, returns it as-is. Returns `null` if the timeout is `.none`.

## Usage Example

### Relative Timeout (Duration)
```zig
const timeout = std.Io.Timeout{
    .duration = .{
  .raw = std.Io.Duration.fromSeconds(5),
  .clock = .awake,
    },
};

// Use in a network operation
const msg = try socket.receiveTimeout(io, &buf, timeout);
```

### Absolute Timeout (Deadline)
```zig
const now = try std.Io.Clock.awake.now(io);
const deadline = now.addDuration(.fromMinutes(1));

const timeout = std.Io.Timeout{
    .deadline = .{
  .raw = deadline,
  .clock = .awake,
    },
};
```

## Error Sets

### Error
- `UnsupportedClock`: The specified clock is not supported on this platform.

## Debug Checklist

1. ✅ **Clock Monotonicity**: Always prefer `.awake` for timeouts. Using `.real` (wall clock) can cause timeouts to fire early or late if the system clock is adjusted (NTP sync, etc.).
2. ✅ **Negative Durations**: When converting from deadlines, `toDurationFromNow` might return a negative or zero duration if the deadline has already passed.

## See Also

- [std.Io.Clock](std.Io.Clock.md) - For reading time sources.
- [std.Io.Duration](std.Io.Duration.md) - For constructing time spans.
- [std.Io.net.Socket](../Namespaces/std.Io.net.Socket.md) - Consumer of timeouts.
