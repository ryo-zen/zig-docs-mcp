# std.macho

## Overview

`std.macho` contains declarations for the Mach-O object format used by Darwin systems.

Source: `/path/to/zig-0.16.0/lib/std/macho.zig`

## Public API Areas

### Headers and Load Commands

- `std.macho.mach_header`
- `std.macho.mach_header_64`
- `std.macho.fat_header`
- `std.macho.fat_arch`
- `std.macho.load_command`
- `std.macho.LC`
- `std.macho.LoadCommandIterator`

### Segments, Sections, and Symbols

- `std.macho.segment_command`
- `std.macho.segment_command_64`
- `std.macho.section`
- `std.macho.section_64`
- `std.macho.symtab_command`
- `std.macho.dysymtab_command`
- `std.macho.nlist`
- `std.macho.nlist_64`

### Dynamic Linking and Build Metadata

- `std.macho.dyld_info_command`
- `std.macho.dylinker_command`
- `std.macho.dylib_command`
- `std.macho.rpath_command`
- `std.macho.build_version_command`
- `std.macho.build_tool_version`
- `std.macho.PLATFORM`
- `std.macho.TOOL`

### Relocations, Binding, and Code Signing

- `std.macho.relocation_info`
- `std.macho.reloc_type_x86_64`
- `std.macho.reloc_type_arm64`
- bind and rebase opcode constants
- code-signing blob and slot constants
- `std.macho.CodeDirectory`
- `std.macho.SuperBlob`
- `std.macho.GenericBlob`

### Compact Unwind

- compact unwind structs and constants, including `CompactUnwindEncoding`.

## Notes

This namespace is mainly used by linkers, debuggers, object readers, and Darwin-specific tooling.
