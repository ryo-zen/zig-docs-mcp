# std.fs.path.extension

**Get the file extension from a path**

```zig
pub fn extension(path: []const u8) []const u8
```

Returns the file extension including the dot (`.`). Returns empty string if no extension. Returns a slice into the original path - **no allocation**.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    const files = [_][]const u8{
        "document.txt",      // → ".txt"
        "archive.tar.gz",    // → ".gz" (only last extension!)
        ".gitignore",        // → "" (dotfiles have no extension)
        ".config.json",      // → ".json"
        "no_extension",      // → ""
        "trailing.",         // → "."
    };

    for (files) |file| {
        const ext = std.fs.path.extension(file);
        std.debug.print("{s} → '{s}'\n", .{ file, ext });
    }
}
```

**Important Rules:**
1. **Includes the dot**: Returns `".txt"`, not `"txt"`
2. **Only last extension**: `"file.tar.gz"` → `".gz"`, not `".tar.gz"`
3. **Dotfiles**: `".gitignore"` → `""` (no extension)
4. **Hidden files with ext**: `".config.json"` → `".json"` ✓

**See Also:**
- 📚 [Complete extension documentation](./std.fs.md#pub-fn-extensionpath-const-u8-const-u8)
- 📚 [std.fs.path practical guide](./std.fs.path.md#gotcha-extension-includes-the-dot)
- Related: `stem` (filename without extension), `basename`
