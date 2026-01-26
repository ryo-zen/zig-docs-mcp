# Zig 0.16 Migration Guide

## Major Breaking Changes Overview

Zig 0.16 introduces a unified I/O interface (`std.Io`) that fundamentally changes how programs interact with the operating system. This is the largest breaking change in Zig's history.

## Quick Reference

### 1. ArrayList - Allocator Parameter Required

**Before (0.13-0.14):**
```zig
var list = std.ArrayList(u32).init(allocator);
try list.append(42);
list.deinit();
```

**After (0.16):**
```zig
var list: std.ArrayList(u32) = .{};
try list.append(allocator, 42);
list.deinit(allocator);
```

### 2. Networking - Moved to std.Io.net

**Before:**
```zig
const addr = try std.net.Address.parseIp4("127.0.0.1", 8080);
```

**After:**
```zig
const net = std.Io.net;
const addr = try net.IpAddress.parse("127.0.0.1", 8080);
```

### 3. Filesystem - Requires Io Parameter

**Before:**
```zig
const dir = std.fs.cwd();
try dir.makePath("foo/bar");
```

**After:**
```zig
var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
defer threaded.deinit();
const io = threaded.io();

const dir = std.Io.Dir.cwd();
try dir.createDirPath(io, "foo/bar");
```

### 4. Time - Through Io.Clock

**Before:**
```zig
const timestamp = std.time.timestamp();
```

**After (Simple):**
```zig
pub fn getTime() i64 {
    const io = std.Io.Threaded.global_single_threaded.ioBasic();
    const ts = std.Io.Clock.real.now(io) catch return 0;
    return ts.toSeconds();
}
```

**After (With Io):**
```zig
const ts = try std.Io.Clock.real.now(io);
const seconds = ts.toSeconds();
```

### 5. Low-Level Alternative - std.posix

For simple synchronous operations without async overhead:
```zig
const fd = try std.posix.open("file.txt", .{ .ACCMODE = .RDONLY }, 0);
defer std.posix.close(fd);
const bytes = try std.posix.read(fd, buffer);
```

## Migration Strategy

### Option A: Full Migration (Recommended for Long-Term)
1. Set up `std.Io.Threaded` in your main function
2. Pass `io` parameter through your call stack
3. Update all fs/net/time operations to use Io
4. Benefits: Future-proof, async-ready, cross-platform

### Option B: Minimal Migration (Quick Fix)
1. Use `std.posix` for simple file operations
2. Keep ArrayList changes (mandatory)
3. Gradually migrate to Io as needed
4. Benefits: Faster migration, less code churn

### Option C: Hybrid Approach (Practical)
1. Use Io for network/async operations
2. Use std.posix for simple file I/O
3. Update ArrayList everywhere (mandatory)
4. Benefits: Best of both worlds

## Detailed Migration Guides

- [ArrayList Changes](migration_arraylist.md)
- [Filesystem Migration](migration_filesystem.md)
- [Networking Migration](migration_networking.md)
- [Time/Timestamp Migration](migration_time.md)
- [Common Patterns & Boilerplate](migration_patterns.md)

## Common Pitfalls

1. **Forgetting allocator in ArrayList methods** - All methods now need allocator
2. **Missing io parameter** - Most fs/net operations need it
3. **Method renames** - `makePath` → `createDirPath`, etc.
4. **Import changes** - `std.net` → `std.Io.net`
5. **Time API** - No more simple `std.time.timestamp()`

## When to Use What

| Use Case | 0.16 Solution | Rationale |
|----------|---------------|-----------|
| Simple file read | `std.posix.open/read` | No async overhead |
| Network server | `std.Io.net` + Io | Async-ready |
| Directory operations | `std.Io.Dir` + io | Cross-platform |
| Current timestamp | `std.Io.Clock.real.now(io)` | Unified interface |
| ArrayList operations | Pass allocator | Mandatory change |

## Testing Your Migration

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test ArrayList
    var list: std.ArrayList(u32) = .{};
    defer list.deinit(allocator);
    try list.append(allocator, 42);

    // Test Io
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Test filesystem
    const dir = std.Io.Dir.cwd();
    try dir.createDirPath(io, "test_dir");

    std.debug.print("Migration successful!\n", .{});
}
```

## Version Detection

```zig
const builtin = @import("builtin");

comptime {
    if (builtin.zig_version.minor < 16) {
        @compileError("This code requires Zig 0.16+");
    }
}
```
