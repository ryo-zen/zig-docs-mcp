# std.fs.path.ComponentIterator

**Iterator for path components**

```zig
pub const ComponentIterator = /* platform-specific type */
```

Iterator that yields path components one at a time. Created via `componentIterator(path)`.

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    const path = "/usr/local/bin/zig";
    var it = std.fs.path.componentIterator(path);

    while (it.next()) |component| {
  // Zig 0.16: component is a struct with .name field
  std.debug.print("Component: {s}\n", .{component.name});
    }
    // Output:
    // Component: usr
    // Component: local
    // Component: bin
    // Component: zig
}
```

**Iterator Methods:**

```zig
// Get next component (or null when done)
pub fn next() ?Component

// Look at next component without consuming it
pub fn peek() ?Component

// Get remaining unparsed path
pub fn rest() []const T

// Get the component that was just returned by next()
pub fn previous() []const T
```

**Zig 0.16 API Change:**
- **Old (pre-0.16):** `next()` returned `[]const u8`
- **New (0.16+):** `next()` returns `Component` struct with `.name` field

**Practical Example - Count Components:**
```zig
const std = @import("std");

pub fn countComponents(path: []const u8) usize {
    var it = std.fs.path.componentIterator(path);
    var count: usize = 0;
    while (it.next()) |_| count += 1;
    return count;
}

pub fn main() void {
    const count = countComponents("/home/user/projects/app/main.zig");
    std.debug.print("Components: {}\n", .{count}); // 5
}
```

**See Also:**
- 📚 [Complete ComponentIterator documentation](./std.fs.md#component-iteration)
- 📚 [std.fs.path practical guide](./std.fs.path.md#iterate-path-components)
- Related: `basename`, `dirname`
