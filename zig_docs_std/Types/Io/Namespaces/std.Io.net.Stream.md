# std.Io.net.Stream

📚 **Runnable examples:** `zig_docs_std/Examples/test_stream_basic.zig`, `zig_docs_std/Examples/test_stream_bidirectional.zig`, `zig_docs_std/Examples/test_stream_shutdown.zig`
📘 **Reliability playbook:** [I/O Reliability and Backpressure](../../../../zig_docs/io_reliability_backpressure.md)

## Quick Start

### Most Common Patterns

**Open and Read from a Stream**
```zig
const addr = net.IpAddress.parse("example.com", 80) catch unreachable;
const stream = try addr.connect(io, .{ .mode = .stream });
defer stream.close(io);

var buffer: [4096]u8 = undefined;
var reader = stream.reader(io, &buffer);
// takeDelimiterInclusive returns content + delimiter; strip the \n
const line_raw = try reader.interface.takeDelimiterInclusive('\n');
const line = line_raw[0 .. line_raw.len - 1];
```

**Open and Write to a Stream**
```zig
const addr = net.IpAddress.parse("example.com", 80) catch unreachable;
const stream = try addr.connect(io, .{ .mode = .stream });
defer stream.close(io);

var buffer: [4096]u8 = undefined;
var writer = stream.writer(io, &buffer);
try writer.interface.writeAll("GET / HTTP/1.1\r\nHost: example.com\r\n\r\n");
try writer.interface.flush();
```

**Bidirectional Communication**
```zig
const addr = net.IpAddress.parse("example.com", 80) catch unreachable;
const stream = try addr.connect(io, .{ .mode = .stream });
defer stream.close(io);

var wbuf: [4096]u8 = undefined;
var writer = stream.writer(io, &wbuf);
try writer.interface.writeAll("GET / HTTP/1.1\r\nHost: example.com\r\n\r\n");
try writer.interface.flush();

var rbuf: [4096]u8 = undefined;
var reader = stream.reader(io, &rbuf);
const response = try reader.interface.take(1024);
```

**Graceful Shutdown**
```zig
// Signal peer that no more data will be sent
try stream.shutdown(io, .send);

// Or shut down both directions
try stream.shutdown(io, .both);

// Then close the socket
stream.close(io);
```

### ⚠️ Critical: Always Flush Writers!
```zig
var writer = stream.writer(io, &buffer);
try writer.interface.writeAll("data");
try writer.interface.flush();  // ← REQUIRED! Data may not be sent until flush
```

---

## Overview

`std.Io.net.Stream` represents an open socket connection with a network protocol that guarantees sequencing, delivery, and prevents repetition. It is typically backed by a TCP connection or a UNIX domain socket.

**Key Characteristics:**
- **Bidirectional**: Supports both reading and writing on the same connection
- **Buffered I/O**: Reader and Writer are both buffered; you supply the buffer
- **Wrapper types**: `stream.reader()` and `stream.writer()` return `Stream.Reader` / `Stream.Writer` wrapper structs. The actual `Io.Reader` / `Io.Writer` methods are accessed via the `.interface` field
- **Explicit lifecycle**: You must `close()` the stream when done
- **Graceful shutdown**: Use `shutdown()` to signal the peer before closing

**When to use Stream:**
- Client-server TCP communication
- UNIX domain socket IPC
- Any scenario requiring a reliable, ordered byte stream over the network

**Relationship to Reader and Writer:**
- `stream.reader(io, &buffer)` returns a `Stream.Reader` wrapping an `Io.Reader` in `.interface`
- `stream.writer(io, &buffer)` returns a `Stream.Writer` wrapping an `Io.Writer` in `.interface`
- Both `Io.Reader` and `Io.Writer` are concrete, non-generic types using a buffer-over-vtable design

