# std.coff

## Overview

`std.coff` contains declarations for the COFF and PE/COFF object formats used by Windows object files, executables, import libraries, and debug data.

Source: `/path/to/zig-0.16.0/lib/std/coff.zig`

## Public API Areas

### PE/COFF Headers

- `std.coff.Header`
- `std.coff.OptionalHeader`
- `std.coff.ImageDataDirectory`
- `std.coff.SectionHeader`
- `std.coff.ImportHeader`

### Directories and Relocations

- `std.coff.BaseRelocationDirectoryEntry`
- `std.coff.BaseRelocation`
- `std.coff.BaseRelocationType`
- `std.coff.DebugDirectoryEntry`
- `std.coff.DebugType`
- `std.coff.ImportDirectoryEntry`
- `std.coff.Relocation`

### Symbols and Tables

- `std.coff.Symbol`
- `std.coff.SectionNumber`
- `std.coff.SymType`
- `std.coff.BaseType`
- `std.coff.ComplexType`
- `std.coff.StorageClass`
- `std.coff.Symtab`
- `std.coff.Strtab`

### Readers and Errors

- `std.coff.Coff`
- `std.coff.Error`

### Import Library Metadata

- `std.coff.ImportType`
- `std.coff.ImportNameType`
- `std.coff.IMAGE`

## Notes

This namespace is primarily for toolchain and object-format code. It exposes format structures and constants rather than high-level application APIs.
