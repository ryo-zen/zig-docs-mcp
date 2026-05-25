# std.DynLib

`std.DynLib` is the root alias for the cross-platform dynamic library loader in `dynamic_library.zig`.

## Source Declaration

```zig
pub const DynLib = @import("dynamic_library.zig").DynLib;
```

## Backing Type

```zig
pub const DynLib = struct {
    inner: InnerType,
};
```

`InnerType` is selected at compile time from the native OS and linking mode. On supported libc-backed Unix-like targets it uses `DlDynLib`. On Linux without a suitable libc dynamic loader path it can use `ElfDynLib`. Unsupported platforms compile-error on open operations.

## Error Set

```zig
pub const Error = ElfDynLibError || DlDynLibError;
```

The error set includes platform-specific loader, file, mapping, and format errors.

## Core Functions

### `pub fn open(path: []const u8) Error!DynLib`

Loads a dynamic library by path or name. The source explicitly warns that this trusts the file and a malicious library can execute arbitrary code.

### `pub fn openZ(path_c: [*:0]const u8) Error!DynLib`

Loads a dynamic library using a sentinel-terminated path.

### `pub fn close(self: *DynLib) void`

Closes or unmaps the loaded library. After closing, the handle must not be used.

### `pub fn lookup(self: *DynLib, comptime T: type, name: [:0]const u8) ?T`

Looks up a sentinel-terminated symbol name and casts it to `T`. Returns `null` when the symbol is not found.

## Platform Implementations

### `ElfDynLib`

ELF loader used for selected Linux configurations. It maps ELF dynamic libraries, validates ELF headers, reads dynamic linking information, and resolves exported symbols through SysV or GNU hash tables.

Public implementation helpers include `open`, `openZ`, `close`, `lookup`, and `lookupAddress`.

### `DlDynLib`

`dlopen`/`dlsym`/`dlclose` wrapper used on supported libc-backed platforms. Public helpers include `open`, `openZ`, `close`, `lookup`, and `getError`.

## Module-Level Helpers

### `pub fn get_DYNAMIC() ?[*]const elf.Dyn`

Returns the `_DYNAMIC` extern symbol when present.

### `pub fn linkmap_iterator() error{InvalidExe}!LinkMap.Iterator`

Returns an iterator over the dynamic link map for supported ELF executables.

## Example

```zig
const std = @import("std");

var lib = try std.DynLib.open("libexample.so");
defer lib.close();

const InitFn = *const fn () callconv(.c) void;
const init = lib.lookup(InitFn, "example_init") orelse return error.MissingSymbol;
init();
```

## Notes

- Loading a library may run arbitrary code from that library.
- Symbol names passed to `lookup` must be sentinel-terminated.
- The exact search behavior depends on the selected platform implementation.

## See Also

- `std.os`
- `std.posix`
