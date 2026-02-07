# std.testing.io_instance

**Type:** `Io.Threaded`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

The underlying `Io.Threaded` instance that powers `std.testing.io`. Initialized by the test runner before tests execute and provides async I/O capabilities for testing.

**State:** `undefined` at compile time - must be initialized by test runner before use.

⚠️ **Internal:** Most tests should use `std.testing.io` directly instead of accessing this instance.

---

## Source

```zig
pub var io_instance: Io.Threaded = undefined;
```

**Initialization:** Set by the test runner infrastructure before test execution begins.

---

## Related

- **[std.testing.io](./std.testing.io.md)** - The public I/O interface (use this in tests)
- **[std.Io.Threaded](../../io/std.io.md)** - Async I/O runtime documentation
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

✅ **Use std.testing.io** - Don't access this instance directly
⚠️ **Not initialized at compile time** - Only valid after test runner setup
❌ **Don't manually initialize** - Let the test runner handle this
