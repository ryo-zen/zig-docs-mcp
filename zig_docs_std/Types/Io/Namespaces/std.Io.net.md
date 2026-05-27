# std.Io.net

## Overview

`std.Io.net` is Zig's comprehensive networking namespace, providing high-level abstractions for TCP, UDP, and Unix domain socket programming. Built on top of the `std.Io` asynchronous I/O framework, it offers ergonomic APIs for common networking patterns while maintaining zero-cost abstractions and cross-platform compatibility.

**Key Features:**
- **Address Handling**: IPv4, IPv6, and Unix domain socket addresses with parsing and formatting
- **Stream & Datagram**: High-level `Stream` for TCP and raw `Socket` for UDP/custom protocols
- **Server Abstractions**: `Server` type for accepting connections with backlog management
- **Message Types**: `IncomingMessage` and `OutgoingMessage` for datagram protocols
- **Cross-Platform**: Abstracts platform differences (Linux, macOS, BSD, Windows)

**Design Philosophy:**
- Zero allocation for common operations (caller provides buffers)
- Integration with `std.Io` for unified async I/O
- Type-safe address handling preventing IPv4/IPv6 mix-ups
- Explicit error handling (no hidden failures)

## Core Types

### Address Types

- **`HostName`** - Host name representation with length limits and parsing
- **`Ip4Address`** - IPv4 address and port (e.g., `192.168.1.1:8080`)
- **`Ip6Address`** - IPv6 address and port with scope support
- **`IpAddress`** - Tagged union of IPv4 and IPv6 addresses
- **`UnixAddress`** - Unix domain socket path (local IPC)

### Connection Types

- **`Stream`** - Bidirectional TCP connection with reader/writer interfaces
- **`Socket`** - Low-level socket handle for UDP, raw sockets, and custom protocols
- **`Server`** - TCP server for accepting incoming connections

### Message Types

- **`IncomingMessage`** - Received datagram with source address
- **`OutgoingMessage`** - Datagram to send with destination address

### Protocol Helpers

- **`Protocol`** - Enum for socket protocols (TCP, UDP, etc.)
- **`Interface`** - Network interface information (addresses, names, flags)

### Control Flags

- **`ReceiveFlags`** - Flags for `recv()` operations (peek, out-of-band, truncation)
- **`SendFlags`** - Flags for `send()` operations (fast open, don't route, end-of-record)
- **`ShutdownHow`** - Direction to shut down (recv, send, or both)

## Values

`default_kernel_backlog: u31`

The default listen backlog size used by the kernel when not explicitly specified. Platform-dependent, typically 128 or 256. This determines how many pending connections can queue before the kernel starts rejecting new SYN packets.

**Use case:** Reference value when choosing backlog size for `Server.listen()`.

------

`has_unix_sockets: bool`

Runtime-detectable boolean indicating whether the platform supports Unix domain sockets.

**Platform notes:**
- Linux, macOS, BSD: Always `true`
- Windows: `true` on Windows 10 build 17063+ (Redstone 4), `false` on older versions

**Use case:** Conditional compilation or runtime checks before using `UnixAddress`.

**Example:**
```zig
if (std.Io.net.has_unix_sockets) {
    // Use Unix sockets for IPC
    const addr = try std.Io.net.UnixAddress.init("/tmp/my.sock");
} else {
    // Fall back to TCP localhost
    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 9000);
}
```

## Error Sets

### `ShutdownError`

Errors that can occur during socket shutdown operations.

**Possible values:**
- `error.SocketNotConnected` - Attempted shutdown on unconnected socket
- `error.SystemResources` - Kernel resources exhausted
- Platform-specific errors from the underlying `shutdown()` syscall

**Use case:** Error handling for `Stream.shutdown()` and `Socket.shutdown()`.

## Quick Start Examples

### TCP Client

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Connect to a DNS host name
    const host = try std.Io.net.HostName.init("example.com");
    const stream = try host.connect(io, 80, .{});
    defer stream.close(io);

    // Write request
    var wbuf: [256]u8 = undefined;
    var writer = stream.writer(io, &wbuf);
    try writer.interface.writeAll("GET / HTTP/1.0\r\n\r\n");
    try writer.interface.flush();

    // Read response
    var rbuf: [4096]u8 = undefined;
    var reader = stream.reader(io, &rbuf);
    const response = reader.interface.readUntilEof() catch |err| {
  if (err == error.EndOfStream) &[_]u8{} else return err;
    };

    std.debug.print("{s}\n", .{response});
}
```

### TCP Server

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 8080);

    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.close(io);

    std.debug.print("Listening on {}\n", .{addr});

    while (true) {
  const client = try server.accept(io);
  defer client.stream.close(io);

  std.debug.print("Client connected from {}\n", .{client.address});

  // Handle client...
    }
}
```

### UDP Socket

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const socket = try std.Io.net.Socket.init(.ip4, .datagram, .udp);
    defer socket.close(io);

    const bind_addr = try std.Io.net.IpAddress.parse("0.0.0.0", 9000);
    try socket.bind(io, bind_addr);

    var buffer: [1024]u8 = undefined;
    const msg = try socket.recvFrom(io, &buffer, .{});

    std.debug.print("Received {} bytes from {}\n", .{msg.data.len, msg.address});
}
```

## See Also

- `std.Io` - Core asynchronous I/O framework
- `std.Io.Threaded` - Thread pool backend for I/O operations
- `std.Io.Evented` - Event loop backend for single-threaded async I/O
