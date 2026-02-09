# std.debug.Info

Cross-platform abstraction for loading debug information into an in-memory format that supports queries such as "what is the source location of this virtual memory address?"

Unlike `std.debug.SelfInfo`, this API does not assume the debug information in question happens to match the host CPU architecture, OS, or other target properties.

### Fields

    impl: union(enum) {
        elf: ElfFile,
        macho: MachOFile,
    }

    coverage: *Coverage

Externally managed, outlives this `Info` instance.

## Functions

`pub fn deinit(info: *Info, gpa: Allocator) void`  

`pub fn load( gpa: Allocator, io: Io, path: Path, coverage: *Coverage, format: std.Target.ObjectFormat, arch: std.Target.Cpu.Arch, ) LoadError!Info`  

`pub fn resolveAddresses( info: *Info, gpa: Allocator, io: Io, sorted_pc_addrs: []const u64, output: []SourceLocation, ) ResolveAddressesError!void`  
Given an array of virtual memory addresses, sorted ascending, outputs a corresponding array of source locations.

## Error Sets

- LoadError
- ResolveAddressesError
