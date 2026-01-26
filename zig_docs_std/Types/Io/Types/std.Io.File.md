# std.Io.File

### Fields

    handle: Handle

## Types

- Atomic
- BlockSize
- CreateFlags
- HardLinkOptions
- Kind
- Lock
- MemoryMap
- OpenFlags
- OpenMode
- Reader
- SetTimestamp
- SetTimestampsOptions
- Stat
- Writer

## Values

|             |     |                                                         |
|-------------|-----|---------------------------------------------------------|
| Gid         |     |                                                         |
| Handle      |     |                                                         |
| INode       |     |                                                         |
| NLink       |     |                                                         |
| Permissions |     | Cross-platform representation of permissions on a file. |
| Uid         |     |                                                         |

## Functions

`pub fn close(file: File, io: Io) void`  

`pub fn closeMany(io: Io, files: []const File) void`  

`pub fn createMemoryMap(file: File, io: Io, options: MemoryMap.CreateOptions) MemoryMap.CreateError!MemoryMap`  

`pub fn downgradeLock(file: File, io: Io) LockError!void`  
Assumes the file is already locked in exclusive mode. Atomically modifies the lock to be in shared mode, without releasing it.

`pub fn enableAnsiEscapeCodes(file: File, io: Io) EnableAnsiEscapeCodesError!void`  

`pub fn hardLink( file: File, io: Io, new_dir: Dir, new_sub_path: []const u8, options: HardLinkOptions, ) HardLinkError!void`  

`pub fn isTty(file: File, io: Io) Io.Cancelable!bool`  
Test whether the file refers to a terminal (similar to libc "isatty").

`pub fn length(file: File, io: Io) LengthError!u64`  
Retrieve the ending byte index of the file.

`pub fn lock(file: File, io: Io, l: Lock) LockError!void`  
Blocks when an incompatible lock is held by another process. A process may hold only one type of lock (shared or exclusive) on a file. When a process terminates in any way, the lock is released.

`pub fn readPositional(file: File, io: Io, buffer: []const []u8, offset: u64) ReadPositionalError!usize`  
Returns 0 on stream end or if `buffer` has no space available for data.

`pub fn readPositionalAll(file: File, io: Io, buffer: []u8, offset: u64) ReadPositionalError!usize`  
Equivalent to creating a positional reader and reading multiple times to fill `buffer`.

`pub fn readStreaming(file: File, io: Io, buffer: []const []u8) Reader.Error!usize`  
Returns 0 on stream end or if `buffer` has no space available for data.

`pub fn reader(file: File, io: Io, buffer: []u8) Reader`  
Defaults to positional reading; falls back to streaming.

`pub fn readerStreaming(file: File, io: Io, buffer: []u8) Reader`  
Positional is more threadsafe, since the global seek position is not affected, but when such syscalls are not available, preemptively initializing in streaming mode skips a failed syscall.

`pub fn realPath(file: File, io: Io, out_buffer: []u8) RealPathError!usize`  
Obtains the canonicalized absolute path name corresponding to an open file handle.

`pub fn setLength(file: File, io: Io, new_length: u64) SetLengthError!void`  
Truncates or expands the file, populating any new data with zeroes.

`pub fn setOwner(file: File, io: Io, owner: ?Uid, group: ?Gid) SetOwnerError!void`  
Also known as "chown".

`pub fn setPermissions(file: File, io: Io, new_permissions: Permissions) SetPermissionsError!void`  
Also known as "chmod".

`pub fn setTimestamps(file: File, io: Io, options: SetTimestampsOptions) SetTimestampsError!void`  
The granularity that ultimately is stored depends on the combination of operating system and file system. When a value as provided that exceeds this range, the value is clamped to the maximum.

`pub fn setTimestampsNow(file: File, io: Io) SetTimestampsError!void`  
Sets the accessed and modification timestamps of `file` to the current wall clock time.

`pub fn stat(file: File, io: Io) StatError!Stat`  
Returns `Stat` containing basic information about the `File`.

`pub fn stderr() File`  

`pub fn stdin() File`  

`pub fn stdout() File`  

`pub fn supportsAnsiEscapeCodes(file: File, io: Io) Io.Cancelable!bool`  
Test whether ANSI escape codes will be treated as such without attempting to enable support for ANSI escape codes.

`pub fn sync(file: File, io: Io) SyncError!void`  
Blocks until all pending file contents and metadata modifications for the file have been synchronized with the underlying filesystem.

`pub fn tryLock(file: File, io: Io, l: Lock) LockError!bool`  
Attempts to obtain a lock, returning `true` if the lock is obtained, and `false` if there was an existing incompatible lock held. A process may hold only one type of lock (shared or exclusive) on a file. When a process terminates in any way, the lock is released.

`pub fn unlock(file: File, io: Io) void`  
Assumes the file is locked.

`pub fn writePositional(file: File, io: Io, buffer: []const []const u8, offset: u64) WritePositionalError!usize`  
See also:

- `writer`

`pub fn writePositionalAll(file: File, io: Io, bytes: []const u8, offset: u64) WritePositionalError!void`  
Equivalent to creating a positional writer, writing `bytes`, and then flushing.

`pub fn writeStreamingAll(file: File, io: Io, bytes: []const u8) Writer.Error!void`  
Equivalent to creating a streaming writer, writing `bytes`, and then flushing.

`pub fn writer(file: File, io: Io, buffer: []u8) Writer`  
Defaults to positional reading; falls back to streaming.

`pub fn writerStreaming(file: File, io: Io, buffer: []u8) Writer`  
Positional is more threadsafe, since the global seek position is not affected, but when such syscalls are not available, preemptively initializing in streaming mode will skip a failed syscall.

## Error Sets

- DowngradeLockError
- EnableAnsiEscapeCodesError
- HardLinkError
- LengthError
- LockError
- OpenError
- ReadPositionalError
- RealPathError
- SeekError
- SetLengthError
- SetOwnerError
- SetPermissionsError
- SetTimestampsError
- StatError
- SyncError
- WriteFilePositionalError
- WritePositionalError
