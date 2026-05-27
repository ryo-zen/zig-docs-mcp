# std.Io.net.Server

📚 **[See Comprehensive Examples & Tests](../../../../Examples/test_server_comprehensive.zig)** - Complete runnable code demonstrating server patterns

## Quick Start

### Most Common Patterns

**Simple TCP Echo Server**
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
    defer server.deinit(io);

    std.debug.print("Listening on {}\n", .{addr});

    while (true) {
  var stream = try server.accept(io);
  defer stream.close(io);

  // Echo back whatever we receive
  var buf: [1024]u8 = undefined;
  var reader = stream.reader(io, &buf);
  const data = try reader.interface.takeDelimiterInclusive('\n');

  var wbuf: [1024]u8 = undefined;
  var writer = stream.writer(io, &wbuf);
  try writer.interface.writeAll(data);
  try writer.interface.flush();
    }
}
```

**Server with Ephemeral Port (Testing)**
```zig
// Let OS assign a free port (avoids conflicts)
const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
var server = try addr.listen(io, .{ .reuse_address = true });
defer server.deinit(io);

// Get the actual assigned port
const actual_addr = server.socket.address;
std.debug.print("Listening on {}\n", .{actual_addr});
```

**Multi-Threaded Server**
```zig
while (true) {
    var stream = try server.accept(io);

    // Spawn a thread to handle this connection
    const thread = try std.Thread.spawn(.{}, handleClient, .{ io, stream });
    thread.detach(); // Continue accepting while handler runs
}

fn handleClient(io: std.Io, stream: std.Io.net.Stream) void {
    defer stream.close(io);
    // Handle connection...
}
```

**Graceful Shutdown Pattern**
```zig
var shutdown = std.atomic.Value(bool).init(false);

// In signal handler or shutdown routine:
shutdown.store(true, .release);

// Main accept loop:
while (!shutdown.load(.acquire)) {
    const stream = server.accept(io) catch |err| {
  if (shutdown.load(.acquire)) break;
  std.debug.print("Accept error: {}\n", .{err});
  continue;
    };
    // Handle connection...
}
server.deinit(io);
```

### Key Operations
- `addr.listen(io, options)` - Create server socket and start listening
- `server.accept(io)` - Wait for and accept incoming connection (blocking)
- `server.socket.address` - Get the actual bound address (useful for ephemeral ports)
- `server.deinit(io)` - Close the listening socket

### ⚠️ Critical: Resource Management
```zig
var server = try addr.listen(io, .{});
defer server.deinit(io);  // ALWAYS clean up the server

var stream = try server.accept(io);
defer stream.close(io);   // ALWAYS close accepted connections

// Without defer, connections leak on early returns!
```

---

## Overview

`std.Io.net.Server` represents a **passive TCP listening socket** that waits for incoming client connections. It is the entry point for building TCP servers in Zig 0.16's new I/O system.

**Key Characteristics:**
- **Passive socket**: Doesn't communicate directly; produces `Stream` objects via `accept()`
- **Blocking by default**: `accept()` blocks until a client connects (unless using async I/O)
- **OS-backed**: Wraps platform-specific listen sockets (BSD sockets, IOCP on Windows)
- **Zero allocation**: The Server struct itself doesn't allocate; only tracks the socket handle
- **Single-threaded accept**: One thread calls `accept()` at a time (spawn threads to handle connections)

**When to use Server:**
- Building TCP network services (HTTP servers, game servers, databases)
- Implementing client-server protocols
- Any scenario where you need to accept incoming network connections
- Testing client code (spin up a temporary test server)

**Server Lifecycle:**
1. **Bind**: `addr.listen(io, options)` - Creates socket, binds to address, starts listening
2. **Accept Loop**: `server.accept(io)` - Repeatedly accept incoming connections
3. **Handle Connections**: Process each `Stream` (often in separate threads/tasks)
4. **Shutdown**: `server.deinit(io)` - Closes the listening socket

## Critical Concept: Connection Backlog

⚠️ **IMPORTANT**: The `kernel_backlog` option controls how many pending connections the OS queues before `accept()` is called.

**How it works:**
- When a client calls `connect()`, the OS adds it to a pending connection queue
- If you're slow to call `accept()`, connections wait in this queue
- If the queue fills up, new connection attempts are **refused** by the kernel

```zig
const server = try addr.listen(io, .{
    .kernel_backlog = 128,  // Allow up to 128 pending connections
});
```

**Choosing backlog size:**
- **Low traffic** (1-10 clients): `kernel_backlog = 10` is fine
- **Medium traffic** (10-100 clients): `kernel_backlog = 128` (common default)
- **High traffic** (100+ clients): `kernel_backlog = 512` or higher
- **Burst handling**: Larger backlog smooths out temporary spikes

**What happens when backlog fills:**
- New clients receive `ECONNREFUSED` or timeout
- No error on the server side (it just doesn't see those connections)
- Solution: Call `accept()` faster or increase backlog

## Basic Usage Examples

### Example 1: Single-Connection Server

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Listen on port 9000
    const addr = try std.Io.net.IpAddress.parse("0.0.0.0", 9000);
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    std.debug.print("Waiting for connection on port 9000...\n", .{});

    // Accept exactly one connection
    var stream = try server.accept(io);
    defer stream.close(io);

    std.debug.print("Client connected!\n", .{});

    // Send welcome message
    var wbuf: [256]u8 = undefined;
    var writer = stream.writer(io, &wbuf);
    try writer.interface.writeAll("Hello from Zig server!\n");
    try writer.interface.flush();
}
```

