# std.testing.ReaderIndirect

**Type:** `struct`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A wrapper for `Io.Reader` that indirects reads through another reader while maintaining its own internal buffer. Always writes to its internal buffer and returns 0 during `stream` and `readVec` operations, forcing consumers to use the underlying reader's data.

**Key Behavior:**
- ⚠️ Returns 0 bytes on direct `stream()` or `readVec()` calls
- ✅ Data comes from the wrapped `in` reader
- ✅ Maintains its own buffer separate from the source

**Use Case:** Testing code that expects readers to behave in specific ways, particularly testing handling of 0-byte reads or buffer management.

---

## Fields

### `in: *Io.Reader`

Pointer to the underlying reader that provides the actual data. All data ultimately comes from this source.

------

### `interface: Io.Reader`

The `Io.Reader` interface for this wrapper. Use this to perform read operations (though they will return 0).

---

## Functions

### `pub fn init(in: *Io.Reader, buffer: []u8) ReaderIndirect`

Creates a new indirect reader that wraps the provided reader with its own buffer.

**Parameters:**
- `in` - Pointer to the source reader
- `buffer` - Internal buffer for this reader (separate from source)

**Example:**
```zig
const std = @import("std");

test "indirect reader behavior" {
    const calls = &[_]std.testing.Reader.Call{
  .{ .buffer = "test data" },
    };

    var source_buf: [256]u8 = undefined;
    var source_reader = std.testing.Reader.init(&source_buf, calls);

    var indirect_buf: [128]u8 = undefined;
    var indirect = std.testing.ReaderIndirect.init(
  &source_reader.interface,
  &indirect_buf,
    );

    // Attempting to read from indirect.interface returns 0
    var read_buf: [32]u8 = undefined;
    const n = try indirect.interface.stream(&read_buf);
    try std.testing.expectEqual(@as(usize, 0), n);

    // Data must be read from source_reader.interface instead
}
```

---

## Usage Patterns

### Testing Zero-Byte Read Handling

```zig
test "handle zero-byte reads correctly" {
    const calls = &[_]std.testing.Reader.Call{
  .{ .buffer = "data" },
    };

    var source_buf: [256]u8 = undefined;
    var source_reader = std.testing.Reader.init(&source_buf, calls);

    var indirect_buf: [128]u8 = undefined;
    var indirect = std.testing.ReaderIndirect.init(
  &source_reader.interface,
  &indirect_buf,
    );

    // Test that your code handles 0-byte reads gracefully
    const result = processReader(&indirect.interface);

    // Code should recognize 0-byte read as special case
    try std.testing.expect(result.handled_zero_read);
}
```

---

## Related

- **[std.testing.Reader](./std.testing.Reader.md)** - Direct test reader with predetermined data
- **[std.Io.Reader](../../io/std.io.md)** - The reader interface being wrapped
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Test 0-byte handling** - Verify code handles readers that return 0 bytes
✅ **Use with other test readers** - Often wraps std.testing.Reader for complex scenarios
⚠️ **Understand indirection** - Data flows through `in`, not `interface` directly
❌ **Not for production** - Testing tool only, use real readers in production
