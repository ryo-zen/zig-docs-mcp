# std.process.Environ

### Fields

    block: Block

Unmodified, unprocessed data provided by the operating system.

## Types

- Block
- CreatePosixBlockOptions
- CreateWindowsBlockOptions
- GlobalBlock
- Map
- PosixBlock
- WindowsBlock

## Values

|       |           |     |
|-------|-----------|-----|
| empty | `Environ` |     |

## Functions

`pub fn contains(environ: Environ, gpa: Allocator, key: []const u8) ContainsError!bool`  
On Windows, if `key` is not valid WTF-8, then `error.InvalidWtf8` is returned.

`pub inline fn containsConstant(environ: Environ, comptime key: []const u8) bool`  
This function is unavailable on WASI without libc due to the memory allocation requirement.

`pub fn containsUnempty(environ: Environ, gpa: Allocator, key: []const u8) ContainsError!bool`  
On Windows, if `key` is not valid WTF-8, then `error.InvalidWtf8` is returned.

`pub inline fn containsUnemptyConstant(environ: Environ, comptime key: []const u8) bool`  
This function is unavailable on WASI without libc due to the memory allocation requirement.

`pub fn createMap(env: Environ, allocator: Allocator) CreateMapError!Map`  
Allocates a `Map` and copies environment block into it.

`pub fn createPosixBlock( existing: Environ, gpa: Allocator, options: CreatePosixBlockOptions, ) Allocator.Error!PosixBlock`  
Creates a null-delimited environment variable block in the format expected by POSIX, from a different one.

`pub fn createWindowsBlock( existing: Environ, gpa: Allocator, options: CreateWindowsBlockOptions, ) Allocator.Error!WindowsBlock`  
Creates a null-delimited environment variable block in the format expected by POSIX, from a different one.

`pub fn getAlloc(environ: Environ, gpa: Allocator, key: []const u8) GetAllocError![]u8`  
Caller owns returned memory.

`pub fn getPosix(environ: Environ, key: []const u8) ?[:0]const u8`  
This function is unavailable on WASI without libc due to the memory allocation requirement.

`pub fn getWindows(environ: Environ, key: [*:0]const u16) ?[:0]const u16`  
Windows-only. Get an environment variable with a null-terminated, WTF-16 encoded name.

## Error Sets

- ContainsError
- CreateMapError
- GetAllocError
