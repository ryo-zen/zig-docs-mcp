# std.Io.Dir

📚 **[See Comprehensive Examples & Tests](../../Examples/test_dir_comprehensive.zig)** - Runnable code demonstrating Dir operations

## Quick Start

### Open a File Relative to cwd
```zig
const dir = std.Io.Dir.cwd();
const file = try dir.openFile(io, "data.txt", .{});
defer file.close(io);
```

### Create a File
```zig
const dir = std.Io.Dir.cwd();
const file = try dir.createFile(io, "output.txt", .{});
defer file.close(io);
try file.writeStreamingAll(io, "hello\n");
```

### Read an Entire File (Preallocated Buffer)
```zig
const dir = std.Io.Dir.cwd();
var buf: [4096]u8 = undefined;
const contents = try dir.readFile(io, "data.txt", &buf);
// contents is a slice into buf
```

### Read an Entire File (Heap-Allocated)
```zig
const dir = std.Io.Dir.cwd();
const contents = try dir.readFileAlloc(io, "data.txt", allocator, .unlimited);
defer allocator.free(contents);
```

### Create a Directory Tree
```zig
const dir = std.Io.Dir.cwd();
try dir.createDirPath(io, "path/to/nested/dir");
```

⚠️ **Critical**: `createFile` overwrites an existing file by default. Use `access` to check existence first if you need to avoid clobbering.

---

## Overview

`std.Io.Dir` represents an open directory handle. It is the primary entry point for all filesystem operations in Zig's 0.16 I/O system — files are not opened directly by path, but through a `Dir` handle via `openFile` or `createFile`.

The most common starting point is `Dir.cwd()`, which returns a handle to the current working directory. All relative paths are resolved against whatever `Dir` handle you use.

**Key Characteristics:**
- **Handle-based**: Wraps an OS directory file descriptor. Relative paths are resolved against this handle.
- **Requires `Io`**: All mutating and I/O operations take an `Io` parameter. `cwd()` and `iterate()` are exceptions — they don't perform I/O.
- **Entry point for File**: You cannot open a `File` without a `Dir`. Use `dir.openFile()` or `dir.createFile()`.
- **Absolute path variants**: Most functions have an `Absolute` variant (e.g. `openFileAbsolute`) that takes an absolute path and no `Dir` handle.
- **Cross-platform**: Works on all platforms supported by Zig.

**When to use:**
- Whenever you need to read, create, delete, or rename files.
- When you need to create or traverse directory trees.
- As the foundation for any filesystem operation.

## Fields

`handle: Handle`

The underlying OS directory file descriptor. Opaque to most users — interact through the `Dir` API.

## Types

- **AccessOptions** — Options for `access` (e.g. read/write/execute checks).
- **CopyFileOptions** — Options for `copyFile`.
- **CreateDirPathOpenOptions** — Options for `createDirPathOpen`.
- **CreateFileAtomicOptions** — Options for atomic file creation.
- **CreatePathStatus** — Result of `createDirPathStatus` (`.created` or `.already_existed`).
- **Entry** — A directory entry yielded by `Iterator` (name + kind).
- **HardLinkOptions** — Options for `hardLink`.
- **Iterator** — Iterates over directory entries without allocating.
- **OpenOptions** — Options for `openDir`.
- **PrevStatus** — Result of `updateFile` indicating whether a copy was needed.
- **Reader** — Buffered reader for directory contents.
- **SelectiveWalker** — Recursive walker where the caller opts in to each subdirectory.
- **SetFileOwnerOptions** — Options for `setFileOwner`.
- **SetFilePermissionsOptions** — Options for `setFilePermissions`.
- **SetTimestampsNowOptions** — Options for `setTimestampsNow`.
- **SetTimestampsOptions** — Options for `setTimestamps`.
- **Stat** — Metadata for the directory itself.
- **StatFileOptions** — Options for `statFile`.
- **SymLinkFlags** — Flags for symbolic link creation.
- **Walker** — Recursive directory walker (allocator-based).
- **WriteFileOptions** — Options for `writeFile`.

## Values

