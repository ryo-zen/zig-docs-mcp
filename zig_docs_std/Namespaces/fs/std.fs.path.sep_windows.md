# std.fs.path.sep_windows

**Windows path separator (always `\`)**

```zig
pub const sep_windows: u8 = '\\';
```

Platform-independent constant for Windows path separator.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Windows separator: {c}\n", .{std.fs.path.sep_windows}); // '\'
}
```

**See Also:**
- 📚 [Path separator documentation](./std.fs.path.sep.md)
- Related: `sep`, `sep_posix`
