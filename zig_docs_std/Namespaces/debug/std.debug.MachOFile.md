# std.debug.MachOFile

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

`pub fn load(gpa: Allocator, io: Io, path: []const u8, arch: std.Target.Cpu.Arch) Error!MachOFile`  

`pub fn lookupSymbolName(mf: *MachOFile, vaddr: u64) error{MissingDebugInfo}![]const u8`  

## Error Sets

- Error