| Name | Type | Description |
| :--- | :--- | :--- |
| `Handle` | type | Platform directory handle type. |
| `Permissions` | type | Cross-platform file permission representation. |
| `max_name_bytes` | usize | Maximum bytes in a single filename component on common filesystems. |
| `max_path_bytes` | usize | Maximum bytes in a full file path the OS will accept. |

## Lifecycle Functions

### `pub fn cwd() Dir`

Returns a handle to the current working directory. This does not perform I/O — it returns a static handle that the OS resolves on each subsequent operation.

**Example:**
```zig
const dir = std.Io.Dir.cwd();
```

------

### `pub fn close(dir: Dir, io: Io) void`

Closes the directory handle. Required for any `Dir` obtained via `openDir` or `createDirPathOpen`. Not required for `cwd()`.

------

### `pub fn closeMany(io: Io, dirs: []const Dir) void`

Closes multiple directory handles in a single call.

## File Operations

### `pub fn openFile(dir: Dir, io: Io, sub_path: []const u8, flags: File.OpenFlags) File.OpenError!File`

Opens an existing file for reading or writing. Does not create the file if it doesn't exist — use `createFile` for that.

**Example:**
```zig
const file = try dir.openFile(io, "data.txt", .{});
defer file.close(io);
```

------

### `pub fn createFile(dir: Dir, io: Io, sub_path: []const u8, flags: File.CreateFlags) File.OpenError!File`

Creates a new file, or overwrites an existing one, with write access.

**Example:**
```zig
const file = try dir.createFile(io, "output.txt", .{});
defer file.close(io);
try file.writeStreamingAll(io, "content\n");
```

------

### `pub fn createFileAtomic(dir: Dir, io: Io, sub_path: []const u8, options: CreateFileAtomicOptions) CreateFileAtomicError!File.Atomic`

Creates an unnamed ephemeral file that can be atomically materialized into `sub_path` on close. Useful for crash-safe writes: the file either fully appears or doesn't exist at all.

------

### `pub fn deleteFile(dir: Dir, io: Io, sub_path: []const u8) DeleteFileError!void`

Deletes a file. Returns an error if the path does not exist or is a directory.

**Example:**
```zig
defer dir.deleteFile(io, "temp.txt") catch {};
```

------

### `pub fn readFile(dir: Dir, io: Io, file_path: []const u8, buffer: []u8) ReadFileError![]u8`

Reads all contents of a file into a preallocated buffer. Returns a slice of `buffer` containing the data. Errors if the file is larger than `buffer`.

**Example:**
```zig
var buf: [4096]u8 = undefined;
const data = try dir.readFile(io, "config.txt", &buf);
```

------

### `pub fn readFileAlloc(dir: Dir, io: Io, sub_path: []const u8, gpa: Allocator, limit: Io.Limit) ReadFileAllocError![]u8`

Reads all contents of a file, allocating as needed. Caller owns the returned slice. Use `limit` to cap the maximum allocation (pass `.unlimited` if unconcerned).

**Example:**
```zig
const data = try dir.readFileAlloc(io, "large.bin", allocator, .unlimited);
defer allocator.free(data);
```

------

### `pub fn writeFile(dir: Dir, io: Io, options: WriteFileOptions) WriteFileError!void`

Writes content to a file using the creation flags provided in `options`. A convenience wrapper around create + write + close.

## Directory Operations

### `pub fn openDir(dir: Dir, io: Io, sub_path: []const u8, options: OpenOptions) OpenError!Dir`

Opens a subdirectory, returning a new `Dir` handle. Must be closed with `close`.

**Example:**
```zig
const sub = try dir.openDir(io, "subdir", .{});
defer sub.close(io);
const file = try sub.createFile(io, "nested.txt", .{});
defer file.close(io);
```

------

### `pub fn createDir(dir: Dir, io: Io, sub_path: []const u8, permissions: Permissions) CreateDirError!void`

Creates a single directory. Errors if parent directories do not exist.

------

### `pub fn createDirPath(dir: Dir, io: Io, sub_path: []const u8) CreateDirPathError!void`

Creates `sub_path` as a directory, including any missing parent directories (like `mkdir -p`).

**Example:**
```zig
try dir.createDirPath(io, "a/b/c");
```

------

### `pub fn createDirPathOpen(dir: Dir, io: Io, sub_path: []const u8, options: CreateDirPathOpenOptions) CreateDirPathOpenError!Dir`

