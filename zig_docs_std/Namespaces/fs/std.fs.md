# std.fs

📚 **[See Comprehensive Examples & Tests](../../Examples/)** - Complete runnable code demonstrating all fs path manipulation features

## Quick Start

### Most Common Patterns

**Extract Filename from Path**
```zig
const path = "src/utils/parser.zig";
const filename = std.fs.path.basename(path);
// Result: "parser.zig"
```

**Join Path Components**
```zig
const allocator = std.heap.page_allocator;
const full_path = try std.fs.path.join(allocator, &.{"src", "main.zig"});
defer allocator.free(full_path);
// Result: "src/main.zig" (or "src\main.zig" on Windows)
```

**Get File Extension**
```zig
const path = "document.tar.gz";
const ext = std.fs.path.extension(path);
// Result: ".gz"

const stem = std.fs.path.stem(path);
// Result: "document.tar"
```

**Check if Path is Absolute**
```zig
const is_abs1 = std.fs.path.isAbsolute("/usr/bin");      // true (POSIX)
const is_abs2 = std.fs.path.isAbsolute("C:\\Windows");   // true (Windows)
const is_abs3 = std.fs.path.isAbsolute("relative/path"); // false
```

**Parse Path Components**
```zig
const path = "/home/user/document.txt";
const parsed = std.fs.path.parsePath(path);

// Access components: root, dir, base, ext, name
// Platform-specific behavior (Windows vs POSIX)
```

### Common Operations Quick Reference

| Operation | Function | Example |
|-----------|----------|---------|
| Get filename | `basename()` | `std.fs.path.basename("a/b.txt")` → `"b.txt"` |
| Get directory | `dirname()` | `std.fs.path.dirname("a/b.txt")` → `"a"` |
| Get extension | `extension()` | `std.fs.path.extension("a.txt")` → `".txt"` |
| Get stem | `stem()` | `std.fs.path.stem("a.tar.gz")` → `"a.tar"` |
| Join paths | `join()` | `std.fs.path.join(alloc, &.{"a", "b"})` |
| Is absolute | `isAbsolute()` | `std.fs.path.isAbsolute("/usr")` → `true` |
| Compute relative | `relative()` | `std.fs.path.relative(alloc, cwd, env, from, to)` |

### ⚠️ Critical: File I/O Has Moved to std.Io.Dir in Zig 0.16

**In Zig 0.16, file and directory I/O operations moved from `std.fs` to `std.Io.Dir`:**

```zig
// ❌ OLD (pre-0.16) - No longer works
const file = try std.fs.cwd().openFile("data.txt", .{});

// ✅ NEW (0.16+) - Use std.Io.Dir
var da = std.heap.DebugAllocator(.{}){};
defer _ = da.deinit();

var threaded = std.Io.Threaded.init(da.allocator(), .{ .environ = .empty });
defer threaded.deinit();
const io = threaded.io();

const dir = std.Io.Dir.cwd();
const file = try dir.openFile(io, "data.txt", .{ .mode = .read_only });
defer file.close(io);
```

**What remains in std.fs (Zig 0.16):**
- Path manipulation utilities (`std.fs.path.*`)
- Path constants (`max_path_bytes`, `max_name_bytes`)
- Platform-specific path behavior

**For file/directory operations, see:**
- `std.Io.Dir` - Directory operations (open, create, iterate, etc.)
- `std.Io.File` - File operations (read, write, seek, stat, etc.)

---

## Overview

`std.fs` provides cross-platform path manipulation utilities for working with file system paths. As of Zig 0.16, this namespace focuses exclusively on path operations—actual file and directory I/O has moved to `std.Io.Dir` and `std.Io.File`.

**Key Characteristics:**
- **Cross-platform path handling** - Works correctly on POSIX, Windows, and WASI
- **Encoding-aware** - Handles POSIX (arbitrary u8), Windows (WTF-16/WTF-8), and WASI (UTF-8)
- **No allocation for simple ops** - Functions like `basename`, `dirname`, `extension` return slices
- **Composable** - Utilities can be chained for complex path manipulations
- **Safe** - Returns slices within original memory, no buffer overruns

**When to use std.fs.path:**
- Extracting components from file paths (directory, filename, extension)
- Joining path segments in a cross-platform way
- Checking whether paths are absolute or relative
- Converting between Windows and POSIX path conventions
- Iterating over path components
- Computing relative paths between two locations

