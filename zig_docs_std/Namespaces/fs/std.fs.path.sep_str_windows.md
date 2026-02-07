# std.fs.path.sep_str_windows

**Windows path separator as string (always `"\\"`)**

```zig
pub const sep_str_windows: []const u8 = "\\";
```

Platform-independent constant for Windows separator string.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Windows separator: {s}\n", .{std.fs.path.sep_str_windows}); // "\"
}
```

**See Also:**
- 📚 [Complete constants documentation](./std.fs.md#constants)
- Related: `sep_str`, `sep_str_posix`
