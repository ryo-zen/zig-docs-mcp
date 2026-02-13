# std.debug.MachOFile

## Overview

`std.debug.MachOFile` is the Mach-O backend for symbol and debug-info lookup on Apple platforms.

It owns mapped binary memory plus symbol/string/object-file tables used during address resolution.

### Fields

    mapped_memory: []align(std.heap.page_size_min) const u8

    symbols: []const Symbol

    strings: []const u8

    text_vmaddr: u64

    ofiles: std.AutoArrayHashMapUnmanaged(u32, Error!OFile)

Key is index into `strings` of the file path.

## Types

- getDwarfForAddress

## Functions

`pub fn deinit(mf: *MachOFile, gpa: Allocator) void`
Releases mapped memory and backend-owned metadata.

`pub fn load(gpa: Allocator, io: Io, path: []const u8, arch: std.Target.Cpu.Arch) Error!MachOFile`
Loads Mach-O debug metadata for the requested architecture.

`pub fn lookupSymbolName(mf: *MachOFile, vaddr: u64) error{MissingDebugInfo}![]const u8`
Returns the symbol name associated with a virtual address.

## Error Sets

- Error

## Usage Notes

- Used internally by `std.debug.Info` for `.macho` object-format paths.
- `lookupSymbolName` may fail with `MissingDebugInfo` on stripped binaries.
- Always pair `load` with `deinit` to avoid mapping leaks.
