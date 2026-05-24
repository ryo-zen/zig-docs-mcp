# std.fs.path.relative

**Compute the relative path from one location to another**

```zig
pub fn relative(
    gpa: Allocator,
    cwd: []const u8,
    environ_map: ?*const std.process.Environ.Map,
    from: []const u8,
    to: []const u8,
) ![]u8
```

Returns the relative path from `from` to `to`. **Allocates memory** - caller must free.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const cwd = try std.process.currentPathAlloc(std.testing.io, allocator);
    defer allocator.free(cwd);

    const rel = try std.fs.path.relative(
  allocator,
  cwd,
  null, // No environment map needed for simple case
  "/usr/local/bin",
  "/usr/local/share/doc",
    );
    defer allocator.free(rel); // Must free!

    std.debug.print("Relative: {s}\n", .{rel});
    // Result: "../../share/doc"
}
```

**Parameters:**
- `gpa` - Allocator for result
- `cwd` - Current working directory
- `environ_map` - Environment variables (used on Windows for drive paths, can be `null`)
- `from` - Starting path
- `to` - Destination path

**Use Cases:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const cwd = "/home/user/projects";

    // From project root to src file
    const path1 = try std.fs.path.relative(
  allocator,
  cwd,
  null,
  "/home/user/projects",
  "/home/user/projects/src/main.zig",
    );
    defer allocator.free(path1);
    std.debug.print("{s}\n", .{path1}); // "src/main.zig"

    // Between sibling directories
    const path2 = try std.fs.path.relative(
  allocator,
  cwd,
  null,
  "/home/user/projects/src",
  "/home/user/projects/tests",
    );
    defer allocator.free(path2);
    std.debug.print("{s}\n", .{path2}); // "../tests"
}
```

**Platform Variants:**
- `relativePosix()` - POSIX-specific (simpler, no drive letters)
- `relativeWindows()` - Windows-specific (handles drives and UNC paths)

**See Also:**
- 📚 [Complete relative documentation](./std.fs.md#pub-fn-relativegpa-allocator-cwd-const-u8-environ_map-const-stdprocessenvironmap-from-const-u8-to-const-u8-u8)
- 📚 [std.fs.path practical guide](./std.fs.path.md#path-conversion)
- Related: `resolve` (normalize paths), `join` (combine paths)
