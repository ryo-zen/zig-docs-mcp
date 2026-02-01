# std.Io.net.SendFlags

## Overview

`std.Io.net.SendFlags` is a packed struct of boolean flags controlling socket send operations. These flags modify the behavior of `send()` and related functions, offering control over routing, message boundaries, urgent data, and performance optimizations like TCP Fast Open.

**Key Characteristics:**
- **Bit-Packed**: Efficiently represents multiple boolean options
- **Platform Mapping**: Maps to OS-level `send()` flags (MSG_CONFIRM, MSG_DONTROUTE, MSG_EOR, MSG_OOB, MSG_FASTOPEN)
- **Zero Defaults**: All flags default to `false` for standard send behavior
- **Performance & Protocol Control**: Mix of performance hints and protocol-level features

**When to use:**
- Performance optimization (fastopen for connection initiation)
- Protocol-specific requirements (eor for message boundaries)
- Routing control (dont_route for local networks)
- Legacy urgent data handling (oob)

## Fields

`confirm: bool = false`

**Neighbor confirmation hint**: Tell the kernel not to probe the neighbor cache (Linux-specific, MSG_CONFIRM). Informs the kernel that forward progress is being made with the peer, preventing ARP/neighbor discovery overhead.

**Use case:** High-performance networking on Linux where you have application-level confirmation of peer reachability.

**Platform:** Linux-specific; ignored on other platforms.

------

`dont_route: bool = false`

**Direct routing**: Send directly without using routing tables (MSG_DONTROUTE). Data is only sent to hosts on directly connected networks.

**Use case:**
- Testing on local networks
- Diagnostic tools that shouldn't traverse routers
- Security-sensitive applications requiring direct connections

**Warning:** Will fail if the destination is not on a directly connected network.

------

`eor: bool = false`

**End-of-record marker**: Mark the end of a logical record (MSG_EOR). For protocols that support record boundaries (e.g., SCTP).

**Use case:** SCTP or other protocols that need explicit message/record boundaries beyond TCP's byte stream model.

**Platform:** Primarily meaningful for SCTP; may be ignored for TCP/UDP.

------

`oob: bool = false`

**Out-of-band data**: Send data as out-of-band/urgent (MSG_OOB). Historically used for TCP's urgent pointer mechanism.

**Use case:** Legacy protocols requiring urgent data (rare in modern applications). Most modern designs use separate channels instead of out-of-band data.

------

`fastopen: bool = false`

**TCP Fast Open**: Send data in the SYN packet during connection establishment (MSG_FASTOPEN). Reduces round trips for connection setup by including payload in the initial handshake.

**Use case:**
- Performance-critical client applications
- Reducing latency for short-lived connections (HTTP requests)
- Requires TCP Fast Open support on both client and server

**Platform:** Linux 3.7+, macOS 10.11+; requires kernel and server support.

------

`_: u3 = 0`

Reserved padding bits for future expansion and proper alignment.

## Usage Examples

### TCP Fast Open (Performance)

```zig
const std = @import("std");

pub fn fastOpenRequest(addr: std.Io.net.IpAddress, io: std.Io) !void {
    const socket = try std.Io.net.Socket.init(.ip4, .stream, .tcp);
    defer socket.close(io);

    var buffer: [256]u8 = undefined;
    const request = "GET / HTTP/1.0\r\n\r\n";

    // Send data during connection establishment
    const flags = std.Io.net.SendFlags{ .fastopen = true };
    _ = try socket.sendTo(io, request, addr, flags);

    // Connection is now established and data is sent
    // Continue with normal I/O...
}
```

### End-of-Record for Message Boundaries

```zig
const std = @import("std");

pub fn sendSctpRecord(stream: std.Io.net.Stream, io: std.Io, message: []const u8) !void {
    var buffer: [512]u8 = undefined;
    var writer = stream.writer(io, &buffer);

    try writer.interface.writeAll(message);

    // Mark end of record
    const flags = std.Io.net.SendFlags{ .eor = true };
    try writer.interface.flush();  // Assume internal use of flags
}
```

### Local Network Only (Don't Route)

```zig
const std = @import("std");

pub fn sendLocalOnly(socket: std.Io.net.Socket, io: std.Io, data: []const u8, addr: std.Io.net.IpAddress) !void {
    // Only send to directly connected networks
    const flags = std.Io.net.SendFlags{ .dont_route = true };
    _ = try socket.sendTo(io, data, addr, flags);
}
```

### Standard Send (All Flags False)

```zig
// Default behavior - all flags false
const flags = std.Io.net.SendFlags{};
_ = try stream.send(io, data, flags);
```

## Performance Notes

1. **TCP Fast Open**: Can reduce connection latency by ~1 RTT, significant for short connections
2. **Confirm Flag**: Reduces ARP overhead on high-throughput Linux servers
3. **Don't Route**: May improve performance for local communication by bypassing routing table lookups

## Platform Compatibility

| Flag | Linux | macOS/BSD | Windows | Notes |
|------|-------|-----------|---------|-------|
| `confirm` | ✓ | ✗ | ✗ | Linux-specific |
| `dont_route` | ✓ | ✓ | ✓ | Widely supported |
| `eor` | ✓ | ✓ | Partial | SCTP/protocol-specific |
| `oob` | ✓ | ✓ | ✓ | Widely supported, rarely used |
| `fastopen` | ✓ (3.7+) | ✓ (10.11+) | ✗ | Requires kernel/OS support |

## See Also

- `std.Io.net.ReceiveFlags` - Flags for receive operations
- `std.Io.net.Stream` - Provides `send()` method
- `std.Io.net.Socket` - Lower-level socket operations
