# std.fs.path.delimiter_windows

**Windows PATH delimiter (always `;`)**

```zig
pub const delimiter_windows: u8 = ';';
```

Platform-independent constant for Windows PATH delimiter.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Windows delimiter: {c}\n", .{std.fs.path.delimiter_windows}); // ';'
}
```

**See Also:**
- 📚 [Complete constants documentation](./std.fs.md#constants)
- Related: `delimiter`, `delimiter_posix`
