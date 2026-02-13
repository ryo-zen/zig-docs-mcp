# std.Io.net.ReceiveFlags

## Overview

`std.Io.net.ReceiveFlags` is a packed struct of boolean flags controlling socket receive operations. These flags modify the behavior of `recv()` and related functions, allowing applications to request out-of-band data, peek at incoming data without consuming it, or detect message truncation.

**Key Characteristics:**
- **Bit-Packed**: Efficiently represents multiple boolean options in a single byte
- **Platform Mapping**: Maps to OS-level `recv()` flags (MSG_OOB, MSG_PEEK, MSG_TRUNC)
- **Zero Defaults**: All flags default to `false` for standard receive behavior

**When to use:**
- Debugging protocols (peek at data without consuming)
- Handling urgent/out-of-band data in protocols that support it
- Detecting buffer truncation in datagram protocols (UDP)

## Fields

`oob: bool = false`

**Out-of-band data**: Request reception of out-of-band (urgent) data. Maps to `MSG_OOB` flag.

Out-of-band data is a separate channel for urgent information, used by protocols like TCP for urgent pointers. Most modern applications don't use this feature.

**Example use case:** Legacy protocols requiring urgent data handling (rare in modern code).

------

`peek: bool = false`

**Peek mode**: Read data from the socket without removing it from the receive queue. The same data will be available on the next receive call.

**Example use case:**
- Protocol sniffing/inspection
- Determining message type before full processing
- Checking if data is available without committing to read

------

`trunc: bool = false`

**Truncation notification**: For datagram sockets (UDP), return the real message length even if it was truncated to fit the buffer. Maps to `MSG_TRUNC` flag.

**Example use case:**
- Detecting when received datagram was larger than your buffer
- Determining correct buffer size for a protocol
- Error handling for undersized buffers

------

`_: u5 = 0`

Reserved padding bits for future expansion and proper alignment.

## Usage Examples

### Peek Without Consuming

```zig
const std = @import("std");

pub fn peekProtocolType(stream: std.Io.net.Stream, io: std.Io) !u8 {
    var buffer: [1]u8 = undefined;
    var reader = stream.reader(io, &buffer);

    // Peek at first byte to determine message type
    const flags = std.Io.net.ReceiveFlags{ .peek = true };
    const peeked = try stream.recv(io, &buffer, flags);

    if (peeked.len == 0) return error.ConnectionClosed;

    return buffer[0]; // Message type
    // Data is still in the socket buffer, next recv() will get it again
}
```

### Detecting Truncation (UDP)

```zig
const std = @import("std");

pub fn receiveUdpMessage(socket: std.Io.net.Socket, io: std.Io) ![]const u8 {
    var buffer: [512]u8 = undefined;

    const flags = std.Io.net.ReceiveFlags{ .trunc = true };
    const result = try socket.recv(io, &buffer, flags);

    if (result.truncated) {
  std.debug.print("Warning: Message truncated! Actual size: {}\n", .{result.real_length});
  return error.MessageTooLarge;
    }

    return result.data;
}
```

### Standard Receive (All Flags False)

```zig
// Default behavior - all flags false
const flags = std.Io.net.ReceiveFlags{};
const data = try stream.recv(io, &buffer, flags);
```

## Platform Notes

- **MSG_OOB**: Supported on most platforms but rarely used in modern protocols
- **MSG_PEEK**: Widely supported; useful for protocol inspection
- **MSG_TRUNC**: Primarily meaningful for datagram sockets (UDP); may be ignored for stream sockets (TCP)

## See Also

- `std.Io.net.SendFlags` - Flags for send operations
- `std.Io.net.Stream` - Provides `recv()` method
- `std.Io.net.Socket` - Lower-level socket operations
