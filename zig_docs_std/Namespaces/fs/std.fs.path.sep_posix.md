# std.fs.path.sep_posix

**POSIX path separator (always `/`)**

```zig
pub const sep_posix: u8 = '/';
```

Platform-independent constant for POSIX path separator.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("POSIX separator: {c}\n", .{std.fs.path.sep_posix}); // '/'
}
```

**See Also:**
- 📚 [Path separator documentation](./std.fs.path.sep.md)
- Related: `sep`, `sep_windows`
