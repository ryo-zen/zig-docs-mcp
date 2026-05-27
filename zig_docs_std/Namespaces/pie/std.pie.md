# std.pie

## Overview

`std.pie` contains startup-time relocation support for position-independent executables.

Source: `/path/to/zig-0.16.0/lib/std/pie.zig`

## Public API

- `std.pie.relocate(phdrs)` - applies relative relocations discovered from ELF program headers.

## Notes

This is low-level runtime startup machinery. Most application code should not call it directly.
