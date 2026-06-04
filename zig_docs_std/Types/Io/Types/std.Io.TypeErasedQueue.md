# std.Io.TypeErasedQueue

## Quick Start

### Basic Byte Queue

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();

    var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Create a 1KB byte queue
    var backing_buffer: [1024]u8 = undefined;
    var queue = std.Io.TypeErasedQueue.init(&backing_buffer);
    defer queue.close(io);

    // Producer: put bytes
    const data = "Hello, Queue!";
    _ = try queue.put(io, data, data.len);

    // Consumer: get bytes
    var result: [128]u8 = undefined;
    const received = try queue.get(io, &result, 1);

    std.debug.print("Received: {s}\n", .{result[0..received]});
}
```

### Producer-Consumer Pattern

```zig
const std = @import("std");

var backing_buffer: [4096]u8 = undefined;
var queue = std.Io.TypeErasedQueue.init(&backing_buffer);

// Producer task
fn producer(io: std.Io) !void {
    var i: u8 = 0;
    while (i < 10) : (i += 1) {
  const byte = [_]u8{i};
  _ = try queue.put(io, &byte, 1);
    }
    queue.close(io);
}

// Consumer task
fn consumer(io: std.Io) !void {
    var buffer: [16]u8 = undefined;
    while (true) {
  const count = queue.get(io, &buffer, 1) catch |err| {
      if (err == error.Closed) break;
      return err;
  };
  // Process buffer[0..count]
    }
}
```

⚠️ **Critical**: Always call `close()` when done to wake any blocked getters/putters. The queue uses a mutex internally - ensure proper cleanup to avoid deadlocks.

---

## Overview

`std.Io.TypeErasedQueue` is the low-level, untyped foundation for `std.Io.Queue`. It implements a thread-safe, blocking, fixed-capacity ring buffer operating on raw bytes. This type is used internally by the generic `Queue(T)` wrapper, which provides type-safe element access.

**Key Characteristics:**
- **Type-Erased**: Operates on `[]u8` byte slices, no knowledge of element types
- **Thread-Safe**: Uses `Mutex` for synchronized access across tasks/threads
- **Blocking**: Producers block when full, consumers block when empty
- **Fixed Capacity**: Backed by a caller-provided buffer, no dynamic allocation
- **Waiter Queues**: Tracks blocked putters and getters via doubly-linked lists

**When to use:**
- **Rarely directly** - prefer `std.Io.Queue(T)` for type-safe element queues
- Implementing custom queue-like structures that need byte-level control
- Building higher-level abstractions on top of the queue primitive

**When NOT to use:**
- Normal application code (use `Queue(T)` instead)
- Situations requiring dynamic resizing
- Lock-free requirements (this uses a mutex)

## Fields

`mutex: Mutex`

Synchronization primitive protecting all queue state. All operations acquire this lock.

------

`closed: bool`

Flag indicating the queue is permanently closed. Once `true`, puts return `error.Closed`; gets first drain buffered data, then return `error.Closed`.

------

`buffer: []u8`

The backing ring buffer storage. Provided by the caller at initialization. Size determines queue capacity.

**Note:** This is the *entire* available space. The actual data stored is tracked by `start` and `len`.

------

`start: usize`

Ring buffer read position. Next `get()` will read from `buffer[start]`.

------

`len: usize`

Number of bytes currently stored in the ring buffer. Always `<= buffer.len`.

------

`putters: std.DoublyLinkedList`

Intrusive linked list of tasks blocked waiting for space to write. Woken when consumers free capacity.

------

`getters: std.DoublyLinkedList`

Intrusive linked list of tasks blocked waiting for data to read. Woken when producers add bytes.

## Initialization

### `pub fn init(buffer: []u8) TypeErasedQueue`

Creates a new queue backed by the provided buffer. The queue takes ownership of this buffer for its lifetime.

**Parameters:**
- `buffer`: Caller-owned byte slice. Must remain valid for the queue's lifetime. Size determines queue capacity.

**Returns:** Initialized `TypeErasedQueue` in the "open" state.

**Example:**
```zig
var backing: [2048]u8 = undefined;
var queue = std.Io.TypeErasedQueue.init(&backing);
defer queue.close(io);
```

## Core Functions

### `pub fn put(q: *TypeErasedQueue, io: Io, elements: []const u8, min: usize) (QueueClosedError || Cancelable)!usize`

Appends bytes to the queue, blocking if insufficient space is available. Returns when at least `min` bytes are written or the queue is closed.

**Parameters:**
- `elements`: Bytes to append
- `min`: Minimum bytes to write before returning (must be `<= elements.len`)

**Returns:** Number of bytes actually written (`min <= returned <= elements.len`)

**Errors:**
- `error.Closed`: The queue has been closed
- `error.Canceled`: The operation was canceled (if supported by the Io backend)

**Behavior:**
- If space available `>= min`, writes at least `min` bytes and returns immediately
- If space available `< min`, blocks until enough space is freed by consumers
- May write more than `min` bytes if additional space becomes available

**Example:**
```zig
const data = "Hello, World!";
const written = try queue.put(io, data, data.len); // Block until all bytes written
std.debug.assert(written == data.len);
```

------

### `pub fn putUncancelable(q: *TypeErasedQueue, io: Io, elements: []const u8, min: usize) QueueClosedError!usize`

Same as `put()`, but does not introduce a cancellation point. Use when you need guaranteed completion.

**Example:**
```zig
const critical_data = "CRITICAL";
_ = try queue.putUncancelable(io, critical_data, critical_data.len);
// Guaranteed to write all bytes or return error.Closed
```

------

### `pub fn get(q: *TypeErasedQueue, io: Io, buffer: []u8, min: usize) (QueueClosedError || Cancelable)!usize`

Receives bytes from the queue, blocking if insufficient data is available. Returns when at least `min` bytes are read or the queue is closed.

**Parameters:**
- `buffer`: Destination buffer for received bytes
- `min`: Minimum bytes to read before returning (must be `<= buffer.len`)

**Returns:** Number of bytes actually read (`min <= returned <= buffer.len`)

**Errors:**
- `error.Closed`: The queue is closed and empty
- `error.Canceled`: The operation was canceled

**Behavior:**
- If available data `>= min`, reads at least `min` bytes and returns immediately
- If available data `< min`, blocks until producers add more bytes
- May read more than `min` bytes if additional data is available

**Example:**
```zig
var recv_buf: [256]u8 = undefined;
const received = try queue.get(io, &recv_buf, 1); // Read at least 1 byte
std.debug.print("Got {} bytes\n", .{received});
```

------

### `pub fn getUncancelable(q: *TypeErasedQueue, io: Io, buffer: []u8, min: usize) QueueClosedError!usize`

Same as `get()`, but does not introduce a cancellation point.

**Example:**
```zig
var buf: [128]u8 = undefined;
const count = try queue.getUncancelable(io, &buf, 16); // Must read at least 16 bytes
```

------

### `pub fn close(q: *TypeErasedQueue, io: Io) void`

Permanently closes the queue. Future `put` operations return `error.Closed`; `get` operations drain buffered data before returning `error.Closed`. Wakes all blocked tasks.

**Behavior:**
- Sets `closed` flag to `true`
- Wakes all waiting producers (putters)
- Wakes all waiting consumers (getters)
- Subsequent puts immediately return `error.Closed`
- Subsequent gets return `error.Closed` after buffered data is drained

**Example:**
```zig
// Signal shutdown to all consumers/producers
queue.close(io);
```

## Usage Patterns

### Graceful Shutdown

```zig
const std = @import("std");

