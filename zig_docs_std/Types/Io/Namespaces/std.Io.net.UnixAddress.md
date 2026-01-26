# std.Io.net.UnixAddress

### Fields

    path: []const u8

## Types

- ListenOptions

## Values

|         |     |     |
|---------|-----|-----|
| max_len |     |     |

## Functions

`pub fn connect(ua: *const UnixAddress, io: Io) ConnectError!Stream`  

`pub fn init(p: []const u8) InitError!UnixAddress`  

`pub fn listen(ua: *const UnixAddress, io: Io, options: ListenOptions) ListenError!Server`  

## Error Sets

- ConnectError
- InitError
- ListenError
