# std.Options

`std.Options` is the root configuration type for compile-time settings that can be overridden by the root source file.

## Source Declaration

```zig
const root = @import("root");

pub const options: Options = if (@hasDecl(root, "std_options")) root.std_options else .{};

pub const Options = struct {
    // settings...
};
```

Applications override these settings by declaring `std_options` in their root source file.

## Example

```zig
const std = @import("std");

pub const std_options: std.Options = .{
    .log_level = .debug,
    .networking = true,
    .http_disable_tls = false,
};
```

## Runtime Value

The resolved value is exposed as `std.options`. If the root file does not declare `std_options`, the default `.{}`
value is used.

## Configurable Settings

### `enable_segfault_handler: bool = debug.default_enable_segfault_handler`

Enables the standard segmentation fault handler when supported.

### `signal_stack_size: ?u64 = 1 << 18`

Requests an alternative per-thread signal stack for `std.start` and `std.Thread`. On Windows this value is currently ignored.

### `log_level: log.Level = log.default_level`

Sets the current standard logging level.

### `log_scope_levels: []const log.ScopeLevel = &.{}`

Provides per-scope log level overrides.

### `logFn`

Overrides the standard logging function. The default is `log.defaultLog`.

### `page_size_min: ?usize = null`

Overrides `std.heap.page_size_min`.

### `page_size_max: ?usize = null`

Overrides `std.heap.page_size_max`.

### `queryPageSize: fn () usize = heap.defaultQueryPageSize`

Overrides the runtime OS page-size query function.

### `fmt_max_depth: usize = fmt.default_max_depth`

Sets the maximum depth used by standard formatting.

### `http_disable_tls: bool = false`

Disables TLS support in the standard HTTP client when true.

### `http_enable_ssl_key_log_file: bool = builtin.mode == .Debug`

Enables SSL key logging for the standard HTTP client through `SSLKEYLOGFILE`.

### `side_channels_mitigations: crypto.SideChannelsMitigations = crypto.default_side_channels_mitigations`

Selects the standard library's side-channel mitigation policy.

### `allow_stack_tracing: bool = !builtin.strip_debug_info`

Controls whether stack traces may be captured and written.

### `networking: bool = true`

Allows networking in standard I/O implementations when true.

### `unexpected_error_tracing`

Controls whether `error.Unexpected` prints its value and a stack trace on supported debug backends.

## Public Declaration Overrides

Several settings are exposed as public declarations rather than ordinary fields:

### `logTerminalMode`

Returns the terminal mode used by logging.

### `elf_debug_info_search_paths`

Optionally overrides ELF debug info search path discovery.

### `debug_threaded_io`

Optionally overrides the threaded I/O instance used for standard debugging operations.

### `debug_io`

Overrides the I/O instance used by `std.debug` for printing, stack traces, executable path discovery, and terminal-mode-related environment lookup.

### `FilePermissions`

Optionally overrides standard file permissions type selection.

### `cwd`

Optionally overrides the standard current working directory provider.

## Notes

- `std_options` must be comptime-known.
- The default `debug_io` is independent from an application's primary `std.Io` instance.
- Disabling TLS makes HTTPS connections impossible through the standard HTTP client.
- Disabling stack tracing leaves captured traces empty and causes write attempts to report that stack traces are unavailable.

## See Also

- `std.options`
- `std.start`
- `std.Thread`
- `std.log`
