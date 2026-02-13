# std.fs.path.dirname

**Extract the directory portion from a path**

```zig
pub fn dirname(path: []const u8) ?[]const u8
```

Strips the last component from a path, returning the directory portion. Returns `null` if path has no directory component. Returns a slice into the original path - **no allocation**.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    // With directory
    if (std.fs.path.dirname("src/utils/parser.zig")) |dir| {
  std.debug.print("Directory: {s}\n", .{dir}); // "src/utils"
    }

    // Root path
    if (std.fs.path.dirname("/etc/passwd")) |dir| {
  std.debug.print("Directory: {s}\n", .{dir}); // "/etc"
    }

    // No directory - returns null
    if (std.fs.path.dirname("file.txt")) |dir| {
  std.debug.print("Directory: {s}\n", .{dir});
    } else {
  std.debug.print("No directory component\n", .{}); // ← This executes
    }
}
```

**Return Values:**
- Some path → Directory portion without trailing separator
- No directory → `null`

**See Also:**
- 📚 [Complete dirname documentation](./std.fs.md#pub-fn-dirnamepath-const-u8-const-u8)
- 📚 [std.fs.path practical guide](./std.fs.path.md)
- Related: `basename`, `extension`, `stem`
