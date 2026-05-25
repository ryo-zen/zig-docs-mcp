# std.Io.Semaphore

Counting semaphore for `std.Io` synchronization.

The local stdlib describes this as an unsigned integer that blocks the kernel thread if the number would become negative. It supports static initialization and does not require deinitialization.

## Initialization

```zig
var sem: std.Io.Semaphore = .{ .permits = 1 };
```

The `permits` field may be initialized to any value.

## Functions

```zig
pub fn wait(s: *Semaphore, io: Io) Io.Cancelable!void
```

Waits until a permit is available, then consumes one permit.

```zig
pub fn waitUncancelable(s: *Semaphore, io: Io) void
```

Waits without introducing a cancellation point.

```zig
pub fn post(s: *Semaphore, io: Io) void
```

Adds one permit and signals a waiter.

## See Also

- `std.Io.Condition`
- `std.Io.Mutex`
- `std.Io.RwLock`