### Example 2: Echo Server with Loop

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 8080);
    var server = try addr.listen(io, .{
  .reuse_address = true,
  .kernel_backlog = 64,
    });
    defer server.deinit(io);

    std.debug.print("Echo server listening on 127.0.0.1:8080\n", .{});

    while (true) {
  var stream = try server.accept(io);
  defer stream.close(io);

  // Read and echo back lines
  var buf: [1024]u8 = undefined;
  var reader = stream.reader(io, &buf);

  while (true) {
      const line = reader.interface.takeDelimiterInclusive('\n') catch |err| {
          if (err == error.EndOfStream) break;
          return err;
      };

      var wbuf: [1024]u8 = undefined;
      var writer = stream.writer(io, &wbuf);
      try writer.interface.writeAll("Echo: ");
      try writer.interface.writeAll(line);
      try writer.interface.flush();
  }

  std.debug.print("Client disconnected.\n", .{});
    }
}
```

### Example 3: Multi-Threaded Server

```zig
const std = @import("std");

fn handleConnection(io: std.Io, stream: std.Io.net.Stream) void {
    defer stream.close(io);

    var buf: [1024]u8 = undefined;
    var reader = stream.reader(io, &buf);

    while (true) {
  const data = reader.interface.takeDelimiterInclusive('\n') catch |err| {
      if (err == error.EndOfStream) break;
      std.debug.print("Read error: {}\n", .{err});
      return;
  };

  var wbuf: [1024]u8 = undefined;
  var writer = stream.writer(io, &wbuf);
  writer.interface.writeAll(data) catch return;
  writer.interface.flush() catch return;
    }
}

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const addr = try std.Io.net.IpAddress.parse("0.0.0.0", 8080);
    var server = try addr.listen(io, .{
  .reuse_address = true,
  .kernel_backlog = 128,
    });
    defer server.deinit(io);

    std.debug.print("Multi-threaded server on 0.0.0.0:8080\n", .{});

    while (true) {
  const stream = try server.accept(io);

  // Spawn a thread to handle this connection concurrently
  const thread = try std.Thread.spawn(.{}, handleConnection, .{ io, stream });
  thread.detach(); // Don't wait for thread to finish
    }
}
```

### Example 4: Test Server with Ephemeral Port

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Port 0 = let OS choose a free port
    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    // Retrieve the actual port assigned by the OS
    const actual_addr = server.socket.address;
    std.debug.print("Test server listening on {}\n", .{actual_addr});

    // Now you can connect clients to actual_addr.port
    var stream = try server.accept(io);
    defer stream.close(io);

    std.debug.print("Test client connected!\n", .{});
}
```

## Fields

`socket: Socket`

The underlying `std.Io.net.Socket` representing the listening socket. This field provides access to low-level socket operations if needed.

**Common uses:**
- `server.socket.address` - Get the actual bound address (useful for ephemeral ports)
- `server.socket.handle` - Get the OS file descriptor (for advanced use cases)

