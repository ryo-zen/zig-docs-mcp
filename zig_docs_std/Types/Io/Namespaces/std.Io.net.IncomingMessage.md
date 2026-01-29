# std.Io.net.IncomingMessage

📚 **[See Comprehensive Examples & Tests](../../Examples/test_incoming_message_comprehensive.zig)** - Complete runnable code demonstrating IncomingMessage features

## Quick Start

### Most Common Patterns

**Receive UDP Datagram**
```zig
var buffer: [2048]u8 = undefined;
const message = try socket.receive(io, &buffer);
std.debug.print("From: {}, Data: {s}\n", .{ message.from, message.data });
```

**Receive with Timeout**
```zig
var buffer: [2048]u8 = undefined;
const timeout = std.Io.Timeout{ .duration = .{
    .raw = std.Io.Duration.fromSeconds(5),
    .clock = .awake,
} };
const message = try socket.receiveTimeout(io, &buffer, timeout);
```

**Receive Multiple Messages**
```zig
var messages: [10]std.Io.net.IncomingMessage = undefined;
for (&messages) |*msg| {
    msg.* = std.Io.net.IncomingMessage.init;
}
const count = try socket.receiveManyTimeout(io, &messages, buffers, .{}, timeout);
```

**Check for Truncated Data**
```zig
const message = try socket.receive(io, &buffer);
if (message.flags.trunc) {
    std.debug.print("Warning: Message was truncated!\n", .{});
}
```

### Key Operations
- `IncomingMessage.init` - Default initializer
- `.from` - Source address of received message
- `.data` - Received data (points into your buffer)
- `.flags` - Message status flags (truncation, OOB, etc.)
- `.control` - Ancillary/control data

### ⚠️ Critical: Buffer Lifetime
```zig
var buffer: [2048]u8 = undefined;
const message = try socket.receive(io, &buffer);
// message.data points INTO buffer - don't let buffer go out of scope!
```

---

## Overview

`std.Io.net.IncomingMessage` represents a received datagram or message from a network socket. It's primarily used with UDP sockets and other datagram-oriented protocols, where each receive operation gets a complete message along with its source address and metadata.

**Key Characteristics:**
- **Zero-copy**: Data field points into caller-supplied buffer (no allocation)
- **Address tracking**: Automatically captures source address
- **Metadata rich**: Includes flags for truncation, out-of-band data, etc.
- **Control data support**: Can receive ancillary data (timestamps, credentials, etc.)
- **Batch receive**: Support for receiving multiple messages at once

**When to use IncomingMessage:**
- Receiving UDP datagrams
- Non-streaming socket communication
- When you need to know the source address of each message
- Datagram-oriented protocols (DNS, DHCP, game networking, etc.)

## Fields

`from: IpAddress`

The source address of the received message. This field is populated by receive functions and indicates where the datagram originated from.

- Contains either IPv4 or IPv6 address with port
- Useful for responding to the sender
- **Note:** Populated by `receive()` functions, undefined before receiving

------

`data: []u8`

Slice pointing to the received data within the caller-supplied buffer. This is a zero-copy reference - the data is not copied into a separate allocation.

- Points into the buffer passed to `receive()`
- Length indicates how many bytes were actually received
- **Lifetime**: Valid only while the buffer remains in scope
- **Note:** Populated by `receive()` functions, undefined before receiving

------

`control: []u8`

Buffer for receiving ancillary/control data (also called out-of-band data). This can include timestamps, credentials, routing information, etc.

- Must be allocated and provided by caller before calling `receive()`
- Mutated by receive functions
- Can be empty (`&.{}`) if not needed
- Platform-specific content (see `cmsg` structures)

------

`flags: Flags`

Status flags providing metadata about the received message. Indicates conditions like truncation, end-of-record, out-of-band data, etc.

- **Note:** Populated by `receive()` functions, undefined before receiving

## Constants

`init: IncomingMessage`

Default initializer for `IncomingMessage`. Useful when preparing message structures before calling `receiveManyTimeout()`.

**Example:**
```zig
var messages: [10]std.Io.net.IncomingMessage = undefined;
for (&messages) |*msg| {
    msg.* = std.Io.net.IncomingMessage.init;
}
```

## Types

### Flags

Packed struct (1 byte) containing status flags for the received message.

**Fields:**
- `eor: bool` - End-of-record marker (used with `SOCK_SEQPACKET`)
- `trunc: bool` - Data was truncated (datagram larger than buffer)
- `ctrunc: bool` - Control data was truncated (control buffer too small)
- `oob: bool` - Out-of-band/expedited data received
- `errqueue: bool` - Error from socket error queue (no normal data)

