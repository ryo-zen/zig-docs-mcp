# std.fs.path

📚 **[See Parent Documentation](./std.fs.md)** - Complete std.fs namespace reference with all path functions

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Working code examples

---

## Overview

`std.fs.path` is a sub-namespace within `std.fs` that provides **cross-platform path manipulation utilities**. These functions handle the differences between operating system path conventions transparently.

### Path Encoding by Platform

**POSIX (Linux, macOS, BSD):**
- Paths are arbitrary sequences of `u8` with **no particular encoding**
- No validation of UTF-8 or any other encoding
- Path separator: `/`
- Example: `/home/user/document.txt`

**Windows:**
- Native paths use **WTF-16** (Wide Character) encoding
- Zig's `[]const u8` APIs use **WTF-8** encoding for cross-platform compatibility
- WTF-8 is a superset of UTF-8 that can losslessly roundtrip unpaired surrogates
- Path separator: `\` (but `/` often works)
- Example: `C:\Users\user\document.txt`

**WASI (WebAssembly System Interface):**
- Paths **must be valid UTF-8** (Unicode scalar values only)
- Cannot represent paths with invalid UTF-8/UTF-16 sequences
- Limitation documented: https://github.com/WebAssembly/wasi-filesystem/issues/17#issuecomment-1430639353

---

## Quick Reference

### Component Extraction

| Function | Description | Example |
|----------|-------------|---------|
| `basename(path)` | Get filename | `"src/main.zig"` → `"main.zig"` |
| `dirname(path)` | Get directory | `"src/main.zig"` → `"src"` |
| `extension(path)` | Get extension | `"file.txt"` → `".txt"` |
| `stem(path)` | Filename without ext | `"file.tar.gz"` → `"file.tar"` |

### Path Construction

| Function | Description | Returns |
|----------|-------------|---------|
| `join(alloc, parts)` | Join with separator | Allocated string |
| `joinZ(alloc, parts)` | Join + null-terminate | Allocated [:0]u8 |
| `resolve(alloc, paths)` | Normalize `.` and `..` | Allocated string |

### Path Analysis

| Function | Description | Returns |
|----------|-------------|---------|
| `isAbsolute(path)` | Check if absolute | bool |
| `isSep(byte)` | Check if separator | bool |
| `parsePath(path)` | Parse into components | Platform-specific struct |

### Path Conversion

| Function | Description | Returns |
|----------|-------------|---------|
| `relative(...)` | Compute relative path | Allocated string |
| `componentIterator(path)` | Iterate components | Iterator |

---

## Common Patterns

### Extract Filename from Any Path

```zig
const std = @import("std");

pub fn main() void {
    const paths = [_][]const u8{
        "/usr/local/bin/zig",
        "src/main.zig",
        "C:\\Windows\\notepad.exe",
        "document.txt",
    };

    for (paths) |path| {
        const filename = std.fs.path.basename(path);
        std.debug.print("{s} -> {s}\n", .{ path, filename });
    }
}
```

### Build Output Path from Input File

```zig
const std = @import("std");

pub fn getOutputPath(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const dir = std.fs.path.dirname(input) orelse ".";
    const name = std.fs.path.stem(input);

    const output_name = try std.fmt.allocPrint(allocator, "{s}.o", .{name});
    defer allocator.free(output_name);

    return std.fs.path.join(allocator, &.{ dir, "build", output_name });
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const output = try getOutputPath(allocator, "src/parser.zig");
    defer allocator.free(output);

    std.debug.print("Output: {s}\n", .{output}); // "src/build/parser.o"
}
```

### Cross-Platform Path Joining

```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Works correctly on both POSIX and Windows
    const path = try std.fs.path.join(allocator, &.{
        "projects",
        "myapp",
        "src",
        "main.zig",
    });
    defer allocator.free(path);

    // POSIX: "projects/myapp/src/main.zig"
    // Windows: "projects\myapp\src\main.zig"
    std.debug.print("Path: {s}\n", .{path});
}
```

### Iterate Path Components

```zig
const std = @import("std");

pub fn printPathStructure(path: []const u8) void {
    var it = std.fs.path.componentIterator(path);
    var depth: usize = 0;

    while (it.next()) |component| {
        // In Zig 0.16, component is a struct with .name field
        var i: usize = 0;
        while (i < depth * 2) : (i += 1) std.debug.print(" ", .{});
        std.debug.print("{s}\n", .{component.name});
        depth += 1;
    }
}

