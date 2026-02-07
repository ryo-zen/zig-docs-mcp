# std.fs.path.sep_str_posix

**POSIX path separator as string (always `"/"`)**

```zig
pub const sep_str_posix: []const u8 = "/";
```

Platform-independent constant for POSIX separator string.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("POSIX separator: {s}\n", .{std.fs.path.sep_str_posix}); // "/"
}
```

**See Also:**
- 📚 [Complete constants documentation](./std.fs.md#constants)
- Related: `sep_str`, `sep_str_windows`
