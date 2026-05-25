# std.Io.RwLock

Read-write lock that supports either one writer or many readers.

`RwLock` integrates with an `std.Io` backend and uses `std.Io.Mutex` plus `std.Io.Semaphore` internally. Use it when shared access should allow concurrent readers but exclusive writers.

## Initialization

```zig
pub const init: RwLock = .{
    .state = 0,
    .mutex = .init,
    .semaphore = .{},
};
```

## Exclusive Lock Functions

```zig
pub fn tryLock(rl: *RwLock, io: Io) bool
```

Attempts to acquire the write lock without waiting.

```zig
pub fn lock(rl: *RwLock, io: Io) Io.Cancelable!void
```

Acquires the write lock, waiting if needed.

```zig
pub fn lockUncancelable(rl: *RwLock, io: Io) void
```

Acquires the write lock without introducing a cancellation point.

```zig
pub fn unlock(rl: *RwLock, io: Io) void
```

Releases the write lock.

## Shared Lock Functions

```zig
pub fn tryLockShared(rl: *RwLock, io: Io) bool
```

Attempts to acquire a read lock without waiting.

```zig
pub fn lockShared(rl: *RwLock, io: Io) Io.Cancelable!void
```

Acquires a read lock, waiting if needed.

```zig
pub fn lockSharedUncancelable(rl: *RwLock, io: Io) void
```

Acquires a read lock without introducing a cancellation point.

```zig
pub fn unlockShared(rl: *RwLock, io: Io) void
```

Releases a read lock.

## See Also

- `std.Io.Mutex`
- `std.Io.Semaphore`
- `std.Io.Condition`
