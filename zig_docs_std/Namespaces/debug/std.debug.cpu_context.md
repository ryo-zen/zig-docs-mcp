# std.debug.cpu_context

## Overview

`std.debug.cpu_context` provides platform-specific helpers for extracting a native CPU context from OS-specific signal/exception payloads.

This is primarily used by stack-unwinding code paths that need register state from crash handlers.

## Types

- Native

## Functions

`pub fn fromPosixSignalContext(ctx_ptr: ?*const anyopaque) ?Native`
Attempts to parse a POSIX signal context pointer into a `Native` CPU context.

`pub fn fromWindowsContext(ctx: *const std.os.windows.CONTEXT) Native`
Converts a Windows `CONTEXT` to `Native`.

## Error Sets

- DwarfRegisterError

## Usage Notes

- `Native` is target-dependent and may be unavailable on some targets.
- `fromPosixSignalContext` returns `null` when context extraction is not possible.
- Typical consumers pass the resulting context through `std.debug.StackUnwindOptions.context`.
