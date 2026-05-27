# std.elf

## Overview

`std.elf` contains ELF constants, enums, structs, and iterators for executable, shared-object, object-file, and archive metadata.

Source: `/path/to/zig-0.16.0/lib/std/elf.zig`

## Public API Areas

### File Identification and Headers

- `std.elf.MAGIC`
- `std.elf.Header`
- `std.elf.EI`
- `std.elf.CLASS`
- `std.elf.DATA`
- `std.elf.OSABI`
- `std.elf.ET`
- `std.elf.EM`

### Program, Section, and Dynamic Tables

- `std.elf.PT`
- `std.elf.SHT`
- `std.elf.SHF`
- `std.elf.PF`
- `std.elf.ProgramHeaderIterator`
- `std.elf.ProgramHeaderBufferIterator`
- `std.elf.takeProgramHeader`
- `std.elf.SectionHeaderIterator`
- `std.elf.SectionHeaderBufferIterator`
- `std.elf.takeSectionHeader`
- `std.elf.DynamicSectionIterator`
- `std.elf.DynamicSectionBufferIterator`
- `std.elf.takeDynamicSection`

### Word-Size-Specific Types

- `std.elf.Elf32`
- `std.elf.Elf64`
- `std.elf.ElfN`
- `std.elf.Ehdr`
- `std.elf.Phdr`
- `std.elf.Shdr`
- `std.elf.Sym`
- `std.elf.Dyn`
- `std.elf.Rel`
- `std.elf.Rela`
- `std.elf.Relr`

### Symbols, Relocations, and Notes

- `std.elf.STB`
- `std.elf.STT`
- `std.elf.STV`
- `std.elf.Versym`
- `std.elf.VER_NDX`
- Architecture-specific relocation enums such as `R_X86_64`, `R_AARCH64`, `R_RISCV`, and `R_PPC64`.

### Archive Support

- `std.elf.ar_hdr`
- `std.elf.ARMAG`
- `std.elf.ARMAG_THIN`
- `std.elf.ARFMAG`
- `std.elf.SYMNAME`
- `std.elf.STRNAME`

## Notes

This namespace intentionally exposes a large amount of raw ELF format data. Higher-level debug and dynamic-loading APIs live elsewhere in the standard library.