**Example:**
```zig
var server = try addr.listen(io, .{});
const bound_addr = server.socket.address;
std.debug.print("Listening on {}\n", .{bound_addr});
```

------

## Types

### ListenOptions

Configuration options for creating a listening server socket.

```zig
pub const ListenOptions = struct {
    reuse_address: bool = false,
    kernel_backlog: u31 = 128,
};
```

**Fields:**

`reuse_address: bool`
- If `true`, enables `SO_REUSEADDR` socket option
- Allows binding to a port in `TIME_WAIT` state (recently closed)
- **Use case**: Development servers that restart frequently
- **Production**: Also useful to avoid "address already in use" errors on restart
- **Default**: `false`

`kernel_backlog: u31`
- Maximum number of pending connections queued by the kernel
- Clients waiting in this queue will complete their `connect()` call
- If queue is full, new connections are refused
- **Default**: `128` (reasonable for most applications)
- **Low traffic**: `10-32`
- **High traffic**: `512-1024`

**Example:**
```zig
const server = try addr.listen(io, .{
    .reuse_address = true,      // Allow binding to recently-used port
    .kernel_backlog = 256,      // Queue up to 256 pending connections
});
```

------

## Core Functions

### `pub fn accept(s: *Server, io: Io) AcceptError!Stream`

Waits for and accepts the next incoming TCP connection from the pending queue.

**Behavior:**
- **Blocks** until a client connects (or a pending connection is available in the backlog)
- Dequeues one connection from the kernel's backlog queue
- Returns a `Stream` representing the established connection
- The returned `Stream` must be closed with `stream.close(io)` to avoid resource leaks

**Returns:** `Stream` - An active bidirectional TCP connection

**Errors:**
- `SystemResources` - Kernel out of memory or file descriptors
- `ProcessFdQuotaExceeded` - Process hit max file descriptor limit
- `SystemFdQuotaExceeded` - System-wide file descriptor limit reached
- `ProtocolFailure` - Network protocol error
- `BlockedByFirewall` - Firewall rejected the connection
- `ConnectionAborted` - Client aborted before `accept()` completed
- `SocketNotListening` - Socket is not in listening state
- `OperationAborted` - Accept was canceled (e.g., server shutdown)

**Example:**
```zig
var stream = try server.accept(io);
defer stream.close(io);

std.debug.print("Accepted connection from client\n", .{});

// Use stream for reading/writing...
```

**Common Pattern (Accept Loop):**
```zig
while (true) {
    const stream = server.accept(io) catch |err| {
  std.debug.print("Accept failed: {}\n", .{err});
  continue; // Keep accepting other connections
    };

    // Handle connection (often spawn a thread here)
    handleClient(io, stream);
}
```

------

### `pub fn deinit(s: *Server, io: Io) void`

Closes the listening socket and releases OS resources. After calling `deinit`, the server cannot accept new connections.

**Behavior:**
- Closes the underlying socket file descriptor
- Any future calls to `accept()` will fail
- Does **not** close existing accepted connections (they have their own `Stream` handles)
- Safe to call multiple times (idempotent)

**Best Practice:**
Always pair `listen()` with `defer deinit()` to ensure cleanup:
```zig
var server = try addr.listen(io, .{});
defer server.deinit(io);
```

**Graceful Shutdown:**
```zig
// 1. Stop accepting new connections
server.deinit(io);

// 2. Wait for existing handlers to finish
// (implementation depends on your concurrency model)

// 3. Clean up other resources
```

------

## Usage Patterns

### Pattern 1: Sequential Server (Simplest)

Handle one connection at a time. Good for low-traffic scenarios or testing.

```zig
while (true) {
    var stream = try server.accept(io);
    defer stream.close(io);

    // Process this connection completely before accepting the next
    handleConnection(io, stream) catch |err| {
  std.debug.print("Handler error: {}\n", .{err});
    };
}
```

**Pros:** Simple, no concurrency overhead
**Cons:** Slow for multiple clients (each waits for the previous to finish)

------

### Pattern 2: Multi-Threaded Server (Common)

Spawn a thread for each connection. Good for medium-traffic servers.

