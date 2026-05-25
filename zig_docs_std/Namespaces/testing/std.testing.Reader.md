# std.testing.Reader

**Type:** `struct`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A test double for `Io.Reader` that returns predetermined buffers during read operations. Simulates reading from a source without actual I/O, useful for testing code that consumes readers.

**Key Features:**
- ✅ Predictable, deterministic read behavior
- ✅ Configurable read patterns via `Call` list
- ✅ Optional artificial byte limits per read
- ✅ No actual I/O - pure in-memory simulation

**Use Case:** Testing parsers, protocols, or any code that reads from `Io.Reader` without needing real files or network connections.

---

## Fields

### `calls: []const Call`

A list of predetermined read operations. Each `Call` specifies what data should be returned on successive reads.

See **[std.testing.Reader.Call](./std.testing.Reader.Call.md)** for details.

------

### `buffer: []u8`

Working buffer used by the wrapped `Io.Reader` interface while streaming test data.

------

### `interface: Io.Reader`

The `Io.Reader` interface that wraps this test reader. Use this for actual read operations.

------

### `next_call_index: usize`

Internal state tracking which call in the `calls` list will be served next.

------

### `next_offset: usize`

Internal state tracking the offset within the current call's buffer.

------

### `artificial_limit: Io.Limit = .unlimited`

Optional limit that further restricts how many bytes are returned in each read call, even if the call's buffer is larger. Useful for testing partial read scenarios.

**Default:** `.unlimited` (no artificial restriction)

---

## Types

### `Call`

Represents a single read operation. See **[std.testing.Reader.Call](./std.testing.Reader.Call.md)** for details.

---

## Functions

### `pub fn init(buffer: []u8, calls: []const Call) Reader`

Creates a new test reader that will serve the specified sequence of calls.

**Parameters:**
- `buffer` - Working buffer for the reader (must be large enough for read operations)
- `calls` - List of predetermined read operations to simulate

**Example:**
```zig
const std = @import("std");

test "reading from test reader" {
    const calls = &[_]std.testing.Reader.Call{
  .{ .buffer = "hello " },
  .{ .buffer = "world" },
    };

    var buffer: [256]u8 = undefined;
    var reader = std.testing.Reader.init(&buffer, calls);

    // Read from the test reader
    var read_buf: [32]u8 = undefined;

    // First read gets "hello "
    const n1 = try reader.interface.stream(&read_buf);
    try std.testing.expectEqualStrings("hello ", read_buf[0..n1]);

    // Second read gets "world"
    const n2 = try reader.interface.stream(&read_buf);
    try std.testing.expectEqualStrings("world", read_buf[0..n2]);

    // Third read gets EOF
    const n3 = try reader.interface.stream(&read_buf);
    try std.testing.expectEqual(@as(usize, 0), n3);
}
```

---

## Usage Patterns

### Testing a Parser

```zig
test "parse with test reader" {
    const input = "header\nline1\nline2\n";
    const calls = &[_]std.testing.Reader.Call{
  .{ .buffer = input },
    };

    var buffer: [256]u8 = undefined;
    var reader = std.testing.Reader.init(&buffer, calls);

    // Test parser with predictable input
    const result = try parseInput(&reader.interface);
    try std.testing.expectEqual(2, result.line_count);
}
```

### Simulating Partial Reads

```zig
test "handle partial reads" {
    const calls = &[_]std.testing.Reader.Call{
  .{ .buffer = "par" },  // Partial chunk
  .{ .buffer = "tial" }, // Rest of word
    };

    var buffer: [256]u8 = undefined;
    var reader = std.testing.Reader.init(&buffer, calls);
    reader.artificial_limit = .{ .max = 3 }; // Limit each read to 3 bytes

    // Test code that handles partial reads correctly
    var full_buffer: [10]u8 = undefined;
    var total: usize = 0;

    while (true) {
  const n = try reader.interface.stream(full_buffer[total..]);
  if (n == 0) break;
  total += n;
    }

    try std.testing.expectEqualStrings("partial", full_buffer[0..total]);
}
```

---

## Related

- **[std.testing.Reader.Call](./std.testing.Reader.Call.md)** - Configuration for individual read operations
- **[std.testing.ReaderIndirect](./std.testing.ReaderIndirect.md)** - Reader that wraps another reader
- **[std.Io.Reader](../../Types/Io/std.io.md)** - The actual reader interface
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Use for deterministic testing** - Perfect for testing parsers and protocols
✅ **Test both complete and partial reads** - Use artificial_limit for partial read scenarios
✅ **Provide realistic data** - Use actual protocol messages in calls
⚠️ **Buffer must be large enough** - Ensure buffer can hold the largest call
❌ **Not for production** - Testing tool only, use real I/O in production
