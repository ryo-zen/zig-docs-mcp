# std.Io.Poller

Provides a mechanism for monitoring multiple I/O streams simultaneously and reading from them once data is available.

## Overview

`std.Io.Poller` is the core mechanism for multiplexing I/O in Zig's 0.16 system. It allows you to wait for any of a set of files or sockets to become ready for reading.

- **Multiplexing:** Handles multiple streams via a generated `PollFiles` struct.
- **Cross-platform:** Maps to `poll`/`epoll`/`kqueue` on POSIX and `OVERLAPPED` I/O on Windows.
- **Integrated Buffering:** Contains internal `Reader` instances for each stream.

## Parameters

`StreamEnum: type`
The enum type defining the set of streams to be polled (same as passed to `PollFiles`).

## Fields

`gpa: Allocator`
The allocator used for internal buffers.

`readers: [enum_fields.len]Reader`
An array of `std.Io.Reader` instances, one for each stream defined in `StreamEnum`.

## Functions

### `pub fn poll(self: *Self) !bool`
Wait indefinitely for at least one stream to become ready. Returns `true` if any stream is ready, `false` on end-of-stream for all monitored files.

------

### `pub fn pollTimeout(self: *Self, nanoseconds: u64) !bool`
Wait for up to `nanoseconds` for a stream to become ready.

- **Returns:** `true` if data is ready, `false` if the timeout expired.

------

### `pub fn reader(self: *Self, which: StreamEnum) *Reader`
Returns a pointer to the `Reader` associated with the specific stream variant. Once `poll` returns `true`, you can use this reader to consume the available data.

------

### `pub fn toOwnedSlice(self: *Self, which: StreamEnum) error{OutOfMemory}![]u8`
Reads all currently buffered data for the specified stream and returns it as an allocated slice owned by the caller.

------

### `pub fn deinit(self: *Self) void`
Releases all internal buffers and resources. Does not close the underlying files/sockets.

## Usage Example

```zig
const std = @import("std");

const MyStreams = enum { stdout, stderr };

pub fn main() !void {
    // ... setup io and get files ...
    
    const files = std.Io.PollFiles(MyStreams){
        .stdout = child_process.stdout,
        .stderr = child_process.stderr,
    };

    var poller = std.Io.poll(allocator, MyStreams, files);
    defer poller.deinit();

    while (try poller.poll()) {
        if (poller.reader(.stdout).bufferedLen() > 0) {
            const out = try poller.toOwnedSlice(.stdout);
            defer allocator.free(out);
            std.debug.print("Stdout: {s}", .{out});
        }
        // ... check stderr ...
    }
}
```

## See Also

- [std.Io.PollFiles](std.Io.PollFiles.md) - Helper for generating the input struct.
- [std.Io.Reader](std.Io.Reader.md) - The interface for reading data from the poller.
- [std.Io](std.io.md) - The `std.Io.poll` factory function.