```zig
fn handleConnection(io: std.Io, stream: std.Io.net.Stream) void {
    defer stream.close(io);
    // Handle connection...
}

// Main accept loop
while (true) {
    const stream = try server.accept(io);
    const thread = try std.Thread.spawn(.{}, handleConnection, .{ io, stream });
    thread.detach(); // Continue accepting while handler runs
}
```

**Pros:** Concurrent, handles multiple clients
**Cons:** Thread overhead, unbounded thread creation under load

------

### Pattern 3: Thread Pool Server (Production)

Use a fixed pool of worker threads. Prevents thread exhaustion under high load.

```zig
const WorkQueue = std.atomic.Queue(std.Io.net.Stream);

fn worker(io: std.Io, queue: *WorkQueue) void {
    while (true) {
  const node = queue.get() orelse continue;
  const stream = node.data;
  defer stream.close(io);
  defer queue.allocator.destroy(node);

  handleConnection(io, stream) catch {};
    }
}

pub fn main() !void {
    // ... setup ...

    var queue = WorkQueue.init();

    // Spawn worker threads
    var workers: [8]std.Thread = undefined;
    for (&workers) |*w| {
  w.* = try std.Thread.spawn(.{}, worker, .{ io, &queue });
    }

    // Accept and enqueue
    while (true) {
  const stream = try server.accept(io);
  const node = try da.allocator().create(WorkQueue.Node);
  node.* = .{ .data = stream };
  queue.put(node);
    }
}
```

**Pros:** Bounded resource usage, handles high load
**Cons:** More complex implementation

------

### Pattern 4: Async/IO_URING Server (Advanced)

Use async I/O for maximum concurrency without thread overhead (Linux 5.1+).

```zig
// Using std.Io.async() to handle connections concurrently
while (true) {
    const stream = try server.accept(io);

    // Launch async task to handle this connection
    _ = io.async(handleConnection, .{ io, stream });
}
```

**Pros:** Extremely scalable, low overhead
**Cons:** Requires async-compatible I/O backend (Evented, IoUring)

------

### Pattern 5: Graceful Shutdown

Cleanly stop the server and finish processing existing connections.

```zig
const std = @import("std");

var shutdown_flag = std.atomic.Value(bool).init(false);
var active_connections = std.atomic.Value(usize).init(0);

fn handleConnection(io: std.Io, stream: std.Io.net.Stream) void {
    _ = active_connections.fetchAdd(1, .acquire);
    defer {
  stream.close(io);
  _ = active_connections.fetchSub(1, .release);
    }

    // Handle connection...
}

pub fn main() !void {
    // ... setup server ...

    // Accept loop with shutdown check
    while (!shutdown_flag.load(.acquire)) {
  const stream = server.accept(io) catch |err| {
      if (shutdown_flag.load(.acquire)) break;
      std.debug.print("Accept error: {}\n", .{err});
      continue;
  };

  const thread = try std.Thread.spawn(.{}, handleConnection, .{ io, stream });
  thread.detach();
    }

    // Shutdown sequence
    server.deinit(io); // Stop accepting new connections

    // Wait for existing connections to finish
    while (active_connections.load(.acquire) > 0) {
  try io.sleep(.fromMilliseconds(100), .awake);
    }

    std.debug.print("Server shutdown complete.\n", .{});
}
```

------

### Pattern 6: Health Check Endpoint

Respond to simple health check requests (useful for load balancers).

```zig
fn handleConnection(io: std.Io, stream: std.Io.net.Stream) void {
    defer stream.close(io);

    var buf: [256]u8 = undefined;
    var reader = stream.reader(io, &buf);

    // Read first line (HTTP request line)
    const line = reader.interface.takeDelimiterInclusive('\n') catch return;

    // Simple health check: respond to any GET request
    if (std.mem.startsWith(u8, line, "GET")) {
  var wbuf: [512]u8 = undefined;
  var writer = stream.writer(io, &wbuf);
  writer.interface.writeAll(
      \\HTTP/1.1 200 OK
      \\Content-Length: 3
      \\
      \\OK
      \\
  ) catch return;
  writer.interface.flush() catch return;
    }
}
```

------

### Pattern 7: Request/Response Protocol

Implement a simple protocol (e.g., line-based commands).

