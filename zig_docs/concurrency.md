# Concurrency and Synchronization Playbook

Practical patterns for race-free shared state, lock discipline, bounded work queues, and cooperative stop signals in Zig 0.16.

## Runnable Examples

- `zig test zig_docs_std/Examples/concurrency_playbook.tests.zig`
- `zig test zig_docs_std/Examples/atomic.tests.zig`
- `zig test zig_docs_std/Examples/test_sync_primitives.zig`

## Core Rule

Concurrency bugs are usually ownership bugs first and synchronization bugs second.
Before adding threads or tasks, write down which state is shared, which code owns each mutation, and what primitive protects every access.

In Zig 0.16, most blocking synchronization should use `std.Io` primitives so the same code works with the application's selected I/O backend:

- `std.Io.Mutex`
- `std.Io.Condition`
- `std.Io.Event`
- `std.Io.Semaphore`
- `std.Io.RwLock`
- `std.Io.Group`
- `std.Io.Queue(T)`

Use `std.atomic.Value(T)` for lock-free counters, flags, sequence numbers, and small coordination fields. Low-level `std.Thread.spawn` is still available for explicit OS-thread lifetimes, but higher-level asynchronous I/O work should generally be modeled with `io.async`, `io.concurrent`, `std.Io.Group`, or `std.Io.Queue(T)`.

## Quick Start

1. Prefer passing ownership or messages over sharing mutable state.
2. If state must be shared, choose one primitive for that state and use it on every access.
3. Use `std.Io` sync primitives for waits, locks, queues, and task groups.
4. Use atomics only when the invariant fits in the atomic value or is protected by a separate synchronization rule.
5. Make every spawned thread, future, or group have a clear join, await, or cancel path.

```zig
const std = @import("std");

const SharedCounter = struct {
    value: std.atomic.Value(u64) = .init(0),
};

fn incrementWorker(shared: *SharedCounter, iterations: usize) void {
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        _ = shared.value.fetchAdd(1, .monotonic);
    }
}

test "threaded counter" {
    var shared = SharedCounter{};
    const thread = try std.Thread.spawn(.{}, incrementWorker, .{ &shared, 1000 });
    thread.join();

    try std.testing.expectEqual(@as(u64, 1000), shared.value.load(.acquire));
}
```

## `std.Io` Synchronization

`std.Io` owns operations that can block, suspend, or become cancelation points. That matters for synchronization: a contended `std.Io.Mutex.lock(io)` can block a kernel thread under `std.Io.Threaded` or yield through an evented backend when one is available.

Common choices:

- Use `std.Io.Mutex` for exclusive access to ordinary mutable state.
- Use `std.Io.RwLock` when many readers and rare writers really matter.
- Use `std.Io.Condition` for predicate-based waits guarded by a mutex.
- Use `std.Io.Event` for a set/reset flag with wait support.
- Use `std.Io.Semaphore` for permit-counted access.
- Use `std.Io.Group` when many tasks share one lifetime and must be awaited or canceled together.
- Use `std.Io.Queue(T)` for bounded many-producer, many-consumer pipelines.

`lock`, `wait`, `put`, and `get` style operations are cancelable when their error set includes `error.Canceled`. Their `Uncancelable` variants should be reserved for tiny critical regions where observing cancelation would break an invariant.

## Atomics

Atomics synchronize one memory location. They do not automatically protect nearby fields.

- Use `.monotonic` for counters where no other memory visibility depends on the operation.
- Use `.release` to publish state that another thread may consume.
- Use `.acquire` to consume state published by a release operation.
- Use `.seq_cst` while proving a new algorithm, then weaken only with a reason.
- Use `cmpxchgWeak` in retry loops and `cmpxchgStrong` when a spurious failure would complicate the logic.

Do not mix atomic and non-atomic accesses to the same memory. If an atomic flag points at a larger object, document the release/acquire relationship that makes the object visible.

