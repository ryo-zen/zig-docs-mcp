# std.debug.ConfigurableTrace

## Overview

`std.debug.ConfigurableTrace` is a generic tracing helper that records recent points of interest (addresses + notes) in a fixed-size ring buffer.

It is intended for debugging object history, mutation origins, and call-path breadcrumbs with compile-time control over memory cost and enablement.

## Parameters

    size: usize

Number of trace records retained.

    stack_frame_count: usize

Number of return addresses captured per record.

    is_enabled: bool

Compile-time toggle. When `false`, tracing compiles to no-op behavior and zero/near-zero overhead.

### Fields

    addrs: [actual_size][stack_frame_count]usize

Recorded frame-address snapshots.

    notes: [actual_size][]const u8

Caller-provided annotation for each record.

    index: Index

Current insertion position/state for the ring buffer.

## Values

|         |           |     |
|---------|-----------|-----|
| add     |           |     |
| enabled |           |     |
| init    | `@This()` |     |

## Functions

`pub fn addAddr(t: *@This(), addr: usize, note: []const u8) void`
Adds a trace entry with an explicit address and note.

`pub noinline fn addNoInline(t: *@This(), note: []const u8) void`
Adds a trace entry while discouraging inlining, useful for clearer stack provenance.

`pub inline fn addNoOp(t: *@This(), note: []const u8) void`
No-op entry point used in disabled/optimized configurations.

`pub fn dump(t: @This()) void`
Prints collected trace information for debugging.

`pub fn format( t: @This(), comptime fmt: []const u8, options: std.fmt.Options, writer: *Writer, ) !void`
Formats the trace for writer-based output.

## Typical Usage

```zig
const std = @import("std");
const builtin = @import("builtin");

const Trace = std.debug.ConfigurableTrace(8, 4, builtin.mode == .Debug);

const State = struct {
    trace: Trace = .init,
};
```

## Gotchas

- Notes are stored as slices; ensure note memory remains valid for as long as the trace is inspected.
- Larger `size` and `stack_frame_count` increase debug memory footprint.
- For default settings, use `std.debug.Trace`.

## Related APIs

- `std.debug.Trace`
- `std.debug.dumpCurrentStackTrace`
