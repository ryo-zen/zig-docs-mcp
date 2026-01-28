# std.Io.net.Socket

📚 **[See Comprehensive Examples & Tests](../../Examples/test_socket_basic.zig)**

## Quick Start

**UDP Echo Client**

```zig
const std = @import("std");
const net = std.Io.net;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Setup IO
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Bind a local socket
    const local_addr = try net.IpAddress.parse("127.0.0.1", 0);
    const socket = try local_addr.bind(io, .{ .mode = .dgram });
    defer socket.close(io);

    // Send data
    const dest_addr = try net.IpAddress.parse("127.0.0.1", 1234);
    const data = "Hello, World!";
    try socket.send(io, &dest_addr, data);

    // Receive response
    var buffer: [1024]u8 = undefined;
    const msg = try socket.receive(io, &buffer);
    std.debug.print("Received from {}: {s}\n", .{ msg.from, msg.data });
}
```

⚠️ **Critical**: Always call `close(io)` on the socket when done to release OS resources.

---

## Overview

Represents an open network socket. This type is primarily used for connectionless protocols (like UDP) via the `send` and `receive` methods.

For connection-oriented protocols (like TCP), see `std.Io.net.Stream`, which uses a `Socket` internally as a handle but provides a stream-based API.

**Key Characteristics**
*   **Protocol Agnostic**: Can represent different socket types, though methods like `receive` imply message-based (datagram) usage.
*   **IO Integrated**: Operations require an `Io` context instance to perform asynchronous or synchronous I/O depending on the backend.
*   **Ownership**: The `Socket` struct itself is a lightweight handle wrapper. The underlying OS resource must be managed via `close()`.

**When to use**
*   Sending or receiving UDP packets.
*   Implementing custom protocols on top of raw sockets.
*   Accessing the underlying handle of a `Stream` for advanced configuration.

## Fields

`handle: Handle`
The underlying OS-specific socket handle (e.g., file descriptor on Linux, SOCKET on Windows).

------

`address: IpAddress`
The local address to which this socket is bound. Contains the resolved ephemeral port number if one was requested during binding (by specifying port 0).

## Types

**Handle**
Platform-dependent integer type representing the socket handle.

**Mode**
Socket mode configuration (e.g., blocking behavior).

**receiveManyTimeout**
Return type structure for bulk receive operations with timeout.

## Core Functions

`pub fn close(s: *const Socket, io: Io) void`
Closes the socket and releases associated OS resources. After this call, the socket handle is invalid.
*   **s**: Pointer to the socket to close.
*   **io**: The IO context used for the operation.

## Data Transmission Functions

`pub fn receive(s: *const Socket, io: Io, buffer: []u8) ReceiveError!IncomingMessage`
Waits for and receives a message into the provided buffer. This is a connectionless operation (e.g., UDP).
*   **s**: The socket to receive on.
*   **io**: The IO context.
*   **buffer**: Destination buffer for the received data.
*   Returns an `IncomingMessage` containing metadata (`from` address) and a slice of `buffer` with the data.

**Example:**
```zig
var buf: [1024]u8 = undefined;
const msg = try socket.receive(io, &buf);
```

------

`pub fn receiveTimeout(s: *const Socket, io: Io, buffer: []u8, timeout: Io.Timeout) ReceiveTimeoutError!IncomingMessage`
Same as `receive`, but fails with `error.Timeout` if no data is received within the specified duration.

**Example:**
```zig
const timeout = std.Io.Timeout{
    .duration = .{
        .raw = .{ .nanoseconds = 100 * std.time.ns_per_ms },
        .clock = .awake,
    },
};
const msg = try socket.receiveTimeout(io, &buf, timeout);
```

------