## Lock Ordering

Define one global ordering for locks that may be acquired together.

1. Assign each lock a rank.
2. Acquire only in ascending rank order.
3. Release in reverse order.
4. Do not call external callbacks while holding multiple locks.
5. Keep blocking I/O outside critical sections unless the lock is explicitly part of that I/O protocol.

`zig_docs_std/Examples/concurrency_playbook.tests.zig` includes a small `LockRank` helper that acquires two `std.Io.Mutex` values in deterministic order.

## Stop and Cancelation Paths

For raw threads, a simple atomic stop flag is often enough:

- Worker loops load the flag with `.acquire`.
- The owner stores `true` with `.release`.
- The owner joins every thread before freeing any captured memory.

For `std.Io` tasks, use the task API's lifetime operation instead:

- `Future.await(io)` waits for a task result.
- `Future.cancel(io)` requests cancelation and releases the task resource.
- `Group.await(io)` waits for all group members.
- `Group.cancel(io)` requests cancelation for all group members and releases group resources.

After creating a future or group, arrange cleanup immediately with `defer` or `errdefer`. A cancel request can still return a successful result, so account for returned resources instead of assuming cancelation always wins.

## Producer and Consumer Design

Bound queues by default. Unbounded queues hide overload until memory pressure or latency makes the failure harder to diagnose.

When using `std.Io.Queue(T)`:

- Size the buffer from a service limit, not from convenience.
- Decide whether producers should block, drop, shed load, or return an error when the queue is full.
- Use `close(io)` to end a stream; consumers can drain buffered items before `error.Closed`.
- Treat `error.Canceled` and `error.Closed` as normal shutdown paths.
- Record queue depth or wait time in long-running services.

## Race-Condition Checklist

1. Is mutable memory shared across threads or tasks?
2. Is every shared write synchronized by the same rule as every shared read?
3. Are read-modify-write operations atomic or guarded by a lock?
4. Does the owner join, await, or cancel all spawned work before freeing captured state?
5. Can timeout, cancelation, and error paths release the same resources as the success path?
6. Are tests run with enough iterations to exercise interleavings?

## Gotchas

1. `std.Io.Mutex.lock(io)` can return `error.Canceled`; use `lockUncancelable(io)` only when the invariant requires it.
2. `.monotonic` ordering is not a substitute for lock discipline or publication ordering.
3. Detached threads can outlive the stack frames, allocators, and file descriptors they captured.
4. `std.Io.Group.await` and `std.Io.Group.cancel` are idempotent but not threadsafe.
5. Infinite retries without backoff hide saturation and make outages worse.
6. `-fsingle-threaded` removes task-level concurrency and cancelation support from `std.Io.Threaded`.

## Zig 0.16 Migration Notes

Zig 0.16 removed `std.Thread.Pool`. Migrate pool-style task sets to `std.Io.Group` or futures from `io.async` and `io.concurrent`.

Blocking sync primitives moved from `std.Thread` to `std.Io` equivalents:

- `std.Thread.ResetEvent` -> `std.Io.Event`
- `std.Thread.WaitGroup` -> `std.Io.Group`
- `std.Thread.Futex` -> low-level `io.futexWait`, `io.futexWaitTimeout`, `io.futexWaitUncancelable`, and `io.futexWake` methods when building custom primitives
- `std.Thread.Mutex` -> `std.Io.Mutex`
- `std.Thread.Condition` -> `std.Io.Condition`
- `std.Thread.Semaphore` -> `std.Io.Semaphore`
- `std.Thread.RwLock` -> `std.Io.RwLock`

Lock-free primitives, including `std.atomic.Value(T)`, do not require an `std.Io` instance.

## Related Docs

- [Atomics](atomics.md)
- [Async Functions](async_functions.md)
- [I/O Reliability and Backpressure](io_reliability_backpressure.md)
- [Error Handling Playbook](error_handling.md)
