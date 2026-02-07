# std.testing.environ

**Type:** `Environ`

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A global environment variable container for test environments. Initialized as `undefined` and must be set up by the test runner before use.

**Use Case:** Managing environment variables in isolated test environments without affecting system environment.

⚠️ **Test-only:** Will trigger a compile error if used outside of `zig test`.

---

## Source

```zig
pub var environ: Environ = if (builtin.is_test) undefined else @compileError("not testing");
```

**Initialization:** Set by the test runner. Do not access until properly initialized.

---

## Related

- **[std.testing.io](./std.testing.io.md)** - I/O runtime for tests
- **[std.testing main docs](./std.testing.md)** - Complete testing guide

---

## Best Practices

⚠️ **Check initialization** - Ensure test runner has initialized before use
❌ **Not for production** - Test-only, will fail to compile outside tests