`pub fn receiveManyTimeout(s: *const Socket, io: Io, message_buffer: []IncomingMessage, data_buffer: []u8, flags: ReceiveFlags, timeout: Io.Timeout) struct { ?ReceiveTimeoutError, usize }`
Receives multiple messages into the provided message and data buffers. This is more efficient than calling `receive` multiple times.
*   **s**: The socket to receive on.
*   **io**: The IO context.
*   **message_buffer**: Slice to store metadata for each received message.
*   **data_buffer**: Large buffer to store the actual payload data for all received messages.
*   **flags**: Receive configuration flags.
*   **timeout**: The maximum time to wait for at least one message.
*   Returns a struct containing an optional error and the number of messages successfully received.

------

`pub fn send(s: *const Socket, io: Io, dest: *const IpAddress, data: []const u8) SendError!void`
Sends a message to the specified destination.
*   **s**: The sending socket.
*   **io**: The IO context.
*   **dest**: Address of the recipient.
*   **data**: The payload to send.

**Example:**
```zig
try socket.send(io, &remote_addr, "ping");
```

------

`pub fn sendMany(s: *const Socket, io: Io, messages: []OutgoingMessage, flags: SendFlags) SendError!void`
Sends multiple messages efficiently, potentially using specialized OS syscalls (like `sendmmsg`). Each message in the slice specifies its own destination address.

## Usage Patterns

### Bulk Message Handling
Using `sendMany` and `receiveManyTimeout` for high-throughput UDP processing.

```zig
// Sending
var out_msgs: [2]net.OutgoingMessage = undefined;
out_msgs[0] = .{ .address = &addr1, .data_ptr = data1.ptr, .data_len = data1.len, .control = &[_]u8{} };
out_msgs[1] = .{ .address = &addr2, .data_ptr = data2.ptr, .data_len = data2.len, .control = &[_]u8{} };
try socket.sendMany(io, &out_msgs, .{});

// Receiving
var in_msgs: [16]net.IncomingMessage = undefined;
var data_buf: [4096]u8 = undefined;
const res = socket.receiveManyTimeout(io, &in_msgs, &data_buf, .{}, timeout);
const count = res[1];
```

## Error Sets

**ReceiveError**
Errors that can occur during `receive`. Includes `AccessDenied`, `AddressFamilyNotSupported`, `SystemResources`, etc.

**ReceiveTimeoutError**
Superset of `ReceiveError` that includes `Timeout`.

**SendError**
Errors that can occur during `send`. Includes `AccessDenied`, `AddressFamilyNotSupported`, `MessageTooBig`, `NetworkUnreachable`, etc.

## Debug Checklist

1.  ✅ **UDP Binding**: Ensure you set `.mode = .dgram` in `BindOptions` when calling `IpAddress.bind()`.
2.  ✅ **Resource Cleanup**: Sockets MUST be closed via `socket.close(io)`.
3.  ✅ **Broken closeMany**: ⚠️ Avoid `net.Socket.closeMany` in version 0.16; it currently has a type mismatch bug. Close sockets individually.
4.  ✅ **Timeout Construction**: `Io.Timeout` is a union. Use the `.duration` field with a `.raw` nanosecond count and a `.clock` (usually `.awake`).
5.  ✅ **Incoming Data**: Access received data via `msg.data` and the sender's address via `msg.from`.

## Performance Tips

1.  **Batching**: Use `sendMany` and `receiveManyTimeout` to reduce the number of syscalls when handling high volumes of small packets.
2.  **Buffer Sizing**: For `receiveManyTimeout`, ensure the `data_buffer` is large enough to hold the maximum expected payload for *all* messages in the `message_buffer`.
3.  **IO Implementation**: Prefer `Io.Threaded` or target-specific high-performance backends (like `IoUring` on Linux) for the best network performance.

## See Also

*   [std.Io.net.Stream](std.Io.net.Stream.md) - For TCP/connection-oriented sockets.
*   [std.Io.net.IpAddress](std.Io.net.IpAddress.md) - For creating/binding sockets.
*   📚 **[Comprehensive Examples](../../Examples/test_socket_comprehensive.zig)**

