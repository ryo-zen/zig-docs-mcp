# std.Io.net.Server

### Fields

    socket: Socket

## Functions

`pub fn accept(s: *Server, io: Io) AcceptError!Stream`  
Blocks until a client connects to the server.

`pub fn deinit(s: *Server, io: Io) void`  

## Error Sets

- AcceptError
