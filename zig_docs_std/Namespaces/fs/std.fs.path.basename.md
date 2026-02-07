# std.fs.path.basename

**Extract the filename from a path**

```zig
pub fn basename(path: []const u8) []const u8
```

Returns the last component of a file path (the filename). Returns a slice into the original path - **no allocation**.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    const paths = [_][]const u8{
        "src/main.zig",           // → "main.zig"
        "/usr/local/bin/zig",     // → "zig"
        "document.txt",           // → "document.txt"
        "/trailing/",             // → "" (empty)
    };

    for (paths) |path| {
        const filename = std.fs.path.basename(path);
        std.debug.print("{s} → {s}\n", .{ path, filename });
    }
}
```

**Platform Behavior:**
- POSIX: Only `/` is a separator
- Windows: Both `/` and `\` are separators

**Gotcha:** Trailing slash returns empty string!

**See Also:**
- 📚 [Complete basename documentation](./std.fs.md#pub-fn-basenamepath-const-u8-const-u8)
- 📚 [std.fs.path practical guide](./std.fs.path.md)
- Related: `dirname`, `extension`, `stem`
