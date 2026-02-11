# std.process.ReplaceOptions

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.ReplaceOptions` is the configuration structure used by `std.process.replace()` and `std.process.replacePath()`. These functions implement the "exec" pattern, where the current process's image is replaced by a new program.

If the replacement succeeds, the calling function never returns.

---

## Fields

`argv: []const []const u8`
------
**Mandatory.** The command and its arguments. `argv[0]` is the name of the program to execute.

`expand_arg0: std.process.ArgExpansion = .no_expand`
------
Controls whether `argv[0]` should be searched for in the `PATH`.

`environ_map: ?*const std.process.Environ.Map = null`
------
If provided, replaces the process environment variables. If `null`, the new process inherits the current environment. **Note:** The `PATH` from this map is *not* used to resolve `argv[0]`; the parent's environment is used for resolution.

---

## Usage Example

```zig
const options = std.process.ReplaceOptions{
    .argv = &[_][]const u8{ "ls", "-l" },
    .expand_arg0 = .expand,
};

// This call will not return if successful
const err = std.process.replace(init.io, options);
std.debug.print("Replacement failed: {}\n", .{err});
```

---

## See Also

- **std.process.replace** - The function that consumes this struct.
- **std.process.can_replace** - Constant indicating if this feature is supported on the target platform.
- **std.process.Environ.Map** - For setting custom environment variables.
