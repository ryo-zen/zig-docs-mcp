# std.pdb

## Overview

`std.pdb` contains structures and enums for Microsoft Program Database files and CodeView-style debug metadata.

Source: `/path/to/zig-0.16.0/lib/std/pdb.zig`

## Public API Areas

### PDB Streams and Headers

- `std.pdb.SuperBlock`
- `std.pdb.StreamType`
- `std.pdb.DbiStreamHeader`
- `std.pdb.IpiStreamHeader`
- `std.pdb.IpiStreamVersion`
- `std.pdb.StringTableHeader`

### Modules, Sections, and Contributions

- `std.pdb.ModInfo`
- `std.pdb.SectionContribEntry`
- `std.pdb.SectionContrSubstreamVersion`
- `std.pdb.SectionMapHeader`
- `std.pdb.SectionMapEntry`

### Symbols and Type Records

- `std.pdb.SymbolKind`
- `std.pdb.TypeIndex`
- `std.pdb.ProcSym`
- `std.pdb.ProcSymFlags`
- `std.pdb.RecordPrefix`
- `std.pdb.LfRecordPrefix`
- `std.pdb.LfRecordKind`
- `std.pdb.LfFuncId`
- `std.pdb.LfMFuncId`

### Line and Inline Metadata

- `std.pdb.LineFragmentHeader`
- `std.pdb.LineFlags`
- `std.pdb.LineBlockFragmentHeader`
- `std.pdb.LineNumberEntry`
- `std.pdb.ColumnNumberEntry`
- `std.pdb.FileChecksumEntryHeader`
- `std.pdb.DebugSubsectionKind`
- `std.pdb.DebugSubsectionHeader`
- `std.pdb.InlineSiteSym`
- `std.pdb.InlineSiteSym2`
- `std.pdb.InlineeSourceLine`
- `std.pdb.InlineeSourceLineEx`
- `std.pdb.BinaryAnnotationOpcode`

## Notes

This namespace is low-level debug-format data for tooling and symbol readers rather than a high-level debugging API.
