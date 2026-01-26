# std.Io.Dir

### Fields

    handle: Handle

## Types

- AccessOptions
- CopyFileOptions
- CreateDirPathOpenOptions
- CreateFileAtomicOptions
- CreatePathStatus
- Entry
- HardLinkOptions
- Iterator
- OpenOptions
- PrevStatus
- Reader
- SelectiveWalker
- SetFileOwnerOptions
- SetFilePermissionsOptions
- SetTimestampsNowOptions
- SetTimestampsOptions
- Stat
- StatFileOptions
- SymLinkFlags
- Walker
- WriteFileOptions

## Namespaces

- path

## Values

|  |  |  |
|----|----|----|
| Handle |  |  |
| Permissions |  | Cross-platform representation of permissions on a file. |
| max_name_bytes |  | This represents the maximum size of a `[]u8` file name component that the platform's common file systems support. File name components returned by file system operations are likely to fit into a `u8` array of this length, but (depending on the platform) this assumption may not hold for every configuration. The byte count does not include a null sentinel byte. On Windows, `[]u8` file name components are encoded as WTF-8. On WASI, file name components are encoded as valid UTF-8. On other platforms, `[]u8` components are an opaque sequence of bytes with no particular encoding. |
| max_path_bytes |  | The maximum length of a file path that the operating system will accept. |

## Functions

`pub fn access(dir: Dir, io: Io, sub_path: []const u8, options: AccessOptions) AccessError!void`  
Test accessing `sub_path`.

`pub fn accessAbsolute(io: Io, absolute_path: []const u8, options: AccessOptions) AccessError!void`  

`pub fn close(dir: Dir, io: Io) void`  

`pub fn closeMany(io: Io, dirs: []const Dir) void`  

`pub fn copyFile( source_dir: Dir, source_path: []const u8, dest_dir: Dir, dest_path: []const u8, io: Io, options: CopyFileOptions, ) CopyFileError!void`  
Atomically creates a new file at `dest_path` within `dest_dir` with the same contents as `source_path` within `source_dir`.

`pub fn copyFileAbsolute( source_path: []const u8, dest_path: []const u8, io: Io, options: CopyFileOptions, ) !void`  
Same as `copyFile`, except asserts that both `source_path` and `dest_path` are absolute.

`pub fn createDir(dir: Dir, io: Io, sub_path: []const u8, permissions: Permissions) CreateDirError!void`  
Creates a single directory with a relative or absolute path.

`pub fn createDirAbsolute(io: Io, absolute_path: []const u8, permissions: Permissions) CreateDirError!void`  
Create a new directory, based on an absolute path.

`pub fn createDirPath(dir: Dir, io: Io, sub_path: []const u8) CreateDirPathError!void`  
Creates parent directories with default permissions as necessary to ensure `sub_path` exists as a directory.

`pub fn createDirPathOpen(dir: Dir, io: Io, sub_path: []const u8, options: CreateDirPathOpenOptions) CreateDirPathOpenError!Dir`  
Performs the equivalent of `createDirPath` followed by `openDir`, atomically if possible.

`pub fn createDirPathStatus(dir: Dir, io: Io, sub_path: []const u8, permissions: Permissions) CreateDirPathError!CreatePathStatus`  
Same as `createDirPath` except returns whether the path already existed or was successfully created.

`pub fn createFile(dir: Dir, io: Io, sub_path: []const u8, flags: File.CreateFlags) File.OpenError!File`  
Creates, opens, or overwrites a file with write access.

`pub fn createFileAbsolute(io: Io, absolute_path: []const u8, flags: File.CreateFlags) File.OpenError!File`  

`pub fn createFileAtomic( dir: Dir, io: Io, sub_path: []const u8, options: CreateFileAtomicOptions, ) CreateFileAtomicError!File.Atomic`  
Create an unnamed ephemeral file that can eventually be atomically materialized into `sub_path`.

`pub fn cwd() Dir`  
Returns a handle to the current working directory.

`pub fn deleteDir(dir: Dir, io: Io, sub_path: []const u8) DeleteDirError!void`  
Returns `error.DirNotEmpty` if the directory is not empty.

`pub fn deleteDirAbsolute(io: Io, absolute_path: []const u8) DeleteDirError!void`  
Same as `deleteDir` except the path is absolute.

`pub fn deleteFile(dir: Dir, io: Io, sub_path: []const u8) DeleteFileError!void`  
Delete a file name and possibly the file it refers to, based on an open directory handle.

