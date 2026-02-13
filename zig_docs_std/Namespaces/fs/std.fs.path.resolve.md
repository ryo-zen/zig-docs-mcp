# std.fs.path.resolve

**Normalize a path by resolving `.` and `..`**

```zig
pub fn resolve(allocator: Allocator, paths: []const []const u8) ![]u8
```

Like a series of `cd` commands executed one after another. Resolves `.` (current directory) and `..` (parent directory). **Allocates memory** - caller must free.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const resolved = try std.fs.path.resolve(allocator, &.{
  "/usr/local",
  "../share",    // Go up from local
  "doc",
    });
    defer allocator.free(resolved); // Must free!

    std.debug.print("Resolved: {s}\n", .{resolved});
    // Result: "/usr/share/doc"
}
```

**Behavior:**
- ✅ Processes paths **left-to-right**
- ✅ Absolute path resets the accumulator
- ✅ Resolves `.` and `..` components
- ⚠️ May leave `..` if path is relative or drive-relative
- ⚠️ **Must free** the returned string!

**Example - Multiple Paths:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const result = try std.fs.path.resolve(allocator, &.{
  "projects",
  "myapp/src",
  "../lib",
  "./utils.zig",
    });
    defer allocator.free(result);

    std.debug.print("Result: {s}\n", .{result});
    // "projects/myapp/lib/utils.zig"
}
```

**Comparison with join:**
- `join(&.{"a", "..", "b"})` → `"a/../b"` (keeps `..`)
- `resolve(&.{"a", "..", "b"})` → `"b"` (resolves `..`)

**Platform Variants:**
- `resolvePosix()` - POSIX-specific resolution
- `resolveWindows()` - Windows-specific resolution (handles drives)

**See Also:**
- 📚 [Complete resolve documentation](./std.fs.md#pub-fn-resolveallocator-allocator-paths-const-const-u8-u8)
- 📚 [std.fs.path practical guide](./std.fs.path.md#path-construction)
- Related: `join` (no normalization), `relative` (compute relative paths)
