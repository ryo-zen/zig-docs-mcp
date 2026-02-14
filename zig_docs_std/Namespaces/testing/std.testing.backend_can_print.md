# std.testing.backend_can_print

**Type:** `bool` (comptime constant)

**Module:** `std.testing`

📚 **[See Complete Testing Documentation](./std.testing.md)** - Full std.testing namespace guide

---

## Overview

A compile-time boolean that indicates whether the current Zig compiler backend supports printing to stdout/stderr. Used to conditionally skip tests that rely on print output.

**Returns `false` for:**
- stage2_aarch64
- stage2_powerpc
- stage2_riscv64
- stage2_spirv

**Returns `true` for:** All other backends (x86_64, wasm, etc.)

---

## Usage

```zig
const std = @import("std");

test "conditional printing test" {
    if (!std.testing.backend_can_print) {
  return error.SkipZigTest;
    }

    // This test requires printing support
    std.debug.print("Running test with print output\n", .{});
}
```

---

## Source

```zig
pub const backend_can_print = switch (builtin.zig_backend) {
    .stage2_aarch64,
    .stage2_powerpc,
    .stage2_riscv64,
    .stage2_spirv,
    => false,
    else => true,
};
```

---

## Related

- **[std.testing main docs](./std.testing.md)** - Complete testing guide
- **[std.builtin.zig_backend](../../../zig_docs/compile_variables.md)** - Compiler backend information

---

## Best Practices

✅ **Skip unsupported tests** - Return `error.SkipZigTest` when print not supported
✅ **Comptime known** - Can be used in comptime conditions
⚠️ **Backend-specific** - Different behavior on different compilation targets