pub fn gracefulShutdown(queue: *std.Io.TypeErasedQueue, io: std.Io) void {
    // Close queue to signal all waiters
    queue.close(io);

    // All blocked producers and consumers will wake with error.Closed
}
```

### Partial Writes/Reads

```zig
const std = @import("std");

pub fn partialWrite(queue: *std.Io.TypeErasedQueue, io: std.Io) !void {
    const large_data = [_]u8{0} ** 10000;

    // Write at least 1 byte, may write more if space available
    const written = try queue.put(io, &large_data, 1);

    if (written < large_data.len) {
  std.debug.print("Partial write: {}/{} bytes\n", .{written, large_data.len});
  // Handle remaining bytes...
    }
}
```

### Producer-Consumer with Close Detection

```zig
const std = @import("std");

pub fn consumer(queue: *std.Io.TypeErasedQueue, io: std.Io) !void {
    var buffer: [512]u8 = undefined;

    while (true) {
  const count = queue.get(io, &buffer, 1) catch |err| {
      if (err == error.Closed) {
          std.debug.print("Queue closed, exiting consumer\n", .{});
          return;
      }
      return err;
  };

  // Process buffer[0..count]
  processBytes(buffer[0..count]);
    }
}
```

## Error Sets

`QueueClosedError`

Contains `error.Closed`, returned by puts on a closed queue and by gets after buffered data has been drained.

## Debug Checklist

- ✅ **Close Called**: Did you call `close()` during cleanup?
- ✅ **Buffer Lifetime**: Is the backing buffer alive for the queue's entire lifetime?
- ✅ **Min Parameter**: Is `min` always `<= buffer.len` for get/put?
- ✅ **Closed Handling**: Do you handle `error.Closed` in consumers/producers?
- ✅ **Deadlock Risk**: Are you avoiding circular waits between queues?

## Performance Tips

1. **Size Buffer Appropriately**: Larger buffers reduce blocking but use more memory. Balance based on message sizes and producer/consumer rates.
2. **Batch Operations**: Use larger `min` values to reduce context switches from blocking.
3. **Prefer Queue(T)**: Unless you need byte-level control, use the typed wrapper for better ergonomics.
4. **Avoid Tiny Writes**: Small `min` values (like 1) cause frequent wake-ups. Batch when possible.

## See Also

- `std.Io.Queue(T)` - Type-safe wrapper around TypeErasedQueue
- `std.Io.Mutex` - The synchronization primitive used internally
- `std.Io.Event` - For simple signaling without data transfer
