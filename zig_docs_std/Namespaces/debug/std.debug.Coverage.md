# std.debug.Coverage

## Overview

`std.debug.Coverage` is an address-resolution support structure used by debug-info loaders.

It maintains global, deduplicated string/file/directory tables so multiple debug units can resolve program counters into stable source locations.

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

Storage backing interned strings referenced by `String` indices.

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
Adds a string into the intern table when capacity has already been reserved.

`pub fn deinit(cov: *Coverage, gpa: Allocator) void`
Releases all memory owned by coverage indices and string storage.

`pub fn fileAt(cov: *Coverage, index: File.Index) *File`
Returns a pointer to a tracked file record by index.

`pub fn resolveAddressesDwarf( cov: *Coverage, gpa: Allocator, io: Io, endian: std.builtin.Endian, sorted_pc_addrs: []const u64, output: []SourceLocation, d: *Dwarf, ) ResolveAddressesDwarfError!void`
Resolves sorted program-counter addresses into source locations using DWARF data.

`pub fn stringAt(cov: *Coverage, index: String) [:0]const u8`
Returns a zero-terminated string slice from the intern table.

## Error Sets

- ResolveAddressesDwarfError

## Usage Notes

- This is an infrastructure type used by debug loaders (`Info`, `ElfFile`, `Dwarf`) rather than direct app code.
- `sorted_pc_addrs` must be sorted ascending for efficient resolution behavior.
- `directories`/`files`/`string_bytes` are shared mutable state and protected by `mutex`.

## Typical Workflow

1. Initialize a `Coverage` value (typically with `.init`).
2. Load debug information (`std.debug.Info.load` or format-specific loaders).
3. Call `resolveAddressesDwarf` (or higher-level wrappers) to fill `SourceLocation` output arrays.
4. Call `deinit` with the allocator used for setup.

## Related APIs

- `std.debug.Info`
- `std.debug.Dwarf`
- `std.debug.SourceLocation`