**⚠️ Delimiter reading gotcha:**
On this dev build, `takeDelimiterExclusive` does not advance the reader past the delimiter byte. Use `takeDelimiterInclusive` and strip the trailing delimiter yourself:
```zig
const raw = try reader.interface.takeDelimiterInclusive('\n');
const line = raw[0 .. raw.len - 1]; // strip \n
```

## Fields

`socket: Socket`

The underlying socket handle for this stream. This is the raw OS-level resource that the stream wraps. All read and write operations ultimately operate on this socket through the Io backend.

## Types

- **Reader** - Wrapper struct containing an `Io.Reader` in `.interface` for receiving data from the stream
- **Writer** - Wrapper struct containing an `Io.Writer` in `.interface` for sending data to the stream

## Stream Functions

### `pub fn close(s: *const Stream, io: Io) void`

Closes the underlying socket, releasing the OS resource. After calling `close()`, the stream is no longer usable. This should be called in a `defer` immediately after obtaining a stream to ensure cleanup on all exit paths.

**Example:**
```zig
const addr = net.IpAddress.parse("127.0.0.1", 8080) catch unreachable;
const stream = try addr.connect(io, .{ .mode = .stream });
defer stream.close(io);
// ... use stream ...
```

------

### `pub fn reader(stream: Stream, io: Io, buffer: []u8) Reader`

Creates a buffered `Reader` wrapper for receiving data from this stream. The caller supplies the buffer; the reader does not allocate. The buffer size determines how much data can be buffered locally before requiring another read from the network.

Access `Io.Reader` methods via the `.interface` field.

**Example:**
```zig
var buffer: [4096]u8 = undefined;
var reader = stream.reader(io, &buffer);

// Read a line terminated by newline (strip the delimiter)
const raw = try reader.interface.takeDelimiterInclusive('\n');
const line = raw[0 .. raw.len - 1];
```

------

### `pub fn shutdown(s: *const Stream, io: Io, how: ShutdownHow) ShutdownError!void`

Signals the peer that one or both directions of the connection are being shut down. This is a graceful shutdown — it allows the peer to finish reading any data already in flight.

**ShutdownHow values:**
- `.send` - No more data will be sent; peer will see EOF on their read
- `.recv` - No more data will be read; peer will get an error on their write
- `.both` - Both directions are shut down

**Example:**
```zig
// Finished sending, but still want to read the response
try stream.shutdown(io, .send);

// Read remaining response data...
const raw = try reader.interface.takeDelimiterInclusive('\n');
const line = raw[0 .. raw.len - 1];

// Now close
stream.close(io);
```

------

### `pub fn writer(stream: Stream, io: Io, buffer: []u8) Writer`

Creates a buffered `Writer` wrapper for sending data to this stream. The caller supplies the buffer; the writer does not allocate. Data is accumulated in the buffer and sent to the network when `flush()` is called or the buffer fills.

Access `Io.Writer` methods via the `.interface` field.

**Example:**
```zig
var buffer: [4096]u8 = undefined;
var writer = stream.writer(io, &buffer);

try writer.interface.print("HTTP/1.1 200 OK\r\nContent-Length: {d}\r\n\r\n", .{body.len});
try writer.interface.writeAll(body);
try writer.interface.flush();
```

## Usage Patterns

### HTTP-Style Request/Response
```zig
const addr = net.IpAddress.parse("api.example.com", 80) catch unreachable;
const stream = try addr.connect(io, .{ .mode = .stream });
defer stream.close(io);

// Send request
var wbuf: [2048]u8 = undefined;
var writer = stream.writer(io, &wbuf);
try writer.interface.writeAll("GET /data HTTP/1.1\r\n");
try writer.interface.writeAll("Host: api.example.com\r\n");
try writer.interface.writeAll("Connection: close\r\n");
try writer.interface.writeAll("\r\n");
try writer.interface.flush();

// Signal done sending
try stream.shutdown(io, .send);

// Read response
var rbuf: [8192]u8 = undefined;
var reader = stream.reader(io, &rbuf);
// Parse status line
const status_raw = try reader.interface.takeDelimiterInclusive('\n');
const status = status_raw[0 .. status_raw.len - 1]; // strip \n
```

