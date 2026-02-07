# std.fs.path.sep

**Platform-native path separator character**

```zig
pub const sep: u8
```

The path separator for the current platform. Comptime constant.

**Values:**
- `/` on POSIX (Linux, macOS, BSD)
- `\` on Windows

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Path separator: {c}\n", .{std.fs.path.sep});
    // POSIX:   /
    // Windows: \

    // Use in cross-platform code
    const is_sep = std.fs.path.isSep(std.fs.path.sep);
    std.debug.print("Is separator? {}\n", .{is_sep}); // true
}
```

**Cross-Platform Example:**
```zig
const std = @import("std");

pub fn splitPath(path: []const u8) void {
    var start: usize = 0;
    for (path, 0..) |c, i| {
        if (c == std.fs.path.sep) {
            if (i > start) {
                std.debug.print("Component: {s}\n", .{path[start..i]});
            }
            start = i + 1;
        }
    }
    if (start < path.len) {
        std.debug.print("Component: {s}\n", .{path[start..]});
    }
}
```

**See Also:**
- 📚 [Complete constants documentation](./std.fs.md#constants)
- 📚 [std.fs.path practical guide](./std.fs.path.md#separator-handling)
- Related: `sep_posix` (always `/`), `sep_windows` (always `\`), `isSep()` (check function)
