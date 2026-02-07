# std.fs.path.isAbsolute

**Check if a path is absolute**

```zig
pub fn isAbsolute(path: []const u8) bool
```

Returns `true` if the path is absolute, `false` if relative. Platform-specific behavior.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    // Absolute paths
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("/usr/bin")});       // true (POSIX)
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("C:\\Windows")});    // true (Windows)
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("\\\\server\\")});   // true (Windows UNC)

    // Relative paths
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("src/main.zig")});   // false
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("./current")});      // false
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("../parent")});      // false
}
```

**Platform-Specific Rules:**

**POSIX (Linux, macOS, BSD):**
- Absolute if starts with `/`
- Examples: `/`, `/usr`, `/home/user`

**Windows:**
- Absolute if has drive letter: `C:\`, `D:\path`
- UNC paths: `\\server\share`
- Device paths: `\\.\device`, `\\?\C:\path`
- NOT absolute: `C:relative` (drive-relative), `\path` (current-drive-relative)

**Force Platform-Specific Check:**
```zig
// Always use POSIX rules
const is_abs_posix = std.fs.path.isAbsolutePosix("/usr/bin"); // true

// Always use Windows rules
const is_abs_win = std.fs.path.isAbsoluteWindows("C:\\Windows"); // true
```

**See Also:**
- 📚 [Complete isAbsolute documentation](./std.fs.md#pub-fn-isabsolutepath-const-u8-bool)
- 📚 [std.fs.path practical guide](./std.fs.path.md#path-analysis)
- Related: `isAbsolutePosix`, `isAbsoluteWindows`, `parsePath`
