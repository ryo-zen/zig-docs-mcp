# Filesystem Migration Guide (0.16)

## Core Change: Io Parameter Required

All filesystem operations now require an `io: Io` parameter. This enables async I/O and cross-platform abstractions.

## Basic Setup

**Standard Io initialization:**
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
defer threaded.deinit();
const io = threaded.io();
```

## API Changes

### Current Working Directory

**Before:**
```zig
const dir = std.fs.cwd();
```

**After:**
```zig
const dir = std.Io.Dir.cwd();
```

### Creating Directories

**Before:**
```zig
try dir.makePath("foo/bar/baz");
```

**After:**
```zig
try dir.createDirPath(io, "foo/bar/baz");
```

**Method rename:** `makePath` → `createDirPath`

### Creating Files

**Before:**
```zig
const file = try dir.createFile("test.txt", .{});
defer file.close();
```

**After:**
```zig
const file = try dir.create(io, "test.txt", .{});
defer file.close(io);
```

### Opening Files

**Before:**
```zig
const file = try dir.openFile("test.txt", .{});
defer file.close();
```

**After:**
```zig
const file = try dir.open(io, "test.txt", .{});
defer file.close(io);
```

### Deleting Directory Trees

**Before:**
```zig
try dir.deleteTree("old_dir");
```

**After:**
```zig
try dir.removeTree(io, "old_dir");
```

**Method rename:** `deleteTree` → `removeTree`

### Reading Files

**Before:**
```zig
const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();

var buffer: [1024]u8 = undefined;
const bytes_read = try file.readAll(&buffer);
```

**After:**
```zig
const file = try std.Io.Dir.cwd().open(io, "data.txt", .{});
defer file.close(io);

var buffer: [1024]u8 = undefined;
const bytes_read = try file.readAll(io, &buffer);
```

### Writing Files

**Before:**
```zig
const file = try std.fs.cwd().createFile("output.txt", .{});
defer file.close();

try file.writeAll("Hello, World!");
```

**After:**
```zig
const file = try std.Io.Dir.cwd().create(io, "output.txt", .{});
defer file.close(io);

try file.writeAll(io, "Hello, World!");
```

## Complete Example

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const dir = std.Io.Dir.cwd();
    const test_dir = "test_mkdir_016/sub";

    // Create directory tree
    try dir.createDirPath(io, test_dir);

    // Create a file
    const file = try dir.create(io, "test_mkdir_016/test.txt", .{});
    defer file.close(io);

    // Write to file
    try file.writeAll(io, "Hello from Zig 0.16!");

    std.debug.print("File operations complete\n", .{});
}
```

## Alternative: std.posix for Simple Operations

For simple synchronous file operations without async overhead, use `std.posix`:

```zig
const std = @import("std");

pub fn main() !void {
    // Open file
    const fd = try std.posix.open("file.txt", .{ .ACCMODE = .RDONLY }, 0);
    defer std.posix.close(fd);

    // Read file
    var buffer: [1024]u8 = undefined;
    const bytes_read = try std.posix.read(fd, &buffer);

    std.debug.print("Read {} bytes\n", .{bytes_read});
}
```

### When to use std.posix:
- Simple file reads without buffering
- Low-level syscalls
- No need for async I/O
- Performance-critical synchronous code

### When to use std.Io.Dir:
- Cross-platform code
- Async operations
- High-level file operations
- Integration with Io ecosystem

## Method Renames Summary

| Before (0.13-0.14) | After (0.16) |
|-------------------|--------------|
| `makePath(path)` | `createDirPath(io, path)` |
| `deleteTree(path)` | `removeTree(io, path)` |
| `createFile(path, opts)` | `create(io, path, opts)` |
| `openFile(path, opts)` | `open(io, path, opts)` |
| `file.close()` | `file.close(io)` |
| `file.readAll(buf)` | `file.readAll(io, buf)` |
| `file.writeAll(data)` | `file.writeAll(io, data)` |

## Common Errors

### Error: "expected 2 arguments, found 1"

```zig
// Wrong
try dir.createDirPath("foo/bar");

// Fixed
try dir.createDirPath(io, "foo/bar");
```

### Error: "no field 'makePath' in struct"

```zig
// Wrong
try dir.makePath("foo/bar");

// Fixed
try dir.createDirPath(io, "foo/bar");
```

### Error: "std.fs.cwd not found"

```zig
// Wrong
const dir = std.fs.cwd();

// Fixed
const dir = std.Io.Dir.cwd();
```

## Migration Checklist

- [ ] Add Io.Threaded setup to main()
- [ ] Replace `std.fs.cwd()` → `std.Io.Dir.cwd()`
- [ ] Add `io` parameter to all dir methods
- [ ] Rename `makePath` → `createDirPath`
- [ ] Rename `deleteTree` → `removeTree`
- [ ] Rename `createFile` → `create`
- [ ] Rename `openFile` → `open`
- [ ] Add `io` to `file.close()`
- [ ] Add `io` to file read/write operations
- [ ] Consider `std.posix` for simple cases
- [ ] Test all file operations
