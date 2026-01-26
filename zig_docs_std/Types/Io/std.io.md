# struct

A cross-platform interface that abstracts all I/O operations and concurrency. It includes:

- file system
- networking
- processes
- time and sleeping
- randomness
- async, await, concurrent, and cancel
- concurrent queues
- wait groups and select
- mutexes, futexes, events, and conditions
- memory mapped files This interface allows programmers to write optimal, reusable code while participating in these operations.

## Fields

```
userdata: ?*anyopaque
```

```
vtable: *const VTable
```

## Types

- [AnyFuture](https://ziglang.org/documentation/master/std/#std.Io.AnyFuture)
- [CancelProtection](https://ziglang.org/documentation/master/std/#std.Io.CancelProtection)
- [Clock](https://ziglang.org/documentation/master/std/#std.Io.Clock)
- [Condition](https://ziglang.org/documentation/master/std/#std.Io.Condition)
- [Dir](https://ziglang.org/documentation/master/std/#std.Io.Dir)
- [Duration](https://ziglang.org/documentation/master/std/#std.Io.Duration)
- [Event](https://ziglang.org/documentation/master/std/#std.Io.Event)
- [Evented](https://ziglang.org/documentation/master/std/#std.Io.Evented)
- [File](https://ziglang.org/documentation/master/std/#std.Io.File)
- [Future](https://ziglang.org/documentation/master/std/#std.Io.Future)
- [Group](https://ziglang.org/documentation/master/std/#std.Io.Group)
- [IoUring](https://ziglang.org/documentation/master/std/#std.Io.IoUring)
- [Kqueue](https://ziglang.org/documentation/master/std/#std.Io.Kqueue)
- [Limit](https://ziglang.org/documentation/master/std/#std.Io.Limit)
- [LockedStderr](https://ziglang.org/documentation/master/std/#std.Io.LockedStderr)
- [Mutex](https://ziglang.org/documentation/master/std/#std.Io.Mutex)
- [PollFiles](https://ziglang.org/documentation/master/std/#std.Io.PollFiles)
- [Poller](https://ziglang.org/documentation/master/std/#std.Io.Poller)
- [Queue](https://ziglang.org/documentation/master/std/#std.Io.Queue)
- [Reader](https://ziglang.org/documentation/master/std/#std.Io.Reader)
- [Select](https://ziglang.org/documentation/master/std/#std.Io.Select)
- [SelectUnion](https://ziglang.org/documentation/master/std/#std.Io.SelectUnion)
- [Terminal](https://ziglang.org/documentation/master/std/#std.Io.Terminal)
- [Threaded](https://ziglang.org/documentation/master/std/#std.Io.Threaded)
- [Timeout](https://ziglang.org/documentation/master/std/#std.Io.Timeout)
- [Timestamp](https://ziglang.org/documentation/master/std/#std.Io.Timestamp)
- [TypeErasedQueue](https://ziglang.org/documentation/master/std/#std.Io.TypeErasedQueue)
- [VTable](https://ziglang.org/documentation/master/std/#std.Io.VTable)
- [Writer](https://ziglang.org/documentation/master/std/#std.Io.Writer)

## Namespaces

[net](https://ziglang.org/documentation/master/std/#std.Io.net)

## Functions

```
pub fn async( io: Io, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function)), ) Future(@typeInfo(@TypeOf(function)).@"fn".return_type.?)
```

Calls `function` with `args`, such that the return value of the function is not guaranteed to be available until `await` is called.

```
pub fn checkCancel(io: Io) Cancelable!void
```

This function acts as a pure cancelation point (subject to protection; see `CancelProtection`) and does nothing else. In other words, it returns `error.Canceled` if there is an outstanding non-blocked cancelation request, but otherwise is a no-op.

```
pub fn concurrent( io: Io, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function)), ) ConcurrentError!Future(@typeInfo(@TypeOf(function)).@"fn".return_type.?)
```

Calls `function` with `args`, such that the return value of the function is not guaranteed to be available until `await` is called, allowing the caller to progress while waiting for any `Io` operations.

```
pub fn futexWait(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, expected: T) Cancelable!void
```

Atomically checks if the value at `ptr` equals `expected`, and if so, blocks until either:

```
pub fn futexWaitTimeout(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, expected: T, timeout: Timeout) Cancelable!void
```

Same as `futexWait`, except also unblocks if `timeout` expires. As with `futexWait`, spurious wakeups are possible. It remains the caller's responsibility to differentiate between these three possible wake-up reasons if necessary.

```
pub fn futexWaitUncancelable(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, expected: T) void
```

Same as `futexWait`, except does not introduce a cancelation point.

```
pub fn futexWake(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, max_waiters: u32) void
```

Unblocks pending futex waits on `ptr`, up to a limit of `max_waiters` calls.

```
pub fn lockStderr(io: Io, buffer: []u8, terminal_mode: ?Terminal.Mode) Cancelable!LockedStderr
```

For doing application-level writes to the standard error stream. Coordinates also with debug-level writes that are ignorant of Io interface and implementations. When this returns, `std.process.stderr_thread_mutex` will be locked.

```
pub fn poll( gpa: Allocator, comptime StreamEnum: type, files: PollFiles(StreamEnum), ) Poller(StreamEnum)
```

```
pub fn random(io: Io, buffer: []u8) void
```

Obtains entropy from a cryptographically secure pseudo-random number generator.

```
pub fn randomSecure(io: Io, buffer: []u8) RandomSecureError!void
```

Obtains cryptographically secure entropy from outside the process.

```
pub fn recancel(io: Io) void
```

Asserts that `error.Canceled` was returned from a prior cancelation point, and "re-arms" the cancelation request, so that `error.Canceled` will be returned again from the next cancelation point.

```
pub fn select(io: Io, s: anytype) Cancelable!SelectUnion(@TypeOf(s))
```

`s` is a struct with every field a `*Future(T)`, where `T` can be any type, and can be different for each field.

```
pub fn sleep(io: Io, duration: Duration, clock: Clock) SleepError!void
```

```
pub fn swapCancelProtection(io: Io, new: CancelProtection) CancelProtection
```

Updates the current task's cancel protection state (see `CancelProtection`).

```
pub fn tryLockStderr(io: Io, buffer: []u8, terminal_mode: ?Terminal.Mode) Cancelable!?LockedStderr
```

Same as `lockStderr` but non-blocking.

```
pub fn unlockStderr(io: Io) void
```

## Error Sets

- [Cancelable](https://ziglang.org/documentation/master/std/#std.Io.Cancelable)
- [ConcurrentError](https://ziglang.org/documentation/master/std/#std.Io.ConcurrentError)
- [QueueClosedError](https://ziglang.org/documentation/master/std/#std.Io.QueueClosedError)
- [RandomSecureError](https://ziglang.org/documentation/master/std/#std.Io.RandomSecureError)
- [SleepError](https://ziglang.org/documentation/master/std/#std.Io.SleepError)
- [UnexpectedError](https://ziglang.org/documentation/master/std/#std.Io.UnexpectedError)