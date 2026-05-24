# std.Io.PollFiles

`std.Io.PollFiles` is not present in Zig 0.16.

Older drafts used `PollFiles` with a removed `std.Io.poll`/`std.Io.Poller`
API. Current Zig 0.16 code should model concurrent I/O with `std.Io` tasks and
futures, or read individual file pipes through `std.Io.File.readerStreaming`.

For current code, prefer:

- `io.async` / `io.concurrent` plus `io.select` for task coordination.
- `std.Io.File.readerStreaming` for file pipe output.
- `std.Io.net` socket and stream APIs for networking.

## See Also

- [std.Io](../std.io.md)
- [std.Io.Future](std.Io.Future.md)
- [std.Io.Reader](std.Io.Reader.md)