`pub fn deleteFileAbsolute(io: Io, absolute_path: []const u8) DeleteFileError!void`  

`pub fn deleteTree(dir: Dir, io: Io, sub_path: []const u8) DeleteTreeError!void`  
Whether `sub_path` describes a symlink, file, or directory, this function removes it. If it cannot be removed because it is a non-empty directory, this function recursively removes its entries and then tries again.

`pub fn deleteTreeMinStackSize(dir: Dir, io: Io, sub_path: []const u8) DeleteTreeError!void`  
Like `deleteTree`, but only keeps one `Iterator` active at a time to minimize the function's stack size. This is slower than `deleteTree` but uses less stack space. On Windows, `sub_path` should be encoded as WTF-8. On WASI, `sub_path` should be encoded as valid UTF-8. On other platforms, `sub_path` is an opaque sequence of bytes with no particular encoding.

`pub fn hardLink( old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8, io: Io, options: HardLinkOptions, ) HardLinkError!void`  

`pub fn iterate(dir: Dir) Iterator`  

`pub fn iterateAssumeFirstIteration(dir: Dir) Iterator`  
Like `iterate`, but will not reset the directory cursor before the first iteration. This should only be used in cases where it is known that the `Dir` has not had its cursor modified yet (e.g. it was just opened).

`pub fn openDir(dir: Dir, io: Io, sub_path: []const u8, options: OpenOptions) OpenError!Dir`  
Opens a directory at the given path. The directory is a system resource that remains open until `close` is called on the result.

`pub fn openDirAbsolute(io: Io, absolute_path: []const u8, options: OpenOptions) OpenError!Dir`  

`pub fn openFile(dir: Dir, io: Io, sub_path: []const u8, flags: File.OpenFlags) File.OpenError!File`  
Opens a file for reading or writing, without attempting to create a new file.

`pub fn openFileAbsolute(io: Io, absolute_path: []const u8, flags: File.OpenFlags) File.OpenError!File`  

`pub fn readFile(dir: Dir, io: Io, file_path: []const u8, buffer: []u8) ReadFileError![]u8`  
Read all of file contents using a preallocated buffer.

`pub fn readFileAlloc( dir: Dir, io: Io, sub_path: []const u8, gpa: Allocator, limit: Io.Limit, ) ReadFileAllocError![]u8`  
Reads all the bytes from the named file. On success, caller owns returned buffer.

`pub fn readFileAllocOptions( dir: Dir, io: Io, sub_path: []const u8, gpa: Allocator, limit: Io.Limit, comptime alignment: std.mem.Alignment, comptime sentinel: ?u8, ) ReadFileAllocError!(if (sentinel) |s| [:s]align(alignment.toByteUnits()) u8 else []align(alignment.toByteUnits()) u8)`  
Reads all the bytes from the named file. On success, caller owns returned buffer.

`pub fn readLink(dir: Dir, io: Io, sub_path: []const u8, buffer: []u8) ReadLinkError!usize`  
Obtain target of a symbolic link.

`pub fn readLinkAbsolute(io: Io, absolute_path: []const u8, buffer: []u8) ReadLinkError!usize`  
Same as `readLink`, except it asserts the path is absolute.

`pub fn realPath(dir: Dir, io: Io, out_buffer: []u8) RealPathError!usize`  
Obtains the canonicalized absolute path name of `sub_path` relative to this `Dir`. If `sub_path` is absolute, ignores this `Dir` handle and obtains the canonicalized absolute pathname of `sub_path` argument.

`pub fn realPathFile(dir: Dir, io: Io, sub_path: []const u8, out_buffer: []u8) RealPathFileError!usize`  
Obtains the canonicalized absolute path name of `sub_path` relative to this `Dir`. If `sub_path` is absolute, ignores this `Dir` handle and obtains the canonicalized absolute pathname of `sub_path` argument.

`pub fn realPathFileAbsolute(io: Io, absolute_path: []const u8, out_buffer: []u8) RealPathFileError!usize`  
Same as `realPathFile` except `absolute_path` is asserted to be an absolute path.

`pub fn realPathFileAbsoluteAlloc(io: Io, absolute_path: []const u8, allocator: Allocator) RealPathFileAllocError![:0]u8`  
Same as `realPathFileAbsolute` except allocates result.