Equivalent to `createDirPath` followed by `openDir`, atomically if possible. Returns the opened `Dir` handle.

------

### `pub fn createDirPathStatus(dir: Dir, io: Io, sub_path: []const u8, permissions: Permissions) CreateDirPathError!CreatePathStatus`

Same as `createDirPath` but returns whether the path already existed or was newly created.

------

### `pub fn deleteDir(dir: Dir, io: Io, sub_path: []const u8) DeleteDirError!void`

Removes an empty directory. Returns `error.DirNotEmpty` if it contains entries.

------

### `pub fn deleteTree(dir: Dir, io: Io, sub_path: []const u8) DeleteTreeError!void`

Recursively removes a directory and all its contents, regardless of whether it is a file, symlink, or directory.

**Example:**
```zig
defer dir.deleteTree(io, "temp_build") catch {};
```

------

### `pub fn deleteTreeMinStackSize(dir: Dir, io: Io, sub_path: []const u8) DeleteTreeError!void`

Like `deleteTree`, but keeps only one `Iterator` active at a time to minimize stack usage. Slower but safer for deeply nested trees.

## Rename and Copy

### `pub fn rename(old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8, io: Io) RenameError!void`

Moves or renames a file or directory. Source and destination can be in different directories.

**Example:**
```zig
try std.Io.Dir.rename(dir, "old.txt", dir, "new.txt", io);
```

------

### `pub fn renamePreserve(old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8, io: Io) RenamePreserveError!void`

Like `rename`, but preserves the destination if it already exists (platform-dependent semantics).

------

### `pub fn copyFile(source_dir: Dir, source_path: []const u8, dest_dir: Dir, dest_path: []const u8, io: Io, options: CopyFileOptions) CopyFileError!void`

Atomically copies a file from `source_path` to `dest_path`. The destination is created fresh.

------

### `pub fn updateFile(source_dir: Dir, io: Io, source_path: []const u8, dest_dir: Dir, dest_path: []const u8, options: CopyFileOptions) !PrevStatus`

Checks file size, mtime, and permissions. If they match, does nothing. Otherwise, atomically copies `source_path` to `dest_path`, preserving metadata so subsequent calls can skip the copy.

## Iteration and Walking

### `pub fn iterate(dir: Dir) Iterator`

Returns an `Iterator` over the entries in this directory. Does not perform I/O on its own — iteration happens through the `Iterator` interface. Does not allocate.

------

### `pub fn iterateAssumeFirstIteration(dir: Dir) Iterator`

Like `iterate`, but skips the initial cursor reset. Only use on a freshly opened `Dir` whose cursor has not been modified.

------

### `pub fn walk(dir: Dir, allocator: Allocator) Allocator.Error!Walker`

Recursively walks the directory tree depth-first. Returns entries for files, directories, and symlinks at all levels.

------

### `pub fn walkSelectively(dir: Dir, allocator: Allocator) !SelectiveWalker`

Recursive walk where the caller explicitly opts in to descending into each subdirectory. Useful for pruning large trees.

## Path Resolution

### `pub fn realPath(dir: Dir, io: Io, out_buffer: []u8) RealPathError!usize`

Resolves the canonicalized absolute path of this directory. Writes into `out_buffer`, returns byte count.

------

### `pub fn realPathFile(dir: Dir, io: Io, sub_path: []const u8, out_buffer: []u8) RealPathFileError!usize`

Resolves the canonicalized absolute path of `sub_path` relative to this `Dir`.

------

### `pub fn realPathFileAlloc(dir: Dir, io: Io, sub_path: []const u8, allocator: Allocator) RealPathFileAllocError![:0]u8`

Like `realPathFile`, but allocates the result. Caller owns the returned string.

------

### `pub fn readLink(dir: Dir, io: Io, sub_path: []const u8, buffer: []u8) ReadLinkError!usize`

Reads the target of a symbolic link at `sub_path`. Returns the number of bytes written to `buffer`.

## Access and Metadata

### `pub fn access(dir: Dir, io: Io, sub_path: []const u8, options: AccessOptions) AccessError!void`

