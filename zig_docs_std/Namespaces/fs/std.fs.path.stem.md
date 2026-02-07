# std.fs.path.stem

**Get filename without its extension**

```zig
pub fn stem(path: []const u8) []const u8
```

Returns the last component of the path without its final extension. Returns a slice into the original path - **no allocation**.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    const files = [_][]const u8{
        "document.txt",           // → "document"
        "archive.tar.gz",         // → "archive.tar" (keeps .tar!)
        "src/main.zig",           // → "main"
        ".bashrc",                // → ".bashrc" (no extension)
        "hello/world/lib.tar.gz", // → "lib.tar"
    };

    for (files) |file| {
        const name = std.fs.path.stem(file);
        std.debug.print("{s} → {s}\n", .{ file, name });
    }
}
```

**Comparison with basename:**
- `basename("src/file.txt")` → `"file.txt"` (full filename)
- `stem("src/file.txt")` → `"file"` (without extension)

**Important:** Only removes **final extension**!
- `"archive.tar.gz"` → `"archive.tar"` (not `"archive"`)

**See Also:**
- 📚 [Complete stem documentation](./std.fs.md#pub-fn-stempath-const-u8-const-u8)
- 📚 [std.fs.path practical guide](./std.fs.path.md#gotcha-stem-only-removes-final-extension)
- Related: `extension`, `basename`, `dirname`