**Related namespaces:**
- `std.Io.Dir` - **Use this for file/directory I/O in Zig 0.16+** (open, create, read, write, iterate)
- `std.Io.File` - File handle operations (read, write, seek, stat)
- `std.posix` - Low-level POSIX file system calls
- `std.mem` - General memory/slice utilities

---

## Path Encoding by Platform

**POSIX (Linux, macOS, BSD):**
- Paths are arbitrary sequences of `u8` with no particular encoding
- No validation of UTF-8 or any other encoding
- Path separator: `/`
- Absolute paths start with `/`

**Windows:**
- Native paths use WTF-16 (Wide Character) encoding
- Zig's `[]const u8` APIs use **WTF-8** encoding for cross-platform compatibility
- WTF-8 is a superset of UTF-8 that can losslessly roundtrip unpaired surrogates
- Path separator: `\` (but `/` often works)
- Absolute paths: `C:\...`, `\\?\...`, `\\.\...`, `\\server\share\...`

**WASI (WebAssembly System Interface):**
- Paths must be valid UTF-8 (Unicode scalar values only)
- Cannot represent paths with invalid UTF-8/UTF-16 sequences
- See https://github.com/WebAssembly/wasi-filesystem/issues/17#issuecomment-1430639353

---

## Component Extraction Functions

### `pub fn basename(path: []const u8) []const u8`

Returns the last component of a file path (the filename).

**Behavior:**
- Returns the portion after the last path separator
- If no separator exists, returns the entire path
- If path ends with separator, returns empty string
- Works on both POSIX and Windows paths (uses `native_os`)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("{s}\n", .{std.fs.path.basename("src/main.zig")});           // "main.zig"
    std.debug.print("{s}\n", .{std.fs.path.basename("/usr/local/bin/zig")});     // "zig"
    std.debug.print("{s}\n", .{std.fs.path.basename("C:\\Windows\\notepad.exe")}); // "notepad.exe"
    std.debug.print("{s}\n", .{std.fs.path.basename("no_slashes")});             // "no_slashes"
    std.debug.print("{s}\n", .{std.fs.path.basename("/trailing/")});             // ""
}
```

------

### `pub fn dirname(path: []const u8) ?[]const u8`

Strips the last component from a file path, returning the directory portion.

**Returns:**
- `null` if path has no directory component
- Slice of original path up to (but not including) last separator

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    if (std.fs.path.dirname("src/utils/parser.zig")) |dir| {
  std.debug.print("{s}\n", .{dir}); // "src/utils"
    }

    if (std.fs.path.dirname("/etc/passwd")) |dir| {
  std.debug.print("{s}\n", .{dir}); // "/etc"
    }

    if (std.fs.path.dirname("no_directory")) |dir| {
  std.debug.print("{s}\n", .{dir});
    } else {
  std.debug.print("null\n", .{}); // This executes - no directory component
    }
}
```

------

### `pub fn extension(path: []const u8) []const u8`

Searches for a file extension separated by `.` and returns the string after that `.`.

**Rules:**
- Files ending with `.` return `"."`
- Files starting with `.` and no other `.` return `""` (e.g., `.gitignore`)
- Hidden files with extensions work correctly (e.g., `.image.png` → `".png"`)
- Returns slice within original path (zero-allocation)

**Examples:**
- `"main.zig"` → `".zig"`
- `"src/main.zig"` → `".zig"`
- `".gitignore"` → `""`
- `".config.json"` → `".json"`
- `"archive.tar.gz"` → `".gz"` (only last extension)
- `"keep."` → `"."`
- `"no_extension"` → `""`

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("{s}\n", .{std.fs.path.extension("document.txt")});     // ".txt"
    std.debug.print("{s}\n", .{std.fs.path.extension("archive.tar.gz")});   // ".gz"
    std.debug.print("{s}\n", .{std.fs.path.extension(".gitignore")});       // ""
    std.debug.print("{s}\n", .{std.fs.path.extension(".vimrc.backup")});    // ".backup"
}
```

------

### `pub fn stem(path: []const u8) []const u8`

Returns the last component of the path without its extension (if any).

