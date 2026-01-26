# std.Io.net.Socket

An open port with unspecified protocol.

### Fields

    handle: Handle

    address: IpAddress

Contains the resolved ephemeral port number if requested.

## Types

- Handle
- Mode
- receiveManyTimeout

## Functions

`pub fn close(s: *const Socket, io: Io) void`  
Leaves `address` in a valid state.

`pub fn closeMany(io: Io, sockets: []const Socket) void`  

`pub fn receive(s: *const Socket, io: Io, buffer: []u8) ReceiveError!IncomingMessage`  
Waits for data. Connectionless.

`pub fn receiveTimeout( s: *const Socket, io: Io, buffer: []u8, timeout: Io.Timeout, ) ReceiveTimeoutError!IncomingMessage`  
Waits for data. Connectionless.

`pub fn send(s: *const Socket, io: Io, dest: *const IpAddress, data: []const u8) SendError!void`  
Transfers `data` to `dest`, connectionless, in one packet.

`pub fn sendMany(s: *const Socket, io: Io, messages: []OutgoingMessage, flags: SendFlags) SendError!void`  

## Error Sets

- ReceiveError
- ReceiveTimeoutError
- SendError
