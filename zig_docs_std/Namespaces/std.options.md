# std.options

## Overview

`std.options` is the compile-time standard-library configuration value. It has type `std.Options` and is initialized from `root.std_options` when present, otherwise it uses default values.

Source: `/path/to/zig-0.16.0/lib/std/std.zig`

## Declaration

```zig
pub const options: Options = if (@hasDecl(root, "std_options")) root.std_options else .{};
```

## Configurable Fields

The `std.Options` type includes fields for:

- segfault handler enablement
- alternative signal stack size
- default log level and scope-specific log levels
- custom log function
- heap page-size overrides and page-size query function
- formatting recursion depth
- HTTP TLS and SSL key-log behavior
- cryptographic side-channel mitigations
- stack tracing enablement
- networking enablement for `std.Io` implementations
- unexpected-error tracing

It also includes public declarations for:

- terminal log mode selection
- ELF debug-info search paths
- debug I/O selection
- file permission type override
- current working directory override

## Notes

Define `pub const std_options = std.Options{ ... };` in the root source file to override these settings for an application or library. Fields not specified use the defaults from `std.Options`.
