# Networking Migration Guide (0.16)

## Core Changes

1. **Location:** `std.net` → `std.Io.net`
2. **Io parameter:** All network operations require `io: Io`
3. **Type renames:** `Address` → `IpAddress`, method changes

## Import Changes

**Before:**
```zig
const net = @import("std").net;
```

**After:**
```zig
const net = @import("std").Io.net;
```

## Address Parsing

### IPv4 Addresses

**Before:**
```zig
const addr = try std.net.Address.parseIp4("127.0.0.1", 8080);
```

**After:**
```zig
const net = std.Io.net;
const addr = try net.IpAddress.parse("127.0.0.1", 8080);
```

**Changes:**
- `Address.parseIp4()` → `IpAddress.parse()` (auto-detects IPv4/IPv6)
- Type rename: `Address` → `IpAddress`
- `IpAddress.parse(text, port)` takes the address text and port separately; use `IpAddress.parseLiteral(text)` for strings like `"127.0.0.1:8080"` or `"[::1]:8080"`

### IPv6 Addresses

**Before:**
```zig
const addr = try std.net.Address.parseIp6("::1", 8080);
```

**After:**
```zig
const net = std.Io.net;
const addr = try net.IpAddress.parse("::1", 8080);
```

## TCP Server

**Before (0.13-0.14):**
```zig
const std = @import("std");

pub fn main() !void {
    const addr = try std.net.Address.parseIp4("127.0.0.1", 8080);
    const listener = try addr.listen(.{});
    defer listener.deinit();

    while (true) {
  const conn = try listener.accept();
  defer conn.stream.close();

  // Handle connection
    }
}
```

**After (0.16):**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const net = std.Io.net;
    const addr = try net.IpAddress.parse("127.0.0.1", 8080);
    const listener = try net.TcpListener.bind(io, addr);
    defer listener.close(io);

    while (true) {
  const conn = try listener.accept(io);
  defer conn.close(io);

  // Handle connection
    }
}
```

## TCP Client

**Before:**
```zig
const std = @import("std");

pub fn main() !void {
    const addr = try std.net.Address.parseIp4("127.0.0.1", 8080);
    const stream = try std.net.tcpConnectToAddress(addr);
    defer stream.close();

    try stream.writeAll("Hello");

    var buffer: [1024]u8 = undefined;
    const bytes_read = try stream.read(&buffer);
}
```

**After:**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const net = std.Io.net;
    const addr = try net.IpAddress.parse("127.0.0.1", 8080);
    const conn = try net.TcpStream.connect(io, addr);
    defer conn.close(io);

    try conn.writeAll(io, "Hello");

    var buffer: [1024]u8 = undefined;
    const bytes_read = try conn.read(io, &buffer);
}
```

## UDP Socket

**Before:**
```zig
const std = @import("std");

pub fn main() !void {
    const addr = try std.net.Address.parseIp4("0.0.0.0", 9000);
    const socket = try std.posix.socket(
  std.posix.AF.INET,
  std.posix.SOCK.DGRAM,
  0
    );
    defer std.posix.close(socket);

    try std.posix.bind(socket, &addr.any, addr.getOsSockLen());
}
```

**After:**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const net = std.Io.net;
    const addr = try net.IpAddress.parse("0.0.0.0", 9000);
    const socket = try net.UdpSocket.bind(io, addr);
    defer socket.close(io);
}
```

## Complete Server Example

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const net = std.Io.net;
    const addr = try net.IpAddress.parse("127.0.0.1", 8080);

    std.debug.print("Listening on {}\n", .{addr});

    const listener = try net.TcpListener.bind(io, addr);
    defer listener.close(io);

    while (true) {
  const conn = try listener.accept(io);
  defer conn.close(io);

  std.debug.print("Client connected\n", .{});

  var buffer: [1024]u8 = undefined;
  const bytes_read = try conn.read(io, &buffer);

  try conn.writeAll(io, buffer[0..bytes_read]);
    }
}
```

## Type/Method Changes Summary

| Before (0.13-0.14) | After (0.16) |
|-------------------|--------------|
| `std.net.Address` | `std.Io.net.IpAddress` |
| `Address.parseIp4()` | `IpAddress.parse()` |
| `Address.parseIp6()` | `IpAddress.parse()` |
| `addr.listen(opts)` | `TcpListener.bind(io, addr)` |
| `tcpConnectToAddress(addr)` | `TcpStream.connect(io, addr)` |
| `listener.accept()` | `listener.accept(io)` |
| `stream.close()` | `stream.close(io)` |
| `stream.read(buf)` | `stream.read(io, buf)` |
| `stream.writeAll(data)` | `stream.writeAll(io, data)` |

## Common Errors

### Error: "std.net not found"

```zig
// Wrong
const net = std.net;

// Fixed
const net = std.Io.net;
```

### Error: "no member 'Address' in net"

```zig
// Wrong
const addr = std.Io.net.Address.parseIp4(...);

// Fixed
const addr = std.Io.net.IpAddress.parse(...);
```

`IpAddress.parse` expects two arguments: address text and port. If the string
already includes the port, call `IpAddress.parseLiteral` instead.

### Error: "expected 2 arguments, found 1"

```zig
// Wrong
const listener = try net.TcpListener.bind(addr);

// Fixed
const listener = try net.TcpListener.bind(io, addr);
```

## Testing Pattern

```zig
test "networking migration" {
    const allocator = std.testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const net = std.Io.net;
    const addr = try net.IpAddress.parse("127.0.0.1", 0);

    // Bind to random port
    const listener = try net.TcpListener.bind(io, addr);
    defer listener.close(io);

    // Test passes if binding succeeds
}
```

## Migration Checklist

- [ ] Replace `std.net` → `std.Io.net`
- [ ] Add Io.Threaded setup
- [ ] Replace `Address` → `IpAddress`
- [ ] Replace `parseIp4/parseIp6` → `parse`
- [ ] Add `io` parameter to bind operations
- [ ] Add `io` parameter to connect operations
- [ ] Add `io` parameter to accept operations
- [ ] Add `io` parameter to read/write operations
- [ ] Add `io` parameter to close operations
- [ ] Update error handling
- [ ] Test all network operations
