# std.Io.net.UnixAddress

📚 **[See Comprehensive Examples & Tests](../../Examples/test_unix_address_comprehensive.zig)** - Complete runnable code demonstrating UnixAddress features

## Quick Start

### Most Common Patterns

**File-System Path Socket**
```zig
const addr = try std.Io.net.UnixAddress.init("/tmp/myapp.sock");
var server = try addr.listen(io, .{});
defer server.deinit(io);
```

**Connect to Unix Socket**
```zig
const addr = try std.Io.net.UnixAddress.init("/tmp/myapp.sock");
const client = try addr.connect(io);
defer client.close(io);
```

**Abstract Namespace Socket (Linux)**
```zig
// Abstract sockets start with null byte (Linux-specific)
const addr = try std.Io.net.UnixAddress.init("\x00myapp");
var server = try addr.listen(io, .{});
defer server.deinit(io);
```

**Custom Listen Backlog**
```zig
const addr = try std.Io.net.UnixAddress.init("/tmp/myapp.sock");
var server = try addr.listen(io, .{ .kernel_backlog = 256 });
defer server.deinit(io);
```

### Key Operations
- `init(path)` - Create UnixAddress from path
- `.listen(io, options)` - Create server socket
- `.connect(io)` - Connect to server socket
- `max_len` - Maximum path length (108 bytes)

### ⚠️ Critical: Path Length Limit
```zig
// Unix domain socket paths are limited to 108 bytes
const addr = try std.Io.net.UnixAddress.init(very_long_path);  // May error!
// Always check path length or handle error.NameTooLong
```

---

## Overview

`std.Io.net.UnixAddress` represents a Unix domain socket address (AF_UNIX/AF_LOCAL). Unix domain sockets provide fast, reliable IPC (Inter-Process Communication) between processes on the same machine, offering better performance than TCP loopback for local communication.

**Key Characteristics:**
- **Path-based addressing**: Identifies sockets by filesystem paths or abstract names
- **Fast IPC**: Lower overhead than TCP for local communication
- **File permissions**: Filesystem-based sockets respect standard file permissions
- **Abstract namespace**: Linux supports abstract sockets (path starts with `\x00`)
- **108-byte limit**: Path length limited to 108 bytes (UNIX_PATH_MAX)

**When to use UnixAddress:**
- Inter-process communication on the same machine
- Communication between system services (systemd, Docker, etc.)
- Fast local client-server architecture
- When you need file permission-based access control
- Replacing TCP localhost for better performance

## Fields

`path: []const u8`

The filesystem path or abstract namespace identifier for the Unix domain socket.

- **Filesystem paths**: Regular paths like `/tmp/app.sock` or `./local.sock`
- **Abstract namespace** (Linux): Paths starting with `\x00` (null byte) don't create filesystem entries
- **Maximum length**: 108 bytes (`max_len`)

## Constants

`max_len: comptime_int = 108`

The maximum length for Unix domain socket paths. This is a system limitation (UNIX_PATH_MAX) defined by the operating system.

**Note:** This includes the null terminator for C string compatibility, so practical usable length is 107 bytes for string paths.

## Types

### ListenOptions

Configuration options for creating a listening Unix domain socket.

**Fields:**
- `kernel_backlog: u31` - Number of connections the kernel will queue (default: 128)

When more connections arrive than the backlog allows, clients will receive "Connection refused" errors.

## Functions

### `pub fn init(p: []const u8) InitError!UnixAddress`

Creates a UnixAddress from the given path.

**Parameters:**
- `p` - The socket path (filesystem or abstract namespace)

**Returns:**
A `UnixAddress` instance with the given path.

**Errors:**
- `error.NameTooLong` - Path exceeds 108 bytes

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    // Filesystem socket
    const addr1 = try std.Io.net.UnixAddress.init("/tmp/myapp.sock");

    // Relative path
    const addr2 = try std.Io.net.UnixAddress.init("./local.sock");

    // Abstract namespace (Linux)
    const addr3 = try std.Io.net.UnixAddress.init("\x00myapp");

    std.debug.print("Created addresses\n", .{});
}
```

------

### `pub fn listen(ua: *const UnixAddress, io: Io, options: ListenOptions) ListenError!Server`

Creates a listening Unix domain socket server at the address.

**Parameters:**
- `ua` - Pointer to the UnixAddress
- `io` - The I/O interface
- `options` - Server configuration options

**Returns:**
A `Server` instance ready to accept connections.

**Behavior:**
- Creates a Unix domain socket
- Binds to the specified path
- Begins listening for connections
- For filesystem paths, creates a socket file (clean up with `deleteFile`)

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const socket_path = "/tmp/myserver.sock";

    // Clean up any existing socket file
    std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};

    const addr = try std.Io.net.UnixAddress.init(socket_path);
    var server = try addr.listen(io, .{ .kernel_backlog = 256 });
    defer {
  server.deinit(io);
  std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};
    }

    std.debug.print("Server listening on {s}\n", .{socket_path});

    // Accept connections...
    // const connection = try server.accept(io);
}
```