**Returns the filename without the final extension:**
- `"hello/world/lib.tar.gz"` → `"lib.tar"`
- `"hello/world/lib.tar"` → `"lib"`
- `"hello/world/lib"` → `"lib"`
- `".gitignore"` → `".gitignore"` (no extension)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("{s}\n", .{std.fs.path.stem("document.txt")});          // "document"
    std.debug.print("{s}\n", .{std.fs.path.stem("archive.tar.gz")});        // "archive.tar"
    std.debug.print("{s}\n", .{std.fs.path.stem("src/main.zig")});          // "main"
    std.debug.print("{s}\n", .{std.fs.path.stem(".bashrc")});               // ".bashrc"
}
```

------

## Path Construction Functions

### `pub fn join(allocator: Allocator, paths: []const []const u8) ![]u8`

Naively combines a series of paths with the native path separator. Allocates memory for the result.

**Parameters:**
- `allocator` - Allocator for result string
- `paths` - Slice of path components to join

**Returns:** Owned slice containing joined path (caller must free)

**Behavior:**
- Uses platform-native separator (`/` on POSIX, `\` on Windows)
- Does NOT normalize `..` or `.` components
- Does NOT check for absolute path conflicts
- Simply concatenates with separator

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const path1 = try std.fs.path.join(allocator, &.{"src", "utils", "parser.zig"});
    defer allocator.free(path1);
    std.debug.print("Path 1: {s}\n", .{path1}); // "src/utils/parser.zig" (POSIX)
                                           // "src\utils\parser.zig" (Windows)

    const path2 = try std.fs.path.join(allocator, &.{"/usr", "local", "bin"});
    defer allocator.free(path2);
    std.debug.print("Path 2: {s}\n", .{path2}); // "/usr/local/bin"

    const path3 = try std.fs.path.join(allocator, &.{"a", "b", "c", "d"});
    defer allocator.free(path3);
    std.debug.print("Path 3: {s}\n", .{path3}); // "a/b/c/d" (or a\b\c\d)
}
```

------

### `pub fn joinZ(allocator: Allocator, paths: []const []const u8) ![:0]u8`

Like `join()`, but returns a null-terminated slice (sentinel-terminated).

**Use case:** Passing to C APIs that require null-terminated strings.

**Example:**
```zig
const allocator = std.heap.page_allocator;
const c_path = try std.fs.path.joinZ(allocator, &.{"usr", "bin", "zig"});
defer allocator.free(c_path);
// c_path is [:0]u8 (null-terminated), can be passed to C functions
```

------

### `pub fn resolve(allocator: Allocator, paths: []const []const u8) ![]u8`

Like a series of `cd` statements executed one after another. Resolves `.` and `..` components.

**Platform dispatch:**
- On Windows: calls `resolveWindows()`
- On POSIX: calls `resolvePosix()`

**Behavior:**
- Processes paths left-to-right
- Absolute paths reset the accumulator
- Resolves `.` (current directory) and `..` (parent directory)
- May leave `..` components if path is relative or drive-relative

**Example:**
```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const resolved = try std.fs.path.resolve(allocator, &.{
  "/usr/local",
  "../share",
  "doc",
    });
    defer allocator.free(resolved);
    std.debug.print("Resolved: {s}\n", .{resolved}); // "/usr/share/doc"
}
```

------

## Path Analysis Functions

### `pub fn isAbsolute(path: []const u8) bool`

Returns whether the path is absolute (platform-specific).

**POSIX:**
- Absolute if starts with `/`

**Windows:**
- Absolute if starts with drive letter (`C:\...`)
- Or UNC path (`\\server\...`)
- Or device path (`\\.\...`)
- Or extended-length path (`\\?\...`)

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("/usr/bin")});       // true (POSIX)
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("C:\\Windows")});    // true (Windows)
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("relative/path")});  // false
    std.debug.print("{}\n", .{std.fs.path.isAbsolute("./current")});      // false
}
```

------

### `pub fn isSep(byte: u8) bool`

Returns whether the given byte is a valid path separator for the current platform.

**POSIX:** Only `/` is a separator
**Windows:** Both `\` and `/` are separators

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("{}\n", .{std.fs.path.isSep('/')});   // true (all platforms)
    std.debug.print("{}\n", .{std.fs.path.isSep('\\')});  // true on Windows, false on POSIX
    std.debug.print("{}\n", .{std.fs.path.isSep('a')});   // false
}
```