Tests whether `sub_path` exists and whether the specified access modes (read/write/execute) are permitted. Returns `error.FileNotFound` if the path does not exist.

**Example:**
```zig
dir.access(io, "config.txt", .{}) catch |err| {
    if (err == error.FileNotFound) {
  // file doesn't exist, use defaults
    } else {
  return err;
    }
};
```

------

### `pub fn stat(dir: Dir, io: Io) StatError!Stat`

Returns metadata for the directory itself.

------

### `pub fn statFile(dir: Dir, io: Io, sub_path: []const u8, options: StatFileOptions) StatFileError!Stat`

Returns metadata for a file inside this directory without opening it.

------

### `pub fn setFilePermissions(dir: Dir, io: Io, sub_path: []const u8, new_permissions: File.Permissions, options: SetFilePermissionsOptions) SetFilePermissionsError!void`

Sets permissions on a file within this directory (equivalent to `fchmodat`).

------

### `pub fn setFileOwner(dir: Dir, io: Io, sub_path: []const u8, owner: ?File.Uid, group: ?File.Gid, options: SetFileOwnerOptions) SetOwnerError!void`

Sets ownership on a file within this directory (equivalent to `fchownat`).

------

### `pub fn setPermissions(dir: Dir, io: Io, new_permissions: File.Permissions) SetPermissionsError!void`

Sets permissions on the directory itself.

------

### `pub fn setOwner(dir: Dir, io: Io, owner: ?File.Uid, group: ?File.Gid) SetOwnerError!void`

Sets ownership on the directory itself.

------

### `pub fn setTimestamps(dir: Dir, io: Io, sub_path: []const u8, options: SetTimestampsOptions) SetTimestampsError!void`

Sets access and modification timestamps on a file within this directory.

------

### `pub fn setTimestampsNow(dir: Dir, io: Io, sub_path: []const u8, options: SetTimestampsNowOptions) SetTimestampsError!void`

Sets timestamps on a file to the current wall-clock time.

## Symbolic Links

### `pub fn symLink(dir: Dir, io: Io, target_path: []const u8, sym_link_path: []const u8, flags: SymLinkFlags) SymLinkError!void`

Creates a symbolic link at `sym_link_path` pointing to `target_path`.

------

### `pub fn symLinkAtomic(dir: Dir, io: Io, target_path: []const u8, sym_link_path: []const u8, flags: SymLinkFlags) !void`

Like `symLink`, but retries until success or a non-`PathAlreadyExists` error. Safe for concurrent creation.

------

### `pub fn hardLink(old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8, io: Io, options: HardLinkOptions) HardLinkError!void`

Creates a hard link from `new_sub_path` to an existing file at `old_sub_path`.

## Absolute Path Variants

Most functions have an `Absolute` variant for use without a `Dir` handle:

- `accessAbsolute(io, path, options)`
- `openFileAbsolute(io, path, flags)`
- `createFileAbsolute(io, path, flags)`
- `openDirAbsolute(io, path, options)`
- `createDirAbsolute(io, path, permissions)`
- `deleteFileAbsolute(io, path)`
- `deleteDirAbsolute(io, path)`
- `renameAbsolute(old_path, new_path, io)`
- `copyFileAbsolute(source, dest, io, options)`
- `symLinkAbsolute(io, target, link, flags)`
- `readLinkAbsolute(io, path, buffer)`
- `realPathFileAbsolute(io, path, buffer)`
- `realPathFileAbsoluteAlloc(io, path, allocator)`

These assert that the provided path is absolute.

## Usage Patterns

### Nested Directory with File
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
defer threaded.deinit();
const io = threaded.io();

const cwd = std.Io.Dir.cwd();
defer cwd.deleteTree(io, "build_out") catch {};

try cwd.createDirPath(io, "build_out/debug");

const sub = try cwd.openDir(io, "build_out/debug", .{});
defer sub.close(io);

const file = try sub.createFile(io, "app.bin", .{});
defer file.close(io);
try file.writeStreamingAll(io, "binary content");
```

### Safe Read with Existence Check
```zig
const cwd = std.Io.Dir.cwd();

cwd.access(io, "config.json", .{}) catch {
    // File missing — write defaults
    const file = try cwd.createFile(io, "config.json", .{});
    defer file.close(io);
    try file.writeStreamingAll(io, "{}");
};

