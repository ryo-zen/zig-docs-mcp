# std.fs.path.delimiter_posix

**POSIX PATH delimiter (always `:`)**

```zig
pub const delimiter_posix: u8 = ':';
```

Platform-independent constant for POSIX PATH delimiter.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("POSIX delimiter: {c}\n", .{std.fs.path.delimiter_posix}); // ':'
}
```

**See Also:**
- 📚 [Complete constants documentation](./std.fs.md#constants)
- Related: `delimiter`, `delimiter_windows`