### Binary Protocol Communication
```zig
const addr = net.IpAddress.parse("db.local", 5432) catch unreachable;
const stream = try addr.connect(io, .{ .mode = .stream });
defer stream.close(io);

var wbuf: [1024]u8 = undefined;
var writer = stream.writer(io, &wbuf);

// Write a length-prefixed message
const message = "AUTH myuser mypass\r\n";
try writer.interface.writeInt(u32, message.len, .big);
try writer.interface.writeAll(message);
try writer.interface.flush();

// Read the response header
var rbuf: [1024]u8 = undefined;
var reader = stream.reader(io, &rbuf);
const resp_len = try reader.interface.takeInt(u32, .big);
const response = try reader.interface.take(resp_len);
```

### Echo Server Pattern
```zig
// After accepting a connection (server_stream is the accepted connection):
var rbuf: [4096]u8 = undefined;
var reader = server_stream.reader(io, &rbuf);

var wbuf: [4096]u8 = undefined;
var writer = server_stream.writer(io, &wbuf);

while (true) {
    const raw = reader.interface.takeDelimiterInclusive('\n') catch |err| {
  if (err == error.EndOfStream) break;
  return err;
    };
    const line = raw[0 .. raw.len - 1]; // strip \n

    try writer.interface.writeAll(line);
    try writer.interface.writeAll("\n");
    try writer.interface.flush();
}

server_stream.close(io);
```

## Error Sets

### `ShutdownError`

Errors that may occur when shutting down a stream connection.

## Debug Checklist

If your code doesn't compile or behave as expected, check:

1. ✅ Did you pass `io` to all stream operations (`close`, `reader`, `writer`, `shutdown`)?
2. ✅ Are you accessing Reader/Writer methods via `.interface`? (`reader.interface.take(...)`, not `reader.take(...)`)
3. ✅ Are you using separate buffers for reader and writer?
4. ✅ Did you call `flush()` on the writer before expecting the peer to receive data? (`writer.interface.flush()`)
5. ✅ Are you using `takeDelimiterInclusive` and stripping the delimiter manually? (`Exclusive` does not advance past the delimiter byte on this build)
6. ✅ Did you `close()` the stream on all exit paths (use `defer`)?
7. ✅ Did you call `shutdown()` before `close()` if you need a graceful termination?
8. ✅ Is your buffer large enough for the messages you're reading/writing?

## Performance Tips

1. **Size your buffer appropriately**: Larger buffers reduce syscalls but use more memory. 4096 bytes is a reasonable default for most TCP workloads.
2. **Flush strategically**: Only flush when the peer needs to see the data (end of a request, before waiting for a response). Multiple `writeAll` calls before a single `flush` are cheaper than flushing after each one.
3. **Reuse streams**: Keep TCP connections open across multiple request/response cycles rather than connecting and closing per request.
4. **Shut down before close**: Call `shutdown(io, .send)` after your last write so the peer sees a clean EOF instead of a connection reset.
5. **Match buffer sizes to message sizes**: If you know your protocol's max message size, size the buffer to fit it — this avoids partial reads and reduces the number of `takeDelimiterInclusive` loops.

## See Also

- `std.Io.Reader` - Buffered reader (`Stream.Reader.interface` type)
- `std.Io.Writer` - Buffered writer (`Stream.Writer.interface` type)
- `std.Io.net` - Network utilities for creating streams (`IpAddress.connect`, `IpAddress.listen`, etc.)
- `std.Io.net.Server` - Server type returned by `IpAddress.listen`, with `accept()` for incoming connections
- `std.Io.Threaded` - Thread-based I/O backend
- `std.Io.Evented` - Event-based I/O backend (async)