------

### `pub fn parsePath(path: []const u8) (WindowsPath2(u8) or PosixPath)`

Parses a path into its components. Return type is platform-specific.

**On Windows:** Returns `WindowsPath2(u8)` with fields:
- `kind` - Path type (unc, c_relative, drive_relative, etc.)
- `root_slice` - Root component (drive, UNC prefix, etc.)
- `is_abs` - Whether path is absolute

**On POSIX:** Returns `PosixPath` with simpler structure

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const path = "/home/user/document.txt";
    const parsed = std.fs.path.parsePath(path);

    // Use parsed.* fields to inspect path structure
    // (exact fields depend on platform)
}
```

------

## Path Conversion Functions

### `pub fn relative(gpa: Allocator, cwd: []const u8, environ_map: ?*const std.process.Environ.Map, from: []const u8, to: []const u8) ![]u8`

Returns the relative path from `from` to `to`.

**Parameters:**
- `gpa` - Allocator for result
- `cwd` - Current working directory
- `environ_map` - Environment variables (used on Windows for drive paths)
- `from` - Starting path
- `to` - Destination path

**Returns:** Allocated string (caller must free)

**Example:**
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
    defer allocator.free(rel);

    std.debug.print("Relative: {s}\n", .{rel}); // "../../share/doc"
}
```

------

## Platform-Specific Functions

### Windows Path Functions