var buf: [4096]u8 = undefined;
const config = try cwd.readFile(io, "config.json", &buf);
```

### Rename Across Directories
```zig
const src_dir = try cwd.openDir(io, "staging", .{});
defer src_dir.close(io);

const dst_dir = try cwd.openDir(io, "production", .{});
defer dst_dir.close(io);

try std.Io.Dir.rename(src_dir, "app.bin", dst_dir, "app.bin", io);
```

## Error Sets

- **AccessError** — Errors from `access` (FileNotFound, PermissionDenied, etc.).
- **CopyFileError** — Errors from file copy operations.
- **CreateDirError** — Errors from creating a single directory.
- **CreateDirPathError** — Errors from creating a directory tree.
- **CreateDirPathOpenError** — Errors from `createDirPathOpen`.
- **CreateFileAtomicError** — Errors from atomic file creation.
- **DeleteDirError** — Errors from removing a directory.
- **DeleteFileError** — Errors from removing a file.
- **DeleteTreeError** — Errors from recursive deletion.
- **HardLinkError** — Errors from hard link creation.
- **OpenError** — Errors from opening a directory.
- **PathNameError** — Invalid or unsupported path name.
- **ReadFileAllocError** — Errors from `readFileAlloc`.
- **ReadFileError** — Errors from `readFile`.
- **ReadLinkError** — Errors from reading a symlink target.
- **RealPathError** — Errors from path canonicalization.
- **RealPathFileAllocError** — Errors from `realPathFileAlloc`.
- **RealPathFileError** — Errors from `realPathFile`.
- **RenameError** — Errors from rename operations.
- **RenamePreserveError** — Errors from preserve-rename operations.
- **SetFileOwnerError** — Errors from changing file ownership.
- **SetFilePermissionsError** — Errors from changing file permissions.
- **SetOwnerError** — Errors from changing directory ownership.
- **SetPermissionsError** — Errors from changing directory permissions.
- **SetTimestampsError** — Errors from setting timestamps.
- **StatError** — Errors from stat on the directory.
- **StatFileError** — Errors from stat on a file within the directory.
- **SymLinkError** — Errors from symbolic link creation.
- **UpdateFileError** — Errors from `updateFile`.
- **WriteFileError** — Errors from `writeFile`.

## Debug Checklist

1. ✅ **Did you close opened dirs?** Any `Dir` from `openDir` or `createDirPathOpen` must be closed. `cwd()` does not.
2. ✅ **Relative vs absolute path?** Paths passed to `Dir` methods are relative to that handle. Use `Absolute` variants for absolute paths.
3. ✅ **createFile overwrites!** It does not error on existing files — use `access` first if you need to check.
4. ✅ **createDirPath vs createDir?** `createDir` requires all parent dirs to exist. `createDirPath` creates them (like `mkdir -p`).
5. ✅ **readFile buffer too small?** Use `readFileAlloc` if file size is unknown, or check with `statFile` first.
6. ✅ **deleteDir vs deleteTree?** `deleteDir` fails on non-empty dirs. `deleteTree` is recursive.

## Performance Tips

1. **Use `readFile` / `readFileAlloc` for small files** — they avoid the overhead of manually opening, reading, and closing when you just need the contents.
2. **Reuse `Dir` handles** — opening a directory is a syscall. Keep the handle alive for the duration of your operations against that directory.
3. **Prefer `createDirPathOpen` over separate create + open** — it's atomic where possible and saves a syscall.
4. **Use `updateFile` for build-style copies** — it skips the copy if size, mtime, and permissions already match, which is significant in incremental build scenarios.
5. **`deleteTreeMinStackSize` for deep trees** — standard `deleteTree` uses O(depth) stack space. Switch to the min-stack variant if you're walking very deep or unknown directory structures.

## See Also

- `std.Io.File` — The file handle type returned by `openFile` and `createFile`.
- `std.Io.Reader` — Buffered reader for file contents.
- `std.Io.Writer` — Buffered writer for file output.
- `std.Io` — The generic I/O interface required by all `Dir` operations.
- `std.Io.Threaded` — The standard thread-pool I/O backend.
