# std.Io.net.Ip4Address

An IPv4 address in binary memory layout.

### Fields

    bytes: [4]u8

    port: u16

## Functions

`pub fn eql(a: Ip4Address, b: Ip4Address) bool`  

`pub fn format(a: Ip4Address, w: *Io.Writer) Io.Writer.Error!void`  

`pub fn loopback(port: u16) Ip4Address`  

`pub fn parse(buffer: []const u8, port: u16) ParseError!Ip4Address`  

`pub fn unspecified(port: u16) Ip4Address`  

## Error Sets

- ParseError
