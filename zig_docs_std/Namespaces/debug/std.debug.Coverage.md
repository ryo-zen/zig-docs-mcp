# std.debug.Coverage

### Fields

    directories: std.ArrayHashMapUnmanaged(String, void, String.MapContext, false)

Provides a globally-scoped integer index for directories.

As opposed to, for example, a directory index that is compilation-unit scoped inside a single ELF module.

String memory references the memory-mapped debug information.

Protected by `mutex`.

    files: std.ArrayHashMapUnmanaged(File, void, File.MapContext, false)

Provides a globally-scoped integer index for files.

String memory references the memory-mapped debug information.

Protected by `mutex`.

    string_bytes: std.ArrayList(u8)

    mutex: Io.Mutex

Protects the other fields.

## Types

- File
- SourceLocation
- String

## Values

|      |            |     |
|------|------------|-----|
| init | `Coverage` |     |

## Functions

`pub fn addStringAssumeCapacity(cov: *Coverage, s: []const u8) String`  

`pub fn deinit(cov: *Coverage, gpa: Allocator) void`  

`pub fn fileAt(cov: *Coverage, index: File.Index) *File`  

`pub fn resolveAddressesDwarf( cov: *Coverage, gpa: Allocator, io: Io, endian: std.builtin.Endian, sorted_pc_addrs: []const u64, output: []SourceLocation, d: *Dwarf, ) ResolveAddressesDwarfError!void`  

`pub fn stringAt(cov: *Coverage, index: String) [:0]const u8`  

## Error Sets

- ResolveAddressesDwarfError
