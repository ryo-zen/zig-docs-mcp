# std.wasm

## Overview

`std.wasm` contains WebAssembly binary-format constants, opcodes, section identifiers, value types, and small data structures.

Source: `/path/to/zig-0.16.0/lib/std/wasm.zig`

## Public API

### Opcodes

- `std.wasm.Opcode`
- `std.wasm.MiscOpcode`
- `std.wasm.SimdOpcode`
- `std.wasm.AtomicsOpcode`

### Types and Sections

- `std.wasm.Valtype`
- `std.wasm.RefType`
- `std.wasm.Limits`
- `std.wasm.InitExpression`
- `std.wasm.Memory`
- `std.wasm.Section`
- `std.wasm.ExternalKind`
- `std.wasm.NameSubsection`
- `std.wasm.BlockType`

### Constants

- `std.wasm.element_type`
- `std.wasm.function_type`
- `std.wasm.result_type`
- `std.wasm.magic`
- `std.wasm.version`
- `std.wasm.page_size`

## Notes

This namespace is for WebAssembly tooling, encoders, decoders, and target-specific code that needs raw wasm constants.