------

### `pub fn connect(ua: *const UnixAddress, io: Io) ConnectError!Stream`

Connects to a Unix domain socket server at the address.

**Parameters:**
- `ua` - Pointer to the UnixAddress
- `io` - The I/O interface

**Returns:**
A `Stream` representing the connected socket.

**Behavior:**
Creates a Unix domain socket and connects to the specified address.

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.UnixAddress.init("/tmp/myserver.sock");
    const stream = try addr.connect(io);
    defer stream.close(io);

    std.debug.print("Connected to server\n", .{});

    // Use stream for communication...
    var write_buffer: [1024]u8 = undefined;
    var writer = stream.writer(&write_buffer);
    try writer.interface.writeAll("Hello\n");
    try writer.interface.flush();
}
```

## Usage Patterns

### Pattern 1: Simple Echo Server

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const socket_path = "/tmp/echo.sock";

    // Clean up old socket
    std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};

    // Start server
    const addr = try std.Io.net.UnixAddress.init(socket_path);
    var server = try addr.listen(io, .{});
    defer {
  server.deinit(io);
  std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};
    }

    std.debug.print("Echo server listening on {s}\n", .{socket_path});

    // Accept one connection
    var connection = try server.accept(io);
    defer connection.stream.close(io);

    // Echo data back
    var read_buf: [1024]u8 = undefined;
    var write_buf: [1024]u8 = undefined;

    var reader = connection.stream.reader(&read_buf);
    var writer = connection.stream.writer(&write_buf);

    while (true) {
  const line = reader.interface.takeDelimiterInclusive('\n') catch |err| {
      if (err == error.EndOfStream) break;
      return err;
  };
  try writer.interface.writeAll(line);
  try writer.interface.flush();
    }
}
```

### Pattern 2: Abstract Namespace (Linux)

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Abstract socket - no filesystem entry
    // Automatically cleaned up when all references are closed
    const addr = try std.Io.net.UnixAddress.init("\x00myapp_abstract");
    var server = try addr.listen(io, .{});
    defer server.deinit(io);

    std.debug.print("Server on abstract socket (no filesystem cleanup needed)\n", .{});
}
```

### Pattern 3: Client-Server Communication

```zig
const std = @import("std");

pub fn runServer(io: std.Io) !void {
    const socket_path = "/tmp/app.sock";
    std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};

    const addr = try std.Io.net.UnixAddress.init(socket_path);
    var server = try addr.listen(io, .{});
    defer {
  server.deinit(io);
  std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};
    }

    // Accept and handle connections...
}