pub fn main() void {
    printPathStructure("/home/user/projects/app/main.zig");
    // Output:
    // home
    //   user
    //     projects
    //       app
    //         main.zig
}
```

### Change File Extension

```zig
const std = @import("std");

pub fn changeExtension(
    allocator: std.mem.Allocator,
    path: []const u8,
    new_ext: []const u8,
) ![]u8 {
    const dir = std.fs.path.dirname(path) orelse ".";
    const base = std.fs.path.stem(path);

    const new_basename = try std.fmt.allocPrint(allocator, "{s}{s}", .{ base, new_ext });
    defer allocator.free(new_basename);

    return std.fs.path.join(allocator, &.{ dir, new_basename });
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const result = try changeExtension(allocator, "src/main.zig", ".o");
    defer allocator.free(result);

    std.debug.print("Object file: {s}\n", .{result}); // "src/main.o"
}
```

---

## Platform-Specific Behavior

### Separator Handling

```zig
const std = @import("std");

pub fn main() void {
    // Platform-native separator
    const sep = std.fs.path.sep;

    // Always POSIX
    const posix_sep = std.fs.path.sep_posix; // '/'

    // Always Windows
    const win_sep = std.fs.path.sep_windows; // '\\'

    // Check if a byte is a separator on current platform
    std.debug.print("Is '/' a separator? {}\n", .{std.fs.path.isSep('/')});

    // On Windows, both '/' and '\\' are separators
    // On POSIX, only '/' is a separator
}
```

### Windows-Specific Functions

For Windows paths on POSIX systems (or vice versa), use platform-specific functions:

```zig
const std = @import("std");

pub fn main() void {
    const win_path = "C:\\Users\\Documents\\file.txt";

    // On POSIX, use Windows-specific function for Windows paths
    const filename = std.fs.path.basenameWindows(win_path);
    std.debug.print("Filename: {s}\n", .{filename}); // "file.txt"

    // Check if Windows path is absolute
    const is_abs = std.fs.path.isAbsoluteWindows(win_path);
    std.debug.print("Absolute? {}\n", .{is_abs}); // true
}
```

### POSIX-Specific Functions

```zig
const std = @import("std");

pub fn main() void {
    const posix_path = "/usr/local/bin/app";

    // Force POSIX interpretation even on Windows
    const filename = std.fs.path.basenamePosix(posix_path);
    std.debug.print("Filename: {s}\n", .{filename}); // "app"

    // Check if POSIX path is absolute
    const is_abs = std.fs.path.isAbsolutePosix(posix_path);
    std.debug.print("Absolute? {}\n", .{is_abs}); // true
}
```

---

## Important Gotchas

### 1. Extension Includes the Dot

```zig
const ext = std.fs.path.extension("file.txt");
// ext is ".txt", NOT "txt"
```

### 2. stem() Only Removes Final Extension

```zig
const stem = std.fs.path.stem("archive.tar.gz");
// stem is "archive.tar", NOT "archive"
```

### 3. basename() Can Return Empty String

```zig
const name = std.fs.path.basename("/path/to/dir/");
// name is "", NOT "dir"
```

### 4. dirname() Can Return null

```zig
const dir = std.fs.path.dirname("file.txt");
// dir is null - no directory component
```

### 5. join() Does NOT Normalize

```zig
const allocator = std.heap.page_allocator;
const path = try std.fs.path.join(allocator, &.{ "a", "..", "b" });
defer allocator.free(path);
// path is "a/../b", NOT "b"
// Use resolve() to normalize
```

### 6. Functions Return Slices, Not Allocations

```zig
// These do NOT allocate:
const name = std.fs.path.basename(path);
const ext = std.fs.path.extension(path);
const stem = std.fs.path.stem(path);
// They return slices into the original path string

