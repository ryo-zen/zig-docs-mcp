# std.Io.Clock

### Fields

    real

A settable system-wide clock that measures real (i.e. wall-clock) time. This clock is affected by discontinuous jumps in the system time (e.g., if the system administrator manually changes the clock), and by frequency adjustments performed by NTP and similar applications.

This clock normally counts the number of seconds since 1970-01-01 00:00:00 Coordinated Universal Time (UTC) except that it ignores leap seconds; near a leap second it is typically adjusted by NTP to stay roughly in sync with UTC.

Timestamps returned by implementations of this clock represent time elapsed since 1970-01-01T00:00:00Z, the POSIX/Unix epoch, ignoring leap seconds. This is colloquially known as "Unix time". If the underlying OS uses a different epoch for native timestamps (e.g., Windows, which uses 1601-01-01) they are translated accordingly.

    awake

A nonsettable system-wide clock that represents time since some unspecified point in the past.

Monotonic: Guarantees that the time returned by consecutive calls will not go backwards, but successive calls may return identical (not-increased) time values.

Not affected by discontinuous jumps in the system time (e.g., if the system administrator manually changes the clock), but may be affected by frequency adjustments.

This clock expresses intent to **exclude time that the system is suspended**. However, implementations may be unable to satisify this, and may include that time.

- On Linux, corresponds `CLOCK_MONOTONIC`.
- On macOS, corresponds to `CLOCK_UPTIME_RAW`.

<!-- -->

    boot

Identical to `awake` except it expresses intent to **include time that the system is suspended**, however, due to limitations it may behave identically to `awake`.

- On Linux, corresponds `CLOCK_BOOTTIME`.
- On macOS, corresponds to `CLOCK_MONOTONIC_RAW`.

<!-- -->

    cpu_process

Tracks the amount of CPU in user or kernel mode used by the calling process.

    cpu_thread

Tracks the amount of CPU in user or kernel mode used by the calling thread.

## Types

- Duration
- Timestamp

## Functions

`pub fn now(clock: Clock, io: Io) Error!Io.Timestamp`  
This function is not cancelable because first of all it does not block, but more importantly, the cancelation logic itself may want to check the time.

## Error Sets

- Error
