# std.Io.File

📚 **[See Comprehensive Examples & Tests](../../Examples/test_file_comprehensive.zig)** - Runnable code demonstrating File read/write patterns

## Quick Start

### Write a File
```zig
const dir = std.Io.Dir.cwd();
const file = try dir.createFile(io, "output.txt", .{});
defer file.close(io);

var buffer: [4096]u8 = undefined;
var writer = file.writer(io, &buffer);
try writer.interface.writeAll("Hello, File!\n");
try writer.interface.flush();
```

### Read a File
```zig
const dir = std.Io.Dir.cwd();
const file = try dir.openFile(io, "output.txt", .{});
defer file.close(io);

var buf: [4096]u8 = undefined;
const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
const contents = buf[0..bytes_read];
```

### One-Shot Write (No Manual Buffer)
```zig
const dir = std.Io.Dir.cwd();
const file = try dir.createFile(io, "quick.txt", .{});
defer file.close(io);

try file.writeStreamingAll(io, "Written in one call.\n");
```

### One-Shot Positional Write
```zig
try file.writePositionalAll(io, "data at offset 0", 0);
```

⚠️ **Critical**: Always call `flush()` on a `Writer` before closing the file — buffered data is lost otherwise. Use `writeStreamingAll` or `writePositionalAll` for one-shot writes that flush implicitly.

---

## Overview

`std.Io.File` represents an open file handle in Zig's 0.16 I/O system. It is a lightweight struct wrapping an OS file descriptor (or equivalent handle). All operations require an `Io` interface parameter, which routes I/O through the active backend (`Threaded`, `Evented`, etc.).

Files are not opened or created by `File` itself — use `std.Io.Dir` to obtain a `File` via `openFile` or `createFile`.

**Key Characteristics:**
- **Handle-based**: Wraps a platform file descriptor; no internal state beyond the handle.
- **Requires `Io`**: Every operation takes an `Io` parameter — `File` alone cannot perform I/O.
- **Buffered via Writer/Reader**: Direct reads and writes go through `readStreaming` / `writeStreamingAll`. For repeated small writes, obtain a buffered `Writer` via `file.writer(io, &buffer)`.
- **Positional and streaming**: Supports both positional (pread/pwrite, thread-safe) and streaming (sequential seek position) access.
- **Cross-platform**: Works on all platforms supported by Zig.

**When to use:**
- Reading or writing regular files on disk.
- Working with stdin, stdout, stderr (`File.stdin()`, `File.stdout()`, `File.stderr()`).
- Any scenario where you need an open handle to an OS file.

## Fields

`handle: Handle`

The underlying OS file descriptor or platform handle. Opaque to most users — interact through the `File` API instead.

## Types

- **Atomic** — Atomic file operation helpers.
- **BlockSize** — Block size representation for the underlying filesystem.
- **CreateFlags** — Options for file creation (passed to `Dir.createFile`).
- **HardLinkOptions** — Options for creating hard links.
- **Kind** — File type classification (regular, directory, symlink, etc.).
- **Lock** — Lock type enum (`.shared`, `.exclusive`).
- **MemoryMap** — Memory-mapped file support.
- **OpenFlags** — Options for opening an existing file (passed to `Dir.openFile`).
- **OpenMode** — Read/write mode specification.
- **Reader** — Buffered reader wrapper returned by `file.reader()`.
- **SetTimestamp** — Timestamp value for `setTimestamps`.
- **SetTimestampsOptions** — Options for `setTimestamps`.
- **Stat** — File metadata (size, kind, permissions, timestamps).
- **Writer** — Buffered writer wrapper returned by `file.writer()`.

## Values

| Name | Type | Description |
| :--- | :--- | :--- |
| `Gid` | type | Group ID type for file ownership. |
| `Handle` | type | Platform file descriptor type. |
| `INode` | type | Inode number type. |
| `NLink` | type | Hard link count type. |
| `Permissions` | type | Cross-platform file permission representation. |
| `Uid` | type | User ID type for file ownership. |

## Lifecycle Functions

### `pub fn close(file: File, io: Io) void`

Closes the file handle, releasing the underlying OS resource. Must be called when the file is no longer needed. Idiomatic pattern:

```zig
const file = try dir.openFile(io, "data.txt", .{});
defer file.close(io);
```

------

### `pub fn closeMany(io: Io, files: []const File) void`

Closes multiple files in a single call. Useful when you have accumulated a batch of open handles.

## Streaming I/O Functions

### `pub fn readStreaming(file: File, io: Io, buffer: []const []u8) Reader.Error!usize`

Reads data from the file's current stream position into one or more buffers (scatter/gather I/O). Returns the total number of bytes read, or 0 at end of stream.

The `buffer` parameter is a slice of slices. For a single contiguous buffer, wrap it in a one-element array literal:

**Example:**
```zig
var buf: [4096]u8 = undefined;
const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
const data = buf[0..bytes_read];
```

------

### `pub fn writeStreamingAll(file: File, io: Io, bytes: []const u8) Writer.Error!void`

Writes all of `bytes` to the file at the current stream position and flushes. Equivalent to creating a streaming writer, calling `writeAll`, and flushing — but without requiring you to manage a buffer.

