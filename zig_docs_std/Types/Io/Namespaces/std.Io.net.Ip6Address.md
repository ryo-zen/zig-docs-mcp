# std.Io.net.Ip6Address

An IPv6 address in binary memory layout.

### Fields

    port: u16

Native endian

    bytes: [16]u8

Big endian

    flow: u32 = 0

    interface: Interface = .none

## Types

- Policy
- Unresolved

## Functions

`pub fn eql(a: Ip6Address, b: Ip6Address) bool`  

`pub fn format(a: Ip6Address, w: *Io.Writer) Io.Writer.Error!void`  
See `formatResolved` for an alternative that additionally prints the optional scope at the end of addresses and requires an `Io` parameter.

`pub fn formatResolved(a: Ip6Address, io: Io, w: *Io.Writer) FormatError!void`  
Includes the optional scope ("%foo" at the end).

`pub fn fromAny(addr: IpAddress) Ip6Address`  
Given an `IpAddress`, converts it to an `Ip6Address` directly, or via constructing an IPv4-mapped IPv6 address.

`pub fn fromIp4(ip4: Ip4Address) Ip6Address`  
Constructs an IPv4-mapped IPv6 address.

`pub fn isLinkLocal(a: Ip6Address) bool`  

`pub fn isLoopBack(a: Ip6Address) bool`  

`pub fn isMultiCast(a: Ip6Address) bool`  

`pub fn isSiteLocal(a: Ip6Address) bool`  

`pub fn loopback(port: u16) Ip6Address`  

`pub fn parse(buffer: []const u8, port: u16) ParseError!Ip6Address`  
This is a pure function but it cannot handle IPv6 addresses that have scope ids ("%foo" at the end). To also handle those, `resolve` must be called instead, or the lower level `Unresolved` API may be used.

`pub fn policy(a: Ip6Address) *const Policy`  

`pub fn resolve(io: Io, buffer: []const u8, port: u16) ResolveError!Ip6Address`  
This function requires an `Io` parameter because it must query the operating system to convert interface name to index. For example, in "fe80::e0e:76ff:fed4:cf22%eno1", "eno1" must be resolved to an index by creating a socket and then using an `ioctl` syscall.

`pub fn scope(a: Ip6Address) u8`  

`pub fn unspecified(port: u16) Ip6Address`  

## Error Sets

- FormatError
- ParseError
- ResolveError
