# std.fs.path.WindowsPath2

**Result of parsing a Windows path**

```zig
pub fn WindowsPath2(comptime T: type) type {
    return struct {
  kind: Win32PathType,
  root_slice: []const T,
  is_abs: bool,
    };
}
```

Structure containing parsed Windows path information.

**Fields:**
- `kind` - Path classification (see `Win32PathType`)
- `root_slice` - Root component (drive letter, UNC prefix, etc.)
- `is_abs` - Whether the path is absolute

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    const path = "C:\\Users\\Documents\\file.txt";
    const parsed = std.fs.path.parsePathWindows(u8, path);

    std.debug.print("Kind: {}\n", .{parsed.kind});        // drive_absolute
    std.debug.print("Root: {s}\n", .{parsed.root_slice}); // "C:\"
    std.debug.print("Is absolute: {}\n", .{parsed.is_abs}); // true
}
```

**Use Case - Path Analysis:**
```zig
const std = @import("std");

pub fn analyzeWindowsPath(path: []const u8) void {
    const parsed = std.fs.path.parsePathWindows(u8, path);

    switch (parsed.kind) {
  .drive_absolute => std.debug.print("Absolute path with drive: {s}\n", .{parsed.root_slice}),
  .unc_absolute => std.debug.print("UNC path: {s}\n", .{parsed.root_slice}),
  .relative => std.debug.print("Relative path (no root)\n", .{}),
  else => std.debug.print("Other path type\n", .{}),
    }
}
```

**See Also:**
- 📚 [Complete types documentation](./std.fs.md#path-parsing-result-types)
- Related: `Win32PathType`, `parsePathWindows`, `PosixPath`
