# std.zig

## Overview

`std.zig` contains compiler and tooling utilities for Zig source, tokens, ASTs, target parsing, build metadata, source hashing, and compiler protocol support.

Source: `/path/to/zig-0.16.0/lib/std/zig.zig`

## Public API Areas

### Parsing, Tokens, and AST

- `std.zig.Token`
- `std.zig.Tokenizer`
- `std.zig.TokenSmith`
- `std.zig.string_literal`
- `std.zig.number_literal`
- `std.zig.parseCharLiteral`
- `std.zig.parseNumberLiteral`
- `std.zig.Ast`
- `std.zig.AstGen`
- `std.zig.AstSmith`
- `std.zig.Zir`
- `std.zig.Zoir`
- `std.zig.ZonGen`

### Compiler Protocol and Target Utilities

- `std.zig.ErrorBundle`
- `std.zig.Server`
- `std.zig.Client`
- `std.zig.system`
- `std.zig.BuiltinFn`
- `std.zig.LibCInstallation`
- `std.zig.WindowsSdk`
- `std.zig.LibCDirs`
- `std.zig.target`
- `std.zig.llvm`

### Source Hashing and Locations

- `std.zig.SrcHasher`
- `std.zig.SrcHash`
- `std.zig.hashSrc`
- `std.zig.srcHashEql`
- `std.zig.hashName`
- `std.zig.Loc`
- `std.zig.findLineColumn`
- `std.zig.lineDelta`

### Formatting and Identifier Helpers

- `std.zig.fmtId`
- `std.zig.fmtIdFlags`
- `std.zig.fmtIdPU`
- `std.zig.fmtIdP`
- `std.zig.FormatId`
- `std.zig.fmtString`
- `std.zig.fmtChar`
- `std.zig.stringEscape`
- `std.zig.charEscape`
- `std.zig.isValidId`
- `std.zig.isUnderscore`

### Build and Target Metadata

- `std.zig.BinNameOptions`
- `std.zig.binNameAlloc`
- `std.zig.SanitizeC`
- `std.zig.BuildId`
- `std.zig.LtoMode`
- `std.zig.Subsystem`
- `std.zig.CompressDebugSections`
- `std.zig.RcIncludes`
- `std.zig.serializeCpu`
- `std.zig.serializeCpuAlloc`
- `std.zig.EnvVar`
- `std.zig.EmitArtifact`

## Notes

This namespace is mainly for Zig tooling and compiler-adjacent code. It is not needed for ordinary application logic.
