# std.Io.net.ShutdownHow

## Overview

`std.Io.net.ShutdownHow` is an enum specifying which parts of a full-duplex connection to shut down. Used with socket shutdown operations to gracefully close one or both directions of data flow without fully closing the socket.

**Key Characteristics:**
- **Directional Control**: Choose to shut down receiving, sending, or both
- **Graceful Shutdown**: Allows coordinated connection teardown
- **Socket Lifecycle**: Part of the proper socket cleanup sequence

**When to use:**
- Implementing half-close patterns (close writing but keep reading)
- Graceful server shutdown sequences
- Protocols requiring ordered shutdown (e.g., HTTP connection close)

## Enum Values

`recv`

Shut down the receiving end of the connection. No more data will be received. The peer will see their send operations potentially fail or complete without the data being read.

**Use case:** Server has received all data it needs and wants to signal "no more input accepted" while still sending response data.

------

`send`

Shut down the sending end of the connection. No more data can be sent. The peer will receive EOF when reading from their end.

**Use case:** Client has sent full request and wants to signal "I'm done sending" while keeping the connection open to receive the response.

------

`both`

Shut down both receiving and sending. Equivalent to calling shutdown twice with `.recv` and `.send`. This is the most common shutdown mode before closing a socket.

**Use case:** Complete connection teardown when no more communication is needed in either direction.

## Usage Example

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1:8080", .{});

    // Connect to server
    const stream = try addr.connect(io, .{});
    defer stream.close(io);

    // Send request
    var buffer: [256]u8 = undefined;
    var writer = stream.writer(io, &buffer);
    try writer.interface.writeAll("GET / HTTP/1.0\r\n\r\n");
    try writer.interface.flush();

    // Signal we're done sending (half-close)
    try stream.shutdown(io, .send);

    // Can still read response
    var read_buf: [1024]u8 = undefined;
    var reader = stream.reader(io, &read_buf);
    const response = reader.interface.readUntilEof() catch |err| {
        if (err == error.EndOfStream) &[_]u8{}
        else return err;
    };

    std.debug.print("Received: {s}\n", .{response});

    // Full shutdown before close
    try stream.shutdown(io, .both);
}
```

## See Also

- `std.Io.net.Stream` - Provides the `shutdown()` method
- `std.Io.net.Socket` - Lower-level socket shutdown operations
