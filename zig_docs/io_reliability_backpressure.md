# I/O Reliability and Backpressure

Operational guidance for partial reads/writes, framing, retries, backpressure, and shutdown semantics in Zig 0.16.

## Runnable Examples

```bash
zig test zig_docs_std/Examples/io_reliability_backpressure.tests.zig
zig test zig_docs_std/Examples/std.process.tests.zig
zig test zig_docs_std/Examples/test_stream_shutdown.zig
zig test zig_docs_std/Examples/test_stream_bidirectional.zig
```

## Overview

I/O boundaries fail in routine ways: short reads, short writes, timeouts, EOF races, and peer shutdown.
Reliable systems treat these as normal control flow.

When producers send data faster than consumers or network links can handle it, queues grow, latency spikes, and memory can be exhausted.
Backpressure is the mechanism that pushes back on producers so overload is handled intentionally (block, drop, or reject) instead of failing unpredictably.

In Zig 0.16, prefer the concrete `std.Io.Reader` and `std.Io.Writer` helpers before writing manual transfer loops:

- `Reader.readSliceAll(buffer)` fills an exact buffer or returns `error.EndOfStream`.
- `Reader.takeDelimiter`, `takeDelimiterInclusive`, and `takeDelimiterExclusive` enforce delimiter contracts using the reader buffer capacity as the line-length cap.
- `Writer.writeAll(bytes)` loops until all bytes are accepted by the writer or `error.WriteFailed` is returned.
- `Writer.flush()` is required when buffered data must reach the underlying file, socket, or stream.
- `std.Io.Queue(T)` is the source-backed blocking bounded queue for producer/consumer backpressure. Its closed error is `error.Closed`.

## Quick Start

1. Read in loops until protocol boundary is satisfied.
2. Write in loops until full payload is sent.
3. Prefer `Reader.readSliceAll` and `Writer.writeAll` for exact byte counts.
4. Validate framing before allocation.
5. Treat EOF, timeout, cancelation, malformed data, and peer reset distinctly.
6. Use bounded queues for producer backpressure.
7. Use graceful shutdown: write, flush, `shutdown(io, .send)`, drain, close.

## What Can Fail and Recovery Pattern

### Read Loop

- Can fail: `error.EndOfStream`, timeout, `error.Canceled`, `error.ReadFailed`, malformed framing.
- Recovery: return typed errors, allow caller retry/reconnect policy.

Use `readSliceAll` when the protocol requires exactly N bytes. Use `readSliceShort` only when a short final read is valid for the protocol.

### Write Loop

- Can fail: short writes, buffered data not flushed, connection reset, backpressure, `error.Canceled`, `error.WriteFailed`.
- Recovery: use `writeAll`, call `flush` at message or shutdown boundaries, and escalate after bounded retries only for transient transport errors.

### Framing

- Can fail: declared frame length too large, truncated frame.
- Recovery: reject frame early with explicit error, optionally drop connection.

For length-prefixed protocols, parse and cap the length before allocating. For delimiter protocols, size the `Reader` buffer to the maximum accepted line or use streaming delimiter APIs with an explicit `std.Io.Limit`.

### Backpressure

- Can fail: producer is faster than consumer, kernel/network buffers are full, queue capacity is exhausted.
- Recovery: choose one policy per boundary: block, drop-oldest, drop-newest, coalesce, or reject with an explicit overload error.

`std.Io.Queue(T)` blocks producers when full and consumers when empty. `put(io, elements, min)` and `get(io, buffer, min)` may return a short count if closure or cancelation happens after partial progress. Passing `min = 0` makes a nonblocking "do as much as possible" attempt; a return value of 0 means no progress was possible without blocking.

When a queue is closed, future puts return `error.Closed`. Buffered elements are drained before gets return `error.Closed`.

### Shutdown

- Can fail: peer closes first, pending writes not flushed, half-close unsupported.
- Recovery: make shutdown idempotent and treat close-path errors as best effort when safe.

For `std.Io.net.Stream`, use `try stream.shutdown(io, .send)` to half-close the write side after flushing, then read the peer's response until EOF or protocol completion, and finally `stream.close(io)`. Use `.recv` or `.both` only when the protocol calls for those directions to stop.

## Decision Guide

1. If protocol has variable lengths, use explicit length-prefix framing.
2. If messages are line-based, enforce max line length and delimiter contract.
3. If queue depth grows, treat as backpressure and apply one policy:
   block, drop-oldest, drop-newest, or shed load with explicit error.
4. If the producer must slow down, use `std.Io.Queue(T)` or another bounded primitive instead of an unbounded `ArrayList`.
5. Use retries only for transport/transient failures, never for malformed payloads.
6. After consuming `error.Canceled` locally, either return it or call `io.recancel()` so outer cancelation policy remains observable.

## Source-Backed API Notes

### `std.Io.Reader`

- `readSliceAll(buffer)` returns `error.EndOfStream` if it cannot fill the whole buffer.
- `readSliceShort(buffer)` returns fewer bytes only at end of stream.
- `takeDelimiter(delimiter)` returns `null` on empty EOF, returns the final unterminated bytes at EOF, and returns `error.StreamTooLong` when the delimiter is not found within the reader buffer capacity.
- `takeDelimiterInclusive(delimiter)` includes the delimiter and returns `error.EndOfStream` when the delimiter is not found before EOF.
- `streamDelimiterLimit(writer, delimiter, limit)` is the streaming form when a line may be larger than the reader buffer but still needs a hard cap.

### `std.Io.Writer`

- `write(bytes)` may accept fewer bytes than requested.
- `writeAll(bytes)` repeatedly calls `write` until all bytes are accepted or an error occurs.
- `flush()` drains buffered bytes; fixed or allocating writers may make flushing a no-op, but stream/file writers use it as the durability/send boundary.

### `std.Io.Queue(T)`

- `Queue(T).init(buffer)` uses caller-owned fixed backing storage; capacity is runtime-configurable and bounded.
- `put` blocks when fewer than `min` elements can be accepted.
- `get` blocks when fewer than `min` elements can be returned.
- `putAll` requires all elements or returns `error.Closed` / `error.Canceled`.
- `close(io)` is thread-safe and idempotent; it wakes blocked producers and consumers.

## Gotchas

1. Assuming one `read` equals one message.
2. Assuming one `write` flushes the entire message.
3. Allocating attacker-controlled frame sizes without cap.
4. Ignoring shutdown ordering (write -> flush -> half-close -> drain -> close).
5. Treating queue closure as data loss: `std.Io.Queue(T)` drains buffered elements before returning `error.Closed` to consumers.
6. Swallowing cancelation without preserving the outer cancelation signal.

## Related Docs

- [Concurrency Playbook](concurrency.md)
- [Error Handling Playbook](error_handling.md)
- [std.Io](../zig_docs_std/Types/Io/std.io.md)
- [std.Io.Queue](../zig_docs_std/Types/Io/Types/std.Io.Queue.md)
- [std.Io.Reader](../zig_docs_std/Types/Io/Types/std.Io.Reader.md)
- [std.Io.Writer](../zig_docs_std/Types/Io/Types/std.Io.Writer.md)
- [std.Io.net.Stream](../zig_docs_std/Types/Io/Namespaces/std.Io.net.Stream.md)
