# std.Target

`std.Target` is the root import of `Target.zig`, the fully resolved description of a machine and platform that will execute code.

## Source Declaration

```zig
pub const Target = @import("Target.zig");
```

## Data Fields

- `cpu: Cpu`
- `os: Os`
- `abi: Abi`
- `ofmt: ObjectFormat`
- `dynamic_linker: DynamicLinker = DynamicLinker.none`

Unlike `std.Target.Query`, a `Target` stores concrete CPU, OS, ABI, object format, and dynamic linker information.

## Major Nested Types

### `Query`

Imports `Target/Query.zig` and represents a target query that may contain defaults or host-dependent values.

### `Os`

Stores `tag` and `version_range`. Notable nested types include:

- `Tag`
- `WindowsVersion`
- `HurdVersionRange`
- `LinuxVersionRange`
- `VersionRange`
- `TaggedVersionRange`

### `Abi`

Enum describing the ABI component, with helpers such as `default`, `isGnu`, `isMusl`, `isOpenHarmony`, `isAndroid`, and `float`.

### `ObjectFormat`

Enum describing output object format. It provides `fileExt` and `default`.

### `Cpu`

Stores `arch`, `model`, and `features`. Notable nested types include:

- `Arch`
- `Model`
- `Feature`
- `Feature.Set`

### `DynamicLinker`

Stores a dynamic linker path in a fixed buffer. It provides `init`, `initFmt`, `get`, `set`, `setFmt`, `eql`, `kind`, and `standard`.

### `AddressSpaceContext`

Enum describing where an address space attribute is being checked.

### `StackGrowth`

Enum with `down` and `up`.

### `CType`

Enum for C ABI type-size and alignment queries.

## Architecture Namespaces

`Target.zig` imports per-architecture namespaces such as `aarch64`, `arm`, `mips`, `riscv`, `wasm`, `x86`, and others. These namespaces hold CPU model and feature declarations used by `Cpu`.

## Core Functions

### `pub fn zigTriple(target: *const Target, allocator: Allocator) Allocator.Error![]u8`

Formats the Zig target triple for a fully resolved target.

### `pub fn linuxTriple(target: *const Target, allocator: Allocator) ![]u8`

Formats a Linux-style triple from a target.

### `pub fn linuxTripleSimple(allocator: Allocator, arch: Cpu.Arch, os_tag: Os.Tag, abi: Abi) ![]u8`

Formats a Linux-style triple from explicit components.

### `pub fn hurdTuple(target: *const Target, allocator: Allocator) ![]u8`

Formats a Hurd tuple from a target.

### `pub fn hurdTupleSimple(allocator: Allocator, arch: Cpu.Arch, abi: Abi) ![]u8`

Formats a Hurd tuple from explicit components.

### `pub fn exeFileExt(target: *const Target) [:0]const u8`

Returns the executable suffix for the target.

### `pub fn staticLibSuffix(target: *const Target) [:0]const u8`

Returns the static library suffix for the target.

### `pub fn dynamicLibSuffix(target: *const Target) [:0]const u8`

Returns the dynamic library suffix for the target.

### `pub fn libPrefix(target: *const Target) [:0]const u8`

Returns the library filename prefix for the target.

### `pub fn standardDynamicLinkerPath(target: *const Target) DynamicLinker`

Returns the standard dynamic linker path for the target, or `DynamicLinker.none`.

### `pub fn requiresLibC(target: *const Target) bool`

Returns whether the target requires linking libc.

### `pub fn supportsAddressSpace(target: Target, address_space: std.builtin.AddressSpace, context: ?AddressSpaceContext) bool`

Checks whether an address space is supported generally or in a specific context.

### `pub fn ptrBitWidth(target: *const Target) u16`

Returns the target pointer width.

### `pub fn stackAlignment(target: *const Target) u16`

Returns the target stack alignment.

### `pub fn stackGrowth(target: *const Target) StackGrowth`

Returns the target stack growth direction.

### `pub fn cCharSignedness(target: *const Target) std.builtin.Signedness`

Returns the default signedness of C `char` for the target.

### `pub fn cTypeByteSize(t: *const Target, c_type: CType) u16`

Returns C ABI byte size for a C type.

### `pub fn cTypeBitSize(target: *const Target, c_type: CType) u16`

Returns C ABI bit size for a C type.

### `pub fn cTypeAlignment(target: *const Target, c_type: CType) u16`

Returns C ABI alignment for a C type.

### `pub fn cTypePreferredAlignment(target: *const Target, c_type: CType) u16`

Returns preferred C ABI alignment for a C type.

### `pub fn cMaxIntAlignment(target: *const Target) u16`

Returns the maximum C integer alignment.

### `pub fn cCallingConvention(target: *const Target) ?std.builtin.CallingConvention`

Returns the default C calling convention for the target when known.

## Compatibility Helpers

- `isMinGW`
- `isGnuLibC`
- `isMuslLibC`
- `isBionicLibC`
- `isDarwinLibC`
- `isFreeBSDLibC`
- `isNetBSDLibC`
- `isOpenBSDLibC`
- `isWasiLibC`

## Deprecated Alias

```zig
pub const SubSystem = std.zig.Subsystem;
```

`SubSystem` is deprecated in favor of `std.zig.Subsystem`.

## See Also

- `std.Target.Query`
- `std.SemanticVersion`
- `std.zig.Subsystem`
