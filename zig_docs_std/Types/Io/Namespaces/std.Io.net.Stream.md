# std.Io.net.Stream

An open socket connection with a network protocol that guarantees sequencing, delivery, and prevents repetition. Typically TCP or UNIX domain socket.

### Fields

    socket: Socket

## Types

- Reader
- Writer

## Functions

`pub fn close(s: *const Stream, io: Io) void`  

`pub fn reader(stream: Stream, io: Io, buffer: []u8) Reader`  

`pub fn shutdown(s: *const Stream, io: Io, how: ShutdownHow) ShutdownError!void`  

`pub fn writer(stream: Stream, io: Io, buffer: []u8) Writer`  