```zig
fn handleConnection(io: std.Io, stream: std.Io.net.Stream) !void {
    defer stream.close(io);

    var rbuf: [1024]u8 = undefined;
    var reader = stream.reader(io, &rbuf);

    while (true) {
  const command = reader.interface.takeDelimiterInclusive('\n') catch |err| {
      if (err == error.EndOfStream) break;
      return err;
  };

  // Parse command (strip newline)
  const cmd = command[0 .. command.len - 1];

  var wbuf: [1024]u8 = undefined;
  var writer = stream.writer(io, &wbuf);

  if (std.mem.eql(u8, cmd, "PING")) {
      try writer.interface.writeAll("PONG\n");
  } else if (std.mem.eql(u8, cmd, "QUIT")) {
      try writer.interface.writeAll("BYE\n");
      try writer.interface.flush();
      break;
  } else {
      try writer.interface.writeAll("ERROR: Unknown command\n");
  }

  try writer.interface.flush();
    }
}
```

------

## Error Sets

### AcceptError

Errors that can occur when calling `accept()`.

`SystemResources`
- Kernel ran out of memory or file descriptors
- **Recovery**: Wait and retry, or fail gracefully

`ProcessFdQuotaExceeded`
- This process hit its file descriptor limit (ulimit)
- **Recovery**: Close other files/sockets, or increase ulimit

`SystemFdQuotaExceeded`
- System-wide file descriptor limit reached
- **Recovery**: System-level issue, needs admin intervention

`ProtocolFailure`
- Network protocol error during accept
- **Recovery**: Log and continue accepting

