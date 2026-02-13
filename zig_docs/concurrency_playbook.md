# Concurrency and Synchronization Playbook

Practical patterns for race-free shared state, lock discipline, and cooperative stop signals.

## Runnable Examples

- `zig_docs_std/Examples/concurrency_playbook.tests.zig`
- `zig_docs_std/Examples/atomic.tests.zig`
- `zig_docs_std/Examples/test_sync_primitives.zig`

## Overview

Concurrency bugs are usually design bugs, not syntax bugs.
Start with explicit ownership and clear synchronization rules.

## Quick Start

1. Prefer message passing when possible.
2. If sharing mutable state, pick one synchronization primitive and stick to it.
3. Define lock ordering globally.
4. Use cancellation flags/tokens for cooperative shutdown.

```zig
const std = @import("std");

const Shared = struct {
    counter: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
};

fn worker(shared: *Shared, iterations: usize) void {
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        _ = shared.counter.fetchAdd(1, .monotonic);
    }
}
```

## Race-Condition Checklist

1. Is mutable memory shared across threads?
2. Is every shared write synchronized (atomic, mutex, channel)?
3. Are read-modify-write operations atomic?
4. Are thread start/stop lifetimes well-defined?
5. Are shutdown/cancel paths tested under load?

## Lock Ordering Convention

Define and document one global order.

1. Assign each lock a rank.
2. Acquire only in ascending rank order.
3. Release in reverse order.
4. Never call external code while holding multiple locks.

## Timeout and Cancellation Guidance

1. Prefer bounded waits.
2. Use periodic cancel checks in loops.
3. On timeout, return typed errors and let callers decide retry policy.
4. Ensure cancellation does not skip required cleanup.

## Producer/Consumer Guidance

1. Bound queues to prevent memory blowup.
2. Treat full queue as backpressure signal, not exceptional crash path.
3. Decide drop/block policy explicitly.
4. Log queue pressure metrics in services.

## Gotchas

1. Locking around broad code regions reduces parallelism and increases deadlock risk.
2. `monotonic` ordering is not a substitute for lock discipline.
3. Detached threads can outlive resources unless lifecycle is explicit.
4. Infinite retries without backoff hide saturation and make outages worse.

## Related Docs

- [Atomics](atomics.md)
- [Async Functions](async_functions.md)
- [I/O Reliability and Backpressure](io_reliability_backpressure.md)
- [Error Handling Playbook](error_handling_playbook.md)