// These DO allocate (must free):
const joined = try std.fs.path.join(allocator, &.{ "a", "b" });
const resolved = try std.fs.path.resolve(allocator, &.{ "a", "..", "b" });
const relative = try std.fs.path.relative(allocator, cwd, env, from, to);
```

---

## When to Use std.fs.path

**✅ Use std.fs.path when:**
- Extracting components from paths (filename, directory, extension)
- Joining path segments in a cross-platform way
- Checking if a path is absolute or relative
- Iterating over path components
- Computing relative paths

**❌ Don't use std.fs.path for:**
- Opening files → Use `std.Io.Dir` and `std.Io.File` (Zig 0.16+)
- Reading/writing files → Use `std.Io.File` methods
- Creating directories → Use `std.Io.Dir.makeDir()`
- Listing directory contents → Use `std.Io.Dir.iterate()`

**See also:**
- **[std.fs](./std.fs.md)** - Parent namespace with full documentation
- **std.Io.Dir** - Directory operations in Zig 0.16+ (open, create, iterate, delete)
- **std.Io.File** - File operations (read, write, seek, stat)
- **std.posix** - Low-level POSIX system calls

---

## Types Reference

### PathType
Enum representing the type of path on the native platform.

### Win32PathType
Windows-specific path classification:
- `.unc_absolute` - UNC path (`\\server\share`)
- `.drive_absolute` - Absolute with drive (`C:\path`)
- `.drive_relative` - Drive-relative (`C:path`)
- `.rooted` - Rooted but drive-relative (`\path`)
- `.relative` - Fully relative (`path`)

### WindowsPath2(T)
Result of parsing a Windows path. Contains:
- `kind: Win32PathType` - Path classification
- `root_slice: []const T` - Root component
- `is_abs: bool` - Whether path is absolute

### PosixPath
Result of parsing a POSIX path (simpler structure than Windows).

### ComponentIterator
Iterator over path components. Methods:
- `next() ?Component` - Get next component (Component has `.name` field in Zig 0.16)
- `peek() ?Component` - Look at next without advancing
- `rest() []const T` - Get remaining unparsed path
- `previous() []const T` - Get previously returned component

---

## Constants Reference

| Constant | Type | Value (POSIX) | Value (Windows) |
|----------|------|---------------|-----------------|
| `sep` | `u8` | `/` | `\` |
| `sep_posix` | `u8` | `/` | `/` |
| `sep_windows` | `u8` | `\` | `\` |
| `sep_str` | `[]const u8` | `"/"` | `"\\"` |
| `sep_str_posix` | `[]const u8` | `"/"` | `"/"` |
| `sep_str_windows` | `[]const u8` | `"\\"` | `"\\"` |
| `delimiter` | `u8` | `:` | `;` |
| `delimiter_posix` | `u8` | `:` | `:` |
| `delimiter_windows` | `u8` | `;` | `;` |

---

## Complete Function List

### Component Extraction
- `basename(path)` / `basenamePosix(path)` / `basenameWindows(path)`
- `dirname(path)` / `dirnamePosix(path)` / `dirnameWindows(path)`
- `extension(path)` - Get file extension
- `stem(path)` - Filename without extension

### Path Construction
- `join(allocator, paths)` - Join with native separator
- `joinZ(allocator, paths)` - Join with null terminator
- `resolve(allocator, paths)` - Normalize `.` and `..`
- `resolvePosix(allocator, paths)` - POSIX-specific resolve
- `resolveWindows(allocator, paths)` - Windows-specific resolve

### Path Analysis
- `isAbsolute(path)` / `isAbsolutePosix(path)` / `isAbsoluteWindows(path)`
- `isAbsolutePosixZ(path_c)` / `isAbsoluteWindowsZ(path_c)` / `isAbsoluteWindowsW(path_w)`
- `isSep(byte)` - Check if separator
- `parsePath(path)` - Parse into components
- `parsePathPosix(path)` - POSIX-specific parse
- `parsePathWindows(T, path)` - Windows-specific parse

### Path Conversion
- `relative(gpa, cwd, environ_map, from, to)` - Compute relative path
- `relativePosix(allocator, cwd, from, to)` - POSIX relative
- `relativeWindows(gpa, cwd, environ_map, from, to)` - Windows relative

### Iteration
- `componentIterator(path)` - Iterate over components

### Formatting
- `fmtUtf8(utf8)` - Format potentially ill-formed UTF-8
- `fmtUtf16Le(utf16le)` - Format UTF-16 LE to UTF-8
- `fmtJoin(paths)` - Formatter for joining paths

### Advanced (Windows)
- `getWin32PathType(T, path)` - Get Windows path type
- `diskDesignator(path)` - **Deprecated**, use `parsePath`
- `diskDesignatorWindows(path)` - **Deprecated**, use `parsePathWindows`
- `windowsParsePath(path)` - **Deprecated**, use `parsePathWindows`

---

For complete documentation with detailed examples for each function, see **[std.fs](./std.fs.md)**.
