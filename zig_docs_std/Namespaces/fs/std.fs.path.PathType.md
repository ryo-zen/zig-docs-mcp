# std.fs.path.PathType

**Enum representing path type on native platform**

```zig
pub const PathType = enum {
    windows,
    posix,
};
```

Indicates which path convention is used.

**Values:**
- `.windows` - Windows path conventions (backslash separators, drive letters)
- `.posix` - POSIX path conventions (forward slash separators)

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    const path_type = switch (@import("builtin").os.tag) {
        .windows => std.fs.path.PathType.windows,
        else => std.fs.path.PathType.posix,
    };
    std.debug.print("Path type: {}\n", .{path_type});
}
```

**See Also:**
- 📚 [Complete types documentation](./std.fs.md#types-and-constants)
- Related: `Win32PathType`, `parsePath`
