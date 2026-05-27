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
    var server = try addr.listen(io, .{});
    defer server.deinit(io);

    while (true) {
  const conn = try server.accept(io);
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
    const conn = try addr.connect(io, .{});
    defer conn.close(io);

    var wbuf: [256]u8 = undefined;
    var writer = conn.writer(io, &wbuf);
    try writer.interface.writeAll("Hello");
    try writer.interface.flush();

    var buffer: [1024]u8 = undefined;
    var reader = conn.reader(io, &buffer);
    const bytes_read = try reader.interface.readSliceShort(&buffer);
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
    const socket = try addr.bind(io, .{ .mode = .dgram });
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

    var server = try addr.listen(io, .{});
    defer server.deinit(io);

    while (true) {
  const conn = try server.accept(io);
  defer conn.close(io);

  std.debug.print("Client connected\n", .{});

  var rbuf: [1024]u8 = undefined;
  var reader = conn.reader(io, &rbuf);
  const bytes_read = try reader.interface.readSliceShort(&rbuf);

  var wbuf: [1024]u8 = undefined;
  var writer = conn.writer(io, &wbuf);
  try writer.interface.writeAll(rbuf[0..bytes_read]);
  try writer.interface.flush();
    }
}
```

## Type/Method Changes Summary

| Before (0.13-0.14) | After (0.16) |
|-------------------|--------------|
| `std.net.Address` | `std.Io.net.IpAddress` |
| `Address.parseIp4()` | `IpAddress.parse()` |
| `Address.parseIp6()` | `IpAddress.parse()` |
| `addr.listen(opts)` | `addr.listen(io, opts)` |
| `tcpConnectToAddress(addr)` | `addr.connect(io, opts)` |
| `server.accept()` | `server.accept(io)` |
| `stream.close()` | `stream.close(io)` |
| `stream.read(buf)` | `stream.reader(io, buffer).interface.readSliceShort(buf)` |
| `stream.writeAll(data)` | `stream.writer(io, buffer).interface.writeAll(data)` |

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
const server = try addr.listen(.{});

// Fixed
var server = try addr.listen(io, .{});
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
    var server = try addr.listen(io, .{});
    defer server.deinit(io);

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