`BlockedByFirewall`
- Connection blocked by firewall rules
- **Recovery**: Log and continue (client won't connect)

`ConnectionAborted`
- Client disconnected before `accept()` completed
- **Recovery**: Harmless, continue accepting

`SocketNotListening`
- Socket is not in listening state (programming error)
- **Recovery**: Bug - ensure `listen()` was called

`OperationAborted`
- Accept operation was canceled (e.g., server shutdown)
- **Recovery**: Clean shutdown, stop accepting

------

## Debug Checklist

Common mistakes and how to fix them:

1. ✅ **Port already in use**: Use `.reuse_address = true` when listening
   ```zig
   // Fix:
   const server = try addr.listen(io, .{ .reuse_address = true });
   ```

2. ✅ **Connection leaks**: Always close accepted streams
   ```zig
   // Bad:
   var stream = try server.accept(io);
   // ... forgot to close ...

   // Good:
   var stream = try server.accept(io);
   defer stream.close(io);
   ```

3. ✅ **Server doesn't clean up**: Always defer server.deinit()
   ```zig
   var server = try addr.listen(io, .{});
   defer server.deinit(io);  // Essential!
   ```

4. ✅ **Clients timing out**: Increase `kernel_backlog` for high traffic
   ```zig
   const server = try addr.listen(io, .{ .kernel_backlog = 512 });
   ```

5. ✅ **Can't find ephemeral port**: Use `server.socket.address` to get actual port
   ```zig
   var server = try addr.listen(io, .{});
   std.debug.print("Port: {}\n", .{server.socket.address.ip4.port});
   ```

6. ✅ **Accept blocks forever in tests**: Use non-zero timeout or spawn client thread before accept
   ```zig
   // Spawn client thread BEFORE calling accept
   const client_thread = try std.Thread.spawn(.{}, connectClient, .{});
   var stream = try server.accept(io);
   ```

7. ✅ **Thread explosion under load**: Use a thread pool instead of spawning unlimited threads
   - See Pattern 3: Thread Pool Server above

8. ✅ **Binding to wrong interface**: Use `0.0.0.0` to listen on all interfaces
   ```zig
   // Localhost only (loopback):
   const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 8080);

   // All interfaces (accessible from network):
   const addr = try std.Io.net.IpAddress.parse("0.0.0.0", 8080);
   ```

9. ✅ **Permission denied on ports < 1024**: Use ports >= 1024 for non-root servers
   ```zig
   // Port 80 requires root
   // Port 8080 works for any user
   ```

10. ✅ **Server hangs on shutdown**: Call `deinit()` to unblock `accept()`
    ```zig
    // In signal handler:
    server.deinit(io);  // Will cause accept() to return error
    ```

------

## Performance Tips

1. **Tune kernel backlog based on traffic patterns**
   - Measure connection arrival rate vs accept rate
   - Set backlog to handle ~2-3 seconds of bursts
   - Example: If you get 100 conn/sec and process 50/sec, use backlog of 150-200

2. **Use SO_REUSEADDR in production**
   - Avoids "address already in use" errors on restart
   - Allows faster server restarts
   ```zig
   .reuse_address = true
   ```

3. **Don't spawn unlimited threads**
   - Under heavy load, thread creation becomes a bottleneck
   - Use a fixed thread pool (Pattern 3) or async I/O (Pattern 4)

4. **Close connections promptly**
   - Each open connection consumes file descriptors
   - Use `defer stream.close(io)` immediately after accept
   - Monitor FD usage: `lsof -p <pid> | wc -l`

5. **Buffer sizes matter**
   - Larger reader/writer buffers reduce syscalls
   - For bulk data transfer: 8KB-64KB buffers
   - For interactive protocols: 1KB-4KB buffers

6. **Bind to specific interface for performance**
   - Binding to `127.0.0.1` (loopback) is faster than `0.0.0.0`
   - If server only handles local clients, use loopback

7. **Consider TCP_NODELAY for low-latency protocols**
   - Disables Nagle's algorithm (batches small writes)
   - Good for request-response protocols
   - Access via `server.socket.handle` and `setsockopt`

8. **Monitor accept queue depth**
   - If queue frequently fills, increase backlog or optimize handler
   - Use `ss -lt` on Linux to see current queue depth

9. **Ephemeral ports for testing are fast**
   - Port 0 lets kernel choose any free port instantly
   - Avoids TIME_WAIT conflicts in rapid test cycles

10. **Graceful shutdown prevents data loss**
    - Don't just kill the server
    - Stop accepting, drain connections, then exit
    - See Pattern 5: Graceful Shutdown

------

## Common Patterns

### Testing Pattern: Client-Server in One Test

```zig
test "server accepts connection" {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Server: ephemeral port
    const addr = try std.Io.net.IpAddress.parse("127.0.0.1", 0);
    var server = try addr.listen(io, .{});
    defer server.deinit(io);

    const server_addr = server.socket.address;

    // Client thread
    const client_thread = try std.Thread.spawn(.{}, struct {
  fn connect(io2: std.Io, sa: std.Io.net.IpAddress) !void {
      const stream = try sa.connect(io2, .{});
      stream.close(io2);
  }
    }.connect, .{ io, server_addr });

    // Server accepts
    var stream = try server.accept(io);
    stream.close(io);

    client_thread.join();
}
```

------

### HTTP-Like Protocol (Simple)

```zig
fn handleHttp(io: std.Io, stream: std.Io.net.Stream) !void {
    defer stream.close(io);

    var rbuf: [4096]u8 = undefined;
    var reader = stream.reader(io, &rbuf);

    // Read request line
    const request_line = try reader.interface.takeDelimiterInclusive('\n');

    // Skip headers until empty line
    while (true) {
  const header = try reader.interface.takeDelimiterInclusive('\n');
  if (header.len <= 2) break; // Empty line (just \r\n)
    }

    // Send response
    var wbuf: [4096]u8 = undefined;
    var writer = stream.writer(io, &wbuf);

    try writer.interface.writeAll("HTTP/1.1 200 OK\r\n");
    try writer.interface.writeAll("Content-Length: 13\r\n");
    try writer.interface.writeAll("\r\n");
    try writer.interface.writeAll("Hello, World!");
    try writer.interface.flush();
}
```

------

## See Also

- [std.Io.net.Stream](std.Io.net.Stream.md) - The active connection returned by `accept()`
- [std.Io.net.Socket](std.Io.net.Socket.md) - Low-level socket operations
- [std.Io.net.Ip4Address](std.Io.net.Ip4Address.md) - IPv4 address type used to create servers
- [std.Io.net.Ip6Address](std.Io.net.Ip6Address.md) - IPv6 address support
- [std.Io.Reader](../Types/std.Io.Reader.md) - Reading from accepted connections
- [std.Io.Writer](../Types/std.Io.Writer.md) - Writing to accepted connections
- [std.Io.Threaded](../Types/std.Io.Threaded.md) - Thread-based I/O backend
- [std.Thread](https://ziglang.org/documentation/master/std/#std.Thread) - Spawning threads for concurrent handling
