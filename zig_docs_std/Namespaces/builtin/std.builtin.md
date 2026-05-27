# std.builtin

## Overview

`std.builtin` defines shared compiler-facing types used by builtins, target descriptions, reflection, calling conventions, panic handling, and compile-time options.

Source: `/path/to/zig-0.16.0/lib/std/builtin.zig`

## Public API Areas

### Compiler and Runtime Types

- `std.builtin.StackTrace`
- `std.builtin.SourceLocation`
- `std.builtin.Type` and `std.builtin.TypeId`
- `std.builtin.TestFn`
- `std.builtin.panic`

### Linkage, Calling, and Codegen

- `std.builtin.GlobalLinkage`
- `std.builtin.SymbolVisibility`
- `std.builtin.CallingConvention`
- `std.builtin.AddressSpace`
- `std.builtin.CodeModel`
- `std.builtin.OptimizeMode`
- `std.builtin.CompilerBackend`

### Atomic, Reduce, and Call Options

- `std.builtin.AtomicOrder`
- `std.builtin.AtomicRmwOp`
- `std.builtin.ReduceOp`
- `std.builtin.CallModifier`
- `std.builtin.BranchHint`
- `std.builtin.PrefetchOptions`

### Target and Output Settings

- `std.builtin.Endian`
- `std.builtin.Signedness`
- `std.builtin.OutputMode`
- `std.builtin.LinkMode`
- `std.builtin.UnwindTables`
- `std.builtin.WasiExecModel`
- `std.builtin.FloatMode`

### C ABI Helpers

- `std.builtin.VaList`
- Architecture-specific `VaList*` structs.
- `std.builtin.ExportOptions`
- `std.builtin.ExternOptions`

## Notes

This namespace is different from `@import("builtin")`. `@import("builtin")` is generated for the current compilation. `std.builtin` provides reusable type definitions used by compiler-generated builtin data and standard-library APIs.
