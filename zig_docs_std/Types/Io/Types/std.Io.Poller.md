# std.Io.Poller

`std.Io.Poller` is not present in Zig 0.16.

Older migration notes and pre-0.16 examples may mention `std.Io.poll`,
`std.Io.Poller`, or `std.Io.PollFiles`. The current `std.Io` API exposes
async tasks, futures, `select`, file readers, networking operations, and
backend-specific event implementations instead of this polling helper.

For current code, prefer:

- `io.async` / `io.concurrent` plus `io.select` for task coordination.
- `std.Io.File.readerStreaming` for file pipe output.
- `std.Io.net` socket and stream APIs for networking.

## See Also

- [std.Io](../std.io.md)
- [std.Io.Future](std.Io.Future.md)
- [std.Io.Reader](std.Io.Reader.md)