#### `pub fn basenameWindows(path: []const u8) []const u8`
Windows-specific basename extraction (recognizes both `/` and `\`).

#### `pub fn dirnameWindows(path: []const u8) ?[]const u8`
Windows-specific dirname extraction.

#### `pub fn isAbsoluteWindows(path: []const u8) bool`
Windows-specific absolute path check.

#### `pub fn parsePathWindows(comptime T: type, path: []const T) WindowsPath2(T)`
Parse a Windows path (works with `u8` or `u16` slices).

#### `pub fn resolveWindows(allocator: Allocator, paths: []const []const u8) ![]u8`
Resolve a Windows path (handles drive letters, UNC paths, etc.).

**Windows-specific behavior:**
- Canonicalizes separators to `\`
- Canonicalizes drive letters to uppercase
- Handles `..` relative to drive roots
- May preserve `..` components in drive-relative paths

------

### POSIX Path Functions

#### `pub fn basenamePosix(path: []const u8) []const u8`
POSIX-specific basename (only recognizes `/`).

#### `pub fn dirnamePosix(path: []const u8) ?[]const u8`
POSIX-specific dirname.

#### `pub fn isAbsolutePosix(path: []const u8) bool`
POSIX-specific absolute check (true if starts with `/`).

#### `pub fn parsePathPosix(path: []const u8) PosixPath`
Parse a POSIX path into components.

#### `pub fn resolvePosix(allocator: Allocator, paths: []const []const u8) ![]u8`
Resolve a POSIX path (simple `..` and `.` resolution).

------

## Component Iteration

### `pub fn componentIterator(path: []const u8) NativeComponentIterator`

Returns an iterator over path components (platform-native).

**Iterator Methods:**
- `.next()` - Returns next component (or `null` when done)
- `.rest()` - Returns remaining unparsed path
- `.peek()` - Look at next component without consuming

**Example:**
```zig
const std = @import("std");

pub fn main() void {
    const path = "/usr/local/bin/zig";
    var it = std.fs.path.componentIterator(path);

    while (it.next()) |component| {
  std.debug.print("Component: {s}\n", .{component});
    }
    // Output:
    // Component: usr
    // Component: local
    // Component: bin
    // Component: zig
}
```

------

## Formatting Utilities

### `pub fn fmtUtf8(utf8: []const u8) std.fmt.Alt([]const u8, formatUtf8)`

Returns a formatter for potentially ill-formed UTF-8 strings. Replaces invalid UTF-8 sequences with U+FFFD (replacement character).

**Use case:** Safely printing paths that might contain invalid UTF-8.

**Example:**
```zig
const path_bytes = "\xFF\xFE invalid utf8";
std.debug.print("Path: {}\n", .{std.fs.path.fmtUtf8(path_bytes)});
// Ill-formed sequences replaced with �
```

------

### `pub fn fmtUtf16Le(utf16le: []const u16) std.fmt.Alt([]const u16, formatUtf16Le)`

Returns a formatter for potentially ill-formed UTF-16 LE strings. Converts to UTF-8 during formatting, replacing unpaired surrogates with U+FFFD.

**Use case:** Printing Windows native paths (WTF-16).

------

## Usage Patterns

### Pattern 1: Building Output Paths from Input Files

```zig
const std = @import("std");

pub fn getOutputPath(allocator: std.mem.Allocator, input_file: []const u8) ![]u8 {
    const dir = std.fs.path.dirname(input_file) orelse ".";
    const base = std.fs.path.stem(input_file);

    return std.fs.path.join(allocator, &.{dir, "output", base ++ ".out"});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const output = try getOutputPath(allocator, "src/parser.zig");
    defer allocator.free(output);

    std.debug.print("Output: {s}\n", .{output}); // "src/output/parser.out"
}
```

------

### Pattern 2: Cross-Platform Path Handling

```zig
const std = @import("std");

pub fn normalizePathSeparators(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    // Split by any separator, rejoin with native separator
    var components = std.ArrayList([]const u8).init(allocator);
    defer components.deinit();

    var it = std.fs.path.componentIterator(path);
    while (it.next()) |component| {
  try components.append(component);
    }

    return std.fs.path.join(allocator, components.items);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const mixed = "usr/local\\bin/zig";
    const normalized = try normalizePathSeparators(allocator, mixed);
    defer allocator.free(normalized);

    std.debug.print("Normalized: {s}\n", .{normalized});
    // POSIX: "usr/local/bin/zig"
    // Windows: "usr\local\bin\zig"
}
```

------

### Pattern 3: Iterating Path Components

```zig
const std = @import("std");

pub fn printPathHierarchy(path: []const u8) void {
    var it = std.fs.path.componentIterator(path);
    var depth: usize = 0;

    while (it.next()) |component| {
  const indent = depth * 2;
  var i: usize = 0;
  while (i < indent) : (i += 1) {
      std.debug.print(" ", .{});
  }
  std.debug.print("{s}\n", .{component});
  depth += 1;
    }
}

pub fn main() void {
    printPathHierarchy("/home/user/projects/myapp/src/main.zig");
    // Output:
    // home
    //   user
    //     projects
    //       myapp
    //         src
    //           main.zig
}
```

------

### Pattern 4: Changing File Extensions

```zig
const std = @import("std");

pub fn changeExtension(allocator: std.mem.Allocator, path: []const u8, new_ext: []const u8) ![]u8 {
    const dir = std.fs.path.dirname(path) orelse ".";
    const stem_only = std.fs.path.stem(path);

    const new_basename = try std.fmt.allocPrint(allocator, "{s}{s}", .{stem_only, new_ext});
    defer allocator.free(new_basename);

    return std.fs.path.join(allocator, &.{dir, new_basename});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const result = try changeExtension(allocator, "src/main.zig", ".o");
    defer allocator.free(result);

    std.debug.print("New path: {s}\n", .{result}); // "src/main.o"
}
```

------

## Types and Constants

### Path Type Enums

**`PathType` (enum)**
Represents the type of path on the native platform.

**`Win32PathType` (enum)**
Windows-specific path classification:
- `.unc_absolute` - UNC path (`\\server\share`)
- `.drive_absolute` - Absolute with drive (`C:\path`)
- `.drive_relative` - Drive-relative (`C:path`)
- `.rooted` - Rooted but drive-relative (`\path`)
- `.relative` - Fully relative (`path`)
- `.unc_relative` - UNC relative

------

### Path Parsing Result Types

**`WindowsPath2(T)` (struct)**
Result of parsing a Windows path.

**Fields:**
- `kind: Win32PathType` - Path classification
- `root_slice: []const T` - Root component (drive, UNC prefix, etc.)
- `is_abs: bool` - Whether path is absolute

------

**`PosixPath` (struct)**
Result of parsing a POSIX path (simpler than Windows).

------

**`ComponentIterator(T, S)` (struct)**
Generic iterator over path components. Platform-specific instantiations:
- `NativeComponentIterator` - Uses native separators
- Platform-specific variants for Windows/POSIX

**Methods:**
- `next() ?[]const T` - Get next component
- `peek() ?[]const T` - Look at next component without advancing
- `rest() []const T` - Get remaining unparsed path
- `previous() []const T` - Get previously returned component

------

### Constants

**`sep: u8`**
Native path separator character:
- `/` on POSIX
- `\` on Windows

------

**`sep_posix: u8 = '/'`**
POSIX path separator (always `/`).

------

**`sep_windows: u8 = '\\'`**
Windows path separator (backslash).

------

**`sep_str: []const u8`**
Native path separator as a string slice.

------

**`sep_str_posix: []const u8 = "/"`**
POSIX separator string.

------

**`sep_str_windows: []const u8 = "\\"`**
Windows separator string.

------

**`delimiter: u8`**
Native path list delimiter (`:` on POSIX, `;` on Windows).

------

**`delimiter_posix: u8 = ':'`**
POSIX PATH delimiter (colon).

------

**`delimiter_windows: u8 = ';'`**
Windows PATH delimiter (semicolon).

------

## Error Sets

### Path-Related Errors

Most path manipulation functions that return slices are infallible. Functions that allocate can return:

**`Allocator.Error`**
- `error.OutOfMemory` - Allocation failed

Functions like `relative()` may also return:
- `error.OutOfMemory`
- Plus any errors from underlying path resolution

------

## Debug Checklist

✅ **Free allocated paths** - `join()`, `resolve()`, `relative()` allocate memory - must free

✅ **Check for null returns** - `dirname()` can return `null` if no directory component exists

✅ **Platform-specific separators** - Don't hardcode `/` or `\` - use `std.fs.path.sep`

✅ **Extension includes the dot** - `extension()` returns `".txt"`, not `"txt"`

✅ **stem() only removes final extension** - `"file.tar.gz"` → stem is `"file.tar"`, not `"file"`

✅ **basename() can return empty** - If path ends with separator, basename is `""`

✅ **Paths are not normalized** - `join()` doesn't resolve `..` or `.` - use `resolve()` for that

✅ **Windows paths need WTF-8 encoding** - When interfacing with Windows APIs, ensure proper encoding

✅ **WASI paths must be valid UTF-8** - Invalid UTF-8 paths will fail on WASI

✅ **Component iteration skips empty components** - Multiple consecutive separators are handled gracefully

------

## Performance Tips

1. **Use slices, not allocations** - Prefer `basename()`, `dirname()`, `extension()` over rebuilding paths when possible:
   ```zig
   // Good: zero-allocation
   const name = std.fs.path.basename(path);

   // Unnecessary: allocates
   const parts = try std.fs.path.join(allocator, &.{std.fs.path.dirname(path) orelse ".", std.fs.path.basename(path)});
   ```

2. **Reuse allocator for batch operations** - If joining many paths, use an arena:
   ```zig
   var arena = std.heap.ArenaAllocator.init(base_allocator);
   defer arena.deinit();
   const allocator = arena.allocator();

   for (files) |file| {
 const path = try std.fs.path.join(allocator, &.{dir, file});
 // Use path...
   }
   // All paths freed at once by arena.deinit()
   ```

3. **Avoid repeated parsing** - Parse once, reuse components:
   ```zig
   const parsed = std.fs.path.parsePath(path);
   // Use parsed.* multiple times rather than re-parsing
   ```

4. **Use platform-specific functions when appropriate** - If you know the platform, `basenamePosix()` is slightly faster than `basename()` (no runtime dispatch).

5. **Don't use `resolve()` unless needed** - If you just need to join paths without normalization, `join()` is faster.

6. **Check `isAbsolute()` before `resolve()`** - Avoid expensive resolution if you only need to detect absolute paths.

------

## See Also

- **std.Io.Dir** - **Primary file/directory I/O in Zig 0.16+** (open, create, iterate, delete, rename)
- **std.Io.File** - File handle operations (read, write, seek, stat, metadata)
- **std.posix** - Low-level POSIX system calls (openat, unlinkat, etc.)
- **std.mem** - Memory utilities (slicing, comparison, searching)
- **std.fmt** - String formatting (useful when building paths with `allocPrint`)
- **std.process.currentPathAlloc** - Get current working directory
