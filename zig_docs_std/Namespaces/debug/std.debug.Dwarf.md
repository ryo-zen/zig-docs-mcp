# std.debug.Dwarf

Implements parsing, decoding, and caching of DWARF information.

This API makes no assumptions about the relationship between the host and the target being debugged. In other words, any DWARF information can be used from any host via this API. Note, however, that the limits of 32-bit addressing can cause very large 64-bit binaries to be impossible to open on 32-bit hosts.

For unopinionated types and bits, see `std.dwarf`.

## Overview

`std.debug.Dwarf` is the high-level DWARF integration layer used by `std.debug` symbolization and unwinding paths.

It is target-agnostic and can consume DWARF data for binaries that differ from the current host architecture/OS.

### Fields

    sections: SectionArray = @splat(null)

    abbrev_table_list: ArrayList(Abbrev.Table) = .empty

Filled later by the initializer

    compile_unit_list: ArrayList(CompileUnit) = .empty

Filled later by the initializer

    func_list: ArrayList(Func) = .empty

Filled later by the initializer

    ranges: ArrayList(Range) = .empty

Populated by `populateRanges`.

## Types

- Abbrev
- CompileUnit
- Die
- FormValue
- Range
- Section
- SectionArray
- SelfUnwinder
- Unwind
- bad
- missing

## Namespaces

- expression

## Functions

`pub fn compactUnwindToDwarfRegNumber(unwind_reg_number: u3) !u16`
Returns the DWARF register number for an x86_64 register number found in compact unwind info

`pub fn deinit(di: *Dwarf, gpa: Allocator) void`

`pub fn findCompileUnit(di: *const Dwarf, endian: Endian, target_address: u64) !*CompileUnit`
TODO: change this to binary searching the sorted compile unit list

`pub fn fpRegNum(arch: std.Target.Cpu.Arch) u16`

`pub fn getLineNumberInfo( d: *Dwarf, gpa: Allocator, endian: Endian, compile_unit: *CompileUnit, target_address: u64, ) !std.debug.SourceLocation`

`pub fn getSymbol(di: *Dwarf, gpa: Allocator, endian: Endian, address: u64) !std.debug.Symbol`

`pub fn getSymbolName(di: *const Dwarf, address: u64) ?[]const u8`

`pub fn invalidDebugInfoDetected() void`

`pub fn ipRegNum(arch: std.Target.Cpu.Arch) ?u16`
Returns `null` for CPU architectures without an instruction pointer register.

`pub fn open(d: *Dwarf, gpa: Allocator, endian: Endian) OpenError!void`
Initialize DWARF info. The caller has the responsibility to initialize most the `Dwarf` fields before calling. `binary_mem` is the raw bytes of the main binary file (not the secondary debug info file).

`pub fn populateRanges(d: *Dwarf, gpa: Allocator, endian: Endian) ScanError!void`

`pub fn populateSrcLocCache(d: *Dwarf, gpa: Allocator, endian: Endian, cu: *CompileUnit) ScanError!void`

`pub fn readUnitHeader(r: *Reader, endian: Endian) ScanError!UnitHeader`

`pub fn section(di: Dwarf, dwarf_section: Section.Id) ?[]const u8`

`pub fn spRegNum(arch: std.Target.Cpu.Arch) u16`

`pub fn supportsUnwinding(target: *const std.Target) bool`
Tells whether unwinding for this target is supported by the Dwarf standard.

## Error Sets

- OpenError
- ScanError

## Usage Notes

- `open` initializes DWARF internals after required sections are wired into the struct.
- Callers typically populate ranges/source-location caches before heavy lookup workloads.
- Symbol and line-resolution helpers (`getSymbol`, `getLineNumberInfo`) are the common read paths once initialized.

## Gotchas

- On some targets/architectures, unwinding support is intentionally limited (`supportsUnwinding`).
- Missing required sections can make symbolization partial even when some DWARF data exists.
- Very large binaries may hit host-address-size limitations (notably 32-bit hosts).
