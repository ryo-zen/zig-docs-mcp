# std.Io.net.IpAddress

### Fields

    ip4: Ip4Address

    ip6: Ip6Address

## Types

- BindOptions
- ConnectOptions
- ListenOptions

## Values

|        |     |     |
|--------|-----|-----|
| Family |     |     |

## Functions

`pub fn bind(address: *const IpAddress, io: Io, options: BindOptions) BindError!Socket`  
Associates an address with a `Socket` which can be used to receive UDP packets and other kinds of non-streaming messages. See `listen` for a streaming alternative.

`pub fn connect(address: IpAddress, io: Io, options: ConnectOptions) ConnectError!Stream`  
Initiates a connection-oriented network stream.

`pub fn eql(a: *const IpAddress, b: *const IpAddress) bool`  

`pub fn format(a: IpAddress, w: *Io.Writer) Io.Writer.Error!void`  
See `formatResolved` for an alternative that additionally prints the optional scope at the end of IPv6 addresses and requires an `Io` parameter.

`pub fn formatResolved(a: IpAddress, io: Io, w: *Io.Writer) Ip6Address.FormatError!void`  
Includes the optional scope ("%foo" at the end) in IPv6 addresses.

`pub fn getPort(a: IpAddress) u16`  
Returns the port in native endian.

`pub fn listen(address: IpAddress, io: Io, options: ListenOptions) ListenError!Server`  
Waits for a TCP connection. When using this API, `bind` does not need to be called. The returned `Server` has an open `stream`.

`pub fn parse(text: []const u8, port: u16) !IpAddress`  
Parse the given IP address string into an `IpAddress` value.

`pub fn parseIp4(text: []const u8, port: u16) Ip4Address.ParseError!IpAddress`  

`pub fn parseIp6(text: []const u8, port: u16) Ip6Address.ParseError!IpAddress`  
This is a pure function but it cannot handle IPv6 addresses that have scope ids ("%foo" at the end). To also handle those, `resolveIp6` must be called instead.

`pub fn parseLiteral(text: []const u8) ParseLiteralError!IpAddress`  
Parse an IP address which may include a port.

`pub fn resolve(io: Io, text: []const u8, port: u16) !IpAddress`  
This function requires an `Io` parameter because it must query the operating system to convert interface name to index. For example, in "fe80::e0e:76ff:fed4:cf22%eno1", "eno1" must be resolved to an index by creating a socket and then using an `ioctl` syscall.

`pub fn resolveIp6(io: Io, text: []const u8, port: u16) Ip6Address.ResolveError!IpAddress`  

`pub fn setPort(a: *IpAddress, port: u16) void`  
`port` is native-endian.

## Error Sets

- BindError
- ConnectError
- ListenError
- ParseLiteralError
