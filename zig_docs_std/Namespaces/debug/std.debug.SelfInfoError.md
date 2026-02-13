# std.debug.SelfInfoError

## Overview

`std.debug.SelfInfoError` is the common error set used by self-debug-info loading and lookup paths.

It distinguishes missing/unsupported debug data from corruption and I/O failures.

## Errors

Canceled
Operation was canceled by caller or environment.

InvalidDebugInfo
The required debug info is invalid or corrupted.

MissingDebugInfo
The required debug info could not be found.

OutOfMemory

ReadFailed
The required debug info could not be read from disk due to some IO error.

Unexpected

UnsupportedDebugInfo
The required debug info was found, and may be valid, but is not supported by this implementation.

## Usage Notes

- Treat `MissingDebugInfo` and `UnsupportedDebugInfo` as expected runtime conditions on stripped or unsupported targets.
- `InvalidDebugInfo` and `ReadFailed` usually indicate actionable deployment or filesystem issues.
- For user-facing diagnostics, convert these errors into clear capability messages rather than hard crashes.
