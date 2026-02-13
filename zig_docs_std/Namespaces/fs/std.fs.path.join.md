# std.fs.path.join

**Join path components with native separator**

```zig
pub fn join(allocator: Allocator, paths: []const []const u8) ![]u8
```

Combines path components using the platform's native separator (`/` on POSIX, `\` on Windows). **Allocates memory** - caller must free.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const path = try std.fs.path.join(allocator, &.{
  "projects",
  "myapp",
  "src",
  "main.zig",
    });
    defer allocator.free(path); // Must free!

    std.debug.print("Path: {s}\n", .{path});
    // POSIX:   "projects/myapp/src/main.zig"
    // Windows: "projects\myapp\src\main.zig"
}
```

**Important Behaviors:**
- ✅ Uses platform-native separator automatically
- ✅ Works with any number of components
- ❌ Does **NOT** normalize `.` or `..` (use `resolve` for that)
- ⚠️ **Must free** the returned string!

**Example - Join doesn't normalize:**
```zig
const path = try std.fs.path.join(allocator, &.{ "a", "..", "b" });
defer allocator.free(path);
// Result: "a/../b" (not "b")
```

**See Also:**
- 📚 [Complete join documentation](./std.fs.md#pub-fn-joinallocator-allocator-paths-const-const-u8-u8)
- 📚 [std.fs.path practical guide](./std.fs.path.md#cross-platform-path-joining)
- Related: `joinZ` (null-terminated), `resolve` (normalizes paths)