pub fn runClient(io: std.Io) !void {
    const addr = try std.Io.net.UnixAddress.init("/tmp/app.sock");
    const stream = try addr.connect(io);
    defer stream.close(io);

    // Communicate with server...
}
```

## Error Sets

### InitError

Errors that may occur when creating a UnixAddress.

**Errors:**
- `NameTooLong` - Path exceeds 108 bytes (`max_len`)

------

### ListenError

Errors that may occur when creating a listening socket.

**Errors:**
- `AddressFamilyUnsupported` - Unix domain sockets not supported on this system
- `AddressInUse` - Another socket is already bound to this path
- `NetworkDown` - Network subsystem failure
- `SystemResources` - Insufficient system resources
- `SymLinkLoop` - Too many symbolic links in path resolution
- `FileNotFound` - Directory in path doesn't exist
- `NotDir` - Path component is not a directory
- `ReadOnlyFileSystem` - Cannot create socket on read-only filesystem
- `ProcessFdQuotaExceeded` - Process file descriptor limit reached
- `SystemFdQuotaExceeded` - System file descriptor limit reached
- `AccessDenied` - Permission denied
- `PermissionDenied` - Insufficient permissions
- `AddressUnavailable` - Address cannot be assigned
- Plus: `Io.Cancelable` and `Io.UnexpectedError`

------

### ConnectError

Errors that may occur when connecting to a socket.

**Errors:**
- `SystemResources` - Insufficient system resources
- `ProcessFdQuotaExceeded` - Process file descriptor limit reached
- `SystemFdQuotaExceeded` - System file descriptor limit reached
- `AddressFamilyUnsupported` - Unix domain sockets not supported
- `ProtocolUnsupportedBySystem` - Protocol not supported
- `ProtocolUnsupportedByAddressFamily` - Protocol incompatible with address family
- `SocketModeUnsupported` - Socket type not supported
- `AccessDenied` - Permission denied
- `PermissionDenied` - Insufficient permissions
- `SymLinkLoop` - Too many symbolic links
- `FileNotFound` - Socket file doesn't exist
- `NotDir` - Path component is not a directory
- `ReadOnlyFileSystem` - Cannot access socket on read-only filesystem
- `WouldBlock` - Operation would block (non-blocking mode)
- `NetworkDown` - Network subsystem failure
- Plus: `Io.Cancelable` and `Io.UnexpectedError`

## Debug Checklist

If your Unix socket isn't working, check:

1. ✅ Is the path length under 108 bytes?
   ```zig
   // ❌ DON'T: Very long paths
   const addr = try std.Io.net.UnixAddress.init("/very/long/path/that/exceeds/the/maximum/allowed/length/for/unix/sockets/...");

   // ✅ DO: Keep paths short
   const addr = try std.Io.net.UnixAddress.init("/tmp/app.sock");
   ```

2. ✅ Did you clean up the old socket file?
   ```zig
   // ✅ Always clean up before listen()
   const socket_path = "/tmp/app.sock";
   std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};
   const addr = try std.Io.net.UnixAddress.init(socket_path);
   var server = try addr.listen(io, .{});
   ```

3. ✅ Do you have permissions for the socket directory?
   ```zig
   // ❌ DON'T: Use protected directories without permissions
   const addr = try std.Io.net.UnixAddress.init("/var/run/app.sock");

   // ✅ DO: Use directories you have access to
   const addr = try std.Io.net.UnixAddress.init("/tmp/app.sock");
   // or get proper permissions for /var/run
   ```

4. ✅ Did you clean up the socket file on server shutdown?
   ```zig
   var server = try addr.listen(io, .{});
   defer {
 server.deinit(io);
 std.Io.Dir.cwd().deleteFile(io, socket_path) catch {};  // Clean up!
   }
   ```

5. ✅ Are you using abstract namespace correctly (Linux)?
   ```zig
   // ✅ Abstract socket: starts with null byte
   const addr = try std.Io.net.UnixAddress.init("\x00myapp");
   // No filesystem cleanup needed!
   ```

6. ✅ Is the server actually listening before the client connects?
   ```zig
   // Ensure server is ready before client attempts connection
   // In production, use synchronization or wait for socket file to exist
   ```

## Performance Tips

1. **Use abstract namespace on Linux for ephemeral sockets**
   ```zig
   // ✅ Faster: No filesystem operations
   const addr = try std.Io.net.UnixAddress.init("\x00myapp");

   // ❌ Slower: Requires filesystem I/O
   const addr = try std.Io.net.UnixAddress.init("/tmp/myapp.sock");
   ```

2. **Increase kernel backlog for high-traffic servers**
   ```zig
   // Default: 128 connections
   var server = try addr.listen(io, .{});

   // High traffic: Increase backlog
   var server = try addr.listen(io, .{ .kernel_backlog = 512 });
   ```

3. **Place socket files on fast storage**
   ```zig
   // ✅ Fast: tmpfs/ramdisk
   const addr = try std.Io.net.UnixAddress.init("/dev/shm/app.sock");

   // ❌ Slower: Network-mounted filesystem
   const addr = try std.Io.net.UnixAddress.init("/nfs/mount/app.sock");
   ```

4. **Choose Unix sockets over TCP for local IPC**
   - Unix sockets are ~2x faster than TCP loopback for local communication
   - No TCP overhead (no 3-way handshake, no congestion control)
   - Better security (filesystem permissions)

## Platform Notes

### Linux
- Supports abstract namespace (path starts with `\x00`)
- Abstract sockets don't create filesystem entries
- Automatically cleaned up when all references close
- Use abstract namespace for temporary/ephemeral sockets

### macOS / BSD
- No abstract namespace support
- Must use filesystem paths
- Socket files must be manually cleaned up

### Windows
- Unix domain sockets supported on Windows 10 build 17063+ (Redstone 4)
- Check `std.Io.net.has_unix_sockets` at comptime
- Use TCP sockets as fallback for older Windows

## See Also

- [std.Io.net.Server](std.Io.net.Server.md) - Server socket returned by `listen()`
- [std.Io.net.Stream](std.Io.net.Stream.md) - Stream returned by `connect()`
- [std.Io.net.Socket](std.Io.net.Socket.md) - Lower-level socket operations
- [std.Io.net.Ip4Address](std.Io.net.Ip4Address.md) - IPv4 socket addresses
- [std.Io.net.Ip6Address](std.Io.net.Ip6Address.md) - IPv6 socket addresses
