# std.testing.log_level

**Type:** `std.log.Level`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A mutable variable that controls the minimum log level for test output. Defaults to `.warn`, meaning only warnings and errors are logged during tests.

**Default:** `std.log.Level.warn`

⚠️ **Known Issue:** See [ziglang/zig#5738](https://github.com/ziglang/zig/issues/5738) for ongoing work on test logging.

---

## Usage

```zig
const std = @import("std");

test "verbose test logging" {
    // Temporarily increase verbosity for this test
    const old_level = std.testing.log_level;
    defer std.testing.log_level = old_level;

    std.testing.log_level = .debug;

    // Now debug logs will be visible
    std.log.debug("This will be printed", .{});
}
```

---

## Source

```zig
pub var log_level = std.log.Level.warn;
```

---

## Related

- **[std.log.Level](../../log/std.log.md)** - Log level enumeration
- **[std.log](../../log/std.log.md)** - Logging utilities
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Log Levels

- `.err` - Errors only
- `.warn` - Warnings and errors (default)
- `.info` - Informational messages, warnings, and errors
- `.debug` - Debug messages and all above

---

## Best Practices

✅ **Save and restore** - Use `defer` to reset log level after modification
✅ **Test-specific verbosity** - Increase for debugging specific tests
⚠️ **Thread-unsafe** - Modifying in concurrent tests may cause issues
