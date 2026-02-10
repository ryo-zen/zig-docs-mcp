# std.process.ArgExpansion

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.ArgExpansion` is an enumeration that controls how command-line arguments are processed regarding wildcard expansion or other shell-like transformations on platforms that support them.

---

## Values

`expand`
------
Enables platform-specific argument expansion (e.g., globbing on some systems).

`no_expand`
------
Disables argument expansion; arguments are passed exactly as received.

---

## Usage

This enum is typically used in conjunction with `std.process.SpawnOptions` or other process creation APIs to specify how the `argv` array should be handled.

```zig
const options = std.process.SpawnOptions{
    .argv = &[_][]const u8{ "ls", "*.txt" },
    .expand_arg0 = .expand,
    // ...
};
```

*(Note: Exact usage depends on the specific API being called.)*
