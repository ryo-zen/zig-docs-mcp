# std.dwarf

## Overview

`std.dwarf` contains constants and enums for DWARF debugging information and exception-handling metadata.

Source: `/path/to/zig-0.16.0/lib/std/dwarf.zig`

## Public API

### Imported Constant Namespaces

- `std.dwarf.TAG`
- `std.dwarf.AT`
- `std.dwarf.OP`
- `std.dwarf.LANG`
- `std.dwarf.FORM`
- `std.dwarf.ATE`
- `std.dwarf.EH`

### Format and Encoding Groups

- `std.dwarf.Format` - 32-bit or 64-bit DWARF format.
- `std.dwarf.LLE` - location-list entry constants.
- `std.dwarf.CFA` - call-frame instruction constants.
- `std.dwarf.CHILDREN` - child-presence constants.
- `std.dwarf.LNS` - line-number standard opcodes.
- `std.dwarf.LNE` - line-number extended opcodes.
- `std.dwarf.UT` - unit type constants.
- `std.dwarf.LNCT` - line-number content type constants.
- `std.dwarf.RLE` - range-list entry constants.
- `std.dwarf.CC` - calling-convention enum.
- `std.dwarf.ACCESS` - access-control constants.

## Notes

Use this namespace for debug-info readers, writers, stack unwinding support, and tooling that needs DWARF numeric constants.