**Example:**
```zig
const message = try socket.receive(io, &buffer);

if (message.flags.trunc) {
    // Buffer was too small - message was truncated
    std.debug.print("Warning: Received partial message\n", .{});
}

if (message.flags.oob) {
    // Urgent/out-of-band data
    std.debug.print("Urgent data received\n", .{});
}
```

## Usage Patterns

### Pattern 1: Simple UDP Server

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Bind UDP socket
    const ip4_addr = try std.Io.net.Ip4Address.parse("0.0.0.0", 8080);
    const addr = std.Io.net.IpAddress{ .ip4 = ip4_addr };
    const socket = try std.Io.net.IpAddress.bind(&addr, io, .{ .mode = .dgram });
    defer socket.close(io);

    std.debug.print("UDP server listening on port 8080\n", .{});

    // Receive loop
    var buffer: [2048]u8 = undefined;
    while (true) {
        const message = try socket.receive(io, &buffer);
        std.debug.print("From {}: {s}\n", .{ message.from, message.data });

        // Echo back to sender
        var response = std.Io.net.OutgoingMessage{
            .address = &message.from,
            .data_ptr = message.data.ptr,
            .data_len = message.data.len,
        };
        try socket.sendMany(io, (&response)[0..1], .{});
    }
}
```

### Pattern 2: Receive with Timeout

```zig
const std = @import("std");

pub fn receiveWithRetry(socket: std.Io.net.Socket, io: std.Io, buffer: []u8) !std.Io.net.IncomingMessage {
    const timeout = std.Io.Timeout{ .duration = .{
        .raw = std.Io.Duration.fromSeconds(5),
        .clock = .awake,
    } };

    var retries: u32 = 0;
    while (retries < 3) : (retries += 1) {
        const result = socket.receiveTimeout(io, buffer, timeout);
        if (result) |message| {
            return message;
        } else |err| {
            if (err == error.Timeout) {
                std.debug.print("Timeout, retrying... ({}/3)\n", .{retries + 1});
                continue;
            }
            return err;
        }
    }
    return error.MaxRetriesExceeded;
}
```

### Pattern 3: Batch Receive (High Performance)

```zig
const std = @import("std");

pub fn receiveBatch(socket: std.Io.net.Socket, io: std.Io) !void {
    // Prepare message structures
    const batch_size = 32;
    var messages: [batch_size]std.Io.net.IncomingMessage = undefined;
    for (&messages) |*msg| {
        msg.* = std.Io.net.IncomingMessage.init;
    }

    // Prepare receive buffers
    var buffers: [batch_size][2048]u8 = undefined;

    const timeout = std.Io.Timeout{ .duration = .{
        .raw = std.Io.Duration.fromMilliseconds(100),
        .clock = .awake,
    } };

    // Receive multiple messages at once
    const count = try socket.receiveManyTimeout(
        io,
        &messages,
        &buffers,
        .{},
        timeout,
    );

    std.debug.print("Received {d} messages in batch\n", .{count});

    for (messages[0..count]) |message| {
        std.debug.print("From {}: {} bytes\n", .{ message.from, message.data.len });
    }
}
```

### Pattern 4: Control Data (Ancillary Data)

```zig
const std = @import("std");

pub fn receiveWithControlData(socket: std.Io.net.Socket, io: std.Io) !void {
    var buffer: [2048]u8 = undefined;
    var control_buffer: [256]u8 = undefined;

    var message = std.Io.net.IncomingMessage.init;
    message.control = &control_buffer;

    // Receive implementation would populate control data
    // const received = try socket.receiveWithControl(io, &buffer, &message);

    // Control data would contain ancillary information like:
    // - SO_TIMESTAMP: Packet receive timestamp
    // - IP_PKTINFO: Packet routing information
    // - SCM_CREDENTIALS: Sender credentials
    std.debug.print("Control data size: {} bytes\n", .{message.control.len});
}
```

### Pattern 5: Handling Truncation

```zig
const std = @import("std");

