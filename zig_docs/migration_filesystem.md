# Filesystem Migration Guide (0.16)

## Core Change: Io Parameter Required

All filesystem operations now require an `io: Io` parameter. This enables async I/O and cross-platform abstractions.

## Basic Setup

**Standard Io initialization:**
```zig
var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();
const allocator = da.allocator();

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
const file = try dir.createFile(io, "test.txt", .{});
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
const file = try dir.openFile(io, "test.txt", .{});
defer file.close(io);
```

### Deleting Directory Trees

**Before:**
```zig
try dir.deleteTree("old_dir");
```

**After:**
```zig
try dir.deleteTree(io, "old_dir");
```

**Signature change:** `deleteTree(path)` → `deleteTree(io, path)`

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
var buffer: [1024]u8 = undefined;
const bytes = try std.Io.Dir.cwd().readFile(io, "data.txt", &buffer);
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
try std.Io.Dir.cwd().writeFile(io, .{
    .sub_path = "output.txt",
    .data = "Hello, World!",
});
```

## Complete Example

```zig
const std = @import("std");

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    defer _ = da.deinit();
    const allocator = da.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const dir = std.Io.Dir.cwd();
    const test_dir = "test_mkdir_016/sub";

    // Create directory tree
    try dir.createDirPath(io, test_dir);

    // Create a file
    const file = try dir.createFile(io, "test_mkdir_016/test.txt", .{});
    defer file.close(io);

    // Write to file
    try file.writeStreamingAll(io, "Hello from Zig 0.16!");

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
| `deleteTree(path)` | `deleteTree(io, path)` |
| `createFile(path, opts)` | `createFile(io, path, opts)` |
| `openFile(path, opts)` | `openFile(io, path, opts)` |
| `file.close()` | `file.close(io)` |
| `dir.readFile(path, buf)` | `dir.readFile(io, path, buf)` |
| `dir.writeFile(options)` | `dir.writeFile(io, options)` |

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
- [ ] Add `io` to `deleteTree`
- [ ] Add `io` to `createFile`
- [ ] Add `io` to `openFile`
- [ ] Add `io` to `file.close()`
- [ ] Use `Dir.readFile`, `Dir.writeFile`, `File.reader`, `File.writer`, or `File.writeStreamingAll` for file contents
- [ ] Consider `std.posix` for simple cases
- [ ] Test all file operations
