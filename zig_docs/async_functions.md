# Async Functions

Async functions regressed with the release of 0.11.0. The current plan is to
reintroduce them as a lower level primitive that powers I/O implementations.

Tracking issue: [Proposal: stackless coroutines as low-level primitives](https://github.com/ziglang/zig/issues/23446)

## Current Practical Guidance (0.16-dev)

In Zig 0.16-dev, application-level async workflows are typically written through `std.Io` task APIs (`io.async`, `io.concurrent`, `io.select`) rather than language-level `async/await` as in older versions.

## Runnable Examples

- `zig_docs_std/Examples/test_async_concurrent_demo.zig`
- `zig_docs_std/Examples/test_async_resource_cleanup.zig`
- `zig_docs_std/Examples/test_queue_and_select.zig`

## Operational Notes

1. Treat cancellation as a normal path; add explicit cancellation points.
2. Use bounded waits and timeout-aware operations for reliability.
3. Keep ownership and cleanup explicit for every spawned task/future.

## See Also

- [Concurrency Playbook](concurrency.md)
- [I/O Reliability and Backpressure](io_reliability_backpressure.md)
- [std.Io](../zig_docs_std/Types/Io/std.io.md)
