# std.Io.net.OutgoingMessage

📚 **[See Comprehensive Examples & Tests](../../Examples/test_outgoing_message_comprehensive.zig)** - Complete runnable code demonstrating OutgoingMessage features

## Quick Start

### Most Common Patterns

**Send UDP Datagram**
```zig
const target_addr = try std.Io.net.IpAddress.parse("127.0.0.1", 8080);
const data = "Hello UDP";
var message = std.Io.net.OutgoingMessage{
    .address = &target_addr,
    .data_ptr = data.ptr,
    .data_len = data.len,
};

// Send single message (wrapped in slice)
_ = try socket.sendMany(io, (&message)[0..1], .{});
```

**Send Multiple Messages (Batch)**
```zig
var batch = [_]std.Io.net.OutgoingMessage{
    .{ .address = &addr1, .data_ptr = data1.ptr, .data_len = data1.len },
    .{ .address = &addr2, .data_ptr = data2.ptr, .data_len = data2.len },
};
const sent = try socket.sendMany(io, &batch, .{});
```

**Send with Ancillary Data**
```zig
const message = std.Io.net.OutgoingMessage{
    .address = &target_addr,
    .data_ptr = data.ptr,
    .data_len = data.len,
    .control = &control_buffer, // Ancillary data
};
```

### Key Fields
- `.address` - Pointer to the destination `IpAddress`
- `.data_ptr` - Pointer to the start of the data to send
- `.data_len` - Number of bytes to send (updated on success)
- `.control` - Ancillary/control data buffer

### ⚠️ Critical: Lifetime Management
```zig
var message = std.Io.net.OutgoingMessage{
    .address = &target_addr, // Must remain valid until send completes!
    .data_ptr = data.ptr,    // Must remain valid until send completes!
    .data_len = data.len,
};
```

---

## Overview

`std.Io.net.OutgoingMessage` represents a message or datagram to be sent over a network socket. It is the output counterpart to `IncomingMessage` and is primarily used with `socket.sendMany()`.

**Key Characteristics:**
- **Zero-copy design**: Uses pointers to existing data rather than owned buffers.
- **Batch-optimized**: Designed to be used in arrays for efficient multiple-message sends.
- **Protocol flexible**: Used for UDP, Unix datagrams, and other message-oriented protocols.
- **Self-updating**: The `data_len` field is updated by the kernel/runtime to reflect the number of bytes actually sent upon success.

**When to use OutgoingMessage:**
- Sending UDP datagrams to specific destinations.
- Using `sendMany()` for high-performance batch sending.
- When you need to provide ancillary (control) data with a message.
- Responding to an `IncomingMessage` (reusing its `from` address).

## Fields

`address: *const IpAddress`

Pointer to the destination address. For datagram sockets, this specifies where the message will be sent.

- **Must be valid** during the entire `sendMany` operation.
- Use with `&` operator on a local or heap-allocated `IpAddress`.

------

`data_ptr: [*]const u8`

Pointer to the byte array containing the data to be sent.

- This is a "many-pointer" (`[*]`), usually obtained from a slice's `.ptr` field.
- The data is not copied into the message structure; the kernel reads directly from your buffer.

------

`data_len: usize`

Initially set to the number of bytes you wish to send.

- **Success Behavior**: After a successful `sendMany` call, this field is overwritten with the number of bytes actually accepted for transmission.
- This allows you to detect partial sends (though rare for datagrams).

------

`control: []const u8 = &.{}`

Buffer for ancillary/control data (out-of-band data).

- Used for advanced socket features like IP options, credentials passing, or timestamps.
- Defaults to an empty slice.

## Usage Patterns

### Pattern 1: Basic UDP Client

```zig
const std = @import("std");

pub fn sendHello(io: std.Io, socket: std.Io.net.Socket) !void {
    const target = try std.Io.net.Ip4Address.parse("127.0.0.1", 9000);
    const addr = std.Io.net.IpAddress{ .ip4 = target };
    
    const payload = "Message body";
    var msg = std.Io.net.OutgoingMessage{
        .address = &addr,
        .data_ptr = payload.ptr,
        .data_len = payload.len,
    };

    const sent = try socket.sendMany(io, (&msg)[0..1], .{});
    if (sent == 1) {
        std.debug.print("Sent {d} bytes successfully\n", .{msg.data_len});
    }
}
```

### Pattern 2: Efficient Batch Sending

```zig
pub fn broadcastToPeers(io: std.Io, socket: std.Io.net.Socket, peers: []const std.Io.net.IpAddress, data: []const u8) !void {
    // Allocate space for message headers on stack
    var messages: [32]std.Io.net.OutgoingMessage = undefined;
    
    var i: usize = 0;
    while (i < peers.len) {
        const batch_size = @min(32, peers.len - i);
        const current_batch = messages[0..batch_size];
        
        for (current_batch, 0..) |*msg, j| {
            msg.* = .{ 
                .address = &peers[i + j],
                .data_ptr = data.ptr,
                .data_len = data.len,
            };
        }
        
        _ = try socket.sendMany(io, current_batch, .{});
        i += batch_size;
    }
}
```

### Pattern 3: Echo Server (Reuse Address)

```zig
// Inside a receive loop
const msg = try socket.receive(io, &buffer);

// message.from is an IpAddress
// message.data is a []u8

var response = std.Io.net.OutgoingMessage{
    .address = &msg.from,
    .data_ptr = msg.data.ptr,
    .data_len = msg.data.len,
};

_ = try socket.sendMany(io, (&response)[0..1], .{});
```

## Debug Checklist

1. ✅ **Address Lifetime**: Is the `IpAddress` pointed to by `.address` still in scope?
   ```zig
   // ❌ BAD: addr goes out of scope before sendMany finishes
   var msg: std.Io.net.OutgoingMessage = undefined;
   {
       var addr = try IpAddress.parse(...);
       msg = .{ .address = &addr, ... };
   }
   _ = try socket.sendMany(io, (&msg)[0..1], .{}); // addr is invalid!
   ```

2. ✅ **Data Lifetime**: Is the buffer pointed to by `.data_ptr` still valid?
   ```zig
   // ❌ BAD: Payload buffer is reused or freed too early
   _ = try socket.sendMany(io, (&msg)[0..1], .{});
   // If the send is asynchronous or queued, payload must remain valid
   ```

3. ✅ **Pointer vs Slice**: Remember `data_ptr` is `[*]const u8`, not `[]const u8`.
   ```zig
   // ✅ DO:
   .data_ptr = my_slice.ptr,
   .data_len = my_slice.len,
   ```

4. ✅ **Check return value**: `sendMany` returns the number of *messages* sent, not bytes.
   ```zig
   const count = try socket.sendMany(io, messages, .{});
   if (count < messages.len) {
       // Only partial batch was sent
   }
   ```

## Performance Tips

1. **Batching**: Always prefer `sendMany()` with multiple messages over multiple calls to `send()` or `sendMany()` with single messages. It reduces the number of syscalls.
2. **Stack Allocation**: For small batches, allocate your `OutgoingMessage` array on the stack.
3. **Zero-Copy**: Since `OutgoingMessage` doesn't own the data, you can point multiple messages to the same data buffer (useful for broadcasts).

## See Also

- [std.Io.net.IncomingMessage](std.Io.net.IncomingMessage.md) - For receiving datagrams
- [std.Io.net.Socket](std.Io.net.Socket.md) - Contains the `sendMany` method
- [std.Io.net.IpAddress](std.Io.net.IpAddress.md) - Destination address types