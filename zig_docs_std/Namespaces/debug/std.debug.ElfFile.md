# std.debug.ElfFile

A helper type for loading an ELF file and collecting its DWARF debug information, unwind information, and symbol table.

## Overview

`std.debug.ElfFile` is the ELF-specific backend used by `std.debug.Info` and related symbolization paths.

It memory-maps ELF inputs, locates debug/unwind sections, and exposes symbol lookup helpers.

### Fields

    is_64: bool

    endian: Endian

    dwarf: ?Dwarf

This is `null` iff any of the required DWARF sections were missing. `ElfFile.load` does *not* call `Dwarf.open`, `Dwarf.scanAllFunctions`, etc; that is the caller's responsibility.

    eh_frame: ?UnwindSection

If non-`null`, describes the `.eh_frame` section, which can be used with `Dwarf.Unwind`.

    debug_frame: ?UnwindSection

If non-`null`, describes the `.debug_frame` section, which can be used with `Dwarf.Unwind`.

    strtab: ?[]const u8

If non-`null`, this is the contents of the `.strtab` section.

    symtab: ?SymtabSection

If non-`null`, describes the `.symtab` section.

    symbol_search_table: ?[]usize

Binary search table lazily populated by `searchSymtab`.

    mapped_file: []align(std.heap.page_size_min) const u8

The memory-mapped ELF file, which is referenced by `dwarf`. This field is here only so that this memory can be unmapped by `ElfFile.deinit`.

    mapped_debug_file: ?[]align(std.heap.page_size_min) const u8

Sometimes, debug info is stored separately to the main ELF file. In that case, `mapped_file` is the mapped ELF binary, and `mapped_debug_file` is the mapped debug info file. Both must be unmapped by `ElfFile.deinit`.

    arena: std.heap.ArenaAllocator.State

## Types

- DebugInfoSearchPaths
- SymtabSection
- UnwindSection

## Functions

`pub fn deinit(ef: *ElfFile, gpa: Allocator) void`  
Releases mapped files, arena state, and associated metadata.

`pub fn load( gpa: Allocator, io: Io, elf_file: Io.File, opt_build_id: ?[]const u8, di_search_paths: *const DebugInfoSearchPaths, ) LoadError!ElfFile`  
Loads ELF metadata and optional external debug-info mappings.

`pub fn searchSymtab(ef: *ElfFile, gpa: Allocator, vaddr: u64) error{ NoSymtab, NoStrtab, BadSymtab, OutOfMemory, }!std.debug.Symbol`  
Performs symbol-table lookup for a virtual address.

## Error Sets

- LoadError

## Usage Notes

- `dwarf` may be `null` when required DWARF sections are absent; symbolization can still partially work via `symtab`.
- `load` does not fully initialize DWARF decode state; callers handle deeper DWARF setup.
- Always call `deinit` to unmap `mapped_file`/`mapped_debug_file`.