**Example:**
```zig
try file.writeStreamingAll(io, "Hello, World!\n");
```

------

### `pub fn reader(file: File, io: Io, buffer: []u8) Reader`

Returns a buffered `Reader` for sequential reading. Defaults to positional reading (thread-safe); falls back to streaming if positional syscalls are unavailable.

**Example:**
```zig
var buf: [4096]u8 = undefined;
var reader = file.reader(io, &buf);
// Use reader.interface for Reader methods (takeDelimiterInclusive, etc.)
```

------

### `pub fn readerStreaming(file: File, io: Io, buffer: []u8) Reader`

Same as `reader`, but explicitly initializes in streaming mode. Use this when you know positional reads are unavailable, to skip the failed syscall fallback.

------

### `pub fn writer(file: File, io: Io, buffer: []u8) Writer`

Returns a buffered `Writer` for sequential writing. Defaults to positional writing (thread-safe); falls back to streaming if positional syscalls are unavailable.

**Example:**
```zig
var buffer: [4096]u8 = undefined;
var writer = file.writer(io, &buffer);
try writer.interface.writeAll("buffered output\n");
try writer.interface.flush(); // required before close
```

------

### `pub fn writerStreaming(file: File, io: Io, buffer: []u8) Writer`

Same as `writer`, but explicitly initializes in streaming mode.

## Positional I/O Functions

Positional functions read or write at an explicit byte offset without affecting the file's stream position. This makes them safe to use from multiple threads concurrently.

### `pub fn readPositional(file: File, io: Io, buffer: []const []u8, offset: u64) ReadPositionalError!usize`

Reads into one or more buffers at the given byte offset. Returns 0 at end of file or if `buffer` has no space.

------

### `pub fn readPositionalAll(file: File, io: Io, buffer: []u8, offset: u64) ReadPositionalError!usize`

Reads at the given offset, retrying until `buffer` is full or end of file is reached.

------

### `pub fn writePositional(file: File, io: Io, buffer: []const []const u8, offset: u64) WritePositionalError!usize`

Writes from one or more buffers at the given byte offset (gather I/O).

------

### `pub fn writePositionalAll(file: File, io: Io, bytes: []const u8, offset: u64) WritePositionalError!void`

Writes all of `bytes` at the given offset, retrying until complete. Equivalent to creating a positional writer, writing, and flushing.

**Example:**
```zig
try file.writePositionalAll(io, "overwrite at 10", 10);
```

## File Metadata Functions

### `pub fn stat(file: File, io: Io) StatError!Stat`

Returns a `Stat` struct containing file metadata: size, kind (regular/directory/symlink), permissions, and access/modification timestamps.

**Example:**
```zig
const info = try file.stat(io);
std.debug.print("Size: {} bytes\n", .{info.size});
```

------

### `pub fn length(file: File, io: Io) LengthError!u64`

Returns the total size of the file in bytes.

------

### `pub fn realPath(file: File, io: Io, out_buffer: []u8) RealPathError!usize`

Resolves the canonicalized absolute path for the open file handle. Writes into `out_buffer` and returns the number of bytes written.

------

### `pub fn setLength(file: File, io: Io, new_length: u64) SetLengthError!void`

Truncates or extends the file to `new_length` bytes. Extended regions are filled with zeroes.

------

### `pub fn setPermissions(file: File, io: Io, new_permissions: Permissions) SetPermissionsError!void`

Sets file permissions (equivalent to `chmod`).

------

### `pub fn setOwner(file: File, io: Io, owner: ?Uid, group: ?Gid) SetOwnerError!void`

Sets file ownership (equivalent to `chown`). Pass `null` for either parameter to leave it unchanged.

------

### `pub fn setTimestamps(file: File, io: Io, options: SetTimestampsOptions) SetTimestampsError!void`

Sets access and modification timestamps. Granularity depends on the OS and filesystem; values exceeding the supported range are clamped.

------

### `pub fn setTimestampsNow(file: File, io: Io) SetTimestampsError!void`

Sets both access and modification timestamps to the current wall-clock time.

## Locking Functions

### `pub fn lock(file: File, io: Io, l: Lock) LockError!void`

Acquires a file lock (`.shared` or `.exclusive`). Blocks if an incompatible lock is held by another process. A process may hold only one lock type on a file at a time. The lock is released automatically when the process terminates.

------

### `pub fn tryLock(file: File, io: Io, l: Lock) LockError!bool`

Non-blocking lock attempt. Returns `true` if the lock was acquired, `false` if an incompatible lock is already held.

------

### `pub fn unlock(file: File, io: Io) void`

Releases the file lock. Assumes the file is currently locked.

------

### `pub fn downgradeLock(file: File, io: Io) LockError!void`

Atomically downgrades an exclusive lock to a shared lock without releasing it.

## Link and Special Functions

### `pub fn hardLink(file: File, io: Io, new_dir: Dir, new_sub_path: []const u8, options: HardLinkOptions) HardLinkError!void`

Creates a hard link to this file at `new_sub_path` within `new_dir`.

------

### `pub fn sync(file: File, io: Io) SyncError!void`

