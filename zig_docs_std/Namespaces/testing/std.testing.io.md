# std.testing.io

**Type:** `Io` (Zig's async I/O runtime)

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

An `Io.Threaded` instance for performing asynchronous I/O operations in unit tests. Provides network sockets, file I/O, and timers in a test-friendly environment.

**Key Features:**
- ✅ Access to async I/O primitives (sockets, files, timers)
- ✅ Only available in test builds (compile error otherwise)
- ✅ Backed by `io_instance` global

⚠️ **Test-only:** Will trigger a compile error if used outside of `zig test`.

---

## Usage

```zig
const std = @import("std");

test "using testing.io for networking" {
    const io = std.testing.io;

    const addr = try std.net.Ip4Address.parse("127.0.0.1", 8080);
    const socket = try addr.connect(io, .{ .mode = .stream });
    defer socket.close(io);

    // Use socket for testing network code...
}
```

---

## Source

```zig
pub const io = if (builtin.is_test) io_instance.io() else @compileError("not testing");
```

The underlying instance is stored in `io_instance` (see `std.testing.io_instance.md`).

---

## Related

- **[std.testing.io_instance](./std.testing.io_instance.md)** - The underlying Io.Threaded global
- **[std.Io](../../Types/Io/std.io.md)** - Async I/O runtime documentation
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Use for I/O tests** - Networking, file operations, timers
✅ **Close resources** - Use `defer` to clean up sockets/files
❌ **Not for production** - Test-only, will fail to compile outside tests
