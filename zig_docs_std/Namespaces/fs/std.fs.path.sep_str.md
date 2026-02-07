# std.fs.path.sep_str

**Platform-native path separator as string**

```zig
pub const sep_str: []const u8
```

The platform's path separator as a string slice.

**Values:**
- `"/"` on POSIX
- `"\\"` on Windows

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Separator string: {s}\n", .{std.fs.path.sep_str});
    // POSIX: "/"
    // Windows: "\"
}
```

**See Also:**
- 📚 [Complete constants documentation](./std.fs.md#constants)
- Related: `sep`, `sep_str_posix`, `sep_str_windows`
