# I/O Reliability and Backpressure

Operational guidance for partial reads/writes, framing, retries, and shutdown semantics.

## Runnable Examples

- `zig_docs_std/Examples/io_reliability_backpressure.tests.zig`
- `zig_docs_std/Examples/std.process.tests.zig`
- `zig_docs_std/Examples/test_stream_shutdown.zig`
- `zig_docs_std/Examples/test_stream_bidirectional.zig`

## Overview

I/O boundaries fail in routine ways: short reads, short writes, timeouts, EOF races, and peer shutdown.
Reliable systems treat these as normal control flow.

When producers send data faster than consumers or network links can handle it, queues grow, latency spikes, and memory can be exhausted.
Backpressure is the mechanism that pushes back on producers so overload is handled intentionally (block, drop, or reject) instead of failing unpredictably.

## Quick Start

1. Read in loops until protocol boundary is satisfied.
2. Write in loops until full payload is sent.
3. Validate framing before allocation.
4. Treat EOF and timeout distinctly.
5. Use graceful shutdown: flush, half-close, drain, close.

## What Can Fail and Recovery Pattern

### Read Loop

- Can fail: `EndOfStream`, timeout, interrupted/canceled operation, malformed framing.
- Recovery: return typed errors, allow caller retry/reconnect policy.

### Write Loop

- Can fail: short writes, connection reset, backpressure (would block).
- Recovery: continue short writes until complete; escalate after bounded retries.

### Framing

- Can fail: declared frame length too large, truncated frame.
- Recovery: reject frame early with explicit error, optionally drop connection.

### Shutdown

- Can fail: peer closes first, pending writes not flushed, half-close unsupported.
- Recovery: make shutdown idempotent and treat close-path errors as best effort when safe.

## Decision Guide

1. If protocol has variable lengths, use explicit length-prefix framing.
2. If messages are line-based, enforce max line length and delimiter contract.
3. If queue depth grows, treat as backpressure and apply one policy:
   block, drop-oldest, drop-newest, or shed load with explicit error.
4. Use retries only for transport/transient failures, never for malformed payloads.

## Gotchas

1. Assuming one `read` equals one message.
2. Assuming one `write` flushes the entire message.
3. Allocating attacker-controlled frame sizes without cap.
4. Ignoring shutdown ordering (write -> flush -> half-close -> close).

## Related Docs

- [Concurrency Playbook](concurrency.md)
- [Error Handling Playbook](error_handling.md)
- [std.Io](../zig_docs_std/Types/Io/std.io.md)
- [std.Io.Reader](../zig_docs_std/Types/Io/Types/std.Io.Reader.md)
- [std.Io.Writer](../zig_docs_std/Types/Io/Types/std.Io.Writer.md)
- [std.Io.net.Stream](../zig_docs_std/Types/Io/Namespaces/std.Io.net.Stream.md)
