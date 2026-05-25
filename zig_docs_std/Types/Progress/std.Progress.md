# std.Progress

`std.Progress` is the root import of `Progress.zig`, a global progress reporting API used by command-line tools and child process progress forwarding.

## Source Declaration

```zig
pub const Progress = @import("Progress.zig");
```

## Overview

The source describes this API as non-allocating, non-fallible, thread-safe, and lock-free. A process can initialize one global progress instance with `start`, create child `Node` values, update counters and names, and finish nodes with `Node.end`.

On unsupported or single-threaded configurations, the implementation becomes a no-op and returns `Node.none`.

## Main Types

### `Status`

```zig
pub const Status = enum {
    working,
    success,
    failure,
    failure_working,
};
```

### `Options`

Options passed to `start`:

- `draw_buffer: []u8 = &default_draw_buffer`
- `refresh_rate_ns: Io.Duration = .fromMilliseconds(80)`
- `initial_delay_ns: Io.Duration = .fromMilliseconds(200)`
- `estimated_total_items: usize = 0`
- `root_name: []const u8 = ""`
- `disable_printing: bool = false`

The draw buffer must have static lifetime and at least 200 bytes.

### `Node`

`Node` represents one unit of progress. Nodes can have children and can track completed and estimated item counts. `Node.none` is a valid no-op node.

Public node helpers include:

- `start`
- `startFmt`
- `completeOne`
- `setName`
- `getName`
- `setCompletedItems`
- `setEstimatedTotalItems`
- `increaseEstimatedTotalItems`
- `end`
- `setIpcFile`
- `setIpcIndex`
- `takeIpcIndex`

### `TerminalMode`

Terminal output mode:

- `off`
- `ansi_escape_codes`
- `windows_api`

### `StartFailure`

Records why `start` failed to initialize a worker or parent IPC connection:

- `unstarted`
- `spawn_ipc_worker`
- `spawn_update_worker`
- `parent_ipc`

## Core Functions

### `pub fn start(io: Io, options: Options) Node`

Initializes the single global progress instance and returns the root node. Call `Node.end` on the returned node when the work is done.

The function asserts that no global progress object has already been initialized.

### `pub fn setStatus(new_status: Status) void`

Updates the global status used by rendering.

### `pub fn clearWrittenWithEscapeCodes(file_writer: *Io.File.Writer) Io.Writer.Error!void`

Clears progress output previously written with ANSI escape codes when clearing is needed.

## Constants

- `max_packet_len`
- `have_ipc`

## Example

```zig
const std = @import("std");

const root = std.Progress.start(std.Options.debug_io, .{
    .root_name = "work",
    .estimated_total_items = 2,
});
defer root.end();

const child = root.start("compile", 0);
defer child.end();

child.completeOne();
```

## Notes

- There can be only one global progress instance.
- `estimated_total_items` of 0 means unknown.
- Node names are truncated to `Node.max_name_len`.
- Progress output may be disabled by target support, single-threaded builds, terminal support, or `disable_printing`.

## See Also

- `std.Io`
- `std.process.Child`
