# std.Io.Future

📚 **[See Comprehensive Examples & Tests](../../Examples/test_future_comprehensive.zig)** - Runnable code demonstrating Future lifecycle, cancellation, and error handling

## Quick Start

### Launch and Await a Task
```zig
var task = io.async(doWork, .{ gpa, io, "input" });
defer if (task.cancel(io)) |result| gpa.free(result) else |_| {};

const result = try task.await(io);
// use result...
```

### Non-Allocating Task (Plain Value Return)
```zig
var task = io.async(double, .{21});
defer _ = task.cancel(io);

const value = task.await(io); // value == 42
```

### Fan-Out: Multiple Concurrent Tasks
```zig
var task1 = io.async(fetchData, .{ gpa, io, "url1" });
defer if (task1.cancel(io)) |data| gpa.free(data) else |_| {};

var task2 = io.async(fetchData, .{ gpa, io, "url2" });
defer if (task2.cancel(io)) |data| gpa.free(data) else |_| {};

const data1 = try task1.await(io);
const data2 = try task2.await(io);
```

⚠️ **Critical**: Always pair `io.async` with a `defer cancel` when the task returns heap-allocated data. If the caller returns early (e.g. due to an error on a different task), the cancel ensures the result is still produced so you can free it.

---

## Overview

`std.Io.Future` is a generic handle representing an asynchronous task that has been submitted to the I/O backend. It is returned by `io.async` and provides two ways to retrieve the task's result: `await` (waits for completion) and `cancel` (requests cancellation, then waits).

`Future` is parameterized on the task's return type:
- If the task function returns `T`, the Future is `Future(T)` and `.await` / `.cancel` return `T`.
- If the task function returns `!T`, the Future is `Future(!T)` and `.await` / `.cancel` return `!T`.

**Key Characteristics:**
- **Generic**: `Future(Result)` where `Result` matches the return type of the async function.
- **Idempotent**: Calling `.await` multiple times returns the same result. Calling `.cancel` after `.await` is a no-op.
- **Not thread-safe**: Do not call `.await` or `.cancel` from multiple threads on the same Future.
- **Must be consumed**: The task runs regardless — you must call either `.await` or `.cancel` to retrieve (or discard) the result.

**When to use:**
- Launching background work that runs concurrently with the caller.
- Fan-out patterns where multiple independent operations run in parallel.
- Any scenario where you want non-blocking task submission with a later synchronization point.

## Parameters

`Result: type`

The return type of the async function. This determines what `.await` and `.cancel` return.

## Fields

`any_future: ?*AnyFuture`

Internal pointer to the type-erased future state managed by the I/O backend. `null` after the task has been awaited or canceled.

------

`result: Result`

Stores the task's return value after completion. Only valid after `.await` or `.cancel` has returned.

## Core Functions

### `pub fn await(f: *Future, io: Io) Result`

Blocks until the task completes and returns its result. Idempotent — subsequent calls return the same value without blocking. Not thread-safe: do not call from multiple threads.

**Example:**
```zig
var task = io.async(computeSum, .{1000});
const sum = task.await(io);
std.debug.print("Sum: {}\n", .{sum});
```

------

### `pub fn cancel(f: *Future, io: Io) Result`

Equivalent to `await`, but first sends a cancellation request to the task. The task will receive `error.Canceled` at its next cancellation point (any `Io` call that supports cancellation, such as `sleep`, network reads, etc.). If the task has already completed, the cancellation request is ignored and the result is returned normally.

This is the idiomatic cleanup mechanism. Use it in a `defer` to ensure the result is always retrieved — even if the caller exits early due to an error on another task.

**Example:**
```zig
var task = io.async(doWork, .{ gpa, io, "data" });
defer if (task.cancel(io)) |result| gpa.free(result) else |_| {};

// If we return early here, the defer still frees the result
const result = try task.await(io);
```

## Usage Patterns

### Fan-Out with Resource Cleanup
```zig
fn juicyMain(gpa: Allocator, io: Io) !void {
    var fetch_user = io.async(fetchUser, .{ gpa, io, 1 });
    defer if (fetch_user.cancel(io)) |data| gpa.free(data) else |_| {};

    var fetch_posts = io.async(fetchPosts, .{ gpa, io, 1 });
    defer if (fetch_posts.cancel(io)) |data| gpa.free(data) else |_| {};

    // defer cancels own the results — do not free manually
    const user = try fetch_user.await(io);
    const posts = try fetch_posts.await(io);

    // use user and posts...
    // If fetchUser fails, the defer on fetchPosts still runs and frees its result
}
```

### Handling Task Failures Gracefully
```zig
var task = io.async(riskyWork, .{ gpa, io });
// defer cancel owns the result on success; logs on error
defer if (task.cancel(io)) |s| {
    gpa.free(s);
} else |err| {
    std.debug.print("Task failed: {}\n", .{err});
};

if (task.await(io)) |_| {
    // success — defer cancel will free the result
} else |err| {
    // error path — task returned an error
    std.debug.print("Caught: {}\n", .{err});
}
```

## Debug Checklist

1. ✅ **Did you await or cancel?** The task runs regardless. If you drop the Future without consuming it, the result leaks.
2. ✅ **Did you `defer cancel` for heap-allocated results?** If a second task fails and you `try` its await, the first task's result must still be freed.
3. ✅ **Are you awaiting from one thread?** `await` and `cancel` are not thread-safe. Use them only from the task's owner.
4. ✅ **Does your task function signature match?** `io.async` infers the Future type from the function's return type. Mismatches are compile errors.
5. ✅ **Cancellation is cooperative, not preemptive.** The task must reach a cancellation point (an `Io` call) for `error.Canceled` to be delivered. A pure CPU loop will not be interrupted.

## Performance Tips

1. **Defer cancel immediately after async** — This pattern ensures cleanup regardless of control flow, and costs nothing if the task completes normally (cancel after await is a no-op).
2. **Fan out before awaiting** — Launch all tasks first, then await in order. This maximizes concurrency overlap.
3. **Match task granularity to overhead** — Very short tasks (sub-microsecond) may not benefit from async dispatch. Reserve `io.async` for work that involves I/O or takes measurable time.

## See Also

- `std.Io` — The generic I/O interface hosting `async`.
- `std.Io.Threaded` — The thread-pool backend that executes async tasks.
- `std.Io.CancelProtection` — Mechanism for marking critical sections that should not be canceled.