`pub fn realPathFileAlloc(dir: Dir, io: Io, sub_path: []const u8, allocator: Allocator) RealPathFileAllocError![:0]u8`  
Same as `realPathFile` except allocates result.

`pub fn rename( old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8, io: Io, ) RenameError!void`  
Change the name or location of a file or directory.

`pub fn renameAbsolute(old_path: []const u8, new_path: []const u8, io: Io) RenameError!void`  

`pub fn renamePreserve( old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8, io: Io, ) RenamePreserveError!void`  
Change the name or location of a file or directory.

`pub fn setFileOwner( dir: Dir, io: Io, sub_path: []const u8, owner: ?File.Uid, group: ?File.Gid, options: SetFileOwnerOptions, ) SetOwnerError!void`  
Also known as "fchownat".

`pub fn setFilePermissions( dir: Dir, io: Io, sub_path: []const u8, new_permissions: File.Permissions, options: SetFilePermissionsOptions, ) SetFilePermissionsError!void`  
Also known as "fchmodat".

`pub fn setOwner(dir: Dir, io: Io, owner: ?File.Uid, group: ?File.Gid) SetOwnerError!void`  
Also known as "chown".

`pub fn setPermissions(dir: Dir, io: Io, new_permissions: File.Permissions) SetPermissionsError!void`  
Also known as "chmod".

`pub fn setTimestamps( dir: Dir, io: Io, sub_path: []const u8, options: SetTimestampsOptions, ) SetTimestampsError!void`  
The granularity that ultimately is stored depends on the combination of operating system and file system. When a value as provided that exceeds this range, the value is clamped to the maximum.

`pub fn setTimestampsNow( dir: Dir, io: Io, sub_path: []const u8, options: SetTimestampsNowOptions, ) SetTimestampsError!void`  
Sets the accessed and modification timestamps of the provided path to the current wall clock time.

`pub fn stat(dir: Dir, io: Io) StatError!Stat`  

`pub fn statFile(dir: Dir, io: Io, sub_path: []const u8, options: StatFileOptions) StatFileError!Stat`  
Returns metadata for a file inside the directory.

`pub fn symLink( dir: Dir, io: Io, target_path: []const u8, sym_link_path: []const u8, flags: SymLinkFlags, ) SymLinkError!void`  
Creates a symbolic link named `sym_link_path` which contains the string `target_path`.

`pub fn symLinkAbsolute( io: Io, target_path: []const u8, sym_link_path: []const u8, flags: SymLinkFlags, ) SymLinkError!void`  

`pub fn symLinkAtomic( dir: Dir, io: Io, target_path: []const u8, sym_link_path: []const u8, flags: SymLinkFlags, ) !void`  
Same as `symLink`, except tries to create the symbolic link until it succeeds or encounters an error other than `error.PathAlreadyExists`.

`pub fn updateFile( source_dir: Dir, io: Io, source_path: []const u8, dest_dir: Dir, dest_path: []const u8, options: CopyFileOptions, ) !PrevStatus`  
Check the file size, mtime, and permissions of `source_path` and `dest_path`. If they are equal, does nothing. Otherwise, atomically copies `source_path` to `dest_path`, creating the parent directory hierarchy as needed. The destination file gains the mtime, atime, and permissions of the source file so that the next call to `updateFile` will not need a copy.

`pub fn walk(dir: Dir, allocator: Allocator) Allocator.Error!Walker`  
Recursively iterates over a directory.

`pub fn walkSelectively(dir: Dir, allocator: Allocator) !SelectiveWalker`  
Recursively iterates over a directory, but requires the user to opt-in to recursing into each directory entry.

`pub fn writeFile(dir: Dir, io: Io, options: WriteFileOptions) WriteFileError!void`  
Writes content to the file system, using the file creation flags provided.

## Error Sets

- AccessError
- CopyFileError
- CreateDirError
- CreateDirPathError
- CreateDirPathOpenError
- CreateFileAtomicError
- DeleteDirError
- DeleteFileError
- DeleteTreeError
- HardLinkError
- OpenError
- PathNameError
- ReadFileAllocError
- ReadFileError
- ReadLinkError
- RealPathError
- RealPathFileAllocError
- RealPathFileError
- RenameError
- RenamePreserveError
- SetFileOwnerError
- SetFilePermissionsError
- SetOwnerError
- SetPermissionsError
- SetTimestampsError
- StatError
- StatFileError
- SymLinkError
- UpdateFileError
- WriteFileError
