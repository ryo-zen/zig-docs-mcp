# Common Patterns & Boilerplate (0.16)

## Standard Main Function Setup

This is the boilerplate you'll need in most 0.16 programs:

```zig
const std = @import("std");

pub fn main() !void {
    // 1. Allocator setup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 2. Io setup
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // 3. Your code here
    try yourFunction(allocator, io);
}
```

## Minimal Setup (No Io)

If you don't need filesystem/network/time operations:

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Use std.posix for simple file operations
    // Use ArrayList with allocator parameter
    var list: std.ArrayList(u32) = .{};
    defer list.deinit(allocator);

    try list.append(allocator, 42);
}
```

## Function Signature Patterns

### Functions Using Io

```zig
fn processData(allocator: Allocator, io: std.Io, data: []const u8) !void {
    // Can use filesystem, network, time operations
    const ts = std.Io.Clock.real.now(io);

    // Can use ArrayList
    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);
    try list.appendSlice(allocator, data);
}
```

### Functions Not Using Io

```zig
fn processData(allocator: Allocator, data: []const u8) !void {
    // Can use ArrayList
    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);
    try list.appendSlice(allocator, data);

    // Can use std.posix for simple operations
}
```

## Common Operations

### File Read/Write

**Full pattern:**
```zig
const std = @import("std");

pub fn readWriteFile(allocator: Allocator, io: std.Io) !void {
    const dir = std.Io.Dir.cwd();

    // Write
    {
  const file = try dir.createFile(io, "data.txt", .{});
  defer file.close(io);
  try file.writeStreamingAll(io, "Hello, World!");
    }

    // Read
    {
  var buffer: [1024]u8 = undefined;
  const bytes = try dir.readFile(io, "data.txt", &buffer);

  std.debug.print("Read: {s}\n", .{bytes});
    }
}
```

**Simple pattern with std.posix:**
```zig
pub fn readFile() !void {
    const fd = try std.posix.open("data.txt", .{ .ACCMODE = .RDONLY }, 0);
    defer std.posix.close(fd);

    var buffer: [1024]u8 = undefined;
    const bytes_read = try std.posix.read(fd, &buffer);

    std.debug.print("Read: {s}\n", .{buffer[0..bytes_read]});
}
```

### Network Server

```zig
const std = @import("std");

pub fn runServer(allocator: Allocator, io: std.Io) !void {
    const net = std.Io.net;
    const addr = try net.IpAddress.parse("127.0.0.1", 8080);

    var server = try addr.listen(io, .{});
    defer server.deinit(io);

    std.debug.print("Listening on port 8080\n", .{});

    while (true) {
  const conn = try server.accept(io);
  errdefer conn.close(io);

  // Handle connection (ideally spawn thread/task)
  try handleConnection(allocator, io, conn);
    }
}

fn handleConnection(allocator: Allocator, io: std.Io, conn: std.Io.net.Stream) !void {
    defer conn.close(io);
    _ = allocator;

    var rbuf: [1024]u8 = undefined;
    var reader = conn.reader(io, &rbuf);
    const bytes_read = try reader.interface.readSliceShort(&rbuf);

    // Echo back
    var wbuf: [1024]u8 = undefined;
    var writer = conn.writer(io, &wbuf);
    try writer.interface.writeAll(rbuf[0..bytes_read]);
    try writer.interface.flush();
}
```

### Data Processing with ArrayList

```zig
const std = @import("std");

pub fn processItems(allocator: Allocator, items: []const u32) ![]u32 {
    var result: std.ArrayList(u32) = .{};
    defer result.deinit(allocator);

    for (items) |item| {
  if (item > 10) {
      try result.append(allocator, item * 2);
  }
    }

    // Return owned slice
    return result.toOwnedSlice(allocator);
}
```

### Logging with Timestamp

```zig
const std = @import("std");

const Logger = struct {
    io: std.Io,

    pub fn log(self: Logger, comptime level: []const u8, msg: []const u8) !void {
  const ts = std.Io.Clock.real.now(self.io);
  const seconds = ts.toSeconds();

  std.debug.print("[{s}][{}] {s}\n", .{level, seconds, msg});
    }

    pub fn info(self: Logger, msg: []const u8) !void {
  try self.log("INFO", msg);
    }

    pub fn err(self: Logger, msg: []const u8) !void {
  try self.log("ERROR", msg);
    }
};

