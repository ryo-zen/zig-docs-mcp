# std.debug.Info

Cross-platform abstraction for loading debug information into an in-memory format that supports queries such as "what is the source location of this virtual memory address?"

Unlike `std.debug.SelfInfo`, this API does not assume the debug information in question happens to match the host CPU architecture, OS, or other target properties.

## Overview

`std.debug.Info` is the format-dispatched entry point for offline/cross-target address-to-source resolution.

It wraps object-format backends (`ElfFile`, `MachOFile`) behind one API and relies on external `Coverage` state for interned metadata.

### Fields

    impl: union(enum) {
        elf: ElfFile,
        macho: MachOFile,
    }

    coverage: *Coverage

Externally managed, outlives this `Info` instance.

## Functions

`pub fn deinit(info: *Info, gpa: Allocator) void`  
Releases backend resources owned by this `Info`.

`pub fn load( gpa: Allocator, io: Io, path: Path, coverage: *Coverage, format: std.Target.ObjectFormat, arch: std.Target.Cpu.Arch, ) LoadError!Info`  
Loads debug-info backend state for the specified object format/architecture.

`pub fn resolveAddresses( info: *Info, gpa: Allocator, io: Io, sorted_pc_addrs: []const u64, output: []SourceLocation, ) ResolveAddressesError!void`  
Given an array of virtual memory addresses, sorted ascending, outputs a corresponding array of source locations.

## Error Sets

- LoadError
- ResolveAddressesError

## Typical Workflow

1. Initialize a `Coverage` value (shared across loads).
2. Call `Info.load` with target format/arch metadata.
3. Call `resolveAddresses` with sorted PCs and output buffer.
4. Call `deinit` when finished.

## Usage Notes

- `coverage` must outlive the `Info` instance.
- `sorted_pc_addrs` should be ascending for expected lookup behavior/performance.
- Use `SelfInfo` instead when resolving addresses for the currently running process.