Flushes all pending file contents and metadata to the underlying filesystem (equivalent to `fsync`). Use when durability is required, e.g. after writing critical data.

------

### `pub fn isTty(file: File, io: Io) Io.Cancelable!bool`

Returns whether the file refers to a terminal device.

------

### `pub fn supportsAnsiEscapeCodes(file: File, io: Io) Io.Cancelable!bool`

Checks whether ANSI escape codes are supported without attempting to enable them.

------

### `pub fn enableAnsiEscapeCodes(file: File, io: Io) EnableAnsiEscapeCodesError!void`

Enables ANSI escape code support on the file handle (relevant on Windows).

------

### `pub fn createMemoryMap(file: File, io: Io, options: MemoryMap.CreateOptions) MemoryMap.CreateError!MemoryMap`

Creates a memory-mapped view of the file.

## Standard Streams

### `pub fn stdin() File`

Returns a `File` handle for standard input.

------

### `pub fn stdout() File`

Returns a `File` handle for standard output.

------

### `pub fn stderr() File`

Returns a `File` handle for standard error.

## Usage Patterns

### Full Read/Write Cycle
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();

var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
defer threaded.deinit();
const io = threaded.io();

const dir = std.Io.Dir.cwd();
const filename = "example.txt";
defer dir.deleteFile(io, filename) catch {};

// Write
{
    const file = try dir.createFile(io, filename, .{});
    defer file.close(io);

    var buffer: [1024]u8 = undefined;
    var writer = file.writer(io, &buffer);
    try writer.interface.writeAll("Hello, File!\n");
    try writer.interface.flush();
}

// Read back
{
    const file = try dir.openFile(io, filename, .{});
    defer file.close(io);

    var buf: [1024]u8 = undefined;
    const bytes_read = try file.readStreaming(io, &[_][]u8{&buf});
    const contents = buf[0..bytes_read];
    // contents == "Hello, File!\n"
}
```

### Positional Read/Write (Thread-Safe)
```zig
const file = try dir.createFile(io, "positional.dat", .{});
defer file.close(io);

// Write at specific offsets
try file.writePositionalAll(io, "AAAA", 0);
try file.writePositionalAll(io, "BBBB", 4);

// Read back from offset 4
var buf: [4]u8 = undefined;
_ = try file.readPositionalAll(io, &buf, 4);
// buf == "BBBB"
```

## Error Sets

- **DowngradeLockError** — Errors from downgrading an exclusive lock.
- **EnableAnsiEscapeCodesError** — Errors from enabling ANSI codes.
- **HardLinkError** — Errors from hard link creation.
- **LengthError** — Errors from retrieving file length.
- **LockError** — Errors from lock/unlock operations.
- **OpenError** — Errors from opening a file (returned by `Dir.openFile`).
- **ReadPositionalError** — Errors from positional reads.
- **RealPathError** — Errors from resolving the real path.
- **SeekError** — Errors from seeking within the file.
- **SetLengthError** — Errors from truncating or extending a file.
- **SetOwnerError** — Errors from changing file ownership.
- **SetPermissionsError** — Errors from changing file permissions.
- **SetTimestampsError** — Errors from setting timestamps.
- **StatError** — Errors from stat operations.
- **SyncError** — Errors from fsync.
- **WritePositionalError** — Errors from positional writes.

## Debug Checklist

1. ✅ **Did you flush?** Buffered `Writer` data is lost if you close without flushing.
2. ✅ **Did you close?** Always `defer file.close(io)` immediately after opening.
3. ✅ **Did you pass `io`?** Every `File` method requires the `Io` interface.
4. ✅ **Scatter/gather buffer format?** `readStreaming` and `readPositional` take `[]const []u8`, not `[]u8`. Wrap a single buffer: `&[_][]u8{&buf}`.
5. ✅ **Positional vs streaming?** Use positional functions (`readPositional`, `writePositional`) when multiple threads access the same file. Streaming functions share a seek position.

## Performance Tips

1. **Use positional I/O for concurrent access** — `readPositional` and `writePositional` don't move a shared seek cursor, so they're safe across threads without locking.
2. **Size your buffer to your workload** — A 4 KiB buffer matches typical filesystem block sizes. For large sequential reads, 64 KiB or more reduces syscall overhead.
3. **Prefer one-shot functions for small writes** — `writeStreamingAll` and `writePositionalAll` avoid the overhead of managing a `Writer` when you have all the data ready.
4. **Call `sync` sparingly** — `fsync` is expensive. Only use it when you need durability guarantees (e.g. after writing a database transaction). Normal `close` does not guarantee data is on disk.
5. **Reuse file handles** — Opening and closing files is relatively expensive. Keep handles open for the lifetime of the operation set.

## See Also

- `std.Io.Dir` — Directory operations; used to obtain `File` handles via `openFile` and `createFile`.
- `std.Io.Reader` — Buffered reader interface returned by `file.reader()`.
- `std.Io.Writer` — Buffered writer interface returned by `file.writer()`.
- `std.Io` — The generic I/O interface required by all `File` operations.
- `std.Io.Threaded` — The standard thread-pool I/O backend.
