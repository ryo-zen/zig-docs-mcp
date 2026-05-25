# std.Thread

`std.Thread` is the root import of `Thread.zig`, a platform-backed kernel thread handle.

## Source Declaration

```zig
pub const Thread = @import("Thread.zig");
```

## Backing Type

```zig
impl: Impl,
```

`Impl` is selected at compile time from the native OS and linking mode: Windows, pthreads, Linux without pthreads, WASI, or an unsupported compile-error implementation.

## Public Constants and Types

### `use_pthreads`

True when the native target uses pthreads through libc.

### `max_name_len`

Maximum supported thread name length for the native target. Unsupported targets use 0.

### `Id`

Platform thread ID type. It is guaranteed to be unique only within the process.

### `Handle`

Platform thread handle type from the selected implementation.

### `SpawnConfig`

```zig
pub const SpawnConfig = struct {
    stack_size: usize = default_stack_size,
    allocator: ?std.mem.Allocator = null,
};
```

`default_stack_size` is 16 MiB. WASI spawning requires an allocator.

## Error Sets

- `SetNameError`
- `GetNameError`
- `CpuCountError`
- `SpawnError`
- `YieldError`

## Core Functions

### `pub fn spawn(config: SpawnConfig, comptime function: anytype, args: anytype) SpawnError!Thread`

Spawns a new thread that calls `function` with `args`. The returned handle must later be consumed by `join` or `detach`.

The entry function may return `void`, `noreturn`, `u8`, `!void`, or `!noreturn`.

### `pub fn join(self: Thread) void`

Waits for the thread to complete and frees resources created by `spawn`. Consumes the `Thread`.

### `pub fn detach(self: Thread) void`

Releases the caller from the obligation to call `join`; the thread cleans up its resources on completion. Consumes the `Thread`.

### `pub fn getHandle(self: Thread) Handle`

Returns the platform handle.

### `pub fn getCurrentId() Id`

Returns the platform ID of the caller's thread, using thread-local storage where possible.

### `pub fn getCpuCount() CpuCountError!usize`

Returns the platform's view of available logical CPU cores. The returned value is at least 1.

### `pub fn setName(self: Thread, io: Io, name: []const u8) SetNameError!void`

Sets a thread name when supported by the native platform.

### `pub fn getName(self: Thread, buffer_ptr: *[max_name_len:0]u8) GetNameError!?[]const u8`

Gets a thread name when supported. On Windows the result is WTF-8. On other platforms it is an opaque byte sequence.

### `pub fn yield() YieldError!void`

Yields the current thread, potentially allowing another thread to run.

### `pub fn maybeAttachSignalStack() void`

Configures the per-thread alternative signal stack requested by the configured signal stack size option.

## Example

```zig
const std = @import("std");

fn worker(value: *usize) void {
    value.* += 1;
}

var value: usize = 0;
const thread = try std.Thread.spawn(.{}, worker, .{&value});
thread.join();
```

## Notes

- `spawn` compile-errors when building in single-threaded mode.
- After `join` or `detach`, using the consumed `Thread` is undefined behavior.
- Thread naming support and limits are platform-specific.
- On WASI, `SpawnConfig.allocator` must be provided.

## See Also

- `std.Io`
- `std.Options.signal_stack_size`
