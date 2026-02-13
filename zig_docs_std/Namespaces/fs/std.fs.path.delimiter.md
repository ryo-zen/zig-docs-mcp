# std.fs.path.delimiter

**Platform-native PATH list delimiter**

```zig
pub const delimiter: u8
```

The character used to separate paths in PATH-like environment variables.

**Values:**
- `:` on POSIX (e.g., `/usr/bin:/usr/local/bin`)
- `;` on Windows (e.g., `C:\bin;C:\tools`)

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("PATH delimiter: {c}\n", .{std.fs.path.delimiter});
    // POSIX: ':'
    // Windows: ';'
}
```

**Use Case - Split PATH:**
```zig
const std = @import("std");

pub fn printPathEntries(path_var: []const u8) void {
    var it = std.mem.splitScalar(u8, path_var, std.fs.path.delimiter);
    while (it.next()) |entry| {
  std.debug.print("PATH entry: {s}\n", .{entry});
    }
}
```

**See Also:**
- 📚 [Complete constants documentation](./std.fs.md#constants)
- Related: `delimiter_posix`, `delimiter_windows`