pub fn receiveComplete(socket: std.Io.net.Socket, io: std.Io, allocator: std.mem.Allocator) ![]u8 {
    var buffer: [2048]u8 = undefined;
    const message = try socket.receive(io, &buffer);

    if (message.flags.trunc) {
        // Message was truncated - need larger buffer
        std.debug.print("Message truncated! Consider larger buffer\n", .{});

        // For protocols where you can retry with larger buffer:
        // 1. Allocate larger buffer
        // 2. Request retransmission
        // 3. Or handle partial message

        return error.MessageTruncated;
    }

    // Copy data to owned slice
    return try allocator.dupe(u8, message.data);
}
```

## Related Socket Functions

### `Socket.receive(io: Io, buffer: []u8) !IncomingMessage`

Receives a single message from the socket. Blocks until a message arrives.

------

### `Socket.receiveTimeout(io: Io, buffer: []u8, timeout: Timeout) !IncomingMessage`

Receives a single message with a timeout. Returns `error.Timeout` if no message arrives within the timeout period.

------

### `Socket.receiveManyTimeout(io: Io, messages: []IncomingMessage, ...) !usize`

Receives multiple messages in a single system call (batch receive). More efficient for high-throughput scenarios. Returns the number of messages received.

## Debug Checklist

If your message receiving isn't working correctly, check:

1. ✅ Is your buffer large enough?
   ```zig
   // ❌ DON'T: Too small for typical UDP packets
   var buffer: [64]u8 = undefined;

   // ✅ DO: Size for your use case (2KB is common)
   var buffer: [2048]u8 = undefined;
   ```

2. ✅ Are you checking the truncation flag?
   ```zig
   const message = try socket.receive(io, &buffer);
   if (message.flags.trunc) {
       // Data was larger than buffer - increase buffer size!
       std.debug.print("Warning: Message truncated\n", .{});
   }
   ```

3. ✅ Is the message.data slice valid?
   ```zig
   // ✅ DO: Use data immediately or copy it
   var buffer: [2048]u8 = undefined;
   const message = try socket.receive(io, &buffer);
   const data_copy = try allocator.dupe(u8, message.data);

   // ❌ DON'T: Let buffer go out of scope
   const message = blk: {
       var buffer: [2048]u8 = undefined;
       break :blk try socket.receive(io, &buffer);
   };
   // message.data now points to invalid memory!
   ```

4. ✅ Did you initialize messages for receiveManyTimeout?
   ```zig
   // ✅ DO: Initialize each message
   var messages: [10]std.Io.net.IncomingMessage = undefined;
   for (&messages) |*msg| {
       msg.* = std.Io.net.IncomingMessage.init;
   }
   ```

5. ✅ Are you handling timeouts correctly?
   ```zig
   const result = socket.receiveTimeout(io, &buffer, timeout);
   if (result) |message| {
       // Got a message
   } else |err| {
       if (err == error.Timeout) {
           // Normal timeout - not necessarily an error
       } else {
           // Real error
           return err;
       }
   }
   ```

6. ✅ Is the socket actually bound/connected?
   ```zig
   // For receiving, socket must be bound to an address
   const socket = try std.Io.net.IpAddress.bind(&addr, io, .{ .mode = .dgram });
   // Now socket can receive messages
   ```

## Performance Tips

1. **Size buffers appropriately**
   ```zig
   // Common sizes:
   // DNS: 512 bytes (traditional), 4096 bytes (EDNS)
   // Games: 1024-1500 bytes (MTU-friendly)
   // Streaming: 2048-8192 bytes
   var buffer: [1500]u8 = undefined;  // MTU-sized
   ```

2. **Use batch receive for high throughput**
   ```zig
   // ✅ Efficient: Receive 32 messages per syscall
   var messages: [32]std.Io.net.IncomingMessage = undefined;
   const count = try socket.receiveManyTimeout(...);

   // ❌ Inefficient: 32 syscalls
   for (0..32) |_| {
       const message = try socket.receive(...);
   }
   ```

3. **Reuse buffers**
   ```zig
   // ✅ DO: Reuse buffer across receives
   var buffer: [2048]u8 = undefined;
   while (true) {
       const message = try socket.receive(io, &buffer);
       processMessage(message.data);
       // buffer can be reused on next iteration
   }
   ```

4. **Avoid control data unless needed**
   ```zig
   // Most applications don't need control data
   // Using IncomingMessage.init (control = &.{}) is fastest
   var message = std.Io.net.IncomingMessage.init;  // control.len == 0
   ```

## Protocol Notes

### UDP
- Each `receive()` gets one complete datagram
- Datagrams may arrive out of order
- No delivery guarantee - messages can be lost
- Check `.flags.trunc` for truncation

### SOCK_SEQPACKET (Unix sockets)
- Similar to UDP but with guaranteed delivery and ordering
- `.flags.eor` indicates end of record
- Maintains message boundaries

### SOCK_DGRAM
- Message-oriented, unreliable
- Each receive gets one complete message
- Source address in `.from` field

## See Also

- [std.Io.net.OutgoingMessage](std.Io.net.OutgoingMessage.md) - For sending datagrams
- [std.Io.net.Socket](std.Io.net.Socket.md) - Socket operations including receive()
- [std.Io.net.IpAddress](std.Io.net.IpAddress.md) - IP address types
- [std.Io.Timeout](std.Io.Timeout.md) - Timeout configuration
