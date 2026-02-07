# std.fs.path.Win32PathType

**Windows-specific path classification**

```zig
pub const Win32PathType = enum {
    unc_absolute,
    drive_absolute,
    drive_relative,
    rooted,
    relative,
    unc_relative,
};
```

Categorizes Windows paths by their type.

**Values:**
- `.unc_absolute` - UNC path: `\\server\share\path`
- `.drive_absolute` - Absolute with drive: `C:\path`
- `.drive_relative` - Drive-relative: `C:path` (relative to current dir on C:)
- `.rooted` - Rooted but drive-relative: `\path` (relative to current drive)
- `.relative` - Fully relative: `path\to\file`
- `.unc_relative` - UNC relative (rare)

**Quick Example:**
```zig
const std = @import("std");

pub fn classifyWindowsPath(path: []const u8) void {
    const parsed = std.fs.path.parsePathWindows(u8, path);
    std.debug.print("Path type: {}\n", .{parsed.kind});
}

pub fn main() void {
    classifyWindowsPath("C:\\Users");      // drive_absolute
    classifyWindowsPath("\\\\server\\share"); // unc_absolute
    classifyWindowsPath("C:relative");     // drive_relative
    classifyWindowsPath("\\rooted");       // rooted
}
```

**See Also:**
- 📚 [Complete types documentation](./std.fs.md#path-type-enums)
- Related: `WindowsPath2`, `parsePathWindows`
