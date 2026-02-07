# std.testing.Reader.Call

**Type:** `struct`

**Module:** `std.testing`

**Parent Type:** `Reader`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

Represents a single read operation in a `std.testing.Reader` sequence. Each `Call` specifies what data should be returned when the reader is asked to read.

**Use Case:** Building sequences of read operations for testing code that consumes `Io.Reader`.

---

## Fields

### `buffer: []const u8`

The data that will be returned when this call is processed. The reader will serve this buffer's contents and then move to the next call in the sequence.

---

## Usage

```zig
const std = @import("std");

test "reader with multiple calls" {
    const calls = &[_]std.testing.Reader.Call{
        .{ .buffer = "first chunk" },
        .{ .buffer = "second chunk" },
        .{ .buffer = "final chunk" },
    };

    var buffer: [256]u8 = undefined;
    var reader = std.testing.Reader.init(&buffer, calls);

    // Each read operation serves one call's buffer
    var read_buf: [32]u8 = undefined;

    const n1 = try reader.interface.stream(&read_buf);
    try std.testing.expectEqualStrings("first chunk", read_buf[0..n1]);

    const n2 = try reader.interface.stream(&read_buf);
    try std.testing.expectEqualStrings("second chunk", read_buf[0..n2]);

    const n3 = try reader.interface.stream(&read_buf);
    try std.testing.expectEqualStrings("final chunk", read_buf[0..n3]);
}
```

---

## Source

```zig
pub const Call = struct {
    buffer: []const u8,
};
```

---

## Related

- **[std.testing.Reader](./std.testing.Reader.md)** - Test reader that uses Call sequences
- **[std.Io.Reader](../../io/std.io.md)** - The reader interface being simulated
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Realistic chunks** - Use buffer sizes similar to real-world scenarios
✅ **Test edge cases** - Include empty buffers, single bytes, large chunks
✅ **Simulate protocols** - Use actual protocol message sequences
⚠️ **Immutable data** - Buffer is `[]const u8` - data won't be modified
