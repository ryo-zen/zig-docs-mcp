# std.fs.path.NativeComponentIterator

**Platform-specific component iterator type**

```zig
pub const NativeComponentIterator = ComponentIterator(native_os, u8);
```

Type alias for the native platform's component iterator. Uses the appropriate path convention for the current OS.

**Platform Behavior:**
- **POSIX systems** - Uses POSIX path rules (only `/` is separator)
- **Windows** - Uses Windows path rules (`/` and `\` are separators)

**Quick Example:**
```zig
const std = @import("std");

pub fn main() void {
    const path = "/usr/local/bin/zig";

    // NativeComponentIterator is the type returned by componentIterator()
    var it: std.fs.path.NativeComponentIterator = std.fs.path.componentIterator(path);

    while (it.next()) |component| {
        std.debug.print("Component: {s}\n", .{component.name});
    }
}
```

**Typical Usage:**
```zig
// Usually you don't need to specify the type explicitly
var it = std.fs.path.componentIterator(path);
while (it.next()) |component| {
    // Process component...
}
```

**See Also:**
- 📚 [ComponentIterator documentation](./std.fs.path.ComponentIterator.md)
- 📚 [Complete iteration documentation](./std.fs.md#component-iteration)
- Related: `ComponentIterator`, `componentIterator()`