pub fn example(io: std.Io) !void {
    const logger = Logger{ .io = io };

    try logger.info("Application started");
    try logger.err("Something went wrong");
}
```

### Struct with Io Field

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

const Database = struct {
    allocator: Allocator,
    io: std.Io,
    connections: std.ArrayList(*Connection),

    pub fn init(allocator: Allocator, io: std.Io) Database {
  return .{
      .allocator = allocator,
      .io = io,
      .connections = .{},
  };
    }

    pub fn deinit(self: *Database) void {
  for (self.connections.items) |conn| {
      conn.close(self.io);
      self.allocator.destroy(conn);
  }
  self.connections.deinit(self.allocator);
    }

    pub fn connect(self: *Database, addr: []const u8) !void {
  const net = std.Io.net;
  const ip_addr = try net.IpAddress.parse(addr, 5432);

  const conn_ptr = try self.allocator.create(Connection);
  errdefer self.allocator.destroy(conn_ptr);

  conn_ptr.* = try Connection.init(self.io, ip_addr);
  try self.connections.append(self.allocator, conn_ptr);
    }
};
```

### Testing Pattern

```zig
const std = @import("std");

test "file operations with Io" {
    const allocator = std.testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Test filesystem operations
    const dir = std.Io.Dir.cwd();
    try dir.createDirPath(io, "test_temp");
    defer dir.deleteTree(io, "test_temp") catch {};

    // Test passes
}

test "arraylist operations" {
    const allocator = std.testing.allocator;

    var list: std.ArrayList(u32) = .{};
    defer list.deinit(allocator);

    try list.append(allocator, 42);
    try std.testing.expectEqual(@as(usize, 1), list.items.len);
}
```

## Error Handling Pattern

```zig
const std = @import("std");

pub fn robustOperation(allocator: Allocator, io: std.Io) !void {
    // Setup with error handling
    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);

    const dir = std.Io.Dir.cwd();

    // Create directory
    dir.createDirPath(io, "output") catch |err| {
  std.debug.print("Failed to create directory: {}\n", .{err});
  return err;
    };

    // Open file
    const file = dir.createFile(io, "output/data.txt", .{}) catch |err| {
  std.debug.print("Failed to create file: {}\n", .{err});
  return err;
    };
    defer file.close(io);

    // Write data
    try file.writeStreamingAll(io, "Important data");

    std.debug.print("Operation completed successfully\n", .{});
}
```

## Performance Pattern (Minimal Allocations)

```zig
const std = @import("std");

pub fn efficientProcessing(io: std.Io) !void {
    // Stack allocate when possible
    var buffer: [4096]u8 = undefined;

    // Use std.posix for simple I/O
    const fd = try std.posix.open("large_file.dat", .{ .ACCMODE = .RDONLY }, 0);
    defer std.posix.close(fd);

    var total: usize = 0;
    while (true) {
  const bytes_read = std.posix.read(fd, &buffer) catch |err| switch (err) {
      error.WouldBlock => break,
      else => return err,
  };

  if (bytes_read == 0) break;
  total += bytes_read;

  // Process buffer in-place
    }

    std.debug.print("Processed {} bytes\n", .{total});
}
```

## When to Use What

| Pattern | Use Case |
|---------|----------|
| `std.Io.Threaded` | Network servers, async operations, cross-platform code |
| `std.posix` | Simple file reads, performance-critical sync code |
| `ArrayList` with allocator | Dynamic arrays (mandatory pattern) |
| `io` parameter threading | Any function needing fs/net/time |
| `std.Io.Clock.real` | Wall clock time, timestamps |
| `std.Io.Clock.awake` | Durations, timers, performance measurement |

## Migration Quick Reference

```zig
// Old (0.13-0.14) → New (0.16)

// ArrayList
var list = ArrayList(u32).init(allocator);          → var list: ArrayList(u32) = .{};
try list.append(42);                                → try list.append(allocator, 42);
list.deinit();                                      → list.deinit(allocator);

// Filesystem
const dir = std.fs.cwd();                           → const dir = std.Io.Dir.cwd();
try dir.makePath("foo");                            → try dir.createDirPath(io, "foo");
const file = try dir.createFile("f.txt", .{});      → const file = try dir.createFile(io, "f.txt", .{});
file.close();                                       → file.close(io);

// Networking
const addr = std.net.Address.parseIp4("::1", 80);   → const addr = std.Io.net.IpAddress.parse("::1", 80);
const listener = try addr.listen(.{});              → var server = try addr.listen(io, .{});
const conn = try listener.accept();                 → const conn = try server.accept(io);

// Time
const ts = std.time.timestamp();                    → const ts = std.Io.Clock.real.now(io).toSeconds();
std.time.sleep(1_000_000_000);                      → try io.sleep(Duration.fromSeconds(1), Clock.awake);
```
