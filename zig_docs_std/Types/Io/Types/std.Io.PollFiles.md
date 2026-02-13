# std.Io.PollFiles

A metaprogramming helper that generates a struct type for use with `std.Io.poll`.

## Overview

`std.Io.PollFiles` takes an enum type as a parameter and returns a struct type. This generated struct has fields corresponding exactly to the fields of the input enum. Each field in the generated struct is of type `std.Io.File`.

This is primarily used to prepare a set of file descriptors (represented by `std.Io.File`) to be monitored simultaneously by `std.Io.poll`.

## Parameters

`StreamEnum: type`
An enum type where each variant represents a distinct IO stream you want to poll.

## Generated Type

The returned type is structurally equivalent to:
```zig
struct {
    // For each field 'Variant' in StreamEnum:
    Variant: std.Io.File,
    // ...
}
```

## Usage Example

```zig
const std = @import("std");

// 1. Define your streams
const MyStreams = enum {
    server_socket,
    console_input,
};

// 2. Generate the struct type
const MyPollFiles = std.Io.PollFiles(MyStreams);

pub fn main() !void {
    // ... setup io ...

    // 3. Initialize the struct with actual files
    var files: MyPollFiles = undefined;
    // Assuming you have 'server' and 'stdin' available:
    // files.server_socket = server.socket.handle; // Note: You need an Io.File here, so you might need to wrap handles
    // files.console_input = std.io.getStdIn();

    // 4. Use with std.Io.poll (hypothetical usage context)
    // var poller = std.Io.poll(allocator, MyStreams, files);
}
```

## See Also

- `std.Io.File` - The type of the fields in the generated struct.
- `std.Io.Poller` - The type returned by `std.Io.poll`.
