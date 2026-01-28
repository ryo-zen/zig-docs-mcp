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

------

`pub fn closeMany(io: Io, sockets: []const Socket) void`
Closes multiple sockets efficiently.
*   **io**: The IO context.
*   **sockets**: Slice of sockets to close.

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
Sends multiple messages efficiently, potentially using specialized OS syscalls (like `sendmmsg`).

## Error Sets

**ReceiveError**
Errors that can occur during `receive`. Includes `AccessDenied`, `AddressFamilyNotSupported`, `SystemResources`, etc.

**ReceiveTimeoutError**
Superset of `ReceiveError` that includes `Timeout`.

**SendError**
Errors that can occur during `send`. Includes `AccessDenied`, `AddressFamilyNotSupported`, `MessageTooBig`, `NetworkUnreachable`, etc.

## See Also

*   [std.Io.net.Stream](std.Io.net.Stream.md) - For TCP/connection-oriented sockets.
*   [std.Io.net.IpAddress](std.Io.net.IpAddress.md) - For creating/binding sockets.

