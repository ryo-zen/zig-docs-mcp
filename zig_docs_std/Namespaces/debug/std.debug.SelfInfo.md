# std.debug.SelfInfo

This type abstracts the target-specific implementation of accessing this process' own debug information behind a generic interface which supports looking up source locations associated with addresses, as well as unwinding the stack where a safe mechanism to do so exists.

## Overview

`std.debug.SelfInfo` resolves to the platform-specific implementation for the current target.

When unsupported for the current target/object format combination, it resolves to `void`.

## Source Code

```
pub const SelfInfo = if (@hasDecl(root, "debug") and @hasDecl(root.debug, "SelfInfo"))
    root.debug.SelfInfo
else switch (std.Target.ObjectFormat.default(native_os, native_arch)) {
    .coff => if (native_os == .windows) @import("debug/SelfInfo/Windows.zig") else void,
    .elf => switch (native_os) {
        .freestanding, .other => void,
        else => @import("debug/SelfInfo/Elf.zig"),
    },
    .macho => @import("debug/SelfInfo/MachO.zig"),
    .plan9, .spirv, .wasm => void,
    .c, .hex, .raw => unreachable,
}
```

## Behavior Notes

- Allows root overrides via `root.debug.SelfInfo`.
- Selects implementation by default object format and native target.
- Some targets intentionally provide no self-debug-info support (`void`).

## Related APIs

- `std.debug.getSelfDebugInfo`
- `std.debug.SelfInfoError`
- `std.debug.Info` (cross-target/offline debug info loading)
