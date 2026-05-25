# std.Io.Condition

Condition variable for `std.Io` synchronization.

`Condition` pairs with `std.Io.Mutex`: callers wait with the mutex held, the wait operation unlocks the mutex while sleeping, and the mutex is reacquired before returning.

## Initialization

```zig
pub const init: Condition = .{
    .state = .init(.{ .waiters = 0, .signals = 0 }),
    .epoch = .init(0),
};
```

## Functions

```zig
pub fn wait(cond: *Condition, io: Io, mutex: *Mutex) Cancelable!void
```

Waits for a signal while releasing and then reacquiring the provided mutex.

```zig
pub fn waitUncancelable(cond: *Condition, io: Io, mutex: *Mutex) void
```

Waits without introducing a cancellation point.

```zig
pub fn signal(cond: *Condition, io: Io) void
```

Wakes one waiter when a waiter is available.

```zig
pub fn broadcast(cond: *Condition, io: Io) void
```

Wakes all current waiters.

## See Also

- `std.Io.Mutex`
- `std.Io.Semaphore`
- `std.Io.Event`
